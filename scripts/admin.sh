#!/usr/bin/env bash
set -eou pipefail

help() {
    cat << EOT
Project admin scripts to either update the thin-edge.io version

USAGE
    $0 <COMMAND> [OPTIONS]

COMMANDS
    $0 update_version          Update the BB layer for thin-edge.io to the latest version
EOT
}

get_latest_version() {
    repo="$1"
    arch="$2"
    cloudsmith ls pkg "$repo" -q "tag:latest AND name:tedge-$arch AND format:raw" -F json -l 1 \
    | jq -r '.data[] | .version'
}

get_tedge_md5_checksum() {
    repo="$1"
    arch="$2"
    version="$3"
    cloudsmith ls pkg "$repo" -q "version:^$version$ AND name:tedge-$arch AND format:raw" -F json -l 1 \
    | jq -r '.data[] | .files[0].checksum_md5'
}

get_services_latest_version() {
    repo="$1"
    cloudsmith ls pkg "$repo" -q "tag:latest AND name:tedge-openrc AND format:raw" -F json -l 1 \
    | jq -r '.data[] | .version'
}

get_services_checksum() {
    repo="$1"
    version="$2"
    pkg="$3"
    cloudsmith ls pkg "$repo" -q "version:^$version$ AND name:$pkg AND format:raw" -F json -l 1 \
    | jq -r '.data[] | .files[0].checksum_md5'
}


update_version() {
    # Install tooling if missing
    if ! [ -x "$(command -v cloudsmith)" ]; then
        echo 'Install cloudsmith cli' >&2
        if command -v pip3 &>/dev/null; then
            pip3 install --upgrade cloudsmith-cli
        elif command -v pip &>/dev/null; then
            pip install --upgrade cloudsmith-cli
        else
            echo "Could not install cloudsmith cli. Reason: pip3/pip is not installed"
            exit 2
        fi
    fi

    echo "Updating version" >&2
    # thin-edge.io
    tedge_channel="release"
    tedge_version=$(get_latest_version "thinedge/tedge-release" "arm64")
    echo "Latest thin-edge.io version: $tedge_version in (thinedge/tedge-release)"

    # tedge service definitions
    community_repo="thinedge/community"
    services_version=$(get_services_latest_version "$community_repo")
    echo "Latest services repo version: $services_version in ($community_repo)"

    # Generate BB file
    tedge_bb_file="recipes-tedge-bin/tedge/tedge_${tedge_version}.bb"

    echo "Writing bb file: $tedge_bb_file" >&2

    cat << EOT | tee "$tedge_bb_file"
# Architecture variables
ARCH_REPO_CHANNEL = "$tedge_channel"
ARCH_VERSION = "$tedge_version"
SRC_URI[aarch64.md5sum] = "$(get_tedge_md5_checksum "thinedge/tedge-${tedge_channel}" "arm64" "$tedge_version")"
SRC_URI[armv6.md5sum] = "$(get_tedge_md5_checksum "thinedge/tedge-${tedge_channel}-armv6" "armv6" "$tedge_version")"
SRC_URI[armv7.md5sum] = "$(get_tedge_md5_checksum "thinedge/tedge-${tedge_channel}" "armv7" "$tedge_version")"
SRC_URI[x86_64.md5sum] = "$(get_tedge_md5_checksum "thinedge/tedge-${tedge_channel}" "amd64" "$tedge_version")"

# Init manager variables
INIT_REPO_CHANNEL = "$(basename "$community_repo")"
INIT_VERSION = "$services_version"
SRC_URI[openrc.md5sum] = "$(get_services_checksum "$community_repo" "$services_version" "tedge-openrc")"
SRC_URI[systemd.md5sum] = "$(get_services_checksum "$community_repo" "$services_version" "tedge-systemd")"
SRC_URI[sysvinit.md5sum] = "$(get_services_checksum "$community_repo" "$services_version" "tedge-sysvinit-yocto")"

require tedge.inc
EOT
}

REST_ARGS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            help
            exit 0
            ;;
        --*|-*)
            echo "Unknown option: $1" >&2
            help
            exit 1
            ;;
        *)
            REST_ARGS+=("$1")
            ;;
    esac
    shift
done

if [ ${#REST_ARGS[@]} -gt 0 ]; then
    set -- "${REST_ARGS[@]}"
fi

if [ $# -eq 0 ]; then
    echo "Missing required argument" >&2
    help
    exit 1
fi

COMMAND="$1"
case "$COMMAND" in 
    update_version)
        update_version
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        exit 1
        ;;
esac
