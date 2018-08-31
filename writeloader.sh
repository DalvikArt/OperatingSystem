#/bin/sh

hdiutil mount build/boot.img
cp build/loader.bin /Volumes/bootloader
sync
hdiutil unmount /Volumes/bootloader

