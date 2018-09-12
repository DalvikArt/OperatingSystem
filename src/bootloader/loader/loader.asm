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

mov     ax, 0x0010
mov     fs, ax

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
in      al, 92h
or      al, 00000010b
out     92h, al
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




; message string
StartBootMessage:   db  "Start Loading System Kernel..."