; start address
org 0x7c00

BaseOfStack     equ 0x7c00
BaseOfLoader    equ 0x1000              ; LoaderAddress = BaseOfLoader << 4 + OffsetOfLoader = \
OffsetOfLoader  equ 0x00                ; 0x1000 << 4 + 0x00 = 0x10000

RootDirSectors              equ 14      ; sectors of root directory         (BPB_RootEntCnt * 32) / BPB_BytesPerSec
SectorNumOfRootDirStart     equ 19      ; start sector of root directory:   BPB_RsvdSecCnt + BPB_NumFATs * BPB_FATSz16
SectorNumOfFAT1Start        equ 1       ; = BPB_RsvdSecCnt
SectorBalance               equ 17

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
push    0000h
push    StartBootMessageLength
push    StartBootMessage
call    Func_PrintString
add     sp, 4h

; reset floppy
; AH = 00h reset floppy
; DL = drive num
xor     ah, ah
xor     dl, dl
int     13h

; Search for loader.bin
mov     word [SectorNo], SectorNumOfRootDirStart

Label_SearchInRootDirBegin:
cmp     word [RootDirSizeForLoop], 0
jz      Label_NoLoaderBin
dec     word [RootDirSizeForLoop]
mov     ax, 0000h
mov     es, ax
mov     bx, 8000h                       ; read buffer
mov     ax, [SectorNo]                  ; sector number
mov     cl, 1                           ; read number
call    Func_ReadOneSector
mov     si, LoaderFileName
mov     di, 8000h
cld
mov     dx, 10h

Label_SearchForLoaderBin:
cmp     dx, 0
jz      Label_GoToNextSectorInRootDir
dec     dx
mov     cx, 11

Label_CmpFileName:
cmp     cx, 0
jz      Label_FileNameFound
dec     cx
lodsb
cmp     al, byte [es:di]
jz      Label_GoOn
jmp     Label_Different

Label_GoOn:
inc     di
jmp     Label_CmpFileName

Label_Different:
and     di, 0ffe0h
add     di, 20h
mov     si, LoaderFileName
jmp     Label_SearchForLoaderBin

Label_GoToNextSectorInRootDir:
add     word [SectorNo], 1
jmp     Label_SearchInRootDirBegin

Label_NoLoaderBin:
; display no loader error
push    0100h ;RowColumn
push    ErrLoaderNotFoundLength
push    ErrLoaderNotFound
call    Func_PrintString
add     sp, 4h

; loop waiting
jmp $

Label_FileNameFound:
nop
; TODO: complete the file name found part

; Read one sector from floppy
; Parms:
; AX = SectorNumber, CL = ReadNum, BX = BufferAddress
; Return:
; No return
Func_ReadOneSector:

push    bp
mov     bp, sp
sub     sp, 2
mov     byte [bp - 2], cl
push    bx
mov     bl, [BPB_SecPerTrk]
div     bl
inc     ah
mov     cl, ah
mov     dh, al
shr     al, 1
pop     bx
mov     dl, [BS_DrvNum]
Label_GoOnReading:
mov     ah, 2
mov     al, byte [bp - 2]
int     13h
jc      Label_GoOnReading
add     sp, 2
pop     bp
ret

; Print a string on screen
; Parms:
; Stack: StringAddress, StringLength, ColRow
; Return:
; No return
Func_PrintString:

; construct stack frame
push    bp
mov     bp, sp

; StringAddress     = [bp + 4]
; StringLength      = [bp + 6]
; ColRow            = [bp + 8]

; protect registers
push    ax
push    bx
push    cx

; protect BP
push bp
; display a string
; AH = 13h display a string
; AL = 01h display mode
; CX = StringLen
; DH = row, DL = column
; ES:BP = String adress
; BH = page num
; BL = text attributes
mov     ax, 1301h
mov     bx, 000fh
mov     cx, [bp + 6]
mov     dx, [bp + 8]
mov     bp, [bp + 4]
int     10h
; recover bp
pop bp

; recover registers
pop     cx
pop     bx
pop     ax

; close stack frame
mov     sp, bp
pop     bp
; return
ret     6h


; Global vars
SectorNo            dw 0
RootDirSizeForLoop  dw 0

; Strings
StartBootMessageLength  equ 18
StartBootMessage        db 'Start booting...',0dh,0ah
ErrLoaderNotFoundLength equ 25
ErrLoaderNotFound       db 'Error: No loader found!',0dh,0ah
LoaderFileName          db  "LOADER  BIN",0h

; padding zero
times   510 - ($ - $$) db 0
; boot signature
dw 0xaa55