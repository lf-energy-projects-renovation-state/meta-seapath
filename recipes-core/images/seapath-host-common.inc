# Copyright (C) 2022, RTE (http://www.rte-france.com)
# Copyright (C) 2024 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

DESCRIPTION = "A production image for Seapath"
require seapath-common.inc
require ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-clustering', 'seapath-host-common-ha.inc', '', d)}

inherit ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-security', 'security/qa-host-images', '', d)}

# Hypervisor and cluster tests
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-clustering', 'cukinia-tests-cluster', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-clustering', \
            bb.utils.contains('DISTRO_FEATURES', 'seapath-security', \
                    'cukinia-tests-cluster-security', '', d), '', d)} \
    cukinia-tests-hypervisor \
    ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-security', 'cukinia-tests-hypervisor-security', '', d)} \
    syslog-ng-client \
    system-config-host \
    ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-clustering', 'system-config-cluster', '', d)} \
    system-config-ovs \
    ${@bb.utils.contains('DISTRO_FEATURES', 'seapath-security', 'system-config-security', '', d)} \
    system-upgrade \
    net-snmp-server \
    net-snmp-client \
    python3-vm-manager \
    python3-setup-ovs \
    tuna \
    irqbalance \
    chrony \
    chronyc \
"

# Docker
IMAGE_INSTALL += " docker-moby docker-moby-contrib docker-compose"

# Host images are compatible with seapath-hypervisor only
# GRUB static configuration for host machines
# depends on seapath-hypervisor
COMPATIBLE_MACHINE = "seapath-hypervisor"

def get_seapath_kernel_parameters(d):
    kernel_parameters = ""
    rt_cores = d.getVar("SEAPATH_RT_CORES", "")
    disable_ipv6 = d.getVar("SEAPATH_DISABLE_IPV6", "")
    if rt_cores:
        kernel_parameters +="isolcpus={} nohz_full={} rcu_nocbs={}".format(
            rt_cores,
            rt_cores,
            rt_cores)
        kernel_parameters += " rcu_nocb_poll nohz=on kvm_intel.ple_gap=0 kvm_intel.ple_window=0"
    if disable_ipv6 == "true":
        kernel_parameters += " ipv6.disable=1"
    return kernel_parameters


APPEND += "${@get_seapath_kernel_parameters(d)}"

require ${@bb.utils.contains('DISTRO_FEATURES', 'kvm', 'seapath-host-common-virtu.inc', '', d)}
