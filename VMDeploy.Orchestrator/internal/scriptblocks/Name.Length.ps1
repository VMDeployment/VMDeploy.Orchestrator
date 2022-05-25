Set-PSFScriptblock -Name 'VMDeploy.Orchestrator.ComputerName.Length' -Scriptblock {
	$_.Length -lt 16
}