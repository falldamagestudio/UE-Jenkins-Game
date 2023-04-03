. ${PSScriptRoot}\Invoke-External-PrintStdout.ps1

class LongtailException : Exception {
	$ExitCode

	LongtailException([int] $exitCode) : base("longtail-win32-x64.exe exited with code ${exitCode}") { $this.ExitCode = $exitCode }
}

function Downsync-Build {

    param (
        [Parameter(Mandatory)] [string] $BuildLocation,
        [Parameter(Mandatory)] [string] $CloudStorageLocation,
        [Parameter(Mandatory)] [string] $BuildVersion,
        [Parameter(Mandatory)] [string] $CacheLocation,
        [Parameter(Mandatory=$false)] [string] $InstalledVersionLocation
    )

    # Fetch installed version from a local file if a path has been provided;
    #  otherwise there is no version identifier available
    if ($InstalledVersionLocation) {
        try {
            $InstalledVersion = (Get-Content -Path $InstalledVersionLocation -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop | Select-Object -First 1 -ErrorAction Stop).version
        } catch [System.Management.Automation.ItemNotFoundException] {
            $InstalledVersion = $null
        }
    } else {
        $InstalledVersion = $null
    }

    if ($InstalledVersion -ne $BuildVersion) {

        # Create output build folder if it does not already exist
        if (!(Test-Path $BuildLocation)) {
            New-Item -Path $BuildLocation -ItemType Directory -ErrorAction Stop | Out-Null
        }

        # Create cache folder if it does not already exist
        if (!(Test-Path $CacheLocation)) {
            New-Item -Path $CacheLocation -ItemType Directory -ErrorAction Stop | Out-Null
        }

        $LongtailLocation = "${PSScriptRoot}\longtail-win32-x64.exe"
        $BuildAbsoluteLocation = "\\?\$(Resolve-Path ${BuildLocation} -ErrorAction Stop)"
        $VersionIndexURI = "${CloudStorageLocation}/index/${BuildVersion}.lvi"
        $StorageURI = "${CloudStorageLocation}/storage"

        $Arguments = @(
            "downsync"
            "--source-path"
            $VersionIndexURI
            "--target-path"
            $BuildAbsoluteLocation
            "--storage-uri"
            $StorageURI
            "--cache-path"
            $CacheLocation
        )

        Write-Host "Beginning Longtail process"
        # Update local build version using Longtail
        $ExitCode = Invoke-External-PrintStdout -LiteralPath $LongtailLocation -ArgumentList $Arguments
        Write-Host "Completed Longtail process"

        if ($ExitCode -ne 0) {
            throw [LongtailException]::new($ExitCode)
        }
        Write-Host "Exit code validated"

        # Update installed version identifier, if a path has been provided
        if ($InstalledVersionLocation) {
            Write-Host "UPdating InstalledVersionLocation"
            @{ "version" = $BuildVersion } | ConvertTo-Json -ErrorAction Stop | Out-File -FilePath $InstalledVersionLocation -ErrorAction Stop
        }
        Write-Host "Downsync-Build done"
    }
}
