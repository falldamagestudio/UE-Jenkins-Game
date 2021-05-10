#!/bin/bash

CloudStorageBucket="$1"

ScriptRoot=$(dirname "$0")

DesiredVersionLocation="${ScriptRoot}/../../../desired-engine-version-linux.json"

BuildVersion=$(if [ -f "${DesiredVersionLocation}" ]; then cat "${DesiredVersionLocation}" | jq -r ".version"; else echo ""; fi)
UELocation="${ScriptRoot}/../../../UE"
CloudStorageLocation="gs://${CloudStorageBucket}/engine-linux"
LongtailCacheLocation="${ScriptRoot}/../../../LongtailCache"
InstalledVersionLocation="${ScriptRoot}/../../../installed-engine-version-linux.json"

"${ScriptRoot}/../Shell/Downsync-EngineBuild.sh" "$UELocation" "$CloudStorageLocation" "$BuildVersion" "$LongtailCacheLocation" "$InstalledVersionLocation"
