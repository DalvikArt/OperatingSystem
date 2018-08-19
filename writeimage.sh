#/bin/sh

dd if=build/boot.bin of=build/boot.img bs=512 count=1 conv=notrunc