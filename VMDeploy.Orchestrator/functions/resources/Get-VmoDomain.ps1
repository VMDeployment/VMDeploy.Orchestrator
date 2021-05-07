function Get-VmoDomain {
    <#
    .SYNOPSIS
        Read the list of available domains.
    
    .DESCRIPTION
        Read the list of available domains.
        Only returns domains the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoDomain

        Read the list of available domains.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $userRoles = Get-UserRole -NoCache:$NoCache
        Get-VMManConfiguration -Type Domain | Where-Object Role -in $userRoles
    }
}