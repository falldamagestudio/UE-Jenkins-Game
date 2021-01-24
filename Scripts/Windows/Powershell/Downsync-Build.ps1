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

        # HACK: Remove output build folder if it does exist
        # This is done because Longtail 0.0.36 has problems handling unexpected trees of empty folders
        #  within the build; for example, if we fetch an UE version, then launch the editor,
        #  then attempt to switch to a different UE version, Longtail will fail
        # We should upgrade to a newer version of Longtail; the current workaround
        #  is to delete the entire installed build before moving to another one
        # This is not all bad, as the local cache will be used to minimize network traffic,
        #  but the entire new build will need to be decompressed & written out to disk regardless
        if (Test-Path $BuildLocation) {
            Remove-Item -Path $BuildLocation -Recurse -Force -ErrorAction Stop
        }

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

        # Update local build version using Longtail
        $Process = Start-Process -FilePath $LongtailLocation -ArgumentList $Arguments -NoNewWindow -Wait -PassThru

        if ($Process.ExitCode -ne 0) {
            throw [LongtailException]::new($Process.ExitCode)
        }

        # Update installed version identifier, if a path has been provided
        if ($InstalledVersionLocation) {
            @{ "version" = $InstalledVersion } | ConvertTo-Json -ErrorAction Stop | Out-File -FilePath $InstalledVersionLocation -ErrorAction Stop
        }
    }
}