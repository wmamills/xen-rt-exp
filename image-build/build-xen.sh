#!/bin/bash

ME=$0
MY_NAME=$(basename $ME)

JOB_NAME=xen-build-$(date +%Y-%m-%d-%H%M%S)

NAME=xen-4.19-unstable

# HEAD COMMIT on master as of 2024-04-08
VER="402c2d3e66a6bc9481dcabfc8697750dc4beabed"

admin_setup() {
    apt update
    apt-get build-dep -y xen
    apt-get install -y git ninja-build libsystemd-dev fakeroot
    rm -rf /opt/$NAME
    mkdir /opt/$NAME
    echo chown $1 /opt/$NAME
    chown $1 /opt/$NAME
}

prj_build() {
    ORIG_PWD=$PWD

    git clone https://xenbits.xen.org/git-http/xen.git
    cd xen
    git reset --hard $VER

    ./configure --enable-systemd
    make -j10 debball
    cp dist/*.deb $ORIG_PWD/
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
    #echo "Wait for inspection"; read ignore
    multipass transfer $JOB_NAME:$NAME.tar.gz .
    multipass delete --purge $JOB_NAME
    ;;
"ssh-sudo")
    scp $0 $2:.
    ssh $2 ./$MY_NAME here-sudo
    mkdir -p saved-images/xen
    scp $2:*.deb saved-images/xen/
    ;;
"ec2")
    ec2 aws-$JOB_NAME run --inst m7g.2xlarge  --os-disk 15 --distro debian-12
    $ME ssh-sudo aws-$JOB_NAME
    #echo "Wait for inspection"; read ignore
    ec2 aws-$JOB_NAME destroy
    ;;
*)
    echo "Don't understand argument $1"
    ;;
esac
