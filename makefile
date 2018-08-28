build/boot.img : build/boot.bin build/fat12 build/loader.bin
	dd if=build/boot.bin of=build/boot.img bs=512 count=1 conv=notrunc

build/loader.bin : src/bootloader/loader.asm
	nasm src/bootloader/loader.asm -o build/loader.bin

build/boot.bin	: src/bootloader/boot.asm
	nasm src/bootloader/boot.asm -o build/boot.bin

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
