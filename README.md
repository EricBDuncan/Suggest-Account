# Suggest-Account
## Active Directory Provisioning Tool to search and suggest available username or email address

Active Directory Provisioning Tool that will check SamAccountName, UPN, and proxyAddresses for an existing account and suggest the next avilable name.
Username, Email/UPN format:

1 - [First Initial][Last Name] - example: EDuncan

2 - [First Initial][Middle Initial (if specified)][Last Name} - example: EBDuncan

3 - [First Initial][Middle Initial (if specified)][Last Name][Number] - example: EBDuncan1..EBDuncan6 etc..

Run using:

Import-Module .\Suggest-Account.ps1 -force

help suggest-account

Suggest-Account -sn smith -gn j -password -email -ht

