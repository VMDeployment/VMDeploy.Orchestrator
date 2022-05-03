function Resolve-TemplateData {
<#
	.SYNOPSIS
		Merges the settings from one or more templates.
	
	.DESCRIPTION
		Merges the settings from one or more templates.
		Will include any listed child templates recursively.
	
	.PARAMETER Name
		The name(s) of the templates to merge.
	
	.PARAMETER Data
		Hashtable the template data is resolved into.
		Defaults to an empty hashtable that is then filled with the template data.
	
	.EXAMPLE
		PS C:\> Resolve-TemplateData -Name 'contoso_dc'
	
		Resolves the template "contoso_dc" and all its child templates and provides a coherent set of settings that results from this.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]]
		$Name,
		
		[hashtable]
		$Data = @{ }
	)
	
	begin {
		$coreProperties = @(
			'Cloud'
			'GuestOSProfile'
			'HardwareProfile'
			'Network'
			'Shielding'
			'VirtualHardDisk'
		)
	}
	process {
		foreach ($entry in $Name) {
			$templateObjects = Get-VmoTemplate -Name $entry
			if (-not $templateObjects) {
				Write-PSFMessage -Level Warning -String 'Resolve-TemplateData.Template.NotFound' -StringValues $entry
				continue
			}
			
			foreach ($templateObject in $templateObjects) {
				foreach ($property in $coreProperties) {
					if ($templateObject.$property) { $Data.$property = $templateObject.$property }
				}
				
				if ($templateObject.GuestConfig) {
					if (-not $Data.GuestConfig) { $Data.GuestConfig = $templateObject.GuestConfig }
					else { $Data.GuestConfig = @($Data.GuestConfig) + @($templateObject.GuestConfig) }
				}
				
				foreach ($templateName in $templateObject.ChildTemplates) {
					Resolve-TemplateData -Name $templateName -Data $Data
				}
			}
		}
		
		if ($Data.GuestConfig) { $Data.GuestConfig = $Data.GuestConfig | Remove-PSFNull | Sort-Object -Unique }
		$Data
	}
}