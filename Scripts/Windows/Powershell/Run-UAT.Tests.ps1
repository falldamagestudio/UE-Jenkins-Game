. ${PSScriptRoot}\Ensure-TestToolVersions.ps1

BeforeAll {

	. ${PSScriptRoot}\Invoke-External-PrintStdout.ps1
	. ${PSScriptRoot}\Run-UAT.ps1

}

Describe 'Run-UAT' {

	It "Launches RunUAT with additional arguments" {

		Mock Invoke-External-PrintStdout -ParameterFilter { $LiteralPath -eq "C:\UE_4.24\Engine\Build\BatchFiles\RunUAT.bat" } { 0 }
		Mock Invoke-External-PrintStdout { throw "Invoke-External-PrintStdout invoked incorrectly" }

		Mock Get-EngineLocationForProject { "C:\UE_4.24" }

		Run-UAT -UProjectLocation "default.uproject" -Arguments "Hello", "World"

		Assert-MockCalled Invoke-External-PrintStdout -ParameterFilter { ($LiteralPath -eq "C:\UE_4.24\Engine\Build\BatchFiles\RunUAT.bat") }
	}

	It "Throws an exception when the editor returns an error" {

		Mock Invoke-External-PrintStdout -ParameterFilter { $LiteralPath -eq "C:\UE_4.24\Engine\Build\BatchFiles\RunUAT.bat" } { 5 }
		Mock Invoke-External-PrintStdout { throw "Invoke-External-PrintStdout invoked incorrectly" }

		Mock Get-EngineLocationForProject { "C:\UE_4.24" }

		{ Run-UAT -UProjectLocation "default.uproject" -Arguments "Hello", "World" } |
			Should -Throw "Run-UAT exited with code 5"
	}
}