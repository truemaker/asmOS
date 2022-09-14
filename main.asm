org 0x7c00
bits 16

mov [BOOT_DISK], dl

cli
mov ax, 0  ; set up segments
mov ds, ax
mov es, ax
mov ss, ax     ; setup stack
mov bp, 0x7c00
mov sp, bp
sti

  call clear_screen
  mov si, msgLoad
  call print_string
  call load_next_sector
  mov si, ENDL
  call print_string
  mov si, success
  call print_string
  mov byte al, [BOOT_DISK]
  call print_hex_byte
  mov si, ENDL
  call print_string
  mov si, welcome
  call print_string
  call install_interrupt_handler
  mov ah, 0
  int 0x80
  call clear_screen
  mov si, msg_welcome
  call print_string
  mov si, logo
  call print_string
  call mainloop
clear_screen:
  mov ah, 0
  mov al, 0x3
  int 0x10
  ret
load_next_sector:
     mov bx, load
     mov dh, 2
     mov ah, 0x02
     mov al, dh 
     mov ch, 0x00
     mov dh, 0x00
     mov cl, 0x02
     mov dl, [BOOT_DISK]
     int 0x13
     jnc .load_next_sector_done
     mov si, failed
     call print_string
     cli
     hlt
 .load_next_sector_done:
     ret
mainloop:
  mov byte [EXTENDED_COM], 1
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
  call more_commands
  cmp byte [EXTENDED_COM], 1
  je mainloop
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

BOOT_DISK: db 0
EXTENDED_COM: db 0
failed: db "failed to read sector", 0
success: db "loaded next sector from disk ", 0
msgLoad: db "loading...", 0
 
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
   dw 0AA55h ; MBR Signature
 load: ; The next sector (the stuff under this label) will be loaded to this address
 welcome db 'Welcome to asmOS!', 0x0D, 0x0A, 0
 msg_helloworld db 'Hello asmOS!', 0x0D, 0x0A, 0
 badcommand db 'Bad command entered.', 0x0D, 0x0A, 0
 msgbadah db 'Bad value in ah.', 0x0D, 0x0A, 0
 interrupt db 'Interrupt ', 0
 ENDL db 0x0D, 0x0A, 0
 prompt db '>', 0
 cmd_hi db 'hi', 0
 cmd_help db 'help', 0
 cmd_exit db 'exit', 0
 cmd_logo db 'logo', 0
 cmd_reboot db 'reboot', 0
 cmd_dvga db 'dvga', 0
 cmd_clear db 'clear', 0
 msg_help db 'asmOS: Commands: hi, help, exit, logo, reboot, dvga, clear', 0x0D, 0x0A, 0
 msg_shutdown db 'Shutting down asmOS...', 0x0D, 0x0A, 0
 msg_welcome db "Welcome to", 0x0D, 0x0A, 0
 logo:
    db "         _____           ____  ____", 0x0D, 0x0A
    db "   /\   /      \      / |    |/    ", 0x0D, 0x0A
    db "  /  \  \____  |\    /| |    |\___ ", 0x0D, 0x0A
    db " /====\      \ | \  / | |    |    \", 0x0D, 0x0A
    db "/      \_____/ |  \/  | |____|____/", 0x0D, 0x0A,0
 buffer times 64 db 0

more_commands:
 mov si, buffer
 mov di, cmd_exit
 call strcmp
 jc .exit
 mov si, buffer
 mov di, cmd_logo
 call strcmp
 jc .logo
 mov si, buffer
 mov di, cmd_reboot
 call strcmp
 jc .reboot
 mov si, buffer
 mov di, cmd_dvga
 call strcmp
 jc .dvga
 mov si, buffer
 mov di, cmd_clear
 call strcmp
 jc .clear
 mov byte [EXTENDED_COM], 0
 ret
.exit:
 mov si, msg_shutdown
 call print_string
 mov ax, 0x1000
 mov ax, ss
 mov sp, 0xf000
 mov ax, 0x5307
 mov bx, 0x0001
 mov cx, 0x0003
 int 0x15
 cli
 hlt
 ret
.logo:
 mov si, logo
 call print_string
 ret
.reboot:
 jmp 0FFFFh:0 ; Go to the beginning of BIOS
.dvga:
 push es
 mov ax, 0xb800
 mov es, ax
 mov ax, 0x0f01
 mov [es:0], ax
 pop es
 ret
.clear:
 call clear_screen
 ret