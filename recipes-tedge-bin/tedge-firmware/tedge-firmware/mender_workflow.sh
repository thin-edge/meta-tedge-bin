#!/bin/sh
set -e
ON_SUCCESS="successful"
ON_ERROR="failed"
ON_RESTART="restart"
FIRMWARE_NAME=
FIRMWARE_VERSION=
FIRMWARE_URL=
FIRMWARE_META_FILE=/etc/tedge/.firmware
MANUAL_DOWNLOAD=1

ACTION="$1"
shift

log() {
    msg="$(date +%Y-%m-%dT%H:%M:%S) [current=$ACTION] $*"
    echo "$msg" >&2

    # publish to pub for better resolution
    current_partition=$(get_current_partition)
    tedge mqtt pub -q 2 te/device/main///e/firmware_update "{\"text\":\"Firmware Workflow: [$ACTION] $*\",\"state\":\"$ACTION\",\"partition\":\"$current_partition\"}"
    sleep 1
}

local_log() {
    # Only log locally and don't push to the cloud
    msg="$(date +%Y-%m-%dT%H:%M:%S) [current=$ACTION] $*"
    echo "$msg" >&2
}

next_state_with_context() {
    echo ":::begin-tedge:::"
    echo "$1"
    echo ":::end-tedge:::"
    sleep 1
}

next_state() {
    status="$1"
    reason=

    if [ $# -gt 1 ]; then
        reason="$2"
    fi

    message=
    if [ -n "$reason" ]; then
        log "Moving to next State: $status. reason=$reason"
        message=$(printf '{"status":"%s","reason":"%s"}' "$status" "$reason")
    else
        log "Moving to next State: $status"
        message=$(printf '{"status":"%s"}' "$status")
    fi

    next_state_with_context "$message"
    sleep 1
}

#
# main
#
while [ $# -gt 0 ]; do
    case "$1" in
        --firmware-name)
            FIRMWARE_NAME="$2"
            shift
            ;;
        --firmware-version)
            FIRMWARE_VERSION="$2"
            shift
            ;;
        --url)
            FIRMWARE_URL="$2"
            shift
            ;;
        --on-success)
            ON_SUCCESS="$2"
            shift
            ;;
        --on-error)
            ON_ERROR="$2"
            shift
            ;;
        --on-restart)
            ON_RESTART="$2"
            shift
            ;;
    esac
    shift
done

wait_for_network() {
    #
    # Wait for network to be ready but don't block if still not available as the mender commit
    # might be used to restore network connectivity.
    #
    attempt=0
    max_attempts=10
    # Network ready: 0 = no, 1 = yes
    ready=0
    local_log "Waiting for network to be ready, and time to be synced"

    while [ "$attempt" -lt "$max_attempts" ]; do
        # TIME_SYNC_ACTIVE=$(timedatectl | grep NTP | awk '{print $NF}')
        TIME_IN_SYNC=$(timedatectl | awk '/System clock synchronized/{print $NF}')
        case "${TIME_IN_SYNC}" in
            yes)
                ready=1
                break
                ;;
        esac
        attempt=$((attempt + 1))
        local_log "Network not ready yet (attempt: $attempt from $max_attempts)"
        sleep 30
    done

    # Duration can only be based on uptime since the device's clock might not be synced yet, so 'date' will not be monotonic
    duration=$(awk '{print $1}' /proc/uptime)

    local_log "Network: ready=$ready (after ${duration}s)"
    if [ "$ready" = "1" ]; then
        log "Network is ready after ${duration}s (from startup)"
        return 0
    fi

    # Don't send cloud message if it is not ready
    return 1
}

get_current_partition() {
    MENDER_ROOTFS_PART_A="/dev/mmcblk0p2"
    #MENDER_ROOTFS_PART_B="/dev/mmcblk0p3"
    current=""
    if mount | grep "${MENDER_ROOTFS_PART_A} on / " >/dev/null; then
        current="A"
    else
        current="B"
    fi
    echo "$current"
}

get_next_partition() {
    [ "$1" = "A" ] && echo "B" || echo "A"
}

executing() {
    current_partition=$(get_current_partition)
    next_partition=$(get_next_partition "$current_partition")
    echo "---------------------------------------------------------------------------"
    echo "Firmware update: $current_partition -> $next_partition"
    echo "---------------------------------------------------------------------------"
    log "Starting firmware update. Current partition is $(get_current_partition), so update will be applied to $next_partition"
}

