#/bin/sh

mount build/boot.img build/bootimg/ -t vfat -o loop
cp build/loader.bin build/bootimg/
sync
umount build/bootimg/

