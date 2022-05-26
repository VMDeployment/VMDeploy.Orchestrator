function Get-VmoDeploymentState
{
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		if (-not $script:deploymentData.Name) { return 'NotStarted' }
		'Started'
	}
}
