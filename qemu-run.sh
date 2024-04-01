#!/bin/bash

MY_DIR=$PWD

# short cut names for some common things
G=$MY_DIR/generated
HD=debian-12-arm64/hd.img
DB=debian-12-arm64/boot
DBK=$G/$DB/vmlinuz-6.1.0-18-arm64
DBI=$G/$DB/initrd.img-6.1.0-18-arm64
DBX=$G/$DB/xen

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
    U_BOOT=qemu-firmware/arm64-tfa-optee-uboot.bin
    ./maybe-fetch ${U_BOOT}.bz2
    ./maybe-fetch ${HD}.bz2
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=on,gic_version=2 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${G}/${HD} \
        -bios ${G}/$U_BOOT
    ;;

"edk2")
    ./maybe-fetch ${HD}.bz2
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=off,gic_version=3 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${G}/${HD} \
        -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
    ;;

"trs")
    # can't handle gicv3 nor memory > 3072
    IMAGE_NAME=trs/trs-image-trs-qemuarm64.rootfs.wic
    FLASH_NAME=trs/flash.bin-qemu
    ./maybe-fetch ${IMAGE_NAME}.bz2
    ./maybe-fetch ${FLASH_NAME}.gz
    echo "Starting QEMU"
    ./qemu-system-aarch64-swtpm $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=on,gic_version=2 \
        -drive id=disk1,file=${G}/${IMAGE_NAME},if=none,format=raw \
        -device virtio-blk-device,drive=disk1 \
        -drive if=pflash,unit=0,readonly=off,file=${G}/${FLASH_NAME},format=raw \
        -m 3072 \
        -device i6300esb,id=watchdog0
    ;;

"direct"|"linux"|"linux-direct")
    ./maybe-fetch ${HD}.bz2
    ./maybe-fetch ${DB}.tar.gz
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,gic_version=3 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${G}/${HD} \
        -kernel ${DBK} \
        -initrd ${DBI} \
        -append "console=ttyAMA0 root=/dev/vda2"
    ;;

"xen-direct"|"xen")
    ./maybe-fetch ${HD}.bz2
    ./maybe-fetch ${DB}.tar.gz
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,gic_version=3 \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${G}/${HD} \
        -kernel ${DBX} \
        -append "dom0_mem=4G,max:4G dom0_max_vcpus=4 dom0_vcpus_pin=true sched=null loglvl=all guest_loglvl=all" \
        -device guest-loader,\
addr=0x49000000,kernel=${DBK},\
bootargs="console=hvc0 earlyprintk=xen root=/dev/vda2" \
        -device guest-loader,\
addr=0x50000000,initrd=${DBI}
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
