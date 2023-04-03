#!/bin/bash

BuildLocation="$1"
CloudStorageLocation="$2"
BuildVersion="$3"
CacheLocation="$4"
InstalledVersionLocation="$5"

ScriptRoot=$(dirname "$0")

# Fetch installed version from a local file if a path has been provided;
#  otherwise there is no version identifier available

if [ "${InstalledVersionLocation}" != "" ]; then
    InstalledVersion=$(if [ -f "${InstalledVersionLocation}" ]; then cat "${InstalledVersionLocation}" | jq -r ".version"; else echo ""; fi)
else
    InstalledVersion=""
fi

echo "Installed version: $InstalledVersion"

if [ "${InstalledVersion}" != "${BuildVersion}" ]; then

    # Create output build folder if it does not already exist
    if [ ! -d "${BuildLocation}" ]; then
        mkdir "${BuildLocation}"
    fi

    # Create cache folder if it does not already exist
    if [ ! -d "${CacheLocation}" ]; then
        mkdir "${CacheLocation}"
    fi

    LongtailLocation="${ScriptRoot}/longtail-linux-x64"
    VersionIndexURI="${CloudStorageLocation}/index/${BuildVersion}.lvi"
    StorageURI="${CloudStorageLocation}/storage"

    echo "Beginning Longtail process"

    "${LongtailLocation}" \
        "downsync" \
        "--source-path" \
        $VersionIndexURI \
        "--target-path" \
        $BuildLocation \
        "--storage-uri" \
        $StorageURI \
        "--cache-path" \
        $CacheLocation

    LongtailResult=$?

    echo "Completed Longtail process"

    if [ ! $LongtailResult ]; then exit 1; fi

    echo "Exit code validated"

    # Update installed version identifier, if a path has been provided
    if [ "${InstalledVersionLocation}" != "" ]; then
        echo "Updating InstalledVersionLocation"

        echo "{ \"version\": \"${BuildVersion}\" }" > $InstalledVersionLocation
    fi

    echo "Downsync-Build done"
fi
