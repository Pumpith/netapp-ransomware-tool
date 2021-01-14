<# 
.SYNOPSIS 
 NetApp Ransomware Tool with ONTAP Fpolicy
 
.DESCRIPTION 
    Powershell script to install, update, remove NetApp ONTAP Fpolicy capabilities to help with Ransomware protection.
 
.NOTES 
┌─────────────────────────────────────────────────────────────────────────────────────────────┐ 
│ ORIGIN STORY                                                                                │ 
├─────────────────────────────────────────────────────────────────────────────────────────────┤ 
│   DATE        : 2021.01.14 
│   AUTHOR      : PUMPITH UNGSUPANIT
|   EMAIL       : pumpith@netapp.com 
│   DESCRIPTION : Community Edition
└─────────────────────────────────────────────────────────────────────────────────────────────┘ 
 
.EXAMPLE 
    PS C:\> .\NetApp-Ransomware-Tool.ps1 ListPolicyFile
    PS C:\> .\NetApp-Ransomware-Tool.ps1 TestPolicy
    PS C:\> .\NetApp-Ransomware-Tool.ps1 ApplyPolicy
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
#Loading PowerShell assemblies -----

Import-Module DataONTAP

param (
 [string]$func = $args[0]
 )

#----------------------------------------------------------[Customer Parameter]----------------------------------------------------------

$script_location= "C:\NTAP-TOOL"

$share_drive= "Z:"

#--------- Fpolicy Configuration -----

$controller = "cluster1"

$vserver_name = "svm_cifs"

$vol_share_name_include = "cifs_share"

#----------------------------------------------------------[Fix Parameter]----------------------------------------------------------

$fsrm_url= "https://fsrm.experiant.ca/api/v1/get"
$fsrm_csv= "fsrm.csv"

$policy_list= "ransomware-list.txt"
$policy_list_allow= "standard-list.txt"
$policy_list_temp= "ransomware-temp.txt"
$policy_list_verify= "ransomware-list-verify.txt"

$script_location_log= $script_location+"\log\"
$exp_policy_dir= $share_drive+"\NTAP\Ransomware\"
$exp_standard_dir= $share_drive+"\NTAP\Standard\"

#--------- Fpolicy Parameter -----

$event_name = "event_"+$vol_share_name_include

$fpolicy_name = "policy_"+$vol_share_name_include

$external_engine_name = "native"

#--------- Volume Parameter ----- 

$file_extension_include = @(Get-Content $script_location\$policy_list) 

$vol_share_name_exclude = "root"

#$file_extension_exclude = ""

#--------- Storage Parameter -----

$password = ConvertTo-SecureString "Netapp1!" -AsPlainText –Force

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $password

Connect-NcController $controller -Credential $cred

#--------- Connect Storage System ----- 

#Connect-NaController $controller -credential (get-credential admin)

Clear-Host

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function ApplyPolicy {

    $CheckEvent = (Get-NcFpolicyEvent -Name $event_name).EventName

    if ($CheckEvent -ne $event_name) {

        New-NcFpolicyEvent -Name $event_name -Protocol cifs -FileOperation create, rename, write -VserverContext $vserver_name
        #New-NcFpolicyExternalEngine -Name $external_engine_name -PrimaryServer 1.1.1.1 -Port 2357 -SslOption no_auth -VserverContext $vserver_name
        New-NcFpolicyPolicy -Name $fpolicy_name -Event $event_name -EngineName $external_engine_name -VserverContext $vserver_name
        New-NcFpolicyScope -PolicyName $fpolicy_name -SharesToInclude $vol_share_name_include -FileExtensionsToInclude $file_extension_include -FileExtensionsToExclude $file_extension_exclude -VserverContext $vserver_name
        Enable-NcFpolicyPolicy -Name $fpolicy_name -SequenceNumber 1 -VserverContext $vserver_name

        Write-Host "#-----------------------------------------------------"
        Write-Host "# Number of Total File Extensions:" ((Get-NcFpolicyScope -PolicyName $fpolicy_name).FileExtensionsToInclude).Count
        Write-Host "#-----------------------------------------------------"

    }

    else {

        Write-Host "Status : Appliy $event_name Fail"
        Write-host "Event  : $event_name is Duplicate"
    }
}

