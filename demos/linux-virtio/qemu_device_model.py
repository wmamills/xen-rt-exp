#!/usr/bin/env python3
import sys, signal
from subprocess import Popen

""" Usage

Save as `qemu_device_model.py`, set as executable
(`chmod +x qemu_device_model.py`) and add in xen guest .cfg:

device_model_version="qemu-xen"
device_model_override="/home/root/qemu_device_model.py"

"""


def handler_exit_signals(signum, frame):
    raise SystemExit(0)


signal.signal(signal.SIGINT, handler_exit_signals)
signal.signal(signal.SIGTERM, handler_exit_signals)

QEMU_BINARY_PATH = "/usr/bin/qemu-system-aarch64"
LOG_FILE = "/var/log/qemu_log.txt"

args = sys.argv[1:]
dom_id = None
name = None

print("args are:",args)

i = 0
try:
    while i < len(args):
        if args[i].startswith("-xen-domid"):
            dom_id = args[i + 1]
            i += 2
            continue

        if args[i].startswith("-name"):
            name = args[i + 1]
            i += 2
            continue

        i += 1
except IndexError as exc:
    print(exc, "for i =", i)
    print("Invalid command line arguments: ", args)
    sys.exit(1)

if name is None:
    name = "trs-vm"

if dom_id is None:
    print("No -xen-domid found in arguments:\nArguments were:", args)
    sys.exit(1)

libxl_cmd_socket = "/var/run/xen/qmp-libxl-{}".format(dom_id)
libxenstat_cmd_socket = "/var/run/xen/qmp-libxenstat-{}".format(dom_id)

# Create new argv with flags that include the domid and guest name first, then
# add the device flags

xen_guest_specific_args = [
    "-name",
    name,
    "-xen-domid",
    dom_id,
    "-chardev",
    "socket,id=libxl-cmd,path={},server=on,wait=off".format(libxl_cmd_socket),
    "-chardev",
    "socket,id=libxenstat-cmd,path={},server=on,wait=off".format(libxenstat_cmd_socket),
    "-mon",
    "chardev=libxl-cmd,mode=control",
    "-mon",
    "chardev=libxenstat-cmd,mode=control",
    "-nodefaults",
    "-no-user-config",
    "-xen-attach",
    "-no-shutdown",
    "-smp",
    "4,maxcpus=4",
    "-machine",
    "xenpvh",
    "-m",
    "6144",
]

guest_device_args = [
    "-vga",
    "std",
    "-vnc",
    "none",
    "-display",
    "sdl,gl=on",
    "-device",
    "virtio-gpu-pci,disable-legacy=on,iommu_platform=on,xres=1080,yres=600",
    "-global",
    "virtio-mmio.force-legacy=false",
    "-device",
    "virtio-mouse-pci,disable-legacy=on,iommu_platform=on",
    "-device",
    "virtio-keyboard-pci,disable-legacy=on,iommu_platform=on",
    "-device",
    "virtio-snd-pci,audiodev=snd0,disable-legacy=on,iommu_platform=on",
    "-audiodev",
    "alsa,id=snd0,out.dev=default",
]

new_args = [QEMU_BINARY_PATH] + xen_guest_specific_args + guest_device_args

print("new args are:",new_args)

with open(LOG_FILE, "a") as log, Popen(new_args, stdout=log, stderr=log) as proc:
    try:
        proc.wait()
    except SystemExit:
        proc.kill()
    sys.exit(proc.returncode)
