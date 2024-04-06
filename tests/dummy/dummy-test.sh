#!/bin/bash

MODE=pass

run_test() {
    echo "This is the dummy test: $@"
    case $MODE in
    "pass"|"")
        sleep 5
        true
        ;;
    "fail")
        sleep 5
        false
        ;;
    "timeout")
        sleep 600
        ;;
    "hang")
        systemctl stop sshd
        ;;
    esac
}

case $1 in
"run")
    shift
    run_test "$@"
    ;;
"files")
    echo ""
    ;;
*)
    echo "unknown command $1"
    false
    ;;
esac
