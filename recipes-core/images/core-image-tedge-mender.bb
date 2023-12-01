require core-image-tedge.bb

IMAGE_INSTALL:append = " \
    tedge-state-scripts \
    tedge-firmware \
    ${@bb.utils.contains('INIT_MANAGER','systemd','tedge-bootstrap','',d)} \
"