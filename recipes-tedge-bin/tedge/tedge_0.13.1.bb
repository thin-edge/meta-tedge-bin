# Architecture variables
ARCH_REPO_CHANNEL = "release"
ARCH_VERSION = "0.13.1"
SRC_URI[aarch64.md5sum] = "7083a1451a059603d249d66e12c53336"
SRC_URI[armv6.md5sum] = "a56a484374024f6545de2fd8bb4f2522"
SRC_URI[armv7.md5sum] = "bd1f4f3568a38a1e3486dae045b88bd2"
SRC_URI[x86_64.md5sum] = "c3fe70d90c7f2a7c77bb1f7369284d2b"

# Init manager variables
INIT_REPO_CHANNEL = "community"
INIT_VERSION = "0.2.0"
SRC_URI[openrc.md5sum] = "de20be9ff99a8c816f710049e0aa4d6f"
SRC_URI[systemd.md5sum] = "807b2e779bb288e2bbe2dfa1a7b029fc"
SRC_URI[sysvinit.md5sum] = "f23ca3cb9582184bfd569f0f3034ef0f"

require tedge.inc