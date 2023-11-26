#!/bin/sh
set -e
ON_SUCCESS="successful"
ON_ERROR="failed"
ON_RESTART="restart"
FIRMWARE_URL=
CMD_ID=x
LOG_FILE=/etc/tedge/firmware_update.log
MANUAL_DOWNLOAD=1

ACTION="$1"
shift

log() {
    msg="$(date +%Y-%m-%dT%H:%M:%S) [cmd=$CMD_ID, current=$ACTION] $*"
    echo "$msg" >&2

    # publish to pub for better resolution
    current_partition=$(get_current_partition)
    tedge mqtt pub -q 2 te/device/main///e/firmware_update "{\"text\":\"Firmware Workflow: [$ACTION] $*\",\"command_id\":\"$CMD_ID\",\"state\":\"$ACTION\",\"partition\":\"$current_partition\"}"
    sleep 1

    if [ -n "$LOG_FILE" ]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

local_log() {
    # Only log locally and don't push to the cloud
    msg="$(date +%Y-%m-%dT%H:%M:%S) [cmd=$CMD_ID, current=$ACTION] $*"
    echo "$msg" >&2

    if [ -n "$LOG_FILE" ]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

next_state() {
    status="$1"
    reason=

    if [ $# -gt 1 ]; then
        reason="$2"
    fi

    if [ -n "$reason" ]; then
        log "Moving to next State: $status. reason=$reason"
        printf '{"status":"%s","reason":"%s"}\n' "$status" "$reason"
    else
        log "Moving to next State: $status"
        printf '{"status":"%s"}\n' "$status"
    fi
    sleep 1
}

#
# main
#
while [ $# -gt 0 ]; do
    case "$1" in
        --id)
            CMD_ID="$2"
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
        --url)
            FIRMWARE_URL="$2"
            shift
            ;;
    esac
    shift
done

wait_for_network() {
    #
    # Wait for network to be ready but don't block
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

executing() {
    hot=$(get_current_partition)
    log "Starting firmware update: current_partition=$hot"
}

download() {
    status="$1"
    url="$2"

    #
    # Change url to a local url using the c8y proxy
    #
    partial_path=$(echo "$url" | sed 's|https://[^/]*/||g')
    c8y_proxy_host=$(tedge config get c8y.proxy.client.host)
    c8y_proxy_port=$(tedge config get c8y.proxy.client.port)
    tedge_url="http://${c8y_proxy_host}:${c8y_proxy_port}/c8y/$partial_path"

    TEDGE_DATA=$(tedge config get data.path)

    if [ "$MANUAL_DOWNLOAD" = 1 ]; then

        # Removing any older files to ensure space for next file to download
        # Note: busy box does not support -delete
        find "$TEDGE_DATA" -name "*.firmware" -exec rm {} \;

        last_part=$(echo "$partial_path" | rev | cut -d/ -f1 | rev)
        local_file="$TEDGE_DATA/${last_part}.firmware"
        log "Manually downloading artifact from $tedge_url and saving to $local_file"
        wget -O "$local_file" "$tedge_url" >&2
        log "Downloaded file from: $tedge_url"
        printf '{"status":"%s","url":"%s"}\n' "$status" "$local_file"
    else
        log "Converted to local url: $url => $tedge_url"
        printf '{"status":"%s","url":"%s"}\n' "$status" "$tedge_url"
    fi
}

install() {
    url="$1"
    log "Executing: mender install --reboot-exit-code '$url'"
    set +e
    sudo mender install --reboot-exit-code "$url" >>"$LOG_FILE" 2>&1
    MENDER_CODE=$?
    set -e

    case "$MENDER_CODE" in
        0)
            log "OK, no REBOOT required"
            next_state "$ON_SUCCESS"
            ;;
        4)
            log "OK, REBOOT required"
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
    set +e
    sudo mender commit >>"$LOG_FILE" 2>&1
    MENDER_CODE=$?
    set -e

    case "$MENDER_CODE" in
        0)
            log "Commit successful. current_partition=$(get_current_partition)"
            next_state "$ON_SUCCESS"
            ;;
        2)
            log "Nothing to commit (update is not in progress)"
            next_state "$ON_ERROR" "Nothing to commit. Either the boot loader triggered the rollback, the device was rebooted after switching to new partition, or someone did a manual rollback!"
            ;;
        *)
            log "Mender returned code: $MENDER_CODE. Rolling back to previous partition"
            next_state "$ON_ERROR"
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
        log "Device has been restarted...continuing workflow. current_partition=$(get_current_partition)"
        next_state "$ON_SUCCESS"
        ;;
    rollback_successful)
        log "Rollback complete. current_partition=$(get_current_partition)"
        next_state "$ON_SUCCESS" "Firmware update failed, but the rollback was successful. current_partition=$(get_current_partition)"
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
