; start address
org 0x7c00

BaseOfStack     equ 0x7c00
BaseOfLoader    equ 0x1000              ; LoaderAddress = BaseOfLoader << 4 + OffsetOfLoader = \
OffsetOfLoader  equ 0x00                ; 0x1000 << 4 + 0x00 = 0x10000

RootDirSectors              equ 14      ; sectors of root directory         (BPB_RootEntCnt * 32) / BPB_BytesPerSec
SectorNumOfRootDirStart     equ 19      ; start sector of root directory:   BPB_RsvdSecCnt + BPB_NumFATs * BPB_FATSz16
SectorNumOfFAT1Start        equ 1       ; = BPB_RsvdSecCnt

; start of boot sector
jmp     short   Label_Start             ; jump to boot program
nop                                     ; placeholder
BS_OEMName          db  'dalvikar'      ; OEM Name
BPB_BytsPerSec      dw  512             ; bytes per section
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
BS_VolLab           db  'bootloader '   ; volume name
BS_FileSysType      db  'FAT12   '      ; file system type

; start of boot program

;;; Function:         Read one sector from floppy
;;; Params:           LBA, BufAddr 
;;; Return value:     None
;;; Descryption:      Read one sector from floppy, LBA is the logical block address,
;;;                   BufAddr is the buffer address to store data of the sector read.
Func_ReadOneSector:
; protect registers
push ax
push bx
push cx
push dx

; construct stack frame
push    bp
mov     bp, es



; recover stack frame
mov     es, bp
pop bp 

; recover registers
pop dx
pop cx
pop bx
pop ax
; return
ret
;;; End of function 