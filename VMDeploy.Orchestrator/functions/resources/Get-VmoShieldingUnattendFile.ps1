function Get-VmoShieldingUnattendFile {
    <#
    .SYNOPSIS
        Read the list of available shielding unattend files.
    
    .DESCRIPTION
        Read the list of available shielding unattend files.
        Only returns shielding unattend files the current user has access to, based on his/her/its role membership.

    .PARAMETER Name
        The name of the shielding unattend file to filter by.
        Defaults to '*'
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoShieldingUnattendFile

        Read the list of available shielding unattend files.
    #>
    [CmdletBinding()]
    param (
        [string]
        $Name = '*',

        [switch]
        $NoCache
    )

    process {
		$userRoles = Get-UserRole -NoCache:$NoCache
		Get-VMManConfiguration -Type ShieldingUnattend | Where-Object {
			$_.Role -in $userRoles -or
			$userRoles -contains 'admins'
		} | Where-Object Name -like $Name
    }
}