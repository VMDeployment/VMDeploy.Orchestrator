function Start-VmoDeployment {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		$BoundParameters
	)
	
	process {
		if ($script:deploymentData.Count -gt 0) {
			Stop-VmoDeployment -State Unknown
		}
		$script:deploymentData = @{
			Name       = $Name
			ID         = ([System.Guid]::NewGuid()) -as [string]
			Start      = Get-Date
			Stop       = $null
			Parameters = $BoundParameters
			Data       = @()
		}
	}
}