#!/bin/bash

ME=$0
MY_NAME=$(basename $ME)

JOB_NAME=qemu-build-$(date +%Y-%m-%d-%H%M%S)

for i in "$@"; do
    VAL=${i#*=}
    case $i in
    VARIANT=*)
        VARIANT=$VAL
        ;;
    esac
done

TARGET_LIST="aarch64-softmmu"
EXTRA_CONFIG="--disable-pixman"

case $VARIANT in
""|"upstream")
    NAME=qemu-v9
    VER=v9.0.0
    URL=https://gitlab.com/qemu-project/qemu.git
    ;;
"xilinx")
    NAME=qemu-xilinx-v2024.1
    VER=xilinx_v2024.1
    URL=https://github.com/Xilinx/qemu.git
    TARGET_LIST="aarch64-softmmu,microblazeel-softmmu"
    EXTRA_CONFIG=""
    ;;
"openamp")
    NAME=qemu-openamp-v2024.05
    VER=origin/v2024.05
    URL=https://github.com/OpenAMP/qemu-openamp-staging.git
    ;;
*)
    echo "unknown variant $2"
    exit 2
    ;;
esac

echo "VARIANT=$VARIANT"

admin_setup() {
    apt-get update
    apt-get install -y git build-essential python3-pip python3-venv ninja-build \
        libglib2.0-dev libncurses-dev libpixman-1-dev libslirp-dev
    rm -rf /opt/$NAME
    mkdir /opt/$NAME
    echo chown $1 /opt/$NAME
    chown $1 /opt/$NAME
}

prj_build() {
    ORIG_PWD=$PWD

    git clone $URL qemu
    cd qemu
    git reset --hard $VER

    mkdir ../build; cd ../build

    ../qemu/configure --target-list="$TARGET_LIST" --prefix=/opt/$NAME \
        --enable-fdt --enable-slirp --enable-strip \
        --disable-docs \
        --disable-gtk --disable-opengl --disable-sdl \
        --disable-dbus-display --disable-virglrenderer \
        --disable-vte --disable-brlapi \
        --disable-alsa --disable-jack --disable-oss --disable-pa \
        $EXTRA_CONFIG

    make -j10
    make install
    for i in ivshmem-{client,server}; do
        cp contrib/$i/$i /opt/$NAME/bin/$i;
    done

    # trim the fat, get rid of the x86 specific roms and extra languages etc
    find /opt/$NAME/share/qemu/ -type f \
        ! -name "efi-*" ! -name "edk2-aarch64*" ! -name "edk2-arm-vars*" \
        ! -name "edk2-*.txt" ! -name "*-edk2-*" ! -name "en-us" | xargs rm

    cd $ORIG_PWD
    tar cvzf $NAME.tar.gz -C /opt $NAME
}

case $1 in
"admin_setup")
    shift
    admin_setup "$@"
    ;;
"here-sudo")
    shift
    sudo $ME admin_setup $UID:$(id -g) "$@"
    prj_build
    ;;
"multipass")
    shift
    multipass launch -n $JOB_NAME -c 10 -d 15G -m 16G 20.04
    multipass transfer $0 $JOB_NAME:.
    multipass exec $JOB_NAME -- ./$MY_NAME here-sudo "$@"
    #echo "Wait for inspection"; read ignore
    # multipass always matches host
    TARGET_ARCH=$(uname -m)
    mkdir -p saved-images/host/$TARGET_ARCH
    multipass transfer $JOB_NAME:$NAME.tar.gz saved-images/host/$TARGET_ARCH/.
    multipass delete --purge $JOB_NAME
    ;;
"ssh-sudo")
    REMOTE_SSH=$2
    shift 2
    scp $ME $REMOTE_SSH:.
    ssh $REMOTE_SSH ./$MY_NAME here-sudo "$@"
    TARGET_ARCH=$(ssh $REMOTE_SSH uname -m)
    mkdir -p saved-images/host/$TARGET_ARCH
    scp $REMOTE_SSH:$NAME.tar.gz saved-images/host/$TARGET_ARCH/.
    ;;
"ec2-x86_64"|"ec2-x86")
    shift
    ec2 aws-$JOB_NAME run --inst m7i.2xlarge  --os-disk 15 --distro ubuntu-20.04
    $ME ssh-sudo aws-$JOB_NAME "$@"
    #echo "Wait for inspection"; read ignore
    ec2 aws-$JOB_NAME destroy
    ;;
"ec2-arm64"|"ec2-arm")
    shift
    ec2 aws-$JOB_NAME run --inst m7g.2xlarge  --os-disk 15 --distro ubuntu-20.04
    $ME ssh-sudo aws-$JOB_NAME "$@"
    #echo "Wait for inspection"; read ignore
    ec2 aws-$JOB_NAME destroy
    ;;
*)
    echo "Don't understand argument $1"
    ;;
esac