function UpdatePolicy {

    Write-Host "#-----------------------------------------------------"
    (Get-NcFpolicyScope -PolicyName $fpolicy_name).FileExtensionsToInclude > $script_location\$policy_list_temp
    Write-Host "# Number of Before Update File Extensions:" ((Get-NcFpolicyScope -PolicyName $fpolicy_name).FileExtensionsToInclude).Count
    Write-Host "#-----------------------------------------------------"

    Copy-Item -Path $script_location\$policy_list -Destination $script_location\$policy_list_temp
    gc $script_location\$policy_list_temp | sort | get-unique > $script_location\$policy_list

    Set-NcFpolicyScope -PolicyName $fpolicy_name -SharesToInclude $vol_share_name_include -FileExtensionsToInclude $file_extension_include -FileExtensionsToExclude $file_extension_exclude -VserverContext $vserver_name

    Remove-Item -Path $script_location\$policy_list_temp –recurse

    Write-Host "#-----------------------------------------------------"
    Write-Host "# Number of After Update File Extensions:" ((Get-NcFpolicyScope -PolicyName $fpolicy_name).FileExtensionsToInclude).Count
    Write-Host "#-----------------------------------------------------"
}

function DeletePolicy {

    Write-Host "#-----------------------------------------------------"
    Write-Host "# Status : Total File Extensions Remove"
    Write-Host "#-----------------------------------------------------"
    Get-NcFpolicyPolicy -Name $fpolicy_name
    Write-Host "#-----------------------------------------------------"

    Disable-NcFpolicyPolicy -Name $fpolicy_name -VserverContext $vserver_name
    # Delete an FPolicy policy scope
    Remove-NcFpolicyScope -PolicyName $fpolicy_name -VserverContext $vserver_name
    # Delete a policy
    Remove-NcFpolicyPolicy -Name $fpolicy_name -VserverContext $vserver_name
    # Delete FPolicy event
    Remove-NcFpolicyEvent -Name $event_name -VserverContext $vserver_name

    Write-Host "#-----------------------------------------------------"
    Write-Host "# Status : Total File Extensions Remove"
    Write-Host "#-----------------------------------------------------"
    Get-NcFpolicyPolicy -Name $fpolicy_name
    Write-Host "#-----------------------------------------------------"

}

function ListVolume {
    Write-Host "#-----------------------------------------------------"
    Write-Host "# Status : List Volume"
    Write-Host "#-----------------------------------------------------"

    Get-NaFpolicyVolumeList ransomware_policy
}

function ListPolicy {

    Write-Host "# --------------------------------"
    Write-Host "# List All File Extensions in Policy = " $fpolicy_name
    Write-Host "# --------------------------------"

    (Get-NcFpolicyScope -PolicyName $fpolicy_name).FileExtensionsToInclude

    Write-Host "# --------------------------------"
    Write-Host "# Total List File Extensions in Policy =  " ((Get-NcFpolicyScope -PolicyName $fpolicy_name).FileExtensionsToInclude).Length
    Write-Host "# --------------------------------"

}

function ListPolicyFile {

    Write-Host "# --------------------------------"
    Write-Host "# List All File Extensions in File = " $script_location\$policy_list
    Write-Host "# --------------------------------"

    Get-Content $script_location\$policy_list

    Write-Host "# --------------------------------"
    Write-Host "# Total List File Extensions in File = " (Get-Content $script_location\$policy_list).Length 
    Write-Host "# --------------------------------"

}

function TestPolicy {

    $i=0

    #$Randomtext = -join ((33..126) | Get-Random -Count 1 | % {[char]$_})
    #Replace string * to . 
    $Randomtext = "."

    #Write-Host "Replace string * to " $Randomtext

    #Create NTAP Ransomware Folder
    if(!(Test-Path -path $exp_policy_dir))  
    {  
        New-Item -ItemType directory -Path $exp_policy_dir
        Write-Host "Folder path has been created successfully at: " $exp_policy_dir
               
    }
    else
    {
        Write-Host "The given folder path $directoyPath already exists";
    }

    #Create File from Ransomware list
    Copy-Item $script_location\$policy_list -Destination $script_location_log\$policy_list_verify

    Get-Content $script_location\$policy_list | % { $_ -replace '[*]', $Randomtext} | Out-File $script_location_log\$policy_list_verify

    Remove-Item -path $exp_policy_dir\* –recurse

        foreach($line in Get-Content $script_location_log\$policy_list_verify) {

            if($line -match $regex){
                # Work here
                $i++;
                write-host "Ransomware Name $i :  " $line
                New-Item -Path $exp_policy_dir -Name $i"."$line -ItemType "file" -Value $line
                #sleep(1)
            }
        }

    Get-ChildItem $exp_policy_dir | Sort CreationTime | Out-File $script_location_log\$policy_list_verify.log

    Write-Host "# --------------------------------"
    #Write-Host "Replate * = " $randomtext
    Write-Host "File Extensions   =" (Get-Content $script_location_log\$policy_list_verify).Length 
    Write-Host "Total Create File =" @( Get-ChildItem $exp_policy_dir ).Count;
    Write-Host "# --------------------------------"

}

