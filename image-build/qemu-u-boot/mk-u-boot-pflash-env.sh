#!/bin/bash
# Make an image of the qemu r/w flash with an altered environment

ME=$0
M=$(dirname ${ME})
G=${M}/generated
SI=${M}/../../saved-images/qemu-firmware

mkdir -p ${G}
mkdir -p $SI

TFTP_ENV=arm64-u-boot-vars-tftp.bin
BLANK_ENV=arm64-u-boot-vars-blank.bin
ENV_SIZE=0x40000
PFLASH_SIZE_MB=64

# make the TFTP only env image
# combine the defaults with the overrides
cat ${M}/default-env.txt ${M}/tftp-env.txt >${G}/combined-env.txt

# make the env partition image 
mkenvimage -s ${ENV_SIZE} -o ${G}/tftp-env.bin ${G}/combined-env.txt

# we need to pad to 64M for qemu to accept it as a pflash
# make a blank 64M file
dd if=/dev/zero of=${G}/${TFTP_ENV} bs=1M count=${PFLASH_SIZE_MB}

# now replace just the first part
dd if=${G}/tftp-env.bin of=${G}/${TFTP_ENV} conv=notrunc

# and bzip2 compress it for saved-images
bzip2 -zckq ${G}/${TFTP_ENV} >${SI}/${TFTP_ENV}.bz2

# now make a blank one
dd if=/dev/zero of=${G}/${BLANK_ENV} bs=1M count=${PFLASH_SIZE_MB}
bzip2 -zckq ${G}/${BLANK_ENV} >${SI}/${BLANK_ENV}.bz2
