# Architecture variables
ARCH_REPO_CHANNEL = "main"
ARCH_VERSION = "0.13.2-rc239+ga9f66cd"
SRC_URI[aarch64.md5sum] = "2b7244190b5728ee7bfb3298a395166b"
SRC_URI[armv6.md5sum] = "030f26fc78351daf89bd41c3700b54a1"
SRC_URI[armv7.md5sum] = "944b6686e505342c11e72ad553fb2caa"
SRC_URI[x86_64.md5sum] = "cb3a389d3148df5379fc7a788863a8a2"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.2.2"
SRC_URI[openrc.md5sum] = "7e8fdc361a868bc5602249879040e156"
SRC_URI[systemd.md5sum] = "fd78bc692b823b56b660f528459d71d9"
SRC_URI[sysvinit.md5sum] = "161568da4b2ff0dbbff4aa24f7e3fca2"

require tedge.inc
