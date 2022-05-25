function Resolve-GuestOSProfile {
	[CmdletBinding()]
	param (
		[string[]]
		$AllTemplates,

		[string[]]
		$LocalTemplates
	)

	$preferLocal = Get-PSFConfigValue -FullName 'VMDeploy.Orchestrator.DynamicConfiguration.PreferLocal' -Fallback $true

	$localApplicable = Get-VmoDynamicGuestOSProfile | Where-Object {
		Resolve-TemplateFilter -Templates $LocalTemplates -Filter $_._Filter
	}
	$allApplicable = Get-VmoDynamicGuestOSProfile | Where-Object {
		Resolve-TemplateFilter -Templates $AllTemplates -Filter $_._Filter
	}

	if ($preferLocal -and $localApplicable) {
		return $localApplicable | Sort-Object -Property _Weight | Microsoft.PowerShell.Utility\Select-Object -First 1
	}
	$allApplicable | Sort-Object -Property _Weight | Microsoft.PowerShell.Utility\Select-Object -First 1
}