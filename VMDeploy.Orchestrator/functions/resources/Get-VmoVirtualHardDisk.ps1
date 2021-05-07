function Get-VmoVirtualHardDisk {
    <#
    .SYNOPSIS
        Read the list of available virtualHardDisks in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available virtualHardDisks in the connected SCVMM.
        Only returns virtualHardDisks the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoVirtualHardDisk

        Read the list of available virtualHardDisks in the connected SCVMM.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $config = Get-VMManConfiguration -Type VirtualHardDisk
        $userRoles = Get-UserRole -NoCache:$NoCache
        $virtualHardDisks = Get-SCVirtualHardDisk
        foreach ($virtualHardDisk in $virtualHardDisks) {
            $configItem = $config | Where-Object ImageName -EQ $virtualHardDisk.Name | Microsoft.PowerShell.Utility\Select-Object -First 1
            if (-not $configItem) { Add-Member -InputObject $virtualHardDisk -MemberType NoteProperty -Name _Role -Value 'Admins' -Force }
            else { Add-Member -InputObject $virtualHardDisk -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force }
            if ($virtualHardDisk._Role -notin $userRoles) { continue }
            $virtualHardDisk
        }
    }
}