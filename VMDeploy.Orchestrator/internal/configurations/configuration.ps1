<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'Scvmm.LibraryPath' -Value '' -Initialize -Validation 'string' -Description "Share in which VMDeploy.Orchestrator will place temporary VHDX files, containing the client bootstrap source code for a VM deployment."
Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'Template.ExpirationDays' -Value 1 -Initialize -Validation integerpositive -Description 'Maximum age after which all temporary VM templates are deleted when creating a new Virtual Machine. Temporary templates are identified by their "TMP_*" prefix.'

Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'GuestConfig.Disk.LunID' -Value 63 -Initialize -Validation integerpositive -Description 'The ID under which the Guest Configuration Disk will be mounted. The Hardware profile must not use this ID'
Set-PSFConfig -Module 'VMDeploy.Orchestrator' -Name 'DynamicConfiguration.PreferLocal' -Value $true -Initialize -Validation bool -Description 'When resolving dynamic configuration items, prefer either the current set of templates or all nested templates.'