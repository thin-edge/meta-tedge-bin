# Architecture variables
ARCH_REPO_CHANNEL = "dev"
ARCH_VERSION = "0.12.1-rc691+g4b556be"
SRC_URI[aarch64.md5sum] = "af18ca4e562abb7f2371dc6ccc3a2b7e"
SRC_URI[armv6.md5sum] = "02686ecc5a78f5be590b42372d1cd652"
SRC_URI[armv7.md5sum] = "5106bfb8b3a7bd2bdaabdfc89f5d050d"
SRC_URI[x86_64.md5sum] = "1ae984777e2a3f268a8626d0f04cd465"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.2.2"
SRC_URI[openrc.md5sum] = "7e8fdc361a868bc5602249879040e156"
SRC_URI[systemd.md5sum] = "fd78bc692b823b56b660f528459d71d9"
SRC_URI[sysvinit.md5sum] = "161568da4b2ff0dbbff4aa24f7e3fca2"

require tedge.inc
