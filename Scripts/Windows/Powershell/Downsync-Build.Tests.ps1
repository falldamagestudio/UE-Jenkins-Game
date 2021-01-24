. ${PSScriptRoot}\Ensure-TestToolVersions.ps1

BeforeAll {

	. ${PSScriptRoot}\Downsync-Build.ps1

}

Describe 'Downsync-Build' {

	It "Succeeds if version already is present" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item { }

		Mock Resolve-Path { }

		Mock Start-Process { }

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1234" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Not -Throw

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 0 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 0 New-Item
		Assert-MockCalled -Times 0 Resolve-Path
		Assert-MockCalled -Times 0 Start-Process
		Assert-MockCalled -Times 0 Out-File
	}

	It "Reports error if build folder cannot be created" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { throw "Cannot create build folder" }

		Mock New-Item -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { }

		Mock Resolve-Path { }

		Mock Start-Process { }

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Throw "Cannot create build folder"

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 2 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 1 New-Item
		Assert-MockCalled -Times 0 Resolve-Path
		Assert-MockCalled -Times 0 Start-Process
		Assert-MockCalled -Times 0 Out-File
	}

	It "Reports error if cache folder cannot be created" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { }
		Mock New-Item -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { throw "Cannot create cache folder" }

		Mock Resolve-Path { }

		Mock Start-Process { }

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Throw "Cannot create cache folder"

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 3 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 2 New-Item
		Assert-MockCalled -Times 0 Resolve-Path
		Assert-MockCalled -Times 0 Start-Process
		Assert-MockCalled -Times 0 Out-File
	}

	It "Reports error if path cannot be resolved" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item { }

		Mock Resolve-Path { throw "Path cannot be resolved" }

		Mock Start-Process { }

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Throw "Path cannot be resolved"

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 3 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 2 New-Item
		Assert-MockCalled -Times 1 Resolve-Path
		Assert-MockCalled -Times 0 Start-Process
		Assert-MockCalled -Times 0 Out-File
	}

	It "Reports error if Longtail executable returns a nonzero status" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item { }

		Mock Resolve-Path { }

		Mock Start-Process { @{ ExitCode = 1234 }}

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Throw

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 3 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 2 New-Item
		Assert-MockCalled -Times 1 Resolve-Path
		Assert-MockCalled -Times 1 Start-Process
		Assert-MockCalled -Times 0 Out-File
	}

	It "Reports error if installed version number cannot be updated" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item { }

		Mock Resolve-Path { }

		Mock Start-Process { @{ ExitCode = 0 }}

		Mock Out-File { throw "Cannot write updated version number" }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Throw "Cannot write updated version number"

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 3 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 2 New-Item
		Assert-MockCalled -Times 1 Resolve-Path
		Assert-MockCalled -Times 1 Start-Process
		Assert-MockCalled -Times 1 Out-File
	}

	It "Reports success if the entire operation goes according to plan" {

		Mock Get-Content { '{ "version" : "1234" }' }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item { }

		Mock Resolve-Path { }

		Mock Start-Process { @{ ExitCode = 0 }}

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" -InstalledVersionLocation "installed-version.json" } |
			Should -Not -Throw

		Assert-MockCalled -Times 1 Get-Content
		Assert-MockCalled -Times 3 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 2 New-Item
		Assert-MockCalled -Times 1 Resolve-Path
		Assert-MockCalled -Times 1 Start-Process
		Assert-MockCalled -Times 1 Out-File
	}

	It "Performs downsync successfully when no InstalledVersionLocation is specified" {

		Mock Get-Content { throw "Cannot read contents of file" }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "BuildFolder") } { $false }

		Mock Test-Path -ParameterFilter { $Path -and ($Path -eq "CacheFolder") } { $false }

		Mock Remove-Item { }

		Mock New-Item { }

		Mock Resolve-Path { }

		Mock Start-Process { @{ ExitCode = 0 }}

		Mock Out-File { }

		{ Downsync-Build -BuildLocation "BuildFolder" -CloudStorageLocation "gs://storage-bucket/folder" -BuildVersion "1235" -CacheLocation "CacheFolder" } |
			Should -Not -Throw

		Assert-MockCalled -Times 0 Get-Content
		Assert-MockCalled -Times 3 Test-Path
		Assert-MockCalled -Times 0 Remove-Item
		Assert-MockCalled -Times 2 New-Item
		Assert-MockCalled -Times 1 Resolve-Path
		Assert-MockCalled -Times 1 Start-Process
		Assert-MockCalled -Times 0 Out-File
	}
}