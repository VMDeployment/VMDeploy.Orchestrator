# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'New-ConfigurationVhdx.GuestConfig.Action.Failed'     = 'Error executing Predeployment Action of guest configuration {0} (Action: {1})' # $entry.Identity, $entry.Action
	'New-ConfigurationVhdx.GuestConfig.Action.NotFound'   = 'Unable to find the action {1} referenced in guest configuration {0}' # $entry.Identity, $entry.Action
	'New-ConfigurationVhdx.Resource.NotFound'             = 'Unable to find resource required by guest configurations: {0}' # $resource
	'New-ConfigurationVhdx.Vhdx.Create'                   = 'Creating Guest Configuration VHDX at {0}' # $vhdxPath
	'New-VmoVirtualMachine.GuestConfig.MissingDependency' = 'The guest configuration {0} requires the configuration {1} to also be present, but it is missing.' # $entry.Identity, $dependency
	'New-VmoVirtualMachine.GuestConfig.NotFound'          = 'Unable to find the referenced guest configuration: {0}' # $nameEntry
	'Resolve-TemplateData.Template.NotFound'              = 'Unable to find the referenced VMDeploy template: {0}' # $entry
	'Validate.ComputerName.Length'                        = 'Illegal computer name: {0} - computernames must not be longer than 15 characters total!'
}