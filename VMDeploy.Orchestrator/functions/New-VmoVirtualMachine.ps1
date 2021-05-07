function New-VmoVirtualMachine {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.Template')]
        [string]
        $Template,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.HardwareProfile')]
        [string]
        $HardwareProfile,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.GuestOSProfile')]
        [string]
        $GuestOSProfile,

        [Parameter(ParameterSetName = 'Cloud')]
        [PsfArgumentCompleter('VMDeploy.Orchestrator.Cloud')]
        [string]
        $Cloud,

        [Parameter(ParameterSetName = 'HostGroup')]
        [PsfArgumentCompleter('VMDeploy.Orchestrator.HostGroup')]
        [string]
        $VMHostGroup,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.Host')]
        [string]
        $VMHost,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.VMDisk')]
        [string]
        $DiskName,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.Network')]
        [string]
        $Network,

        [PsfArgumentCompleter('VMDeploy.Orchestrator.DNSServer')]
        [string[]]
        $DNSServer
    )

    process {
        $configParam = @{ }

        #region Process Template
        $templateObject = Get-VmoTemplate -Name $Template | Microsoft.PowerShell.Utility\Select-Object -First 1
        # Hardware Profile
        if (-not $HardwareProfile) { $HardwareProfile = $templateObject.HardwareProfile }
        if (-not $HardwareProfile) { throw "Hardware profile not specified! Use a template or specify the -HardwareProfile parameter!" }
        # Guest OS Profile
        if (-not $GuestOSProfile) { $GuestOSProfile = $templateObject.GuestOSProfile }
        if (-not $GuestOSProfile) { throw "Guest OS profile not specified! Use a template or specify the -GuestOSProfile parameter!" }
        # Cloud / VM Host Group
        if (-not $Cloud -and -not $VMHostGroup) {
            if ($templateObject.Cloud) { $Cloud = $templateObject.Cloud }
            elseif ($templateObject.VMHostGroup) { $VMHostGroup = $templateObject.VMHostGroup }
        }
        if (-not $Cloud -and -not $VMHostGroup) { throw "Neither Cloud nor VM Host Group specified! Use a template that defines them or manually offer either as parameter!" }
        #endregion Process Template
    
        #region Retrieve and validate resource access
        $hwProfile = Get-VmoHardwareProfile -NoCache | Where-Object Name -EQ $HardwareProfile
        if (-not $hwProfile) { throw "Unable to find Hardware Profile $hwProfile! Ensure it exists and you have the permission to use it." }
        $osProfile = Get-VmoGuestOSProfile | Where-Object Name -EQ $GuestOSProfile
        if (-not $osProfile) { throw "Unable to find Guest OS Profile $osProfile! Ensure it exists and you have the permission to use it." }
        if ($Cloud) {
            $cloudObject = Get-VmoCloud | Where-Object Name -EQ $Cloud
            if (-not $cloudObject) { throw "Unable to find cloud $Cloud! Ensure it exists and you have the permission to use it." }
            $configParam.Cloud = $cloudObject
        }
        if ($VMHostGroup) {
            $hostGroupObject = Get-VmoVMHostGroup | Where-Object Name -EQ $VMHostGroup
            if (-not $hostGroupObject) { throw "Unable to find VMHostGroup $VMHostGroup! Ensure it exists and you have the permission to use it." }
            $configParam.VMHostGroup = $VMHostGroup
        }

        $vhdx = Get-VmoVirtualHardDisk | Where-Object Name -EQ $DiskName
        if (-not $vhdx) { throw "Unable to find virtual hard disk $DiskName! Ensure it exists and you have the permission to use it." }
        #endregion Retrieve and validate resource access

        $seed = Get-Random
        $jobGroup = [System.Guid]::NewGuid()
        New-SCVirtualDiskDrive -SCSI -Bus 0 -LUN 0 -JobGroup $jobGroup -CreateDiffDisk $false -VirtualHardDisk $vhdx -FileName "$($Name)_$($DiskName)" -VolumeType BootAndSystem
    
        $template = New-SCVMTemplate -Name "TMP_$($Name)_$($seed)" -HardwareProfile $hwProfile -GuestOSProfile $osProfile -JobGroup $jobGroup
        $configuration = New-SCVMConfiguration -VMTemplate $template -Name "CFG_$($Name)_$($seed)" @configParam
        New-SCVirtualMachine -VMConfiguration $configuration -Name $Name -StartVM -ReturnImmediately
    }
}