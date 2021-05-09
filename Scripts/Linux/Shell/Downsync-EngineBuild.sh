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

    # HACK: Remove output build folder if it does exist
    # This is done because Longtail 0.0.36 has problems handling unexpected trees of empty folders
    #  within the build; for example, if we fetch an UE version, then launch the editor,
    #  then attempt to switch to a different UE version, Longtail will fail
    # We should upgrade to a newer version of Longtail; the current workaround
    #  is to delete the entire installed build before moving to another one
    # This is not all bad, as the local cache will be used to minimize network traffic,
    #  but the entire new build will need to be decompressed & written out to disk regardless
    if [ -d "${BuildLocation}" ]; then
        rm -rf "${BuildLocation}"
    fi

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