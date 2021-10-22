function Get-VmoHardwareProfile {
    <#
    .SYNOPSIS
        Read the list of available hardwareProfiles in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available hardwareProfiles in the connected SCVMM.
        Only returns hardwareProfiles the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoHardwareProfile

        Read the list of available hardwareProfiles in the connected SCVMM.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $config = Get-VMManConfiguration -Type HardwareProfile
        $userRoles = Get-UserRole -NoCache:$NoCache
        $hardwareProfiles = Get-SCHardwareProfile
        foreach ($hardwareProfile in $hardwareProfiles) {
            $configItem = $config | Where-Object Name -EQ $hardwareProfile.Name | Microsoft.PowerShell.Utility\Select-Object -First 1
			if (-not $configItem) {
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Role -Value 'Admins' -Force
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Disks -Value @() -Force
			}
			else {
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force
				Add-Member -InputObject $hardwareProfile -MemberType NoteProperty -Name _Disks -Value $configItem.Disks -Force
			}
            if ($hardwareProfile._Role -notin $userRoles -and $userRoles -notcontains 'admins') { continue }
            $hardwareProfile
        }
    }
}