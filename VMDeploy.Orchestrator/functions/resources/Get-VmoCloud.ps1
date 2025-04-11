function Get-VmoCloud {
	<#
    .SYNOPSIS
        Read the list of available clouds in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available clouds in the connected SCVMM.
        Only returns clouds the current user has access to, based on his/her/its role membership.

	.PARAMETER VmmServer
		Der SCVMM Server to connect to.
		If not specified, it will use the SCVMM used for the last deployment (if any) or the default server (otherwise)
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoCloud

        Read the list of available clouds in the connected SCVMM.
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
		$config = Get-VMManConfiguration -Type Cloud
		$userRoles = Get-UserRole -NoCache:$NoCache
		$clouds = Get-SCCloud
		foreach ($cloud in $clouds) {
			$configItem = $config | Where-Object Name -EQ $cloud.Name | Microsoft.PowerShell.Utility\Select-Object -First 1
			if (-not $configItem) { Add-Member -InputObject $cloud -MemberType NoteProperty -Name _Role -Value 'Admins' -Force }
			else { Add-Member -InputObject $cloud -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force }
			if ($cloud._Role -notin $userRoles -and $userRoles -notcontains 'admins') { continue }
			$cloud
		}
	}
}