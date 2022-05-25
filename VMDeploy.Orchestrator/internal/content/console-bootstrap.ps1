<#
.SYNOPSIS
	Bootstrap script to prepare for troubleshooting a VMDeployment process.

.DESCRIPTION
	Bootstrap script to prepare for troubleshooting a VMDeployment process.

	Load the script file by running it from any already active PowerShell console, for example by running:
	& "z:\console-bootstrap.ps1"
#>
[CmdletBinding()]
param (

)

# Prepare PSDrive
$null = New-PSDrive -Name VMDeploy -PSProvider FileSystem -Root $PSScriptRoot -Scope Global -ErrorAction Ignore

# Prepare Modules
$modulePath = "$PSScriptRoot\Modules" -replace '\\\\', '\'
$env:PSModulePath = $modulePath, $env:PSModulePath -join ";"

# Load up all actions
foreach ($file in Get-ChildItem -Path "$PSScriptRoot\Actions" -Recurse -Filter *.ps1) {
	. $file.FullName
}

# Import configuration settings
Import-VMGuestConfiguration -Path "$PSScriptRoot\Config\*"

# Eventlog Analysis
function global:Get-VMDeploymentLog {
	[CmdletBinding()]
	param (
		[string]
		$LogName = 'VMDeployment'
	)

	$events = Get-WinEvent -LogName $LogName
	$eventsGrouped = $events | Group-Object { $_.Properties[-1].Value }
	foreach ($group in $eventsGrouped) {
		$start = $group.Group[-1]
		$end = $group.Group[0]

		[PSCustomObject]@{
			Name      = $start.Properties[2].Value
			ID        = $start.Properties[3].Value
			ProcessID = $start.Properties[1].Value
			Start     = $start.TimeCreated
			End       = $end.TimeCreated
			Events    = $group.Group
			Message   = ($group.Group | ForEach-Object { '{0:HH:mm:ss} {1}' -f $_.TimeCreated, $_.Message }) -join "`n"
			Count     = $group.Count
		}
	}
}

Write-Host @'
VMDeploy.Guest ready for use:
+ Run 'Test-VMGuestConfiguration' to check the current configuration status
+ Run 'Get-VMDeploymentLog' to check status of previous deployments

Example:
$runs = Get-VMDeploymentLog

# Check last run
$runs[0]
# Check first run
$runs[-1]
'@