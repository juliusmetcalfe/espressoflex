#!/bin/bash
# This file is sourced from the top level build script

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

export TOPDIR=$(pwd)

build_buildroot () {
    (
        cd $BUILDROOT_DIR
        cp ../br_espressoconfig .config
        make
    )
}

build_uboot () {
    (
        cd $UBOOT_DIR
        make mvebu_espressobin-88f3720_defconfig
        cp ../uboot_espressoconfig .config
        make -j$(nproc) DEVICE_TREE=armada-3720-espressobin
        if [ ! -f u-boot.bin ]; then
            echo "Building u-boot failed"
            exit;
        fi 
    )
    export BL33=$UBOOT_DIR/u-boot.bin
}

build_linux () {
    (
        export ARCH=arm64
        export CROSS_COMPILE=aarch64-linux-gnu-
        cd $LINUX_DIR
        make defconfig
        cp ../linux_espressoconfig .config
        make -j$(nproc) Image dtbs modules
        if [ -d rootfs ]; then
            rm -rf rootfs;
        fi
        mkdir $TOPDIR/rootfs
        make modules_install INSTALL_MOD_PATH=$TOPDIR/rootfs/
    )
}


if [ ! -d ./buildroot ]; then
    echo "Pulling Buildroot-2018.02.x..."
    (
        git clone git://git.busybox.net/buildroot -b 2018.02.x buildroot --depth=1
    )
fi
BUILDROOT_DIR=$(pwd)/buildroot


if [ ! -d ./linux ]; then
    echo "Pulling Linux-4.19.y..."
    (
        git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-4.19.y --depth=1 linux
        cd linux
        git am ../espressopatches/linux/*.patch
    )
fi
LINUX_DIR=$(pwd)/linux


if [ ! -d ./u-boot ]; then
    echo "Pulling U-Boot..."
    (
        git clone git@github.com:MarvellEmbeddedProcessors/u-boot-marvell.git --depth=1 -b u-boot-2017.03-armada-17.10 u-boot
        cd u-boot
        git am ../espressopatches/u-boot/*.patch
    )
fi
UBOOT_DIR=$(pwd)/u-boot

if [ ! -d ./atf ]; then
    echo "Pulling atf..."
    (
        git clone https://github.com/MarvellEmbeddedProcessors/atf-marvell.git atf
    )
fi
ATF_DIR=$(pwd)/atf

if [ ! -d ./A3700-utils ]; then
    echo "Pulling A3700-utils..."
    (
        git clone https://github.com/MarvellEmbeddedProcessors/A3700-utils-marvell.git A3700-utils
    )
fi
A3700UTILS_DIR=$(pwd)/A3700-utils
export BUILDROOT_DIR

build_buildroot;
build_linux;
build_uboot;
build_buildroot;

BUILD_IMAGEDIR=$TOPDIR/images
if [ ! -d $BUILD_IMAGEDIR ]; then
    mkdir $BUILD_IMAGEDIR;
fi

(
	cd $BUILDROOT_DIR/output/images
	# Create a single FIT image from the sources to allow for netbooting
	cp $TOPDIR/espressofit.its .
    cp $LINUX_DIR/arch/$ARCH/boot/Image .
    cp $LINUX_DIR/arch/$ARCH/boot/dts/marvell/armada-3720-espressobin.dtb .
	mkimage -f espressofit.its a3720-linux.ub
	cp a3720-linux.ub $BUILD_IMAGEDIR/
)

ls -l $BUILD_IMAGEDIR 1>&2
