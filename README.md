# Backup Retention Policy Report Generator

Input format: csv
Language: PowerShell

This script takes in the following files:
1) Server inventory
2) Backup report (containing the list of all the servers that have been backed up)
3) Retention policy mapping information (containing the retention policy corresponding to each group category)

Outputs:
1) A report of servers from the inventory that were successfully backed up, together with their corresponding retention policy information
2) A report of servers whch have been successfully backed up but which are missing in the inventory, together with their corresponding retention policy
3) A report of servers from the inventory that have not been backed up
