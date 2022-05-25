function Get-VmoDeploymentData
{
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*',

		[PSFDateTime]
		$Start,

		[PSFDateTime]
		$End
	)
	
	begin {
		Assert-Role -Role Admins -RemoteOnly -Cmdlet $PSCmdlet
		
		$contentPath = Get-PSFConfigValue -FullName 'VMDeploy.Management.ContentPath'
		$deploymentDataPath = Join-Path -Path $contentPath -ChildPath 'DeploymentData'
		if (-not (Test-Path -Path $deploymentDataPath)) {
			$null = New-Item -Path $deploymentDataPath -ItemType Directory -Force -ErrorAction Stop
		}
	}
	process
	{
		if ($script:deploymentData.Count -gt 0) {
			Stop-VmoDeployment -State Unknown
		}
		Get-ChildItem -Path $deploymentDataPath | Import-PSFClixml | Where-Object {
			$_.Name -like $Name -and
			(-not $Start -or $Start.Value -lt $_.Start) -and
			(-not $End -or $End.Value -gt $_.End)
		}
	}
}
