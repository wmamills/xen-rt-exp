#!/bin/bash

run_test() {
    dd if=/dev/zero of=disk0.img bs=1M count=16
    xl vcpu-list
    xl create ./linux-xenpv.conf 'name="test1"'
    xl vcpu-list
    xl block-list test1
    xl network-list test1
    sleep 20
    xl destroy test1
    xl vcpu-list
}

case $1 in
""|"run")
    shift
    run_test "$@"
    ;;
"files")
    echo linux-xenpv.conf $IMAGES/min
    ;;
*)
    echo "$0: unknown command $1"
    false
    ;;
esac
