inherit mender-state-scripts

LICENSE = "CLOSED"

SRC_URI += " \
    file://copy-direct;subdir=${PN}-${PV} \
    file://backup-restore;subdir=${PN}-${PV} \
    file://verify-tedge;subdir=${PN}-${PV} \
"

do_compile() {
    cp copy-direct ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_00_copy-direct
    cp backup-restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_50_backup-runtime
    cp backup-restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_00_restore-runtime
    cp verify-tedge ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_50_verify-tedge
}

ALLOW_EMPTY:${PN} = "1"
