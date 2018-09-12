BaseOfStack     equ 0x7c00
RootDirSecNum   equ 14                  ; sector count of root directory  (BPB_RootEntCnt * 32) / BPB_BytesPerSec
DirStruPerSec   equ 16                  ; directory structure in on sector
RootDirStart    equ 19
BufferAddr      equ 0x8000
DataStart       equ 31                  ; realstart - 2
FATTabStart     equ 1
BaseOfLoader    equ 0x1000
OffsetOfLoader  equ 0x0000

BS_OEMName          db  'WINIMAGE'      ; OEM Name
BPB_BytesPerSec     dw  512             ; bytes per section
BPB_SecPerClus      db  1               ; sectors per cluster
BPB_RsvdSecCnt      dw  1               ; reserved sector count (boot sector)
BPB_NumFATs         db  2               ; number of FAT tables
BPB_RootEntCnt      dw  224             ; max dir count of root dir
BPB_TotSec16        dw  2880            ; total number of sectors
BPB_Media           db  0xf0            ; drive type
BPB_FATSz16         dw  9               ; size of each FAT table
BPB_SecPerTrk       dw  18              ; sectors per track
BPB_NumHeads        dw  2               ; number of magnetic heads
BPB_HiddSec         dd  0               ; number of hidden sectors
BPB_TotSec32        dd  0               ; this value effects when BPB_TotSec16 is 0
BS_DrvNum           db  0               ; number of drives
BS_Reserved1        db  0               ; Reserved
BS_BootSig          db  29h             ; boot signature
BS_VolID            dd  0               ; volume ID
BS_VolLab           db  'bootloader '   ; volume name, padding with space(20h)
BS_FileSysType      db  'FAT12   '      ; file system type