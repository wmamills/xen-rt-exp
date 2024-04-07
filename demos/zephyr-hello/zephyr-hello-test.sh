#!/bin/bash

run_test() {
    xl list
    xl vcpu-list
    xl create ./zephyr-hello.conf 'name="z1"'
    xl vcpu-list
    sleep 5
    xl destroy z1
    xl vcpu-list
}

case $1 in
""|"run")
    shift
    run_test "$@"
    ;;
"files")
    echo zephyr-hello.conf $IMAGES/zephyr-apps/zephyr-hello-mod-gicv3.bin
    ;;
*)
    echo "$0: unknown command $1"
    false
    ;;
esac
