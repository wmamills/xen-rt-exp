#!/bin/bash

MY_DIR=$PWD

QEMU_BASE="-machine type=virt \
           -machine type=virt,virtualization=on \
           -cpu cortex-a53 \
           -smp 8 \
           -accel tcg \
           -device virtio-net-pci,netdev=unet \
           -device virtio-scsi-pci \
           -device scsi-hd,drive=hd \
           -netdev user,id=unet,hostfwd=tcp::2222-:22 \
           -blockdev driver=raw,node-name=hd,file.driver=file,file.filename=${MY_DIR}/generated/debian-12-arm64.img \
           -serial mon:stdio \
           -m 8192 \
           -object memory-backend-memfd,id=mem,size=8G,share=on \
           -display none"

case $1 in
""|"uefi"|"efi")
    qemu-system-aarch64 $QEMU_BASE \
           -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
    ;;
"direct"|"linux"|"linux-direct")
    qemu-system-aarch64 $QEMU_BASE \
        -kernel ${MY_DIR}/direct-boot/Image \
        -initrd ${MY_DIR}/direct-boot/initrd.img \
        -append "console=ttyAMA0 root=/dev/sda2"

    ;;
"xen-direct"|"xen")
    qemu-system-aarch64 $QEMU_BASE \
        -kernel ${MY_DIR}/direct-boot/xen.efi \
        -append dom0_mem=4G,max:4G -append loglvl=all -append guest_loglvl=all \
        -device guest-loader,\
addr=0x49000000,kernel=${MY_DIR}/direct-boot/Image,\
bootargs="console=hvc0 earlyprintk=xen root=/dev/sda2" \
        -device guest-loader,\
addr=0x50000000,initrd=${MY_DIR}/direct-boot/initrd.img
    ;;
*)
    echo "unknown option $1"
    ;;
esac



