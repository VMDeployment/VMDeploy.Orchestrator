function Get-VmoGuestConfiguration
{
<#
	.SYNOPSIS
		Read the list of available guest configuration options.
	
	.DESCRIPTION
        Read the list of available guest configuration options.
        Guest configuration entries specify an action, its parameters and metadata such as dependencies, processing order, etc.
        Only returns configuration entries the current user has access to, based on his/her/its role membership.

    .PARAMETER Name
        The name of the guest configuration to filter by.
        Defaults to '*'
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoGuestConfiguration

        Read the list of available guest configuration options.
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*',
		
        [switch]
		$NoCache
	)
	
	process
	{
		$userRoles = Get-UserRole -NoCache:$NoCache
		Get-VMManConfiguration -Type GuestConfig | Where-Object {
			$_.Role -in $userRoles -or
			$userRoles -contains 'admins'
		} | Where-Object Identity -like $Name
	}
}