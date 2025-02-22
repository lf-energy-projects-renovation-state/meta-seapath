# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2023 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

#
# Handle users creation
#
require users-config.inc
inherit extrausers

SUDO_BIN ?="${IMAGE_ROOTFS}/usr/bin/sudo"
SUDOERS_DIR ?="${IMAGE_ROOTFS}/etc/sudoers.d"
USERS_LIST ?= ""
USERS_LIST_DISABLEMAXDAYS ?= ""
USERS_LIST_EXPIRED ?= ""
USERS_LIST_LOCKED ?= ""
USERS_LIST_REMOVED ?= ""
USERS_LIST_SUDOERS ?= ""
USER_GROUP_LIST ?= ""
GROUPS_LIST ?= ""
GROUPS_LIST_SUDOERS ?= ""
GROUPS_LIST_NOPASSWD ?= ""
GROUPS_LIST_EXEC ?= ""
SUDO_GROUP_OWNER ?= ""

IMAGE_INSTALL:append = " sudo"

python do_configure_users() {
    import crypt
    def encrypt_user_password(user):
        return crypt.crypt(user, crypt.mksalt(crypt.METHOD_SHA512)).replace("$","\$")

    userslist = d.getVar("USERS_LIST").split()
    userslistdisablemaxdays = d.getVar("USERS_LIST_DISABLEMAXDAYS").split()
    userslistexpired = d.getVar("USERS_LIST_EXPIRED").split()
    userslistlocked = d.getVar("USERS_LIST_LOCKED").split()
    userslistremoved = d.getVar("USERS_LIST_REMOVED").split()
    userslistsudoers = d.getVar("USERS_LIST_SUDOERS").split()

    sudoersdir = d.getVar("SUDOERS_DIR")

    extrausersparams = ""
    if not userslist:
        bb.warn("USERS_LIST empty, not creating any users")
        return
    # add users defined in USERS_LIST
    for user in userslist:
        useradd_options = "-p '{}'".format(encrypt_user_password(user))
        if user in userslistdisablemaxdays:
            useradd_options += " -K PASS_MAX_DAYS=-1"

        extrausersparams += " useradd {} {} ;".format(
           useradd_options, user)

    # set expiration for users in USERS_LIST_EXPIRED
    for user in userslistexpired:
        if user not in userslist:
            bb.warn("Can not set expiration for user %s (not in USERS_LIST)"
                %(user))
            continue

        extrausersparams += "usermod -e -1 "+user+";"

    # add in sudoers for users in USERS_LIST_SUDOERS
    for user in userslistsudoers:
        if user not in userslist:
            bb.warn("Can not add sudoers for user %s (not in USERS_LIST)"
                %(user))
            continue

        with open(os.path.join(sudoersdir, user), "w") as f:
            f.write(user+"  ALL=(ALL) ALL")
            os.chmod(f.name, 0o440)

    # remove users from USERS_LIST_REMOVED
    for user in userslistremoved:
        extrausersparams += " userdel "+user+";"

    # lock users from USERS_LIST_LOCKED
    for user in userslistlocked:
        extrausersparams += " usermod -L "+user+";"

    ret = configure_groups(d, userslist, extrausersparams)
    if ret:
        extrausersparams += ret

    if extrausersparams:
        d.setVar("EXTRA_USERS_PARAMS", extrausersparams)
}

def configure_groups(d, userslist, extrausersparams):
    groupslist = d.getVar("GROUPS_LIST").split()
    groupslistsudoers = d.getVar("GROUPS_LIST_SUDOERS").split()
    sudoersdir = d.getVar("SUDOERS_DIR")
    usergrouplist = d.getVarFlags("USER_GROUP_LIST")
    groupslistnopasswd = d.getVar("GROUPS_LIST_NOPASSWD").split()
    groupslistexec = d.getVar("GROUPS_LIST_EXEC").split()
    ret = ""

    for g in groupslist:
        bb.note("adding group %s" %(g))
        ret += " groupadd "+g+";"

    # add in sudoers for groups in GROUP_LIST_SUDOERS
    for group in groupslistsudoers:
        if group not in groupslist:
            bb.warn("Can not add sudoers for group %s (not in GROUP_LIST)"
                %(group))
            continue

        with open(os.path.join(sudoersdir, group), "w") as f:
            tags = ""
            if group in groupslistnopasswd:
                tags += "NOPASSWD:"
            if group in groupslistexec:
                tags += "EXEC:"
            f.write("%"+group+"  ALL=(ALL) "+tags+" ALL")
            os.chmod(f.name, 0o440)

    for g in usergrouplist:
        bb.note("adding group for %s" %(g))
        if g not in userslist:
            bb.fatal("%s is not defined in USERS_LIST" %(g))

        for group in usergrouplist[g].split():
            ret += " usermod -a -G "+group+" "+g+";"
            bb.note("adding group %s for %s" %(group, g))
    return ret

contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"; then
        return 0
    else
        return 1
    fi
}

do_configure_policy () {
    # install policies for sudo
    for GROUP in ${GROUP_POLICIES_SUDO}; do
        contains " ${GROUPS_LIST} " " ${GROUP} " || \
            bbfatal "Group ${GROUP} is not defined in GROUPS_LIST"
        test -f ${SEC_ARTIFACTS_DIR}/sudoers.d/${GROUP} || \
            bbfatal "Missing ${POLICY} policy for ${GROUP}"
        install -d -m 0755 ${IMAGE_ROOTFS}/etc/sudoers.d/
        install -m 440 ${SEC_ARTIFACTS_DIR}/sudoers.d/${GROUP} \
            ${IMAGE_ROOTFS}/etc/sudoers.d
    done
}

do_configure_sudo() {
    $PSEUDO chown "root:${SUDO_GROUP_OWNER}" ${SUDO_BIN}
    $PSEUDO chmod 4750 ${SUDO_BIN}
}

# do_add_users must be called very early following rootfs generation
# so that extrausers.bbclass can use EXTRA_USERS_PARAMS variable
python modify_rootfs_postprocess () {
    e.data.prependVar('ROOTFS_POSTPROCESS_COMMAND', ' do_configure_users;')
    e.data.appendVar('ROOTFS_POSTPROCESS_COMMAND', ' do_configure_sudo;')
    e.data.appendVar('ROOTFS_POSTPROCESS_COMMAND', ' do_configure_policy;')
}
addhandler modify_rootfs_postprocess
modify_rootfs_postprocess[eventmask] = "bb.event.RecipePreFinalise"
