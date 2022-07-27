org 0x7c00
bits 16

cli
mov ax, 0  ; set up segments
mov ds, ax
mov es, ax
mov ss, ax     ; setup stack
mov bp, 0x7c00
mov sp, bp
sti
   call clear_screen
   mov si, welcome
   call print_string
   call install_interrupt_handler
   mov ah, 0
   int 0x80
   call mainloop
 clear_screen:
   mov ah, 0
    mov al, 0x3
    int 0x10
 mainloop:
   mov si, prompt
   call print_string
 
   mov di, buffer
   call get_string
 
   mov si, buffer
   cmp byte [si], 0  ; blank line?
   je mainloop       ; yes, ignore it
 
   mov si, buffer
   mov di, cmd_hi  ; "hi" command
   call strcmp
   jc .helloworld
 
   mov si, buffer
   mov di, cmd_help  ; "help" command
   call strcmp
   jc .help
 
   mov si,badcommand
   call print_string 
   jmp mainloop  
 
 .helloworld:
   mov si, msg_helloworld
   call print_string
 
   jmp mainloop
 
 .help:
   mov si, msg_help
   call print_string
 
   jmp mainloop
 
 welcome db 'Welcome to asmOS!', 0x0D, 0x0A, 0
 msg_helloworld db 'Hello asmOS!', 0x0D, 0x0A, 0
 badcommand db 'Bad command entered.', 0x0D, 0x0A, 0
 msgbadah db 'Bad value in ah.', 0x0D, 0x0A, 0
 interrupt db 'Interrupt ', 0
 ENDL db 0x0D, 0x0A, 0
 prompt db '>', 0
 cmd_hi db 'hi', 0
 cmd_help db 'help', 0
 msg_help db 'asmOS: Commands: hi, help', 0x0D, 0x0A, 0
 buffer times 64 db 0
 
 ; ================
 ; calls start here
 ; ================
 
 print_string:
   lodsb        ; grab a byte from SI
 
   or al, al  ; logical or AL by itself
   jz .done   ; if the result is zero, get out
 
   mov ah, 0x0E
   int 0x10      ; otherwise, print out the character!
 
   jmp print_string
 
 .done:
   ret
 
 get_string:
   xor cl, cl
 
 .loop:
   mov ah, 0
   int 0x16   ; wait for keypress
 
   cmp al, 0x08    ; backspace pressed?
   je .backspace   ; yes, handle it
 
   cmp al, 0x0D  ; enter pressed?
   je .done      ; yes, we're done
 
   cmp cl, 0x3F  ; 63 chars inputted?
   je .loop      ; yes, only let in backspace and enter
 
   mov ah, 0x0E
   int 0x10      ; print out character
 
   stosb  ; put character in buffer
   inc cl
   jmp .loop
 
 .backspace:
   cmp cl, 0	; beginning of string?
   je .loop	; yes, ignore the key
 
   dec di
   mov byte [di], 0	; delete character
   dec cl		; decrement counter as well
 
   mov ah, 0x0E
   mov al, 0x08
   int 10h		; backspace on the screen
 
   mov al, ' '
   int 10h		; blank character out
 
   mov al, 0x08
   int 10h		; backspace again
 
   jmp .loop	; go to the main loop
 
 .done:
   mov al, 0	; null terminator
   stosb
 
   mov ah, 0x0E
   mov al, 0x0D
   int 0x10
   mov al, 0x0A
   int 0x10		; newline
 
   ret
 
 strcmp:
 .loop:
   mov al, [si]   ; grab a byte from SI
   mov bl, [di]   ; grab a byte from DI
   cmp al, bl     ; are they equal?
   jne .notequal  ; nope, we're done.
 
   cmp al, 0  ; are both bytes (they were equal before) null?
   je .done   ; yes, we're done.
 
   inc di     ; increment DI
   inc si     ; increment SI
   jmp .loop  ; loop!
 
 .notequal:
   clc  ; not equal, clear the carry flag
   ret
 
 .done: 	
   stc  ; equal, set the carry flag
   ret
 print_hex_byte: 
   mov [.temp],al
   shr al,4
   cmp al,10
   sbb al,69h
   das
 
   mov ah,0Eh
   int 10h
 
   mov al,[.temp]
   ror al,4
   shr al,4
   cmp al,10
   sbb al,69h
   das
 
   mov ah,0Eh
   int 10h
 
   ret
 
 .temp db 0

inthandler:
   cmp ah,0
   je .ahzero
 
   ; ......
 
   mov si,msgbadah
   call print_string
   cli
   hlt
 
 .ahzero:
   mov si, interrupt
   call print_string
   mov al,0
   call print_hex_byte
   mov si,ENDL
   call print_string
   iret

install_interrupt_handler:
    cli
    pusha
    mov ax,0x80
    mov bx,4
    mul bx
    mov bx, ax
    mov dword [es:bx], inthandler
    add bx, 2
    mov [es:bx], cs
    popa
    sti
    ret

   times 510-($-$$) db 0
   dw 0AA55h ; some BIOSes require this signature