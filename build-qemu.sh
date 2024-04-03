#!/bin/bash

ME=$0
MY_NAME=$(basename $ME)

JOB_NAME=qemu-build-$(date +%Y-%m-%d-%H%M%S)

NAME=qemu-9-wip
VER=v9.0.0-rc1

admin_setup() {
    apt update
    apt install -y git build-essential python3-pip python3-venv ninja-build libglib2.0-dev libncurses-dev
    rm -rf /opt/$NAME
    mkdir /opt/$NAME
    echo chown $1 /opt/$NAME
    chown $1 /opt/$NAME
}

prj_build() {
    ORIG_PWD=$PWD

    git clone https://gitlab.com/qemu-project/qemu.git
    cd qemu
    git reset --hard $VER

    mkdir ../build; cd ../build

    ../qemu/configure --target-list="aarch64-softmmu" --enable-fdt --enable-slirp --disable-docs --disable-oss --enable-strip --prefix=/opt/$NAME
    make -j10
    make install
    for i in ivshmem-{client,server}; do
        cp contrib/$i/$i /opt/$NAME/bin/$i;
    done
    find /opt/$NAME/share/qemu/ -type f ! -name "efi-*" ! -name "edk2-aarch64*" ! -name "edk2-arm-vars*" ! -name "edk2-*.txt" ! -name "*-edk2-*" ! -name "en-us" | xargs rm

    cd $ORIG_PWD
    tar cvzf $NAME.tar.gz -C /opt $NAME
}

case $1 in
"admin_setup")
    shift
    admin_setup "$@"
    ;;
"here-sudo")
    sudo $ME admin_setup $UID:$(id -g)
    prj_build
    ;;
"multipass")
    multipass launch -n $JOB_NAME -c 10 -d 15G -m 16G 20.04
    multipass transfer $0 $JOB_NAME:.
    multipass exec $JOB_NAME -- ./$MY_NAME here-sudo
    echo "Wait for inspection"; read ignore
    multipass transfer $JOB_NAME:$NAME.tar.gz .
    multipass delete --purge $JOB_NAME
    ;;
*)
    echo "Don't understand argument $1"
    ;;
esac
