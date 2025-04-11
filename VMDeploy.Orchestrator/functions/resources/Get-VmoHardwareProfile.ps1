function Get-VmoHardwareProfile {
    <#
    .SYNOPSIS
        Read the list of available hardwareProfiles in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available hardwareProfiles in the connected SCVMM.
        Only returns hardwareProfiles the current user has access to, based on his/her/its role membership.

	.PARAMETER VmmServer
		Der SCVMM Server to connect to.
		If not specified, it will use the SCVMM used for the last deployment (if any) or the default server (otherwise)
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoHardwareProfile

        Read the list of available hardwareProfiles in the connected SCVMM.
    #>
    [CmdletBinding()]
    param (
        [string]
		$VmmServer,

		[switch]
        $NoCache
    )

    begin {
		if ($VmmServer) {
			$vmmServerObject = Get-VMManSCVMM | Where-Object Name -EQ $VmmServer
			if (-not $vmmServerObject) { throw "Unable to find SCVMM Server $($VmmServer)! Ensure it exists and you have the permission to deploy to it." }
			try { $Null = Get-SCVMMServer -ComputerName $vmmServerObject.Server -ErrorAction Stop }
			catch {
				Write-Warning "Failed to access SCVMM Server $($vmmServerObject.Name) | $($vmmServerObject.Server): $_"
				throw
			}
		}
	}
	process {
        $config = Get-VMManConfiguration -Type HardwareProfile
        $userRoles = Get-UserRole -NoCache:$NoCache
        $hardwareProfiles = Get-SCHardwareProfile
        foreach ($hardwareProfile in $hardwareProfiles) {
            $configItem = $config | Where-Object Name -EQ $hardwareProfile.Name | Microsoft.PowerShell.Utility\Select-Object -First 1
			if (-not $configItem) {
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Role -Value 'Admins' -Force
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Disks -Value @() -Force
			}
			else {
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Disks -Value $configItem.Disks -Force
			}
            if ($hardwareProfile._Role -notin $userRoles -and $userRoles -notcontains 'admins') { continue }
            $hardwareProfile
        }
    }
}