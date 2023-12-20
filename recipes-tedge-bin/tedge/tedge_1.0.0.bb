# Architecture variables
ARCH_REPO_CHANNEL = "release"
ARCH_VERSION = "1.0.0-rc.1"
SRC_URI[aarch64.md5sum] = "7dc35d241045e5445e2cb5a0a6ff6aaa"
SRC_URI[armv6.md5sum] = "255deb0e2ec5fd87c80b9b2b89ef2ea6"
SRC_URI[armv7.md5sum] = "a2549438177c4ec7ac61c0a2a48c02d7"
SRC_URI[x86_64.md5sum] = "d4e12eb0e90815cb435bfeeeb82f2b71"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.3.0"
SRC_URI[openrc.md5sum] = "b47d51788d5cf0d83a7f138fb2cf037c"
SRC_URI[systemd.md5sum] = "c815f7666216ef5cb3d78be50eddc073"
SRC_URI[sysvinit.md5sum] = "7286a80f0d6b42cf5a0681f951f0e318"

require tedge.inc
