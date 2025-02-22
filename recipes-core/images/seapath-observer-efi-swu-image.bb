
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# SPDX-License-Identifier: Apache-2.0

DESCRIPTION = "SWUpdate upgrade observer image for SEAPATH"
LICENSE = "Apache-2.0"
FILESEXTRAPATHS:prepend := "${THISDIR}/files/observer:"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit swupdate

SRC_URI = "\
    file://sw-description \
    file://swupdate_install.sh \
"

# Images to build before building SWUpdate image
IMAGE_DEPENDS = "seapath-observer-efi-image"

# Images and files that will be included in the .swu image
SWUPDATE_IMAGES = "seapath-observer-efi-image seapath-observer-efi-image-boot"

SWUPDATE_IMAGES_FSTYPES[seapath-observer-efi-image] = ".rootfs.tar.xz"
SWUPDATE_IMAGES_FSTYPES[seapath-observer-efi-image-boot] = ".tar.xz"
