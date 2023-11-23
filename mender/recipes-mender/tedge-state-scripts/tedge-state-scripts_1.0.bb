inherit mender-state-scripts

LICENSE = "CLOSED"

SRC_URI += " \
    file://tedge-install-leave-script;subdir=${PN}-${PV} \
    file://tedge-commit-enter-script;subdir=${PN}-${PV} \
"

do_compile() {
    cp tedge-install-leave-script ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_00
    cp tedge-commit-enter-script ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_00
}

ALLOW_EMPTY:${PN} = "1"
