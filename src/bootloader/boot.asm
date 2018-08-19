org 0x7c00

BaseOfStack equ 0x7c00

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

; message string
StartBootMessage:   db  "Start Booting..."

; reset floppy
; AH = 00h reset floppy
; DL = drive num
xor     ah, ah
xor     dl, dl
int     13h

; loop wait interrupt
jmp $

; padding zero and set flag
times   510 - ($ - $$) db 0
dw      0xaa55
