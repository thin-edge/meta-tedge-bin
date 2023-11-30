LICENSE = "CLOSED"

inherit systemd features_check

REQUIRED_DISTRO_FEATURES = "systemd"

SRC_URI += " \
    file://tedge-identity \ 
    file://tedge-bootstrap \
    file://tedge-bootstrap.service \
"

do_install () {
    install -d "${D}${bindir}"
    install -m 0755 "${WORKDIR}/tedge-identity" "${D}${bindir}"

    install -d "${D}${bindir}"
    install -m 0755 "${WORKDIR}/tedge-bootstrap" "${D}${bindir}"

    install -d "${D}${systemd_system_unitdir}"
    install -m 0644 "${WORKDIR}/tedge-bootstrap.service" "${D}${systemd_system_unitdir}"
}

FILES:${PN} += " \
    ${bindir}/tedge-identity \
    ${bindir}/tedge-bootstrap \
    ${systemd_system_unitdir}/tedge-bootstrap.service \
"

SYSTEMD_SERVICE:${PN} = "tedge-bootstrap.service"