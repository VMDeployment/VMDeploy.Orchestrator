Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.HardwareProfile" -ScriptBlock {
    (Get-VmoHardwareProfile).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.GuestOSProfile" -ScriptBlock {
    (Get-VmoGuestOSProfile).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.Cloud" -ScriptBlock {
    (Get-VmoCloud).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.HostGroup" -ScriptBlock {
    (Get-VmoVMHostGroup).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.Host" -ScriptBlock {
    if ($fakeBoundParameters.Cloud) {
        ((Get-VmoCloud | Where-Object Name -eq $fakeBoundParameters.Cloud).HostGroup | Get-SCVMHost).Name
    }
    elseif ($fakeBoundParameters.VMHostGroup) {
        (Get-SCVMHostGroup -Name $fakeBoundParameters.VMHostGroup | Get-SCVMHost).Name
    }
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.VMDisk" -ScriptBlock {
    (Get-VmoVirtualHardDisk).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.Template" -ScriptBlock {
    (Get-VmoTemplate).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.Network" -ScriptBlock {
    (Get-VmoNetwork).Name
}

Register-PSFTeppScriptblock -Name "VMDeploy.Orchestrator.DNSServer" -ScriptBlock {
    (Get-VmoDNSServer).Addresses | Sort-Object -Unique
}