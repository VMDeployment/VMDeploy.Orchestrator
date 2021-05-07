function Get-VmoTemplate {
    <#
    .SYNOPSIS
        Read the list of available templates.
    
    .DESCRIPTION
        Read the list of available templates.
        Templates are predefined sets of resources assigned to a given VM.
        Only returns templates the current user has access to, based on his/her/its role membership.

    .PARAMETER Name
        The name of the template to filter by.
        Defaults to '*'
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoTemplate

        Read the list of available templates.
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
        Get-VMManConfiguration -Type Template | Where-Object Role -in $userRoles | Where-Object Name -like $Name
    }
}