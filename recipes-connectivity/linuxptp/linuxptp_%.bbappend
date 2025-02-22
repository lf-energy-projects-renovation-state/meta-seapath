# Copyright (C) 2020, RTE (http://www.rte-france.com)
# SPDX-License-Identifier: Apache-2.0

FILESEXTRAPATHS:prepend :="${THISDIR}/files:"

inherit systemd

SYSTEMD_AUTO_ENABLE = "disable"

SYSTEMD_SERVICE:${PN} = "ptp4l@.service phc2sys@.service timemaster.service"

SRC_URI:append = " \
    file://ptp4l@.service \
    file://phc2sys@.service \
    file://timemaster.service \
"
do_install:append() {
  install -d ${D}${systemd_system_unitdir}
  install -m 0644 ${WORKDIR}/ptp4l@.service ${D}${systemd_system_unitdir}/
  install -m 0644 ${WORKDIR}/phc2sys@.service ${D}${systemd_system_unitdir}/
  install -m 0644 ${WORKDIR}/timemaster.service ${D}${systemd_system_unitdir}/
  install -d ${D}/etc/linuxptp
}

FILES:${PN} += "${systemd_system_unitdir}/ptp4l@.service"
FILES:${PN} += "${systemd_system_unitdir}/phc2sys@.service"
FILES:${PN} += "${systemd_system_unitdir}/timemaster.service"
