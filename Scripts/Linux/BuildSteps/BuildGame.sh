#!/bin/bash

ProjectLocation="$1"
TargetPlatform="$2"
Configuration="$3"
Target="$4"
ArchiveDir="$5"

ScriptRoot=$(dirname "$0")

# Create archive folder if it does not already exist
if [ ! -d "${ArchiveDir}" ]; then
    mkdir "${ArchiveDir}"
fi

UELocation="${ScriptRoot}/../../../UE"

RunUATLocation="${UELocation}/Engine/Build/BatchFiles/RunUAT.sh"

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
