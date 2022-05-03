
<#
	.SYNOPSIS
		Launcher script that should be added to the OS image as a scheduled task run on system boot.
	
	.DESCRIPTION
		Launcher script that should be added to the OS image as a scheduled task run on system boot.
		Note: Should probably be run as System with maximum privileges for most OS tasks.

		This script will search all available volumes for a guest configuration package.
		It expects the following folder structure within that volume at the root level:
		
		Modules\*
		Actions\*
		Config\*

		Additional folders are ignored by this script.
		It assumes that the modules folder contains all PowerShell modules needed for the VM Deployment's Guest Configuration workflow.
		The folder will be added to PSModulePath with max priority for this workflow only.
		The modules PSFramework and VMDeploy.Guest must be included in this folder at a minimum.

		The "Actions" folder is designed for additional, customer specific, non-public VMGuest Actions.
		You can define your own actions using Register-VMGuestAction.
		Actions are the actual implementation logic performing to Guest configuration steps.

		The "Config" folder is for the actual configuration files that define the intended post-deployment state.
		
		Running this script will have it register the volume root as a PSDrive named VMDeploy.
		It will also set this path as the VMDeploy PSFPath, which will be available for path insertion in builtin actions.
		This allows you for example to add another folder - let's call it "Install" - for your installation media and
		then specify the path during a configuration for SCCM client install as "%VMDeploy%Install\sccm.client.setup.exe"

		Note on volumes:
		- The volume need not have a drive letter for being detected
		- On PowerShell 7, a bug requires the volume to have a driveletter, but this task is designed with Windows PowerShell in mind anyway.
	
	.EXAMPLE
		PS C:\> .\vmdeploy.ps1
#>
[CmdletBinding()]
param (
	[ValidateRange(1, 63)]
	[int]
	$ConfigLun = 63,

	[switch]
	$EnableAllDisks
)

#region Functions
function Write-LogEntry {
	[CmdletBinding()]
	param (
		[string]
		$LogName,
			
		[string]
		$Source,
			
		[int]
		$EventID,
			
		[int]
		$Category,
			
		[System.Diagnostics.EventLogEntryType]
		$Type,
			
		[object[]]
		$Data
	)
	$id = New-Object System.Diagnostics.EventInstance($EventID, $Category, $Type)
	$evtObject = New-Object System.Diagnostics.EventLog
	$evtObject.Log = $LogName
	$evtObject.Source = $Source
	$evtObject.WriteEvent($id, $Data)
}

function Get-DiskLetters {
	[CmdletBinding()]
	param (
		$VolumeObject
	)

	(Get-Volume).DriveLetter

	$configRoot = "$($VolumeObject.Path)Config"
	foreach ($file in Get-ChildItem -Path $configRoot -Recurse -Filter *.json) {
		$config = Get-Content -LiteralPath $file.FullName | ConvertFrom-Json
		if ($config.Action -ne 'disk') { continue }
		$config.Parameters.Letter
	}
}
#endregion Functions

#region Detect VMDeploy Volume
if ($EnableAllDisks) {
	Get-Disk | Where-Object OperationalStatus -EQ 'Offline' | Set-Disk -IsOffline $false
}
else {
	$disk = Get-Disk | Where-Object Location -Match "LUN $ConfigLun" | Where-Object OperationalStatus -EQ 'Offline'
	if ($disk) { $disk | Set-Disk -IsOffline $false }
}
Start-Sleep -Seconds 1
$volumes = Get-Volume
$volumeObject = foreach ($volume in $volumes) {
	if (-not (Test-Path -LiteralPath "$($volume.Path)Modules\VMDeploy.Guest")) { continue }
	
	$volume
	break
}

if (-not $volumeObject) {
	Write-LogEntry -LogName Application -Source Application -EventID 1 -Category 666 -Type Information -Data "No VMDeploy.Guest configuration volume detected. Assuming image used outside of the system, unregistering scheduled task"
	Unregister-ScheduledTask -TaskName VMDeployGuestConfig -ErrorAction Stop
	return
}

$diskLetters = Get-DiskLetters -VolumeObject $volumeObject
foreach ($number in 122..97) {
	if (([char]$number) -in $diskLetters) { continue }
	$vmdeployOSConfigLetter = [char]$number
	break
}
if ($volumeObject.DriveLetter) {
	$null = "SELECT VOLUME $($volumeObject.DriveLetter)", "REMOVE LETTER $($volumeObject.DriveLetter)" | diskpart
}
$volumeObject | Get-Partition | Set-Partition -NewDriveLetter $vmdeployOSConfigLetter
#endregion Detect VMDeploy Volume

#region Apply & Prepare paths for convenient use from PowerShell
if (Get-PSDrive -Name VMDeploy -ErrorAction Ignore) { Remove-PSDrive -Name VMDeploy }
$null = New-PSDrive -Name VMDeploy -PSProvider FileSystem -Root "$($vmdeployOSConfigLetter):\" -Scope Global

$env:PSModulePath = "$($vmdeployOSConfigLetter):\Modules", $env:PSModulePath -join ";"
Set-PSFPath -Name VMDeploy -Path "$($vmdeployOSConfigLetter):\"
#endregion Apply & Prepare paths for convenient use from PowerShell

# Load additional Action files
foreach ($file in Get-ChildItem -Path "$($vmdeployOSConfigLetter):\Actions\*.ps1" -ErrorAction Ignore) {
	& $file.FullName
}
# Load configuration files for the current client
Import-VMGuestConfiguration -Path "$($vmdeployOSConfigLetter):\Config\*"

# If Configuration successfull: Kill task as no longer needed
$testResults = Test-VMGuestConfiguration
if ($testResults.Success -notcontains $false) {
	$schtaskResult = schtasks /delete /TN VMDeployGuestConfig /f
	Write-PSFMessage -Message "schtasks:`n$($schtaskResult -join "`n")"
	$null = "SELECT VOLUME $($vmdeployOSConfigLetter)", "REMOVE LETTER $($vmdeployOSConfigLetter)" | diskpart
	Write-PSFMessage -Message "VMDeployment Guest Configuration Concluded"
	Wait-PSFMessage
	return
}

# Execute Guest Config
Invoke-VMGuestConfiguration -Restart

$null = "SELECT VOLUME $($vmdeployOSConfigLetter)", "REMOVE LETTER $($vmdeployOSConfigLetter)" | diskpart
Wait-PSFMessage