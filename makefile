
build/boot.bin : bootloader/boot.asm
	nasm bootloader/boot.asm -o build/boot.bin

clean:
	rm build/*.bin
