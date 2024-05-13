<#PSScriptInfo
.VERSION 1.7
.GUID 7a98d29c-7f67-46b0-b579-655a1b421636
.AUTHOR Eric Duncan
.COMPANYNAME kalyeri
.COPYRIGHT
MIT License

Copyright (c) 2024 Eric Duncan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
.LICENSEURI https://mit-license.org/
.PROJECTURI https://github.com/EricBDuncan/Suggest-Account
.EXTERNALMODULEDEPENDENCIES
ActiveDirectory
.RELEASENOTES
20240430 - v1.5
	Remove apostrophes from names
	Added password output option
	Added hashtable output option
	Added email output option
	Added UPN to search filter
	Sets computers local domain if option is not specified.
20240507 - v1.6
	Added requires for AD module.
	Added Import-Module to help load correctly.
20240513 - v1.7
	Added interactive mode if script is ran and not imported.
.TODO
Enable pipeline
#>

<#
.SYNOPSIS
Active Directory Provisioning Tool that will suggest account username, email, and/or password.

.DESCRIPTION
Active Directory Provisioning Tool that will check SamAccountName, UPN, and proxyAddresses for an existing account and suggest the next avilable name.
Username, Email/UPN format:
[First Initial][Last Name] - example: EDuncan
[First Initial][Middle Initial (if specified)][Last Name} - example: EBDuncan
[First Initial][Middle Initial (if specified)][Last Name][Number] - example: EBDuncan1..EBDuncan6 etc..

.PARAMETER sn
Surname/Lastname - Required

.PARAMETER gn
Given Name/First name - Required

.PARAMETER mi
Middle Name or Initial - Optional

.PARAMETER domain
Domain name for Active Directory, UPN, or Email. Will use the domain name of connected PC if not specified. - Optional

.PARAMETER email
Print Email Domain or UPN to output. - Optional

.PARAMETER password
Print random 16-character length password to output. - Optional

.PARAMETER ht
Format output as a hashtable. - Optional

.INPUTS
You cannot pipe objects to this script module at this time.

.OUTPUTS
String text list or hasttable with -ht switch

.EXAMPLE
Import-Module .\Suggest-Account.ps1 -force
-or-
.\Suggest-Account.ps1

Suggest-Account -sn smith -gn j -password -email -ht
#>
function Suggest-Account{
Param(
[Parameter(Mandatory=$true,HelpMessage="Sur (Last) Name")] [String]$sn,
[Parameter(Mandatory=$true,HelpMessage="Given (First) Name")] [String]$gn,
[Parameter(Mandatory=$false,HelpMessage="Middle Initial")] [String]$mi,
[Parameter(Mandatory=$false,HelpMessage="Email Domain or UPN")] [String]$domain = $env:USERDNSDOMAIN,
[Parameter(Mandatory=$false,HelpMessage="Add email to output")] [switch]$email = $false,
[Parameter(Mandatory=$false,HelpMessage="Provide a random password")] [switch]$password = $false,
[Parameter(Mandatory=$false,HelpMessage="Return results in a hasttable")] [switch]$ht = $false
)

$ErrorActionPreference="SilentlyContinue"
$SuggestAD=@{}

#Clean up spaces
$sn=$sn.trim().Replace(' ','')
$gn=$gn.trim().Replace(' ','')
$mi=$mi.trim().Replace(' ','')

#Clean up apos
$sn=$sn.Replace("'",'')
$gn=$gn.Replace("'",'')
$mi=$mi.Replace("'",'')

#Hyphentated Last/Sur names; take left side of hyphen.
if ($gn -match '-') {$gn="$($name.Split('-')[-0])"}

#Get initals
IF ($gn) {$fi=$gn.Substring(0,1)}
IF ($mi) {$mi=$mi.Substring(0,1)} ELSE {$mi=""}

function suggest-password {
	begin {Add-Type -AssemblyName System.Web}
	process {[System.Web.Security.Membership]::GeneratePassword(16,1)}
}

function queryad() {
	$value2='*'+"$value"+'*'
	$adResults1=Get-ADUser -filter {$filter2 -eq $value -or $filter3 -eq $value} | select samaccountname
	$adResults2=(Get-ADUser -filter {$filter1 -like $value2} -Properties $filter1 | select -ExpandProperty proxyAddresses | ? {$_ -match "$domain"}).tolower().replace('smtp:','').replace("@$domain",'') | sort -Unique
	IF ($adResults1 -OR $adResults2) {$adResults=$true} ELSE {$adResults=$false}
	IF ($adResults) {return $true; Remove-Variable adResults,adResults1,adResults2} ELSE {return $false; Remove-Variable adResults,adResults1,adResults2}
}

$script:defAcct="$fi$sn"
$script:filter1="proxyAddresses"
$script:filter2="samaccountname"
$script:filter3="UserPrincipalName"
$script:value=$defAcct
$q1=queryad

#"query 1: $q1"
	IF (!($q1)) {
		$account = $defAcct
	} ELSE {
		$defAcct="$fi$mi$sn"
		$value=$defAcct
		$q2=queryad
		
		#"query 2: $defAcct $q2"
		IF (!($q2)) {$defAcct} ELSE {
			$i=0
			$Unused = $false
			if (!($defAcct)) {$defAcct} ELSE {
				do {
					$i++
					$account = $defAcct + $i
					$value=$account
					$q3=queryad
				} until (!($q3))
			} #End if defAcct
		} #End q2
	} #End q1

#Results
if ($ht) {
	$SuggestAD.add('username',"$account")
	if ($email) {$SuggestAD.add('email',"$account@$domain")}
	if ($password) {$passwd=suggest-password; $SuggestAD.add('password',"$passwd")}
	return $SuggestAD
} ELSE {
	"$account"
	if ($email) {"$account@$domain"}
	if ($password) {suggest-password}
	if ($pause) {pause; Suggest-Account -email -password}
	} #End ht Else

#Cleanup	
remove-Variable SuggestAD,password,gn,sn,mi,ht,account,pause
Export-ModuleMember -Function Suggest-Account
} #End Suggest-Account

## Main ##
#requires -modules ActiveDirectory
if (!(Get-Module "activedirectory" | select name)) {Import-Module ActiveDirectory}

#Script Vars
$ErrorActionPreference="stop"
[string]$Script:ScriptFile=$MyInvocation.MyCommand.name
[string]$Script:ScriptName=($ScriptFile).replace(".ps1",'')
[string]$Script:ScriptPath=($MyInvocation.MyCommand.Source).replace("\$ScriptFile",'')
[string]$Script:ModFYI=
@"

Use as a PS module: import-Module .\Suggest-Account.ps1"
For more information, type: help suggest-account

"@

#Load as module
if ((Get-Module | Where-Object {$_.name -eq $ScriptName}) -or ($MyInvocation.CommandOrigin -eq "Internal")) {"$ScriptName loaded..."; $ModFYI} else {
#Interactive run
import-module "$ScriptPath\$ScriptFile" -force
$pause=$true
write-host "Running in interactive mode..."
Suggest-Account -email -password
pause
}

## End ##