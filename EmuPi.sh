#!/usr/bin/env sh
#
# Description: $ This script is to make raspi emulation even eaiser.
#
# Authors: cyng93
#
# Contact: cyng93@gmail.com
#
# Date: $Date: 2017/11/08 22:00:00 $
# Version: $Revision: 1.0 $
#
# History:
#
# $Log: EmuPi.sh,v $
# Revision 1.0  2017/11/08  22:00:00  cyng93
# Support mode `raspi2` & `versatilepb`


# ---------- SOURCE , INCLUDE
comm_func=$(cat "/tmp/.CommonFunc.sh" > /dev/null 2>&1)
if [ ! "$comm_func" ]; then
    url="https://raw.githubusercontent.com/cyng93/scripts/master/CommonFunc.sh"
    curl -s $url > /tmp/.CommonFunc.sh && true \
        || { echo "[ERROR] Fail to download CommonFunc. Aborting."; exit 1; }
fi
. /tmp/.CommonFunc.sh


# ---------- DEFAULT ARGS
MODE="versatilepb"
LOG_LEVEL=10    # INFO
RES_DIR=res
MNT_DIR=mnt
TARGET_IMG=""   # TARGET_IMG default value are decide after args parsing
KERNEL_IMG=""   # KERNEL_IMG default value are decide after args parsing


# ----------- FUNCTIONS

#
# MountImage ( _img, _mnt_dir )
#   Create loop device for `_img` if such loop device not yet present,
#   then mount second partition of loop_device on `_mnt_dir`
#
MountImage()
{
    local _img
    local _mnt_dir
    local _loop_device

    # Checking
    [ "$1" ] && _img=$1     || MissingArg "MountImage:$LINENO" "_img"
    [ "$2" ] && _mnt_dir=$2 || MissingArg "MountImage:$LINENO" "_mnt_dir"

    CheckFileExist "$_img" && true \
        || PrintMsg "MountImage:$LINENO - Couldn't locate \`$_img\`" "E"
    CheckDirExist "$_mnt_dir" && true \
        || PrintMsg "MountImage:$LINENO - Couldn't locate \`$_mnt_dir\`" "E"


    # 1. Create loop device for image if not loop device not yet present
    # TODO - there might be bugs if x.img-xyz present and mounted as loop dev
    _loop_device=$(sudo losetup --list | grep $_img | awk '{print $1}')

    if [ "" = "$_loop_device" ]; then
        _loop_device=$(sudo losetup -f --show -P $_img)
        [ "$_loop_device" ] \
            && PrintMsg "Created loop device \`$_loop_device\` for \`$_img\`" \
            || PrintMsg "MountImage:$LINENO Fail to create loop device" "E"
    fi


    # 2. Mount loop device to _mnt_dir
    #   2-1. try unmount _mnt_dir if it's mounted
    sudo umount $_mnt_dir > /dev/null 2>&1 \
        && PrintMsg "Unmount \`$_mnt_dir\`" "D" \
        || true
    #   2-2. mount it
    PrintMsg "_loop_device: $_loop_device" "D"
    sudo mount "$_loop_device"p2 $_mnt_dir > /dev/null 2>&1 \
        && PrintMsg "Mounted ${_loop_device}p2 to $_mnt_dir" "D" \
        || PrintMsg "MountImage:$LINENO Fail to mount loop device" "E"

}


#
# UmountImage ( $_dir )
#
UmountImage()
{
    local _dir
    [ "$1" ] && _dir=$1 || MissingArg "UnmountImage:$LINENO" "_dir"

    # workaround with targeted device busy when trying to unmount
    sync && sleep 2 && sudo umount $_dir > /dev/null 2>&1 \
        && PrintMsg "$_dir unmounted!" "D" \
        || PrintMsg "UnmountImage:$LINENO - Fail to unmount $_mnt_dir" "E"
}


