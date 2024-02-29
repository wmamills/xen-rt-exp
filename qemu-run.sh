#!/bin/bash

MY_DIR=$PWD

QEMU_BASE="-machine type=virt \
           -cpu cortex-a57 \
           -smp 8 \
           -accel tcg \
           -device virtio-net-pci,netdev=unet \
           -netdev user,id=unet,hostfwd=tcp::2222-:22 \
           -serial mon:stdio \
           -m 8192 \
           -nographic"

# U-boot can't handle virtio-scsi ATM so use virtio-blk (and /dev/vda)
# but for now leave the choice to the specific case
: \
           -device virtio-scsi-pci \
           -device scsi-hd,drive=hd \


case $1 in

""|"uefi"|"efi")
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on,secure=on \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -bios ${MY_DIR}/qemu-firmware/arm64-tfa-optee-uboot.bin
    ;;
"direct"|"linux"|"linux-direct")
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on \
        -device virtio-blk-device,drive=hd \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -kernel ${MY_DIR}/direct-boot/Image \
        -initrd ${MY_DIR}/direct-boot/initrd.img \
        -append "console=ttyAMA0 root=/dev/vda2"
    ;;

"xen-direct"|"xen")
    qemu-system-aarch64 $QEMU_BASE \
        -machine type=virt,virtualization=on \
        -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
        -kernel ${MY_DIR}/direct-boot/xen.efi \
        -append "dom0_mem=4G,max:4G loglvl=all guest_loglvl=all" \
        -device guest-loader,\
addr=0x49000000,kernel=${MY_DIR}/direct-boot/Image,\
bootargs="console=hvc0 earlyprintk=xen root=/dev/vda2" \
        -device guest-loader,\
addr=0x50000000,initrd=${MY_DIR}/direct-boot/initrd.img
    ;;

*)
    echo "unknown option $1"
    ;;

esac



