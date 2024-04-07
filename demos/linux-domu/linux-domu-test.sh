#!/bin/bash

run_test() {
    xl list
    xl vcpu-list
    xl create ./linux-domu.conf 'name="test1"'
    xl vcpu-list
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
    # we want everything in the min dir
    echo linux-domu.conf $IMAGES/min
    ;;
*)
    echo "$0: unknown command $1"
    false
    ;;
esac
