param (
	[Parameter(Mandatory)] [string] $ProjectLocation,
	[Parameter(Mandatory)] [string] $TargetPlatform,
	[Parameter(Mandatory)] [string] $Configuration,
	[Parameter(Mandatory)] [string] $Target,
	[Parameter(Mandatory)] [string] $ArchiveDir
)

. $PSScriptRoot\..\Powershell\Run-UAT.ps1

# Create archive folder if it does not already exist
New-Item -Path $ArchiveDir -ItemType Directory -Force -ErrorAction Stop | Out-Null

$Arguments = @(
	"-ScriptsForProject=$(Resolve-Path $ProjectLocation)"
	"BuildCookRun"
	"-installed"
	"-nop4"
	"-project=$(Resolve-Path $ProjectLocation)"
	"-cook"
	"-stage"
	"-archive"
	"-archivedirectory=$(Resolve-Path $ArchiveDir)"
	"-package"
	"-pak"
	"-prereqs"
	"-nodebuginfo"
	"-targetplatform=$TargetPlatform"
	"-build"
	"-target=$Target"
	"-clientconfig=$Configuration"
	"-utf8output"
	"-buildmachine"
	"-iterativecooking"
	"-iterativedeploy"
	"-NoCodeSign"	
)

Run-UAT -UProjectLocation $ProjectLocation -Arguments $Arguments
