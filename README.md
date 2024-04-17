# Bill's Xen RT and Virtio experiments

This repo and its accompanying image submodule capture my experiments for running
* Zephyr on Xen
* Realtime domUs on Xen
* Virtio on Xen
* (Future) AMP Virtio on Xen
* (Future) AMP Virtio on Zephyr in Realtime in a DomU on Xen

## Machine setup

You will need a Linux machine or VM with at least 15G disk and 8G of memory.
It is recommended to have 10 cpu's (threads count) and 16G of memory as the
qemu machine uses 8 cpu's and 8G of memory.

I used Ubuntu 22.04 but other distros should work if the instructions below are
adjusted.

Install the following packages
```
sudo apt install git git-lfs bzip2 zstd u-boot-tools
```

Next clone the repo:
```
git clone https://github.com/wmamills/xen-rt-exp.git
cd xen-rt-exp
```
## Running the Dom0 xl based demos

Now you can run the the zephyr-hello demo using this command:
```
./scripts/qemu-demo demos/zephyr-hello
```

The first time you run it, it will pull the images you need and decompress them.
It will take some time depending on your internet connection.
This only happens the first time you use a given qemu model.

(On a slow connection you may get a timeout on the host side.
If so just let qemu finish getting the images and then exit from the host side and run again.
You will be find thereafter.)

QEMU will now be running Xen and a Linux DOM0 and the needed files for the demo will have been transfered to the target system (qemu).  You will have a host pane on the right and the target system on the left.

Now on the target systems, log in as root with no password and do these commands:
```
xl list
xl vcpu-list
xl create ./zephyr-hello.conf 'name="z1"'
xl list
xl vcpu-list
xl console z1
```

You should see the zephyr program saying hello periodically.
Exit the z1 console using ctrl-] (control and close square bracket).
```
xl destroy z1
xl list
```

You can run this as many times as you like.  You can even run up to 4 zephyr
domains at the same time, just change the name for each of the 4.

To do a graceful please destroy all domains except domain-0 and then:
```
poweroff
```

QEMU should exit when the machine powers down.

A non-graceful termination can be done via Ctrl-A X.
(Control and 'a' key and then capitol letter X) in the qemu pane or just exit on the host pane.
Keep in mind that this demo has a persistent disk image and there is a small chance of
disk corruption for a non graceful termination.

If the hard disk image is ever messed up, just delete the
file images/debian-12-arm64/hd.img.  It will be recreated when you need it
again by decompressing the template file in saved-images.  A new download
will not be required.

The other demos that don't start with dom0less-* can be run in a similar way.  You can look at the *-test.sh files to see what commands you may want to try on the target.

## Running the Dom0less demos

To run one of the dom0less demos do the following (using the zephyr-only demo as an example):
```
./demos/dom0less-zephyr-only/do_it
```

For the demos that have more that one domain (for example dom0less-linux-hello), use Ctrl-A SIX times to switch the console input to a new focus.  QEMU is eating every other Ctrl-A and Xen needs to see 3 to switch.

To exit these demos you can use Ctrl-A x to quit qemu.  For the demos that do have a dom0 you can also use poweroff from dom0.