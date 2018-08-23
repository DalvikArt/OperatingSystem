; start address
org 0x7c00

BaseOfStack     equ 0x7c00
BaseOfLoader    equ 0x1000              ; LoaderAddress = BaseOfLoader << 4 + OffsetOfLoader = \
OffsetOfLoader  equ 0x00                ; 0x1000 << 4 + 0x00 = 0x10000

RootDirSectors              equ 14      ; sectors of root directory         (BPB_RootEntCnt * 32) / BPB_BytesPerSec
SectorNumOfRootDirStart     equ 19      ; start sector of root directory:   BPB_RsvdSecCnt + BPB_NumFATs * BPB_FATSz16
SectorNumOfFAT1Start        equ 1       ; = BPB_RsvdSecCnt

; Entry point of boot sector
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

; entry point
Label_Start:
; init registers
mov     ax, cs
mov     ds, ax
mov     es, ax
mov     ss, ax
mov     sp, BaseOfStack

; clear screen
; AH = 06h roll pages
; AL = page num (0 to clear screen)
; BH = color attributes
; CL = left row, CH = left column
; DL = right row, DL = right column
mov     ax, 0600h
mov     bx, 0700h
mov     cx, 0
mov     dx, 184Fh
int     10h

; set focus
; AH = 02h set focus
; DL = row
; DH = column
; BH = page num
mov     ax, 0200h
mov     bx, 0000h
mov     dx, 0000h
int     10h

; display boot string
; AH = 13h display a string
; AL = 01h display mode
; CX = StringLen
; DH = row, DL = column
; ES:BP = String adress
; BH = page num
; BL = text attributes
mov     ax, 1301h
mov     bx, 000fh
mov     cx, 16
mov     bp, StartBootMessage
int     10h

; reset floppy
; AH = 00h reset floppy
; DL = drive num
xor     ah, ah
xor     dl, dl
int     13h

push    1000h
push    2h
call    Func_ReadOneSector
add     sp, 4h

; loop
jmp $

;;; Function:         Read one sector from floppy
;;; Params:           ClusNum, BufAddr 
;;; Return value:     None
;;; Descryption:      Read one sector from floppy, ClusNum is the Cluster number,
;;;                   BufAddr is the buffer address to store data of the sector read.
Func_ReadOneSector:
; construct stack frame
push    bp
mov     bp, sp

; protect registers
push    ax
push    bx
push    cx
push    dx

; ClusNum = bp + 4
; BufAddr = bp + 6

; AX = LSB(logical block address)
mov     ax, [bp + 4]
sub     ax, 2
mov     bx, [BPB_SecPerClus]
xor     bh, bh
mul     bx
add     ax, [BPB_HiddSec]
add     ax, [BPB_RsvdSecCnt]
mov     cx, ax
mov     ax, [BPB_NumFATs]
xor     ah,ah
mov     bx, [BPB_FATSz16]
mul     bx
add     ax, cx
add     ax, RootDirSectors
dec     ax

; AX = LSB / BPB_SecPerTrk, DX = LSB % BPB_SecPerTrk
mov     bx, [BPB_SecPerTrk]
div     bx

; CL = SectorNumber = LSB % BPB_SecPerTrk + 1
mov     cl, dl
inc     cl

; AL = LSB / BPB_SecPerTrk / BPB_NumHeads, AH = (LSB / BPB_SecPerTrk) % BPB_NumHeads
mov     bx, [BPB_NumHeads] ;7cba
div     bl

; CH = TrackNumber
mov     ch, al

; DH = HeadNum
mov     dh, ah

; DL = DriveNum
mov     dl, [BS_DrvNum]

; AH = 0x2  Read data from floppy
; AL = Read sector num
; CH = TrackNumber, CL = SectorNumber
; DH = HeadNumber,  DL = DriveNumber
; BX = BufferAddress
mov     ah, 02h
mov     al, 1
mov     bx, [bp + 6]
int     13h

; recover registers
pop     dx
pop     cx
pop     bx
pop     ax

; recover stack frame
mov     sp, bp
pop     bp 

; return
ret
;;; End of function 

; message string
StartBootMessage:   db  "Start Booting..."

; padding zero and set flag
times   510 - ($ - $$) db 0
dw      0xaa55