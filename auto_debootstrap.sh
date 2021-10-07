#!/bin/bash
# Based on a test script from avsm/ocaml repo https://github.com/avsm/ocaml

CHROOT_DIR=$HOME/arm-chroot
MIRROR=http://ports.ubuntu.com/ubuntu-ports
# MIRROR=http://ru.archive.ubuntu.com/ubuntu
VERSION=focal
CHROOT_ARCH=armhf

# Debian package dependencies for the host
HOST_DEPENDENCIES="debootstrap qemu-user-static binfmt-support sbuild"

# Debian package dependencies for the chrooted environment
GUEST_DEPENDENCIES="build-essential git m4 sudo"

# Command used to run the tests
TEST_COMMAND="make test"

function setup_arm_chroot {
    # Host dependencies
    sudo apt-get install -qq -y ${HOST_DEPENDENCIES}

    # Create chrooted environment
    sudo mkdir ${CHROOT_DIR}
    sudo debootstrap --foreign --no-check-gpg --include=fakeroot,build-essential \
        --arch=${CHROOT_ARCH} ${VERSION} ${CHROOT_DIR} ${MIRROR}
    # sudo cp /usr/bin/qemu-arm-static ${CHROOT_DIR}/usr/bin/
    sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
    sudo sbuild-createchroot --arch=${CHROOT_ARCH} --foreign --setup-only \
        ${VERSION} ${CHROOT_DIR} ${MIRROR}

    # Install dependencies inside chroot
    sudo chroot ${CHROOT_DIR} apt-get update
    sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install \
        -qq -y ${GUEST_DEPENDENCIES}

    sudo mount proc -t proc ${CHROOT_DIR}/proc
    sudo mount sys -t sysfs ${CHROOT_DIR}/sys
    sudo mount --bind /dev ${CHROOT_DIR}/dev
    sudo mount --bind /dev/pts ${CHROOT_DIR}/dev/pts

    sudo chroot ${CHROOT_DIR} /usr/bin/env -i HOME=/root TERM="$TERM" /bin/bash --login
}

setup_arm_chroot
