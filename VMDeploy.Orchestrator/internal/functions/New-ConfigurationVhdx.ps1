function New-ConfigurationVhdx {
	[CmdletBinding()]
	param (
		[string]
		$Seed,
		
		$Configuration,
		
		[string]
		$ComputerName
	)
	
	begin {
		#region Utility Functions
		function Copy-Module {
			[CmdletBinding()]
			param (
				[string]
				$Source,
				
				[string]
				$Destination,
				
				[System.Collections.Hashtable]
				$Module
			)
			
			if (-not $Module.Name) { throw "Module to copy must have a name!" }
			
			$sourceRoot = Join-Path -Path $Source -ChildPath $Module.Name
			if (-not (Test-Path -Path $sourceRoot)) {
				throw "Module not found: $($Module.Name)! Ensure path exists: $sourceRoot"
			}
			
			$destRoot = Join-Path -Path $Destination -ChildPath $Module.Name
			if (-not (Test-Path -Path $destRoot)) {
				$null = New-Item -Path $destRoot -ItemType Directory -Force
			}
			
			$versions = Get-ChildItem -Path $sourceRoot
			if ($Module.RequiredVersion) { $versions = $versions | Where-Object Name -EQ $Module.RequiredVersion }
			if ($Module.MinimumVersion) { $versions = $versions | Where-Object { ($_.Name -as [version]) -ge ($Module.MinimumVersion -as [version]) } }
			if ($Module.MaximumVersion) { $versions = $versions | Where-Object { ($_.Name -as [version]) -le ($Module.MaximumVersion -as [version]) } }
			
			if (-not $versions) {
				throw "Module $($Module.Name) found, but no version matching requirements available! $Module"
			}
			$version = $versions | Sort-Object { $_.Name -as [System.Version] } -Descending | Microsoft.PowerShell.Utility\Select-Object -First 1
			
			Copy-Item -Path $version.FullName -Destination $destRoot -Force -Recurse
		}
		#endregion Utility Functions
		
		$modules = @(
			@{ Name = 'PSFramework' }
			@{ Name = 'VMDeploy.Guest' }
		)
	}
	process {
		#region RegionName Preparing folder structure
		$workingDirectory = Join-Path -Path (Get-PSFPath -Name temp) -ChildPath "VMDeploy.Guest_$($Seed)"
		$null = New-Item -Path $workingDirectory -ItemType Directory -Force
		$null = New-Item -Path "$workingDirectory\Modules" -ItemType Directory -Force
		$null = New-Item -Path "$workingDirectory\Actions" -ItemType Directory -Force
		$null = New-Item -Path "$workingDirectory\Config" -ItemType Directory -Force
		$null = New-Item -Path "$workingDirectory\Resources" -ItemType Directory -Force
		#endregion RegionName Preparing folder structure
		
		$contentPath = Get-PSFConfigValue -FullName 'VMDeploy.Management.ContentPath'
		
		#region Process Modules
		$modulesSource = Join-Path -Path $contentPath -ChildPath Modules
		foreach ($module in $modules) {
			Copy-Module -Source $modulesSource -Destination "$workingDirectory\Modules" -Module $module
		}
		#endregion Process Modules
		
		#region Process Actions
		$actionSource = Join-Path -Path $contentPath -ChildPath Actions
		foreach ($action in Get-ChildItem -Path $actionSource -Filter *.ps1) {
			Copy-Item -LiteralPath $action.FullName -Destination "$workingDirectory\Actions" -Force
			& $action.FullName
		}
		#endregion Process Actions
		
		#region Process Configuration & Resources
		foreach ($entry in $Configuration) {
			$entry | ConvertTo-Json -Depth 99 | Set-Content -Path "$workingDirectory\Config\$($entry.Identity).json" -Encoding UTF8
		}
		$resources = $Configuration.Resources | Remove-PSFNull | Sort-Object -Unique
		$destinationRoot = "$workingDirectory\Resources"
		foreach ($resource in $resources) {
			$sourcePath = Join-Path -Path "$contentPath\Resources" -ChildPath $resource
			if (-not (Test-Path $sourcePath)) {
				Write-PSFMessage -Level Warning -String 'New-ConfigurationVhdx.Resource.NotFound' -StringValues $resource
				continue
			}
			$relativeParent = Split-Path -Path $resource
			$destination = $destinationRoot
			if ($relativeParent) {
				$destination = Join-Path -Path $destination -ChildPath $relativeParent
				if (-not (Test-Path -Path $destination)) {
					$null = New-Item -Path $destination -ItemType Directory -Force
				}
			}
			Copy-Item -Path $sourcePath -Destination $destination -Recurse -Force
		}
		foreach ($entry in $Configuration) {
			$actionObject = Get-VMGuestAction -Name $entry.Action
			if (-not $actionObject) {
				Write-PSFMessage -Level Warning -String 'New-ConfigurationVhdx.GuestConfig.Action.NotFound' -StringValues $entry.Identity, $entry.Action -Target $entry
				continue
			}
			if (-not $actionObject.PreDeploymentCode) { continue }
			
			try { & $actionObject.PreDeploymentCode $entry.Parameters $workingDirectory }
			catch {
				Write-PSFMessage -Level Warning -String 'New-ConfigurationVhdx.GuestConfig.Action.Failed' -StringValues $entry.Identity, $entry.Action -Target $entry -ErrorRecord $_
				continue
			}
		}
		$ComputerName | Export-PSFClixml -Path "$workingDirectory\Resources\__computername.dat"
		#endregion Process Configuration & Resources
		
		#region Wrapping up and reporting
		$vhdxPath = "$workingDirectory\VMDeploy_OSConfig-$($Seed).vhdx"
		Invoke-PSFProtectedCommand -ActionString 'New-ConfigurationVhdx.Vhdx.Create' -ActionStringValues $vhdxPath -Target $Seed -ScriptBlock {
			(Get-ChildItem -Path $workingDirectory) | New-Vhdx -Path $vhdxPath -ErrorAction Stop -Label "VMGuestConfig-$Seed"
		} -EnableException $true -PSCmdlet $PSCmdlet
		
		[PSCustomObject]@{
			Path = $vhdxPath
			Name = "VMDeploy_OSConfig-$($Seed)"
			VmmName = "VMDeploy_OSConfig-$($Seed).vhdx"
			WorkingDirectory = $workingDirectory
		}
		#endregion Wrapping up and reporting
	}
}