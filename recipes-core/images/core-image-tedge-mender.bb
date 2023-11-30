require core-image-tedge.bb

IMAGE_INSTALL:append = " \
    tedge-state-scripts \
    ${@bb.utils.contains('INIT_MANAGER','systemd','tedge-bootstrap','',d)} \
"