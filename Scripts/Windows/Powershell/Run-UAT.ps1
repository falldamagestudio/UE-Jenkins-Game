. ${PSScriptRoot}\Get-EngineLocationForProject.ps1
. ${PSScriptRoot}\Invoke-External.ps1

class UATException : Exception {
	$ExitCode

	UATException([int] $exitCode) : base("Run-UAT exited with code ${exitCode}") { $this.ExitCode = $exitCode }
}

function Run-UAT {

	param (
		[Parameter(Mandatory)] [String] $UProjectLocation,
		[Parameter()] [String[]] $Arguments
	)

	$EngineLocation = Get-EngineLocationForProject -UProjectLocation $UProjectLocation

	$RunUATLocation = Join-Path $EngineLocation -ChildPath "Engine\Build\BatchFiles\RunUAT.bat"
	
	$RunUATArguments = $Arguments | Where { $_ -ne $null }

	$ExitCode = Invoke-External -LiteralPath $RunUATLocation -ArgumentList $RunUATArguments
	
	if ($ExitCode -ne 0) {
		throw [UATException]::new($ExitCode)
	}
}