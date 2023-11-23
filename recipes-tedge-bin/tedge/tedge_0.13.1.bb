# Architecture variables
ARCH_REPO_CHANNEL = "release"
ARCH_VERSION = "0.13.1"
SRC_URI[aarch64.md5sum] = "7083a1451a059603d249d66e12c53336"
SRC_URI[armv6.md5sum] = "a56a484374024f6545de2fd8bb4f2522"
SRC_URI[armv7.md5sum] = "bd1f4f3568a38a1e3486dae045b88bd2"
SRC_URI[x86_64.md5sum] = "c3fe70d90c7f2a7c77bb1f7369284d2b"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.2.2"
SRC_URI[openrc.md5sum] = "7e8fdc361a868bc5602249879040e156"
SRC_URI[systemd.md5sum] = "fd78bc692b823b56b660f528459d71d9"
SRC_URI[sysvinit.md5sum] = "161568da4b2ff0dbbff4aa24f7e3fca2"

require tedge.inc
