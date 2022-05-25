function Remove-VmoDeploymentData {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$ID
	)
	
	begin {
		Assert-Role -Role Admins -RemoteOnly -Cmdlet $PSCmdlet
		
		$contentPath = Get-PSFConfigValue -FullName 'VMDeploy.Management.ContentPath'
		$deploymentDataPath = Join-Path -Path $contentPath -ChildPath 'DeploymentData'
		if (-not (Test-Path -Path $deploymentDataPath)) {
			$null = New-Item -Path $deploymentDataPath -ItemType Directory -Force -ErrorAction Stop
		}
	}
	process {
		foreach ($identity in $ID) {
			Remove-Item -LiteralPath "$deploymentDataPath\$identity.clidat"
		}
	}
}