download() {
    status="$1"
    url="$2"

    MANUAL_DOWNLOAD=0

    tedge_url="$url"

    # Auto detect based on the url if the direct url can be used or not
    case "$url" in
        */inventory/binaries/*)
            # FUTURE: The mender client 3.x currently checks for a Content-Length header in the response
            # and fails if it is not present. Cumulocity IoT uses chunked Transfter-Encoding where the Content-Length
            # is no included in the response headers, thus causing mender to fail.
            # mender is currently being rewritten and seems to have support for proper Content-Range handling, however
            # it is still in alpha.
            #
            MANUAL_DOWNLOAD=1

            #
            # Change url to a local url using the c8y proxy
            #
            partial_path=$(echo "$url" | sed 's|https://[^/]*/||g')
            c8y_proxy_host=$(tedge config get c8y.proxy.client.host)
            c8y_proxy_port=$(tedge config get c8y.proxy.client.port)
            tedge_url="http://${c8y_proxy_host}:${c8y_proxy_port}/c8y/$partial_path"

            log "Converted to local url: $url => $tedge_url"
            ;;
    esac

    if [ "$MANUAL_DOWNLOAD" = 1 ]; then
        # Removing any older files to ensure space for next file to download
        # Note: busy box does not support -delete
        TEDGE_DATA=$(tedge config get data.path)
        find "$TEDGE_DATA" -name "*.firmware" -exec rm {} \;

        last_part=$(echo "$partial_path" | rev | cut -d/ -f1 | rev)
        local_file="$TEDGE_DATA/${last_part}.firmware"
        log "Manually downloading artifact from $tedge_url and saving to $local_file"
        wget -O "$local_file" "$tedge_url" >&2
        log "Downloaded file from: $tedge_url"
        next_state_with_context "$(printf '{"status":"%s","url":"%s"}\n' "$status" "$local_file")"
    else
        log "Using download url: $tedge_url"
        next_state_with_context "$(printf '{"status":"%s","url":"%s"}\n' "$status" "$tedge_url")"
    fi
}

install() {
    url="$1"
    log "Executing: mender install --reboot-exit-code '$url'"
    EXIT_CODE=0
    sudo mender install --reboot-exit-code "$url" || EXIT_CODE="$?"

    case "$EXIT_CODE" in
        0)
            log "OK, no RESTART required"
            next_state "$ON_SUCCESS"
            ;;
        4)
            log "OK, RESTART required"
            next_state "$ON_RESTART"
            ;;
        *)
            log "ERROR. Unexpected mender return code"
            next_state "$ON_ERROR"
            ;;
    esac
}

commit() {
    log "Executing: mender commit"
    EXIT_CODE=0
    sudo mender commit || EXIT_CODE="$?"

    case "$EXIT_CODE" in
        0)
            log "Commit successful. New default partition is $(get_current_partition)"

            # Save firmware meta information to file (for reading on startup during normal operation)
            local_log "Saving firmware info to $FIRMWARE_META_FILE"
            printf 'FIRMWARE_NAME=%s\nFIRMWARE_VERSION=%s\nFIRMWARE_URL=%s\n' "$FIRMWARE_NAME" "$FIRMWARE_VERSION" "$FIRMWARE_URL" > "$FIRMWARE_META_FILE"

            next_state "$ON_SUCCESS"
            ;;
        2)
            log "Nothing to commit (update is not in progress)"
            next_state "$ON_ERROR" "Nothing to commit. Either the boot loader triggered the rollback, the device was rebooted after switching to new partition, or someone did a manual commit or rollback!"
            ;;
        *)
            log "Mender returned code: $EXIT_CODE. Rolling back to previous partition"
            next_state "$ON_RESTART"
            ;;
    esac
}

case "$ACTION" in
    executing)
        executing
        next_state "$ON_SUCCESS"
        ;;
    download) download "$ON_SUCCESS" "$FIRMWARE_URL"; ;;
    install) install "$FIRMWARE_URL"; ;;
    commit) commit; ;;
    restarted)
	    wait_for_network ||:
        log "Device has been restarted...continuing workflow. partition=$(get_current_partition)"
        next_state "$ON_SUCCESS"
        ;;
    rollback_successful)
        next_state "$ON_SUCCESS" "Firmware update failed, but the rollback was successful. partition=$(get_current_partition)"
        ;;
    failed_restart)
        # There is no success/failed action here, we always transition to the next state
        # Only an error reason is added
        next_state "$ON_SUCCESS" "Device failed to restart"
        ;;
    *)
        log "Unknown command. This script only accecpts: download, install, commit, rollback, rollback_successful, failed_restart"
        exit 1
        ;;
esac

exit 0
