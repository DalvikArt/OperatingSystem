jmp     Label_Start

%include "fat12.inc"

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
push    KernelInitMessageLength
push    KernelInitMessage
call    Func_PrintString

%include "functions.inc"

KernelInitMessageLength equ 22
KernelInitMessage       db 'Initializing kernel...'