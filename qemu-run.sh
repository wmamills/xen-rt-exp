#!/bin/bash

MY_DIR=$PWD

QEMU_BASE="-machine type=virt \
           -cpu cortex-a57 \
           -smp 8 \
           -accel tcg \
           -device virtio-net-pci,netdev=unet \
           -netdev user,id=unet,hostfwd=tcp::2222-:22 \
           -serial stdio \
           -monitor tcp::2220,server=on,wait=off \
           -gdb tcp::2221,server=on,wait=off \
           -pidfile qemu-run.pid \
           -m 8192 \
           -nographic"

# U-boot can't handle virtio-scsi ATM so use virtio-blk (and /dev/vda)
# but for now leave the choice to the specific case
: \
           -device virtio-scsi-pci \
           -device scsi-hd,drive=hd \

qemu-via-docker() {
    docker run -it --rm -v${HOME}:${HOME} \
        -w ${PWD} -u ${UID}:$(id -g) -e HOME=${HOME} \
        registry.gitlab.com/linaro/blueprints/qemu-swtpm \
        /usr/local/bin/qemu-system-aarch64-swtpm "$@"
}

case $1 in

"kill")
    if [ -r qemu-run.pid ]; then
        kill -3 $(cat qemu-run.pid)
    fi
    exit 0
    ;;

""|"u-boot")
    # can't handle gicv3
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=on,gic_version=2 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -bios ${MY_DIR}/qemu-firmware/arm64-tfa-optee-uboot.bin
    ;;

"edk2")
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=off,gic_version=3 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
    ;;

"trs")
    # can't handle gicv3
    IMAGE_NAME=trs-image-trs-qemuarm64.rootfs
    FLASH_NAME=flash.bin-qemu
    #rm -rf trs/${IMAGE_NAME}.wic
    if [ ! -r trs/$IMAGE_NAME.wic ]; then
        echo "Decompressing rootfs image $IMAGE_NAME"
        bzip2 -k -d trs/${IMAGE_NAME}.wic.bz2
    fi
    if [ ! -r trs/$FLASH_NAME.bin ]; then
        zcat trs/$FLASH_NAME.gz >trs/$FLASH_NAME.bin
    fi
    echo "Starting QEMU"
    ./qemu-system-aarch64-swtpm $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=on,gic_version=2 \
        -drive id=disk1,file=${MY_DIR}/trs/trs-image-trs-qemuarm64.rootfs.wic,if=none,format=raw \
        -device virtio-blk-device,drive=disk1 \
        -drive if=pflash,unit=0,readonly=off,file=${MY_DIR}/trs/$FLASH_NAME.bin,format=raw \
        -m 3072 \
        -device i6300esb,id=watchdog0
    ;;

"direct"|"linux"|"linux-direct")
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,gic_version=3 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -kernel ${MY_DIR}/direct-boot/Image \
        -initrd ${MY_DIR}/direct-boot/initrd.img \
        -append "console=ttyAMA0 root=/dev/vda2"
    ;;

"xen-direct"|"xen")
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,gic_version=3 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -kernel ${MY_DIR}/direct-boot/xen \
        -append "dom0_mem=4G,max:4G dom0_max_vcpus=4 dom0_vcpus_pin=true sched=null vwfi=native loglvl=all guest_loglvl=all" \
        -device guest-loader,\
addr=0x49000000,kernel=${MY_DIR}/direct-boot/Image,\
bootargs="console=hvc0 earlyprintk=xen root=/dev/vda2" \
        -device guest-loader,\
addr=0x50000000,initrd=${MY_DIR}/direct-boot/initrd.img
    ;;

*)
    echo "unknown option $1"
    exit 0
    ;;

esac

if [ $? -gt 100 ]; then
    reset
    echo "terminal reset due to error exit"
fi
