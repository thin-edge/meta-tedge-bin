inherit mender-state-scripts

LICENSE = "CLOSED"

SRC_URI += " \
    file://post_download;subdir=${PN}-${PV} \
    file://backup_restore;subdir=${PN}-${PV} \
    file://verify_tedge_health;subdir=${PN}-${PV} \
"

do_compile() {
    cp post_download ${MENDER_STATE_SCRIPTS_DIR}/Download_Leave_01_copy-static
    cp backup_restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_00_backup-runtime
    cp backup_restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_00_restore-runtime
    cp verify_tedge_health ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_10_verify-tedge
}

ALLOW_EMPTY:${PN} = "1"
