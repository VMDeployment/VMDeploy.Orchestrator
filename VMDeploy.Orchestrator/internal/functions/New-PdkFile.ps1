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
		Import-Module CimCmdlets -Scope Global
		Import-Module HgsClient -Scope Global
		Import-Module ShieldedVMDataFile -Scope Global
	}
	process {
		$tempFolder = Join-Path -Path (Get-PSFPath -Name Temp) -ChildPath "PDK-$(Get-Random)"
		$null = New-Item -Path $tempFolder -ItemType Directory -Force
	
		$vscPath = Join-Path -Path $tempFolder -ChildPath 'templateDisk.vsc'
		Save-VolumeSignatureCatalog -TemplateDiskPath $OSVhdxPath -VolumeSignatureCatalogPath $vscPath
	
		try { $owner = Get-VMManShieldingOwner }
		catch { throw }
		try { $guardian = Get-VMManGuardedFabric }
		catch { throw }

		# The parametername for unattend answer files changes between Server 2016 & 2019
		$unattendParamName = 'WindowsUnattendFile'
		if ((Get-Command New-ShieldingDataFile).Parameters.Keys -contains 'AnswerFile') { $unattendParamName = 'AnswerFile' }
		
		$param = @{
			ShieldingDataFilePath = $Path
			Owner                 = $owner
			VolumeIDQualifier     = New-VolumeIDQualifier -VolumeSignatureCatalogFilePath $vscPath -VersionRule Equals
			$unattendParamName    = $AnswerFile
			Guardian              = $guardian
			Policy                = 'Shielded'
		}
		New-ShieldingDataFile @param

		New-SCVMShieldingData -Name "VMDeploy-$(Split-Path -Path $Path -Leaf)" -VMShieldingDataPath $Path -Description "VMDeploy $(Split-Path -Path $Path -Leaf) - $(Get-Date -Format yyyy-MM-dd)"
		
		# Cleanup Temp Folder
		Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction Ignore
	}
}