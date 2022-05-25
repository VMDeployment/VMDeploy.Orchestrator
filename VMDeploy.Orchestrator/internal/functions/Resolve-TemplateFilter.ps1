function Resolve-TemplateFilter {
	<#
	.SYNOPSIS
		Resolves, whether a template filter applies to the specified list of templates.
	
	.DESCRIPTION
		Resolves, whether a template filter applies to the specified list of templates.
	
	.PARAMETER Templates
		List of templates to check against the filter
	
	.PARAMETER Filter
		The filter condition to apply to the templates.
	
	.EXAMPLE
		PS C:\> Resolve-TemplateFilter -Templates $allTemplates -Filter $config._Filter
		
		Returns whether the filter of the specified config item applies to the current set of templates.
	#>
	[CmdletBinding()]
	param (
		[string[]]
		$Templates,

		[string]
		$Filter
	)

	$filterObject = New-PSFFilter -Expression $Filter
	$conditions = foreach ($templateName in $filterObject.Conditions) {
		New-PSFFilterCondition -Module VMDeploy -Name $templateName -ScriptBlock ([scriptblock]::Create("`$_ -contains '$templateName'"))
	}
	$filterObject.ConditionSet = New-PSFFilterConditionSet -Module VMDeploy -Name "TemplateDynamic_$(Get-Random)" -Version '1.0.0' -Conditions $conditions
	$filterObject.Evaluate($Templates)
	$filterContainer = & (Get-Module PSFramework) { $script:filterContainer }
	$content = [PSFramework.Utility.UtilityHost]::GetPrivateField("Content", $filterContainer)
	#TODO: Replace with formal removal logic once PSFramework has been updated
	$null = $content.Remove("VMDeploy")
}