function Publish-ScvmmVhdx
{
	[CmdletBinding()]
	Param (
		$GuestVhdxConfig
	)
	
	begin
	{
		$libraryShare = Get-PSFConfigValue -FullName 'VMDeploy.Orchestrator.Scvmm.LibraryPath'
	}
	process
	{
		Copy-Item -Path $GuestVhdxConfig.Path -Destination (Join-Path -Path $libraryShare -ChildPath VHDs)
		Remove-Item -Path $GuestVhdxConfig.WorkingDirectory -Recurse -Force
		
		# Refresh Library so it detects the new disk
		$null = Get-SCLibraryShare | Where-Object Path -eq $libraryShare | Read-SCLibraryShare
		
		Get-SCVirtualHardDisk -Name $GuestVhdxConfig.VmmName
	}
}