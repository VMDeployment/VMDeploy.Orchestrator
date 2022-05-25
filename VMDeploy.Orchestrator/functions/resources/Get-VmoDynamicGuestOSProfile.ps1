function Get-VmoDynamicGuestOSProfile {
    <#
    .SYNOPSIS
        Read the list of available dynamic GuestOSProiles in the connected SCVMM.
    
    .DESCRIPTION
        Read the list of available dynamic GuestOSProiles in the connected SCVMM.
        Only returns dynamic GuestOSProiles the current user has access to, based on his/her/its role membership.
    
    .PARAMETER NoCache
        Disable the user role cache.
        This forces a refresh of the current user role resolution and ensure time-exact configurations are applied.
        Note: This has no effect on user AD Groupmembership changes - only changes to role configuration are refreshed.
    
    .EXAMPLE
        PS C:\> Get-VmoDynamicGuestOSProfile

        Read the list of available dynamic GuestOSProiles in the connected SCVMM.
    #>
    [CmdletBinding()]
    param (
        [switch]
        $NoCache
    )

    process {
        $config = Get-VMManConfiguration -Type DynamicGuestOSProfile
        $userRoles = Get-UserRole -NoCache:$NoCache
        $guestOSProfiles = Get-SCGuestOSProfile
        foreach ($guestOSProfile in $guestOSProfiles) {
            $configItem = $config | Where-Object Name -EQ $guestOSProfile.Name | Microsoft.PowerShell.Utility\Select-Object -First 1
            if (-not $configItem) { Add-Member -InputObject $guestOSProfile -MemberType NoteProperty -Name _Role -Value 'Admins' -Force }
            else { Add-Member -InputObject $guestOSProfile -MemberType NoteProperty -Name _Role -Value $configItem.Role -Force }
            if ($guestOSProfile._Role -notin $userRoles -and $userRoles -notcontains 'admins') { continue }
            Add-Member -InputObject $guestOSProfile -MemberType NoteProperty -Name _Filter -Value $configItem.Filter -Force
			Add-Member -InputObject $guestOSProfile -MemberType NoteProperty -Name _Weight -Value $configItem.Weight -Force
			$guestOSProfile
        }
    }
}