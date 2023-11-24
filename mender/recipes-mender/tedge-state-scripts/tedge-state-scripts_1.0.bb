inherit mender-state-scripts

LICENSE = "CLOSED"

SRC_URI += " \
    file://copy_direct;subdir=${PN}-${PV} \
    file://backup_restore;subdir=${PN}-${PV} \
    file://verify_tedge_health;subdir=${PN}-${PV} \
"

do_compile() {
    cp copy_direct ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_00_copy-direct
    cp backup_restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_50_backup-runtime
    cp backup_restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_00_restore-runtime
    cp verify_tedge_health ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_50_verify-tedge
}

ALLOW_EMPTY:${PN} = "1"
