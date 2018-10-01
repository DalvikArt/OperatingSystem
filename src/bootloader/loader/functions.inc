;;; Function:         Func_PrintString
;;; Params:           Stack: StringAddress, StringLength, ColRow 
;;; Return value:     No return
;;; Descryption:      Print a white string on screen
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
push    bx
push    cx

; FileNameAddr = [sp + 6]

mov     bx, sp
mov     ax, 1
cld
mov     cx, 11
mov     si, [bx + 6]
mov     di, LoaderFileName
repe cmpsb ;7cf6
jcxz   Label_Equal

xor     ax, ax

Label_Equal:
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
cmp     ax, 0
jnz     Label_FileFound

inc     ch

cmp     ch, DirStruPerSec
jle     Label_InnerLoop

; go to next round
inc     cl
jmp     Label_StartSearch

Label_FileFound:
mov     ax, [bx + 0x1a]
jmp     Label_FuncReturn

Label_FileNotFound:
xor     ax, ax

Label_FuncReturn:
mov     sp, bp
pop     bp
ret     02h

;;; Function:       Func_GetNextCluster
;;; Params:         AX = CurrentCluster
;;; Return value:   AX = NextCluster
;;; Descryption:    Get next cluster number according to current clus num.
Func_GetNextCluster:
push    bx
push    cx
push    bp

; use bp to judge odd
mov bp, ax

mov     bx, 3
mul     bx
shr     ax, 1 ; AX = CurClus * 3 / 2 = CurClus * 1.5
mov     bx, ax
mov     bx, [bx + BufferAddr]

shr     bp, 1
jc      Label_Odd

and     bx, 0x0fff
jmp Label_GetNextClusRet

Label_Odd:
shr     bx, 4

Label_GetNextClusRet:
mov     ax, bx

pop     bp
pop     cx
pop     bx
ret

;;; Function:         Func_FastGateA20
;;; Params:           No param 
;;; Return value:     No return
;;; Descryption:      Enable a20
Func_FastGateA20:
push    ax
push    dx

in      al, 0x92
or      al, 2
out     0x92, al

pop     dx
pop     ax
ret

Func_EnableA20Bios:
push    ax
mov     ax, 0x2401
int     15h
pop     ax
ret

;;; Function:         Func_EnterProtectMode
;;; Params:           No param 
;;; Return value:     No return
;;; Descryption:      Enter protect mode
Func_EnterProtectMode:
cli

db 0x66

mov     eax, cr0
or      eax, 1
mov     cr0, eax

ret

; Function: check_a20
;
; Purpose: to check the status of the a20 line in a completely self-contained state-preserving way.
;          The function can be modified as necessary by removing push's at the beginning and their
;          respective pop's at the end if complete self-containment is not required.
;
; Returns: 0 in ax if the a20 line is disabled (memory wraps around)
;          1 in ax if the a20 line is enabled (memory does not wrap around)
 
check_a20:
    pushf
    push ds
    push es
    push di
    push si
 
    cli
 
    xor ax, ax ; ax = 0
    mov es, ax
 
    not ax ; ax = 0xFFFF
    mov ds, ax
 
    mov di, 0x0500
    mov si, 0x0510
 
    mov al, byte [es:di]
    push ax
 
    mov al, byte [ds:si]
    push ax
 
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF
 
    pop ax
    mov byte [ds:si], al
 
    pop ax
    mov byte [es:di], al
 
    mov ax, 0
    je check_a20__exit
 
    mov ax, 1
 
check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf
 
    ret