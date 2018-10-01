all: build/boot.img build/loader.bin build/boot.bin

build/boot.img : build/boot.bin build/fat12 build/loader.bin build/kernel.bin
	dd if=build/boot.bin of=build/boot.img bs=512 count=1 conv=notrunc
	./writeloader.sh

build/boot.bin	: src/bootloader/boot/boot.asm
	nasm src/bootloader/boot/boot.asm -o build/boot.bin

build/loader.bin : src/bootloader/loader/loader.asm src/bootloader/loader/fat12.inc src/bootloader/loader/functions.inc
	nasm -i src/bootloader/loader/ src/bootloader/loader/loader.asm -o build/loader.bin

build/kernel.bin : src/kernel/kernel.asm src/bootloader/loader/functions.inc src/bootloader/loader/fat12.inc
	nasm -i src/bootloader/loader/ src/kernel/kernel.asm -o build/kernel.bin

prom = build/fat12
deps = src/tools/FAT12/fat12.h src/tools/FAT12/utils.h
obj = build/fat12.o build/utils.o

$(prom) : $(obj)
	gcc -ggdb3 -o $(prom) $(obj)

build/%.o : src/tools/FAT12/%.c $(deps)
	gcc -c $< -o $@

clean:
	rm build/*.bin
	rm $(obj)
	rm $(prom)
