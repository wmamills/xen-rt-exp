demos/dom0less: Run zephyr as only guest

This uses zephyr as "dom0" but it is not controlling anything.

Short Status:
* Xen runs and starts dom0
* dom0 causes trap at start

(XEN) d0v0 Decoding instruction 0xa9bf7bfd is not supported
(XEN) d0v0 unhandled Arm instruction 0xa9bf7bfd
(XEN) d0v0 Unable to decode instruction
(XEN) arch/arm/traps.c:1954:d0v0 HSR=0x00000092000045 pc=0x000000c0002984 gva=0x4003f760 gpa=0x0000004003f760


