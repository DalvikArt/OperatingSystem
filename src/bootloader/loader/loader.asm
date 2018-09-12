[bits 16]

org 0x10000

jmp     Label_Start

%include "fat12.inc"

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

; print boot message
push    0000h
push    30
push    StartBootMessage
call    Func_PrintString

call    Func_FastGateA20

call    check_a20

; loop wait
jmp $

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


; message string
StartBootMessage:   db  "Start Loading System Kernel..."