; start address
org 0x7c00

BaseOfStack     equ 0x7c00
RootDirSecNum   equ 14                  ; sector count of root directory  (BPB_RootEntCnt * 32) / BPB_BytesPerSec
DirStruPerSec   equ 16                  ; directory structure in on sector
RootDirStart    equ 19
BufferAddr      equ 0x8000

; Entry point of boot sector
jmp     short   Label_Start             ; jump to boot program
nop                                     ; placeholder
BS_OEMName          db  'MSDOS5.0'      ; OEM Name
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

push    LoaderFileName
call    Func_FindFile

cmp     ax, ax
jnz     Label_LoaderFound

; loader not found
push    0x0100
push    ErrLoaderNotFoundLength
push    ErrLoaderNotFound
call    Func_PrintString

jmp     $

Label_LoaderFound:


jmp $

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

;;; Function:         Func_ReadOneSector
;;; Params:           Stack: SectorNum, BufAddr 
;;; Return value:     AH = StatusCode
;;; Descryption:      Read one sector from floppy, SectorNum is the sector number,
;;;                   BufAddr is the buffer address to store data of the sector read.
Func_ReadOneSector:
; construct stack frame
push    bp
mov     bp, sp
sub     sp, 02h

; protect registers
push    bx
push    cx
push    dx

; SectorNum = bp + 4
; BufAddr   = bp + 6

mov     ax, [bp + 4]
mov     bx, [BPB_SecPerTrk]
div     bx

inc     dx
mov     [bp - 2], dx ; [bp - 2] is sector num

mov     bx, [BPB_NumHeads]
xor     bh, bh
xor     dx, dx
div     bx ; AX is cylinder, DX is head num

mov     cx, [bp - 2] ; CL = sector num
mov     ch, al ; CH = cylinder
mov     dh, dl ; DH = head num
mov     dl, [BS_DrvNum] ; DL = drive num
mov     al, 1 ; AL = read count
mov     ah, 02h ; AH = 0x02
mov     bx, [bp + 6]
int     13h

; recover registers
pop     dx ;7ccf
pop     cx
pop     bx

; recover stack frame
mov     sp, bp
pop     bp 
ret     04h

;;; Function:         Func_CompareFileName
;;; Parms:            Stack: FileNameAddr
;;; Return value:     AX = not zero if equal, 0 if not equal
;;; Descryption:      Compare if the file name is equal the loader file name.
Func_CompareFileName:
; FileNameAddr = [sp + 4]
push    bx
push    cx

mov     bx, sp
mov     ax, 1
cld
mov     cx, 11
mov     si, [bx + 4]
mov     di, LoaderFileName
repe cmpsb
jecxz   Label_Equal

xor     ax, ax

Label_Equal: ; TODO: Check the compare logic
pop     cx
pop     bx
ret 02h

;;; Function:         Func_FindFile
;;; Params:           Stack: FileNameAddress
;;; Return value:     AX = FirstCluster, zero if not found.
;;; Descryption:      Find the file named [FileNameAddress] in root directory.
;;;                   The length of file name must be 11 bytes.
Func_FindFile:
; construct stack frame
push    bp
mov     bp, sp

xor     cx, cx ; ch = inner, cl = outer

Label_StartSearch:
cmp     cl, RootDirSecNum
ja      Label_FileNotFound

mov     ax, RootDirStart
add     al, cl ; AX = current sector

push    BufferAddr
push    ax
call    Func_ReadOneSector

xor     ch, ch
Label_InnerLoop:
mov     al, ch
xor     ah, ah
mov     bx, 32
mul     bx
add     ax, BufferAddr
mov     bx, ax ; BX = cur dir struc addr

; BX = cur file name (11 btyes)

push    bx
call    Func_CompareFileName
cmp     ax, ax
jnz     Label_FileFound

inc     ch

cmp     ch, DirStruPerSec
jle     Label_InnerLoop

; go to next round
inc     cl
jmp     Label_StartSearch

Label_FileFound:
mov     ax, 1
jmp     Label_FuncReturn

Label_FileNotFound:
xor     ax, ax

Label_FuncReturn:
mov     sp, bp
pop     bp
ret     02h

; Strings
StartBootMessageLength  equ 16
StartBootMessage        db 'Start booting...'
ErrLoaderNotFoundLength equ 24
ErrLoaderNotFound       db 'Error! Loader not found!'
LoaderFileName          db 'README  TXT'

; padding zero
times   510 - ($ - $$) db 0
; boot signature
dw 0xaa55