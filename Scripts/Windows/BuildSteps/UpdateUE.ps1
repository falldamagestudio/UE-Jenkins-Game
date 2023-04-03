param (
	[Parameter(Mandatory)] [string] $CloudStorageBucket
)

. $PSScriptRoot\..\Powershell\Downsync-Build.ps1

$DesiredVersionLocation = "${PSScriptRoot}\..\..\..\desired-engine-version-win64.json"

$BuildVersion = (Get-Content -Path $DesiredVersionLocation -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop | Select-Object -First 1 -ErrorAction Stop).version

$UELocation = "${PSScriptRoot}\..\..\..\UE"
$CloudStorageLocation = "gs://${CloudStorageBucket}/ue-win64"
$LongtailCacheLocation = "${PSScriptRoot}\..\..\..\LongtailCache"
$InstalledVersionLocation = "${PSScriptRoot}\..\..\..\installed-engine-version-win64.json"

Downsync-Build -BuildLocation $UELocation -CloudStorageLocation $CloudStorageLocation -BuildVersion $BuildVersion -CacheLocation $LongtailCacheLocation -InstalledVersionLocation $InstalledVersionLocation
