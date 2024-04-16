#!/bin/bash

MY_DIR=$(dirname $0)
BASE_DIR=$(cd $MY_DIR/..; pwd)

mkdir -p $BASE_DIR/images/zephyr-apps
mkdir -p $BASE_DIR/saved-images/zephyr-apps

# make sure submodule is init'ed
if [ ! -e $BASE_DIR/zephyr-apps/.gitignore ]; then
    git submodule init zephyr-apps
    git submodule update zephyr-apps
fi

if [ -z "$ZEPHYR_BASE" ]; then
    if [ -e $BASE_DIR/zephyr-top/zephyr/zephyr-env.sh ]; then
        . $BASE_DIR/zephyr-top/zephyr/zephyr-env.sh
    else
        echo "You either need to define the required env vars "
        echo "or have a valid ./zephyr-top"
        echo ""
        echo "Required vars are:"
        echo "    ZEPHYR_BASE"
        echo "    ZEPHYR_SDK_INSTALL_DIR"
        echo "    ZEPHYR_TOOLCHAIN_VARIANT"
        echo ""
        echo "./zephyr-top can be a symlink to a zephyr top dir or a full"
        echo "west clone.  Either way ./zephyr-top/zephyr/zephyr-env.sh"
        echo "should exist."
        echo ""
        echo "Your machine should be setup for building zephyr as well."
        echo "Required packages, west and sdk installed etc"
        exit 2
    fi
fi

declare -A board_name
declare -A config_opts
declare -A mode_suffix
board_name["gicv2"]="xenvm"
board_name["gicv3"]="xenvm_gicv3"
config_opts["xl"]="-DCONFIG_XEN_DOM0LESS=n"
config_opts["dom0less"]="-DCONFIG_XEN_DOM0LESS=y -DDTC_OVERLAY_FILE=dom0less.overlay"
mode_suffix["xl"]=""
mode_suffix["dom0less"]="-dom0less"

do_one() {
    cd $BASE_DIR/zephyr-apps
    echo "******* Do ${full_name}"
    if west build -p -d build-${full_name} \
        -b $board $app -- $config; then
        cp build-${full_name}/zephyr/zephyr.bin \
            $BASE_DIR/images/zephyr-apps/zephyr-${full_name}.bin
        bzip2 -czk build-${full_name}/zephyr/zephyr.bin \
            >$BASE_DIR/saved-images/zephyr-apps/zephyr-${full_name}.bin.bz2
        echo "*** OK"
    else
        echo "*** Error"
    fi
    echo ""
}

for app in hello-mod xen-irq-latency; do
    for gic in gicv2 gicv3; do
        board=${board_name["$gic"]}
        for mode in xl dom0less; do
            config=${config_opts["$mode"]}
            full_name="${app}-${gic}${mode_suffix["$mode"]}"
            (do_one)
        done
    done
done
