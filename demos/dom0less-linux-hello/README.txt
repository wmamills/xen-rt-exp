demos/dom0less: initial start using min Linux for domus

This uses min Linux as 2 domu's and Debian as dom0.

Short Status:
* all 3 domains are created
* I can't get output from dom1 or dom2

Long Status:
* The u-boot script looks ok and the files get loaded and started.
* In dom0 I can see all 3 domains are there and have the correct memory
  and vcpus.
* The domu's have (null) name and xl console 1 gives me nothing.
* Likewise if I switch the console to dom1 or dom2 with Ctrl-A,
  I see nothing even after hitting enter.

Note: it takes 6 Ctrl-A's to switch the console in QEMU as qemu is looking
for Ctrl-A also.  2 Ctrl-A's in QEMU => 1 Ctrl-A in target.
