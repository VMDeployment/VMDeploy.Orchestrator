function Get-VmoDNSServer {
    <#
    .SYNOPSIS
        Read the list of available DNS servers.
    
    .DESCRIPTION
        Read the list of available DNS servers.
        Only returns DNS servers the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoDNSServer

        Read the list of available DNS servers.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $userRoles = Get-UserRole -NoCache:$NoCache
        Get-VMManConfiguration -Type DNSServer | Where-Object {
			$_.Role -in $userRoles -or
			$userRoles -contains 'admins'
		}
	}
}