#
# SetupEnv ( _mode, _img=$TARGET_IMG, _res_dir=$RES_DIR, _mnt_dir=$MNT_DIR )
#
#   To support different board, changes are needed to be made to several files:
#       1. /etc/ld.so.conf
#       2. /etc/fstab
#
#   Our idea is to prepare those files and set them up in proper place before
#   we start the emulation.
#
SetupEnv()
{
    local _mode
    local _img
    local _res_dir
    local _mnt_dir

    [ "$1" ] && _mode=$1    || MissingArg "SetupEnv:$LINENO" "_mode"
    [ "$2" ] && _img=$2     || _img=$TARGET_IMG
    [ "$3" ] && _res_dir=$3 || _res_dir=$RES_DIR
    [ "$4" ] && _mnt_dir=$4 || _mnt_dir=$MNT_DIR

    CheckFileExist "$_img" && true \
        || PrintMsg "SetupEnv:$LINENO - Couldn't locate $_img" "E"
    CheckDirExist "$_res_dir" && true \
        || PrintMsg "SetupEnv:$LINENO - Couldn't locate $_res_dir" "E"
    CheckDirExist "$_mnt_dir" && true \
        || PrintMsg "SetupEnv:$LINENO - Couldn't locate $_mnt_dir" "E"

    MountImage "$_img" "$_mnt_dir"

    sudo cp $_res_dir/ld.so.preload-$_mode $_mnt_dir/etc/ld.so.preload \
        && PrintMsg "$_mode's ld.so.preload copied" "D" \
        || PrintMsg "SetupEnv:$LINENO - Fail to copy ld.so.preload" "E"
    sudo cp $_res_dir/fstab-$_mode $_mnt_dir/etc/fstab \
        && PrintMsg "$_mode's fstab copied" "D" \
        || PrintMsg "SetupEnv:$LINENO - Fail to copy fstab" "E"
    sudo cp $_res_dir/dhcpcd.conf-$_mode $_mnt_dir/etc/dhcpcd.conf \
        && PrintMsg "$_mode's dhcpcd.conf copied" "D" \
        || PrintMsg "SetupEnv:$LINENO - Fail to copy dhcpcd.conf" "E"

    UmountImage "$_mnt_dir"
}


#
# StartVersatilepb ( _img, _kernel, _res_dir )
#
#   Start Emulation as versatilepb board, using:
#       - `_img`    as the hard drive,
#       - `_kernel` as the kernel
#
#   where needed resources file like /etc/fstab... can be found in `_res_dir`
#
StartVersatilepb()
{
    local _img
    local _kernel
    local _res_dir

    # 0. Checking
    [ "$1" ] && _img=$1     || MissingArg "StartVersatilepb:$LINENO" "_img"
    [ "$2" ] && _kernel=$2  || MissingArg "StartVersatilepb:$LINENO" "_kernel"
    [ "$3" ] && _res_dir=$3 || MissingArg "StartVersatilepb:$LINENO" "_res_dir"

    CheckFileExist "$_img" && true \
        || PrintMsg "StartVersatilepb:$LINENO - Couldn't locate $_img" "E"
    CheckFileExist "$_kernel" && true \
        || PrintMsg "StartVersatilepb:$LINENO - Couldn't locate $_kernel" "E"
    CheckDirExist "$_res_dir" && true \
        || PrintMsg "StartVersatilepb:$LINENO - Couldn't locate $_res_dir" "E"

    # 1. Setup Env
    SetupEnv "versatilepb" "$_img" "$_res_dir"

    sudo qemu-system-arm \
        -kernel $_kernel \
        -cpu arm1176 \
        -m 256 \
        -M versatilepb \
        -no-reboot \
        -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
        -hda $_img \
        -net nic -net user,hostfwd=tcp::22-:22 \
        -nographic \
        &
        # -net nic,vlan=0 \
        # -net tap,vlan=0,ifname=tap0,script=no,downscript=no \
}


#
# StartRaspi2 ( _img, _kernel, _res_dir )
#
#   Start Emulation as raspi2 board, using:
#       - `_img`    as the hard drive,
#       - `_kernel` as the kernel
#
#   where needed resources file like /etc/fstab... can be found in `_res_dir`
#
StartRaspi2()
{
    local _img
    local _kernel
    local _res_dir

    # 0. Checking
    [ "$1" ] && _img=$1     || MissingArg "StartRaspi2:$LINENO" "_img"
    [ "$2" ] && _kernel=$2  || MissingArg "StartRaspi2:$LINENO" "_kernel"
    [ "$3" ] && _res_dir=$3 || MissingArg "StartRaspi2:$LINENO" "_res_dir"

    CheckFileExist "$_img" && true \
        || PrintMsg "StartRaspi2:$LINENO - Couldn't locate $_img" "E"
    CheckFileExist "$_kernel" && true \
        || PrintMsg "StartRaspi2:$LINENO - Couldn't locate $_kernel" "E"
    CheckDirExist "$_res_dir" && true \
        || PrintMsg "StartRaspi2:$LINENO - Couldn't locate $_res_dir" "E"

    # 1. Setup Env
    SetupEnv "raspi2" "$_img" "$_res_dir"

    sudo qemu-system-arm \
        -kernel $_kernel \
        -cpu arm1176 \
        -smp 4 \
        -m 1G \
        -M raspi2 \
        -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2" \
        -dtb $_res_dir/bcm2709-rpi-2-b.dtb \
        -sd $_img \
        -nographic \
        ;
}



