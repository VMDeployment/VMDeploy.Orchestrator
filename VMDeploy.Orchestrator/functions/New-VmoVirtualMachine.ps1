function New-VmoVirtualMachine {
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[PsfArgumentCompleter('VMDeploy.Orchestrator.Template')]
		[string[]]
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
		
		[Parameter(ParameterSetName = 'Host')]
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
		$DNSServer,
		
		[string]
		$IPAddress,
		
		[int]
		$PrefixLength,
		
		[string]
		$DefaultGateway,
		
		[string]
		$ComputerName,
		
		[string[]]
		$GuestConfiguration
	)
	
	begin {
		#region Functions
		function Resolve-Configuration {
			[CmdletBinding()]
			param (
				[AllowEmptyCollection()]
				[AllowEmptyString()]
				[string[]]
				$Name,
				
				[AllowNull()]
				$Disks,
				
				[AllowNull()]
				$Network,
				
				$BoundParameters
			)
			
			$entries = Get-VmoGuestConfiguration | Where-Object Identity -In $Name | Microsoft.PowerShell.Utility\Select-Object -ExcludeProperty ConfigType -Property *
			
			foreach ($nameEntry in $Name | Where-Object { $_ -notin $entries.Identity } | Remove-PSFNull) {
				Write-PSFMessage -Level Warning -String 'New-VmoVirtualMachine.GuestConfig.NotFound' -StringValues $nameEntry -FunctionName New-VmoVirtualMachine
			}
			foreach ($entry in $entries) {
				foreach ($dependency in $entry.DependsOn) {
					if ($entries.Identity -notcontains $dependency) {
						Write-PSFMessage -Level Warning -String 'New-VmoVirtualMachine.GuestConfig.MissingDependency' -StringValues $entry.Identity, $dependency -FunctionName New-VmoVirtualMachine -Data @{ Entry = $entry }
					}
				}
				if ($entry.Weight -lt 1) { $entry.Weight = 1 }
			}
			$entries
			
			foreach ($disk in $Disks) {
				[PSCustomObject]@{
					Identity = "__Disk_$($disk.Letter)_$($disk.LUN)"
					Weight   = -1
					Action   = 'disk'
					Parameters = $disk
				}
			}
			
			$networkParam = @{ }
			if ($Network.PrefixLength) { $networkParam.PrefixLength = $Network.PrefixLength }
			if ($Network.DefaultGateway) { $networkParam.DefaultGateway = $Network.DefaultGateway }
			if ($Network.DnsServer) { $networkParam.DnsServer = $Network.DnsServer }
			if ($BoundParameters.PrefixLength) { $networkParam.PrefixLength = $BoundParameters.PrefixLength }
			if ($BoundParameters.DefaultGateway) { $networkParam.DefaultGateway = $BoundParameters.DefaultGateway }
			if ($BoundParameters.DnsServer) { $networkParam.DnsServer = $BoundParameters.DnsServer }
			if ($BoundParameters.IPAddress) { $networkParam.IPAddress = $BoundParameters.IPAddress }
			[PSCustomObject]@{
				Identity = '__Network'
				Weight   = -2
				Action   = 'network'
				Parameters = $networkParam
			}

			# ComputerName Config
			$computerName = $BoundParameters.Name
			if ($BoundParameters.ComputerName) { $computerName = $BoundParameters.ComputerName }
			[PSCustomObject]@{
				Identity = '__ComputerName'
				Weight = 0
				Action = 'Computername'
				Parameters = @{
					Name = $computerName
				}
			}
		}
		#endregion Functions
	}
	process {
		$configParam = @{ }
		
		#region Process Template
		$templateData = Resolve-TemplateData -Name $Template
		# Hardware Profile
		if (-not $HardwareProfile) { $HardwareProfile = $templateData.HardwareProfile }
		if (-not $HardwareProfile) { throw "Hardware profile not specified! Use a template or specify the -HardwareProfile parameter!" }
		# Guest OS Profile
		if (-not $GuestOSProfile) { $GuestOSProfile = $templateData.GuestOSProfile }
		if (-not $GuestOSProfile) { throw "Guest OS profile not specified! Use a template or specify the -GuestOSProfile parameter!" }
		# Cloud / VM Host Group
		if (-not $Cloud -and -not $VMHostGroup -and -not $VMHost) {
			if ($templateData.Cloud) { $Cloud = $templateData.Cloud }
			elseif ($templateData.VMHostGroup) { $VMHostGroup = $templateData.VMHostGroup }
			elseif ($templateData.VMHost) { $VMHost = $templateData.VMHost }
		}
		if (-not $Cloud -and -not $VMHostGroup -and -not $VMHost) { throw "Neither Cloud nor VM Host Group nor VM Host specified! Use a template that defines them or manually offer either as parameter!" }
		if (-not $DiskName) { $DiskName = $templateData.VirtualHardDisk }
		if (-not $Network) { $Network = $templateData.Network }
		
		if (-not $ComputerName) { $ComputerName = $Name }

		if ($templateData.Shielding) {
			$unattendFile = @(Get-VmoShieldingUnattendFile -Name $templateData.Shielding)[0]
			if (-not $unattendFile) { throw "No shielding unattend file found for shielding config $($templateData.Shielding)" }
		}
		Write-PSFMessage -Message "HWP: $HardwareProfile | OSP: $GuestOSProfile | Target: $($Cloud)$($VMHostGroup)$($VMHost) | Disk: $DiskName | Network: $Network | Name: $ComputerName | Shield: $($templateData.Shielding)"
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
		$vmHostObject = $null
		if ($VMHost) {
			$hostObjects = Get-VmoVMHost
			$vmHostObject = $hostObjects | Where-Object ID -EQ $VMHost
			if (-not $vmHostObject) { $vmHostObject = $hostObjects | Where-Object FQDN -EQ $VMHost | Microsoft.PowerShell.Utility\Select-Object -First 1 }
			if (-not $vmHostObject) { $vmHostObject = $hostObjects | Where-Object Name -EQ $VMHost | Microsoft.PowerShell.Utility\Select-Object -First 1 }
			if (-not $vmHostObject) { $vmHostObject = $hostObjects | Where-Object ComputerName -EQ $VMHost | Microsoft.PowerShell.Utility\Select-Object -First 1 }
			if (-not $vmHostObject) { throw "Unable to find VM Host $VMHost! Ensure it exists and you have the permission to use it." }
		}
		
		$vhdx = Get-VmoVirtualHardDisk | Where-Object Name -EQ $DiskName
		if (-not $vhdx) { throw "Unable to find virtual hard disk $DiskName! Ensure it exists and you have the permission to use it." }
		
		$networkData = Get-VmoNetwork | Where-Object Name -EQ $Network | Microsoft.PowerShell.Utility\Select-Object -First 1
		#endregion Retrieve and validate resource access
		
		$seed = Get-Random
		
		$resolvedConfiguration = Resolve-Configuration -Name (@($templateData.GuestConfig) + $GuestConfiguration) -Disks $hwProfile._Disks -Network $networkData -BoundParameters $PSBoundParameters
		$guestConfigData = New-ConfigurationVhdx -Seed $seed -Configuration $resolvedConfiguration -ComputerName $ComputerName
		$guestConfigVhdx = Publish-ScvmmVhdx -GuestVhdxConfig $guestConfigData
		
		$jobGroup = [System.Guid]::NewGuid()
		New-SCVirtualDiskDrive -SCSI -Bus 0 -LUN 0 -JobGroup $jobGroup -CreateDiffDisk $false -VirtualHardDisk $vhdx -FileName "$($Name)_$($DiskName)" -VolumeType BootAndSystem -ErrorAction Stop
		foreach ($disk in ($resolvedConfiguration | Where-Object Action -EQ disk).Parameters) {
			New-SCVirtualDiskDrive -SCSI -Bus 0 -LUN $disk.Lun -JobGroup $jobGroup -VirtualHardDiskFormatType VHDX -VirtualHardDiskSizeMB ($disk.Size / 1mb) -Dynamic -VolumeType None -FileName "$($seed)-$($Name)-$($disk.Letter).vhdx" -ErrorAction Stop
		}
		New-SCVirtualDiskDrive -SCSI -Bus 0 -LUN (Get-PSFConfigValue -FullName 'VMDeploy.Orchestrator.GuestConfig.Disk.LunID') -JobGroup $jobGroup -CreateDiffDisk $false -VirtualHardDisk $guestConfigVhdx -FileName "$($Name)_$($guestConfigData.Name)" -VolumeType None -ErrorAction Stop
		
		$templateObject = New-SCVMTemplate -Name "TMP_$($Name)_$($seed)" -HardwareProfile $hwProfile -GuestOSProfile $osProfile -JobGroup $jobGroup -Shielded ($templateData.Shielding -as [bool])
		$newVMParam = @{
			StartVM = $true
			ReturnImmediately = $true
			Name = $ComputerName
		}
		#region Shielding
		if ($templateData.Shielding) {
			$tempPdkFile = Join-Path -Path (Get-PSFPath -Name temp) -ChildPath "shielding_$($seed).pdk"
			try { $fileObject = New-PdkFile -Path $tempPdkFile -OSVhdxPath $vhdx.Location -AnswerFile $unattendFile.FilePath }
			catch {
				Write-PSFMessage -Level Warning -Message "Failed to create Shielding Data File (.pdk)" -ErrorRecord $_
				throw
			}
			$newVMParam['VMShieldingData'] = $fileObject
		}
		#endregion Shielding

		if (-not $vmHostObject) {
			Write-PSFMessage -Message 'Deploying VM {0} to {1}{2}' -StringValues $Name, $cloudObject.Name, $hostGroupObject.Name
			$configuration = New-SCVMConfiguration -VMTemplate $templateObject -Name "CFG_$($Name)_$($seed)" @configParam
			New-SCVirtualMachine @newVMParam -VMConfiguration $configuration
		}
		else {
			$vmPath = $null
			if ($vmHostObject._VMPaths) { $vmPath = $vmHostObject._VMPaths | Get-Random }
			if (-not $vmPath) { $vmPath = $vmHostObject.VMPaths | Get-Random }
			
			Write-PSFMessage -Message 'Deploying VM {0} to {1} at {2}' -StringValues $Name, $vmHostObject.Name, $vmPath
			New-SCVirtualMachine -VMTemplate $templateObject -VMHost $vmHostObject -Path $vmPath
		}
		
		
		# Clean up old Templates & VHDXs
		# Current Template is locked while deploying
		$timeLimit = Get-PSFConfigValue -FullName 'VMDeploy.Orchestrator.Template.ExpirationDays'
		$null = Get-SCVMTemplate | Where-Object Name -Like TMP_* | Where-Object AddedTime -LT (Get-Date).AddDays((-1 * $timeLimit)) | Remove-SCVMTemplate
		$null = Get-SCVirtualHardDisk | Where-Object Name -like "VMDeploy_OSConfig-*.vhdx" | Where-Object AddedTime -lt (Get-Date).AddDays((-1 * $timeLimit)) | Remove-SCVirtualHardDisk
		if ($tempPdkFile) { Remove-Item -Path $tempPdkFile -Force -ErrorAction Ignore }
	}
}