function Write-VmoDeploymentData {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		$Data,

		[string]
		$Comment
	)
	
	process {
		if ($script:deploymentData.Count -eq 0) { return }

		$script:deploymentData.Data += [PSCustomObject]@{
			Name      = $Name
			Data      = $Data
			Comment   = $Comment
			Timestamp = Get-Date
		}
	}
}