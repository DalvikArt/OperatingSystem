mkdir -Force build

pushd .\src\bootloader\
.\make.ps1
popd


pushd .\src\kernel\
.\make.ps1
popd

cp .\src\bootloader\boot.bin .\build\boot.bin
cp .\src\bootloader\loader.bin .\build\loader.bin
cp .\src\kernel\kernel.bin .\build\kernel.bin

copy a.img build/boot.img
dd if=build/boot.bin of=build/boot.img bs=512 count=1 conv=notrunc
