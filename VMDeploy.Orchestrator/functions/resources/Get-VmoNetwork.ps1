function Get-VmoNetwork {
    <#
    .SYNOPSIS
        Read the list of available network configuration sets.
    
    .DESCRIPTION
        Read the list of available network configuration sets.
        Only returns network configuration sets the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoNetwork

        Read the list of available network configuration sets.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $userRoles = Get-UserRole -NoCache:$NoCache
        Get-VMManConfiguration -Type Network | Where-Object {
			$_.Role -in $userRoles -or
			$userRoles -contains 'admins'
		}
	}
}