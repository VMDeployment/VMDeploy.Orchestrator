function Convert-ShieldingUnattendFile {
	[CmdletBinding()]
	param (
		$UnattendFile,

		[string]
		$Seed
	)

	#region Utility Functions
	function New-Password {
		[cmdletBinding()]
		param (
			[int]
			$Length = 24
		)

		$pool = @(
			'A','B','C','D','E','F','G','H','I','J','K','L','M','N','P','Q','R','S','T','U','V','W','X',
			'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x',
			'0','1','2','3','4','5','6','7','8','9',
			'0','1','2','3','4','5','6','7','8','9',
			'A','B','C','D','E','F','G','H','I','J','K','L','M','N','P','Q','R','S','T','U','V','W','X',
			'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x',
			'0','1','2','3','4','5','6','7','8','9',
			'0','1','2','3','4','5','6','7','8','9',
			'A','B','C','D','E','F','G','H','I','J','K','L','M','N','P','Q','R','S','T','U','V','W','X',
			'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x',
			'0','1','2','3','4','5','6','7','8','9',
			'0','1','2','3','4','5','6','7','8','9'
		)

		$characters = $pool | Get-Random -Count $Length
		$characters -join ""
	}
	#endregion Utility Functions

	$tempFilePath = Join-Path -Path (Get-PSFPath -Name Temp) -ChildPath "Unattend-$Seed.xml"
	if (-not $UnattendFile.Dynamic) {
		Copy-Item -LiteralPath $UnattendFile.FilePath -Destination $tempFilePath
		return $tempFilePath
	}

	$fileContent = [System.IO.File]::ReadAllText($UnattendFile.FilePath)

	#region Process

	#region Local Admin Password
	if ($fileContent -like '*%!adminpassword!%*') {
		$newPassword = New-Password
		$fileContent = $fileContent.Replace('%!adminpassword!%', $newPassword)
		Write-VmoDeploymentData -Name 'LocalAdminPassword' -Data ($newPassword | ConvertTo-SecureString -AsPlainText -Force)
	}
	#endregion Local Admin Password

	#endregion Process

	[System.IO.File]::WriteAllText($tempFilePath, $fileContent)
	$tempFilePath
}