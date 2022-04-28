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

# Prepare Modules
$modulePath = "$PSScriptRoot\Modules" -replace '\\\\','\'
$env:PSModulePath = $modulePath, $env:PSModulePath -join ";"

# Load up all actions
foreach ($file in Get-ChildItem -Path "$PSScriptRoot\Actions" -Recurse -Filter *.ps1) {
	. $file.FullName
}

# Import configuration settings
Import-VMGuestConfiguration -Path "$PSScriptRoot\Config\*"

Write-Host "VMDeploy.Guest ready for use. Run 'Test-VMGuestConfiguration' to check the current configuration status"