# ---------- GENERAL FUNCTINO

#
# Usage ( [_exit_val], [_caller] )
#
#   Print usage, abort program with exit value = `_exit_val` if `_exit_val`
#   was provided.
#   When `_exit_val` is being provide, one can pass in `_caller` to let himself
#   has clue where the heck is calling this Usage, to make debugging easier.
#
Usage()
{
    local _prog=$(basename $0)
    local _exit_val
    local _caller   # For debug purpose

    [ "$1" ] && _exit_val=$1
    [ "$2" ] && _caller=$2

    echo "Usage: $_prog [option]..."
    echo "option:"
    echo "  --image <image=$TARGET_IMG>"
    echo "  --mode <raspi2|versatilepb>"
    echo "      raspi2      : emulate machine type raspi2"
    echo "      versatilepb : emulate machine type versatilepb  (default)"
    echo "  --kernel <kernel_img=$KERNEL_IMG>"
    echo "  --res <resource_dir=$RES_DIR>"
    echo "  --log-level <log_level>"
    echo "      0 : ERROR"
    echo "      5 : WARNING"
    echo "      10: INFO (default)"
    echo "      15: DEBUG"

    PrintMsg "$_caller call Usage()" "D"
    [ $_exit_val ] && exit $_exit_val || true
}


#
# CheckParams ( $@ )
#
#   CheckParams would require user to pass in all arguments ($@)
#   It then parsed and change the default value of variable defined in top
#   of the script.
#
CheckParams()
{
    while [ "$1" != "" ]; do
        case $1 in
        -h | --help)
            Usage 0 "CheckParams:$LINENO"
            ;;
        --image)
            [ "$2" = "" ] && Usage 1 "CheckParams:$LINENO" || TARGET_IMG=$2
            shift
            ;;
        --kernel)
            [ "$2" = "" ] && Usage 1 "CheckParams:$LINENO" || KERNEL_IMG=$2
            shift
            ;;
        --log-level)
            [ "$2" = "" ] && Usage 1 "CheckParams:$LINENO" || LOG_LEVEL=$2
            shift
            ;;
        --mode)
            [ "$2" = "" ] && Usage 1 "CheckParams:$LINENO" || MODE=$2
            shift
            ;;
        --res)
            [ "$2" = "" ] && Usage 1 "CheckParams:$LINENO" || RES_DIR=$2
            shift
            ;;
        -v | --version)
            grep "\$Revision" $0 | head -1 | awk '{print "version", $4}'
            exit 0
            ;;
        *)
            TARGET_IMG=$RES_DIR/raspi2.img
            KERNEL_IMG=$RES_DIR/kernel7-$MODE.img
            Usage 1 "CheckParams:$LINENO"
        esac
        shift
    done

    # Default below might be affect by RES_DIR, so are decide after args parse
    [ "" = "$TARGET_IMG" ] && TARGET_IMG=$RES_DIR/raspi2.img || true
    [ "" = "$KERNEL_IMG" ] && KERNEL_IMG=$RES_DIR/kernel7-$MODE.img || true
}


# ---------- ENTRY POINT
CheckParams $@

case $MODE in
    "raspi2" | "raspi" | "pi" )
        StartRaspi2 \
            "$TARGET_IMG" "$KERNEL_IMG" "$RES_DIR"
        ;;
    "versatilepb" | "ver" )
        StartVersatilepb \
            "$TARGET_IMG" "$RES_DIR/kernel7-versatilepb.img" "$RES_DIR"
        ;;
    *)
        PrintMsg "Invalid mode" "E"
        ;;
esac
