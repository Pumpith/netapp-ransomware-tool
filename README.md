# NetApp ONTAP Ransomware Protection with Native FPolicy File Blocking

The NetApp FPolicy solution provides a file blocking methodology that allows organizations to filter or block traffic based on file extensions and file metadata. A great reference for additional information is TR-4572.

The NetApp Solution for Ransomware : https://www.netapp.com/media/7334-tr4572.pdf

This Powershell was written in order to use NetApp ONTAP Fpolicy more conveniently. It supports the ability to create, update, delete in the Policy section through Powershell with the following usability format.

># ==========================================="
># NetApp Ransomware Tool - Community Edition"
># ==========================================="
># Help NetApp-Ransomware-Tool.ps1;"
># Command Line     : NetApp-Ransomware-Tool.ps1 function"
># Example          : NetApp-Ransomware-Tool.ps1 UpdateFpolicy"
># -------------------------------------------"
># ListPolicyFile   : List Policy file :" $script_location\$policy_list
># ListPolicy       : List Policy in system ""$fpolicy_name"" Policy"
># -------------------------------------------"
># ApplyPolicy      : Create and Enable Ransomware Policy"
># UpdatePolicy     : Update Ransomware Policy List"
># DeletePolicy     : Delete all Policy and File Extensions"
># AllPolicy        : Delete and Apply Policy"
># -------------------------------------------"
># TestPolicy       : Testing Create Ransomware File"
># TestStandard     : Testing Create Standard File"
># ==========================================="

Thank you www.bcyber.com.au for the sample ransomware encrypted file extensions list in 2020 (latest)
