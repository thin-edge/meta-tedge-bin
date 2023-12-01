# Architecture variables
ARCH_REPO_CHANNEL = "main"
ARCH_VERSION = "0.13.2-rc118+g8457fa6"
SRC_URI[aarch64.md5sum] = "d46ef8e2521cfd66e2c3d3aabc76b2de"
SRC_URI[armv6.md5sum] = "7c37f84c989db0207ecdfcc8ab74d258"
SRC_URI[armv7.md5sum] = "219b4977fdfa9e9cbeef23080580b636"
SRC_URI[x86_64.md5sum] = "ac93c8fd77ab27f1e954412487ef5814"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.2.2"
SRC_URI[openrc.md5sum] = "7e8fdc361a868bc5602249879040e156"
SRC_URI[systemd.md5sum] = "fd78bc692b823b56b660f528459d71d9"
SRC_URI[sysvinit.md5sum] = "161568da4b2ff0dbbff4aa24f7e3fca2"

require tedge.inc
