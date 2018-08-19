org 0x7c00

BaseOfStack equ 0x7c00

; init registers
mov     ax, cs
mov     ds, ax
mov     es, ax
mov     ss, ax
mov     sp, BaseOfStack

; clear screen
mov     ax, 0600h
mov     bx, 0700h
mov     cx, 0
int     10h

; set focus
mov     ax, 0200h
mov     bx, 0000h
mov     dx, 0000h
int     10h

; display boot string
mov     ax, 1301h
mov     bx, 000fh
mov     cx, 10
push    ax
mov     ax, ds
mov     es, ax
pop     ax
mov     bp, StartBootMessage
int     10h

StartBootMessage:   db  "Start Boot"

; padding zero and set flag
times   510 - ($ - $$) db 0
dw      0xaa55
