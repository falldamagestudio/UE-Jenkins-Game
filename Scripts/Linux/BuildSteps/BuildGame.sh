#!/bin/bash

ProjectLocation="$1"
TargetPlatform="$2"
Configuration="$3"
Target="$4"
ArchiveDir="$5"
LogFolder="$6"

ScriptRoot=$(dirname "$0")

# Create archive folder if it does not already exist
if [ ! -d "${ArchiveDir}" ]; then
    mkdir "${ArchiveDir}"
fi

# Remove log folder and its contents if it already exists
if [ -d "${LogFolder}" ]; then
    rm -rf "${LogFolder}"
fi

# Create log folder if it does not already exist
if [ ! -d "${LogFolder}" ]; then
    mkdir "${LogFolder}"
fi

UELocation="${ScriptRoot}/../../../UE"

RunUATLocation="${UELocation}/Engine/Build/BatchFiles/RunUAT.sh"

uebp_LogFolder=${LogFolder} \
"$RunUATLocation" \
	"-ScriptsForProject=${ProjectLocation}" \
	BuildCookRun \
	-installed \
	-nop4 \
	"-project=${ProjectLocation}" \
	-cook \
	-stage \
	-archive \
	"-archivedirectory=${ArchiveDir}" \
	-package \
	-pak \
	-prereqs \
	-nodebuginfo \
	"-targetplatform=${TargetPlatform}" \
	-build \
	"-target=${Target}" \
	"-clientconfig=${Configuration}" \
	-utf8output \
	-buildmachine \
	-iterativecooking \
	-iterativedeploy \
	-NoCodeSign
