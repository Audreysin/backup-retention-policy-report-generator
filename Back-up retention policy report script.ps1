<#
Date created: 15 May 2019
Created by Audrey Sin Fai Lam
#>

# ***************************************************************************************
# The input files:
# 1) Daily inventory release
# 2) Daily DPA schedule report (Back-up report)
# 3) Group mapping file
# Requires: All files are in .csv format

# *****************************************************************************************

Write-host "Input files:"
$inventory = import-csv -path 'Z:\Coop handover- Audrey\Backup report + script\Inputs\Enterprise Server Inventory Release.csv'
Write-host "Enterprise Server Inventory Release.csv"
$backup = import-csv -path 'Z:\Coop handover- Audrey\Backup report + script\Inputs\DPA_ScheduledReport.csv'
Write-host "DPA_ScheduledReport.csv"
$map = import-csv -path 'Z:\Coop handover- Audrey\Backup report + script\Inputs\Retention policy mapping.csv'
Write-host "Retention policy mapping.csv"

# *********************************************************************************************

# $inventoryheadings is the required columns from the inventory release file
$inventoryheadings = $inventory | select name,description,department,"hardware status", 
    "business entity", "support group", environment, 'Operating system'
# $backupheading is the required columns from the DPA Schedule report
$backupheadings = $backup | select client, group
# $mapheadings is the required columns from the group mapping file
$mapheadings = $map | select group, policy

# **********************************************************************************************

#output columns
$servername = $null
$s_description = $null
$s_dept = $null
$s_hwstatus = $null
$s_entity = $null
$s_sgroup = $null
$s_environment = $null
$s_OS = $null
$group_policy = $null

# output row
$output = $null

# Creates the column headings of the output files:
# The output files are in .csv format

$date = (Get-Date -UFormat "%d-%m-%y").ToString()

# File 1: consists of the servers in the inventory that are being backed-up successfully
$path1 = 'Z:\Coop handover- Audrey\Backup report + script\Backup report\Server & retention policy ' + $date + '.csv'
Add-content -path $path1 -value 'Name,Description,Department,Hardware status,Business entity,Support group,Environment,Operating system,Back-up Policy'

# File 2: consists of servers in the inventory that are not eing backed-up
$path2 = 'Z:\Coop handover- Audrey\Backup report + script\Backup report\Servers not backed-up ' + $date + '.csv'
Add-content -path $path2 -value 'Name,Description,Department,Hardware status,Business entity,Support group,Environment,Operating system'

# File 3: consists of servers in the DPA report that are not in the inventory release
$path3 = 'Z:\Coop handover- Audrey\Backup report + script\Backup report\Backed-up servers not in inventory ' + $date + '.csv'
Add-content -path $path3 -value 'Name,Back-up Policy'

# ***************************************************************************************************

# Routine No. 1
# For each server in the inventory release, 
# 1) if the server is in the DPA report, the server name and the required fields along with 
#    its back-up policy is added to File 1.
# 2) if the server is not in the DPA report, the server name and the required fields are added to File 2.


# loop through the entries in the inventory
foreach ($invserver in $inventoryheadings){

$servername = $invserver.name
$s_description = $invserver.description
$s_dept = $invserver.department
$s_hwstatus = $invserver."hardware status"
$s_entity = $invserver."business entity"
$s_sgroup = $invserver."support group"
$s_environment = $invserver.environment
$s_OS = $invserver."operating system"

# Assigning the server group as "Missing from the DPA report" sa default.
# This will be changed to the actual group name if the server is found in the backup file
$group_policy = 'Missing from the DPA report'

    # looks for the server in the DPA report
    foreach($backupserver in $backupheadings) {

        if ((((($backupserver.client).trim()) -like (($servername + '.*').trim())) -or 
            ((($backupserver.client).trim()) -contains ($servername.trim()))) -or
            ($servername -like (((($backupserver.client).trim()) + '.*').trim()))) {
        # mutates $servergroup if $servername is found in the DPA report, i.e, if
        # 1) the $invserver.name matches $backupserver.client exactly
        # or 2) the $invserver.name matches $backupserver.client till the first occurence of '.' in $backupserver.client or vice versa
        $group_policy = $backupserver.group

        # map it to the corresponding back-up policy
            foreach($groupmap in $mapheadings) {

                if ($groupmap.group -contains $group_policy) {
                    $group_policy = $groupmap.policy
                    break
                }
            }
            
            break        
          }
          
          
      }

if ($group_policy -contains 'Missing from the DPA report') {
    # adds the row of add to File 2
    $output = @{Name = $servername; Description = $s_description; Department =  $s_dept; 
        'Hardware status' = $s_hwstatus; 'Business entity' = $s_entity; 'Support group' = $s_sgroup; 
        Environment = $s_environment; 'Operating system' = $s_OS}
    [pscustomobject]$output | export-csv -path $path2 -Append -NoTypeInformation 
} else {
    # add the row of data to File 1
    $output = @{Name = $servername; Description = $s_description; Department =  $s_dept; 
        'Hardware status' = $s_hwstatus; 'Business entity' = $s_entity; 'Support group' = $s_sgroup; 
        Environment = $s_environment; 'Operating system' = $s_OS; 'Back-up policy' = $group_policy}
    [pscustomobject]$output | export-csv -path $path1 -Append -NoTypeInformation 
}

$output = $null
$servername = $null
$s_description = $null
$s_dept = $null
$s_hwstatus = $null
$s_entity = $null
$s_sgroup = $null
$s_environment = $null
$group_policy = $null
$output = $null

}

# ************************************************************************************************************

# Routine No. 2
# Checks if any server in the DPA report is not in the inventory release.
#  If so, the server name and the back-up policy is added to File 3

$found? = "Missing"


# Loops through the servers in the DPA report
foreach($backupserver in $backupheadings) {
    
    # Loops through the servers in the inventory release
    foreach ($invserver in $inventoryheadings){

        if ((($backupserver.client).trim()) -like (($invserver.name + '.*').trim()) -or 
            ((($backupserver.client).trim()) -contains ($invserver.name.trim())) -or
            ($servername -like (((($backupserver.client).trim()) + '.*').trim()))) {

          # Mutates the status of the server to be 'Found', if
          # 1) the $invserver.name matches $backupserver.client exactly
          # or 2) the $invserver.name matches $backupserver.client till the first occurence of '.' in $backupserver.client
          $found? = "Found"
          break;
         }
     }

     if ($found? -contains "Missing") {
        $servername = $backupserver.client
        $group_policy = $backupserver.group

        # map it to the corresponding back-up policy
        foreach($groupmap in $mapheadings) {

            if ($groupmap.group -contains $group_policy) {
                $group_policy = $groupmap.policy
                break
            }
         }

        $output = @{Name = $servername; 'Back-up policy' = $group_policy}

        [pscustomobject]$output | export-csv -path $path3 -Append -NoTypeInformation 
        $output = $null
     }
     $found? = "Missing"
}

Write-host ""
Write-host "Mapping complete"
Write-host ""
Write-host "Output files:"
Write-host "Server & retention policy.csv"
Write-host "Servers not backed-up.csv"
Write-host "Backed-up servers not in inventory.csv"

         
