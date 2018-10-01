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

; print loading message
push    0000h
push    30
push    StartBootMessage
call    Func_PrintString

call    Func_FastGateA20

call    check_a20

; find loader
push    LoaderFileName
call    Func_FindFile

cmp     ax, 0
jne     Label_KernelFound

; kernel not found
push    0x0100
push    ErrKernelNotFoundLength
push    ErrKernelNotFound
call    Func_PrintString

; kernel found
Label_KernelFound:

xor     bx, bx
mov     es, bx
push    0x3000
push    0x8000
call    Func_ReadFile

; loop wait
jmp $

%include "functions.inc"

; message string
StartBootMessage:       db  "Start Loading System Kernel..."
ErrKernelNotFoundLength equ 24
ErrKernelNotFound       db 'Error! Kernel not found!'

LoaderFileName          db 'KERNEL  BIN'