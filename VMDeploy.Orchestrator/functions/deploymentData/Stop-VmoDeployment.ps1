function Stop-VmoDeployment {
	[CmdletBinding()]
	Param (
		[ValidateSet('Success', 'Failed', 'Unknown')]
		[string]
		$State
	)
	
	begin {
		$contentPath = Get-PSFConfigValue -FullName 'VMDeploy.Management.ContentPath'
		$deploymentDataPath = Join-Path -Path $contentPath -ChildPath 'DeploymentData'
		if (-not (Test-Path -Path $deploymentDataPath)) {
			$null = New-Item -Path $deploymentDataPath -ItemType Directory -Force -ErrorAction Stop
		}
	}
	process {
		$current = $script:deploymentData
		if (-not $current.Name) { return }

		$current.Stop = Get-Date
		$current.State = $State

		[PSCustomObject]$current | Export-PSFClixml -Path "$deploymentDataPath\$($current.ID).clidat" -Depth 6
		$script:deploymentData = @{ }
	}
}