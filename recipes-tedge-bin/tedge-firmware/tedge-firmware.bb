LICENSE = "CLOSED"

SRC_URI += " \
    file://mender_workflow.sh \ 
    file://firmware_update.toml \
    file://tedge-firmware \
    file://persist.conf \
"

do_install () {
    # Add firmware worfklow and script
    install -d "${D}${bindir}"
    install -m 0755 "${WORKDIR}/mender_workflow.sh" "${D}${bindir}"

    install -d "${D}/etc/tedge/operations"
    install -m 0644 "${WORKDIR}/firmware_update.toml" "${D}${sysconfdir}/tedge/operations"

    # FIXME: This cases a conflict with the existing sudoers.d folder
    # Allow sudo access
    #install -d -m 0700 "${D}/etc/sudoers.d"
    #install -m 0644 "${WORKDIR}/tedge-firmware" "${D}${sysconfdir}/sudoers.d/"

    # mosquitto setup
    install -d "${D}/var/lib/mosquitto"
    install -d "${D}${sysconfdir}/tedge/mosquitto-conf/"
    install -m 0644 "${WORKDIR}/persist.conf" "${D}${sysconfdir}/tedge/mosquitto-conf/"
}

FILES:${PN} += " \
    ${bindir}/mender_workflow.sh \
    ${sysconfdir}/tedge/operations/firmware_update.toml \
    ${sysconfdir}/sudoers.d/tedge-firmware \
    ${sysconfdir}/tedge/mosquitto-conf/persist.conf \
"
