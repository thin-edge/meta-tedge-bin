# Architecture variables
ARCH_REPO_CHANNEL = "main"
ARCH_VERSION = "0.13.2-rc177+gb4974b9"
SRC_URI[aarch64.md5sum] = "beb555359e8923208912665e6ad3a9ad"
SRC_URI[armv6.md5sum] = "8a64348db1509a5ffa671509417509d9"
SRC_URI[armv7.md5sum] = "54d3ae57e52dea5d4392ae8c71a6d5f0"
SRC_URI[x86_64.md5sum] = "59bd15d5856274f96430ab3308f8bd36"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.2.2"
SRC_URI[openrc.md5sum] = "7e8fdc361a868bc5602249879040e156"
SRC_URI[systemd.md5sum] = "fd78bc692b823b56b660f528459d71d9"
SRC_URI[sysvinit.md5sum] = "161568da4b2ff0dbbff4aa24f7e3fca2"

require tedge.inc
