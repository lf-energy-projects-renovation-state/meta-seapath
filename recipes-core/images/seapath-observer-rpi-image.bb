# Copyright (C) 2024 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

DESCRIPTION = "An observer image for Raspberry Pi on Seapath cluster"
require seapath-common.inc
require seapath-observer-common.inc
require seapath-host-common-ha.inc

IMAGE_INSTALL:append = " syslog-ng-server"
COMPATIBLE_MACHINE = "seapath-observer-rpi"

IMAGE_FSTYPES = "wic.bz2 wic.bmap"
WKS_FILE = "sdimage-raspberrypi.wks.in"