function TestStandard {

    $i=0

    #Create NTAP Ransomware Folder
    if(!(Test-Path -path $exp_standard_dir))  
    {  
        New-Item -ItemType directory -Path $exp_standard_dir
        Write-Host "Folder path has been created successfully at: " $exp_standard_dir
               
    }
    else
    {
        Write-Host "The given folder path $directoyPath already exists";
    }

    Remove-Item -path $exp_standard_dir\* –recurse

        foreach($line in Get-Content $script_location\$policy_list_allow) {

            if($line -match $regex){
                # Work here
                $i++;
                write-host "Ransomware Name $i :  " $line
                New-Item -Path $exp_standard_dir -Name $i"."$line -ItemType "file" -Value $line
                #sleep(1)
            }
        }

    Get-ChildItem $exp_standard_dir | Sort CreationTime | Out-File $script_location_log\$policy_list_allow.log

    Write-Host "# --------------------------------"
    Write-Host "File Extensions   =" (Get-Content $script_location\$policy_list_allow).Length 
    Write-Host "Total Create File =" @( Get-ChildItem $exp_standard_dir ).Count;
    Write-Host "# --------------------------------"

}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

switch ($func) {

"DeletePolicy"  {
    Write-Host "# --------------------------------"
    Write-Host "# !! Warning !! Do you want delete policy !! >> " $fpolicy_name;
    Write-Host "# --------------------------------"
    Write-Host "Press Enter to continue"

    $userInput = Read-Host
    RemoveFpolicy
    }

"ApplyPolicy"  {
    Write-Host "# --------------------------------"
    Write-Host "# Apply Ransomware Policy and List to NetApp Fpolicy !!";
    Write-Host "# --------------------------------"
    Write-Host "Press Enter to continue"
    $userInput = Read-Host
    ApplyPolicy
    }

"UpdatePolicy"  {
    Write-Host "# --------------------------------"
    Write-Host "# Update Ransomware List to NetApp Fpolicy !!";
    Write-Host "# Number for New Exentsion :" (Get-Content $script_location\$policy_list).Length
    Write-Host "# --------------------------------"
    Write-Host "Press Enter to continue"
    $userInput = Read-Host
    UpdatePolicy 
    }

"ListVolume"  {
    Clear-Host
    ListVolume
    }

"ListPolicy"  {
    Clear-Host
    ListPolicy
    }

"ListPolicyFile"  {
    Clear-Host
    ListPolicyFile
    }

"TestPolicy"  {
    Write-Host "# --------------------------------"
    Write-Host "# Testing Create Ransomware File to" $exp_policy_dir;
    Write-Host "# --------------------------------"
    Write-Host "Press Enter to continue"
    $userInput = Read-Host
    TestPolicy
    }

"TestStandard"  {
    Write-Host "# --------------------------------"
    Write-Host "# Testing Create Standard File to" $exp_standard_dir;
    Write-Host "# --------------------------------"
    Write-Host "Press Enter to continue"
    $userInput = Read-Host
    TestStandard 
    }

"AllPolicy"{
    DeletePolicy
    ApplyPolicy
    UpdatePolicy
}

    Default {
    Write-Host "# ==========================================="
    Write-Host "# NetApp Ransomware Tool - Community Edition"
    Write-Host "# ==========================================="
    Write-Host "# Help NetApp-Ransomware-Tool.ps1;"
    Write-Host "# Command Line     : NetApp-Ransomware-Tool.ps1 function"
    Write-Host "# Example          : NetApp-Ransomware-Tool.ps1 UpdateFpolicy"
    Write-Host "# -------------------------------------------"
    Write-Host "# ListPolicyFile   : List Policy file :" $script_location\$policy_list
    Write-Host "# ListPolicy       : List Policy in system ""$fpolicy_name"" Policy"
    Write-Host "# -------------------------------------------"
    Write-Host "# ApplyPolicy      : Create and Enable Ransomware Policy"
    Write-Host "# UpdatePolicy     : Update Ransomware Policy List"
    Write-Host "# DeletePolicy     : Delete all Policy and File Extensions"
    Write-Host "# AllPolicy        : Delete and Apply Policy"
    Write-Host "# -------------------------------------------"
    Write-Host "# TestPolicy       : Testing Create Ransomware File"
    Write-Host "# TestStandard     : Testing Create Standard File"
    Write-Host "# ==========================================="
    }

}

#-----------------------------------------------------------[Manual Execution]------------------------------------------------------------



#-----------------------------------------------------------[End]------------------------------------------------------------

