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

If you do not have swtpm-tools (like Ubuntu 20.04) just drop it and don't run the "trs" qemu target.

Next clone the repo:
```
git clone https://github.com/wmamills/xen-rt-exp.git
cd xen-rt-exp
```

Now you can run the demo using this command:
```
./scripts/qemu-run xen
```

The first time you run it, it will pull the images you need and decompress them.
It will take some time depending on your internet connection.
This only happens the first time you use a given qemu model.

QEMU will now be running Xen and a Linux DOM0.

You will need some files on the target.
From another terminal on the host, use
```
./scripts/maybe-fetch zephyr-apps
./scripts/my-scp demos/zephyr-hello/* images/zephyr-apps/* qemu:
```

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
shutdown now
```

QEMU should exit when the machine powers down.

A non-graceful termination can be done via Ctrl-A X.
(Control and 'a' key and then capitol letter X).  Keep in mind that this demo
has a persistent disk image and there is a small chance of disk corruption for
a non graceful termination.

If the hard disk image is ever messed up, just delete the
file images/debian-12-arm64/hd.img.  It will be recreated when you need it
again by decompressing the template file in saved-images.  A new download
will not be required.

Note:

Additional packages are required to run the TRS target but that target is
not needed for this demo.  The required packages are all available in
ubuntu 22.04 but not Ubuntu 20.04.

Note also that TRS takes a very long time to boot the first time.  It encrypts
the rootfs to the specific simulated TPM on first boot.  It then reboots.

The additional packages are:
```
sudo apt install --no-install-recommends qemu-system-arm \
    qemu-efi-aarch64 swtpm-tools ipxe-qemu
```
