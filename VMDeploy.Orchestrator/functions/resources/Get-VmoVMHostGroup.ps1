function Get-VmoVMHostGroup {
    <#
    .SYNOPSIS
        Read the list of available vMHostGroups in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available vMHostGroups in the connected SCVMM.
        Only returns vMHostGroups the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoVMHostGroup

        Read the list of available vMHostGroups in the connected SCVMM.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $config = Get-VMManConfiguration -Type VMHostGroup
        $userRoles = Get-UserRole -NoCache:$NoCache
        $vMHostGroups = Get-SCVMHostGroup
        foreach ($vMHostGroup in $vMHostGroups) {
            $configItem = $config | Where-Object Name -EQ $vMHostGroup.Name | Microsoft.PowerShell.Utility\Select-Object -First 1
            if (-not $configItem) { Add-Member -InputObject $vMHostGroup -MemberType NoteProperty -Name _Role -Value 'Admins' -Force }
            else { Add-Member -InputObject $vMHostGroup -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force }
            if ($vMHostGroup._Role -notin $userRoles) { continue }
            $vMHostGroup
        }
    }
}