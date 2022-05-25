function Get-VmoDeploymentState
{
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		if (-not $script:deploymentDatav.Name) { return 'NotStarted' }
		'Started'
	}
}
