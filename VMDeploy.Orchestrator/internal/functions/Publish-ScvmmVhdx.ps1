function Publish-ScvmmVhdx {
	[CmdletBinding()]
	Param (
		$GuestVhdxConfig,

		[string]
		$LibraryShare
	)
	
	process {
		Copy-Item -Path $GuestVhdxConfig.Path -Destination (Join-Path -Path $LibraryShare -ChildPath VHDs)
		Remove-Item -Path $GuestVhdxConfig.WorkingDirectory -Recurse -Force
		
		# Refresh Library so it detects the new disk
		$null = Get-SCLibraryShare | Where-Object Path -EQ $LibraryShare | Read-SCLibraryShare
		
		Get-SCVirtualHardDisk -Name $GuestVhdxConfig.VmmName
	}
}