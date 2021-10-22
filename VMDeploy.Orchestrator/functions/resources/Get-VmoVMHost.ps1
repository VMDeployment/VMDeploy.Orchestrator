function Get-VmoVMHost {
	<#
    .SYNOPSIS
        Read the list of available VM Hosts in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available VM Hosts in the connected SCVMM.
        Only returns VM Hosts the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoVMHost

        Read the list of available VM Hosts in the connected SCVMM.
    #>
	[CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $config = Get-VMManConfiguration -Type VMHost
        $userRoles = Get-UserRole -NoCache:$NoCache
        $vMHosts = Get-SCVMHost
        foreach ($vMHost in $vMHosts) {
            $configItem = $config | Where-Object Name -EQ $vMHost.FQDN | Microsoft.PowerShell.Utility\Select-Object -First 1
			if (-not $configItem) {
				Add-Member -InputObject $vMHost -MemberType NoteProperty -Name _Role -Value 'Admins' -Force
				Add-Member -InputObject $vMHost -MemberType NoteProperty -Name _VMPaths -Value $null -Force
			}
			else {
				Add-Member -InputObject $vMHost -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force
				Add-Member -InputObject $vMHost -MemberType NoteProperty -Name _VMPaths -Value $configItem.VMPaths -Force
			}
            if ($vMHost._Role -notin $userRoles -and $userRoles -notcontains 'admins') { continue }
			$vMHost
        }
    }
}