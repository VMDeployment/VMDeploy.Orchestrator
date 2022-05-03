function New-PdkFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,

		[Parameter(Mandatory = $true)]
		[string]
		$OSVhdxPath,

		[Parameter(Mandatory = $true)]
		[string]
		$AnswerFile
	)

	begin {
		Import-Module HgsClient -Scope Global
	}
	process {
		$tempFolder = Join-Path -Path (Get-PSFPath -Name Temp) -ChildPath "PDK-$(Get-Random)"
		$null = New-Item -Path $tempFolder -ItemType Directory -Force
	
		$vscPath = Join-Path -Path $tempFolder -ChildPath 'templateDisk.csv'
		Save-VolumeSignatureCatalog -TemplateDiskPath $OSVhdxPath -VolumeSignatureCatalogPath $vscPath
	
		try { $owner = Get-VMManShieldingOwner }
		catch { throw }
		try { $guardian = Get-VMManGuardedFabric }
		catch { throw }

		$param = @{
			ShieldingDataFilePath = $Path
			Owner                 = $owner
			VolumeIDQualifier     = New-VolumeIDQualifier -VolumeSignatureCatalogFilePath $vscPath -VersionRule Equals
			AnswerFile            = $AnswerFile
			Guardian              = $guardian
			Policy                = 'Shielded'
		}
		$result = New-ShieldingDataFile @param
		
		# Cleanup Temp Folder
		Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction Ignore
	}
}