inherit mender-state-scripts

LICENSE = "CLOSED"

SRC_URI += " \
    file://transfer;subdir=${BPN}-${PV} \
    file://restore;subdir=${BPN}-${PV} \
    file://verify-tedge;subdir=${BPN}-${PV} \
"

do_compile() {
    cp transfer ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_00_transfer
    cp restore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_00_restore
    cp verify-tedge ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_50_verify-tedge
}

ALLOW_EMPTY:${PN} = "1"
