[org 0x0000]
[BITS 16]

;*************************************
;On entry print cursor and setup regs*
;*************************************
start:
    mov ax,0x1000
    ; mov ds, ax
    ; mov es, ax
    ; mov ss, ax
    ; mov di, 0x0000;
    ; call clear_screen
    mov si, KernelTestString
    call print_Service
    call print_newline
    call print_cursor
;******************************************************

;*************************************************
;All the magic happens down here in the main loop*
;*************************************************
main_loop:
    call read_key
    
    mov si, string_input_buffer
    call print_newline
    mov si, string_input_buffer
    ; call print_Service
    ; call print_newline
    ; call clear_screen
    call CMD_parser
    call print_cursor
    jmp main_loop
;******************************************************


;*********************
;Services and helpers*
;*********************
print_Service:
    lodsb ;load from ds:si in AL
    or al, al ;aflam daca am atins caracter null
    jz end
    mov ah, 0x0e ;teletype 
    int 0x10
    jmp print_Service
end:
    ret
;******************************************************
read_key:
    mov di, string_input_buffer;Set SI segment to the key buff
    xor cx, cx              ;then rst the input length counter value
    cld
    key_read_loop:
        mov ah, 0x0        ;BIOS key in. ~scan in blocking mode~
        int 0x16            ;call for key interrupt/ wait for key press
        cmp ah, 0x1C;al,0x0D        ;Enter key. BIOS returneaza CR adica 0x0D
        je done_input       ;end on enter
        cmp ah, 0x0E        ;Backspace scancode
        je handle_backspace
        stosb               ;store char in buff
        inc cx
        mov ah, 0x0E        ;Output the read char    
        int 0x10
        cmp cx, 128         ;prevenim un buffer overflow
        je done_input       
        jmp key_read_loop
    handle_backspace:
        test cx, cx
        je key_read_loop
        dec di              ;daca dam de backspace mutam pointerul de buffer in spate
        dec cx              ;and we decrease
        ; mov ah, 0x0E
        ; mov al, 0x08        ;print out the backspace
        ; int 0x10
        ; mov al,' '          ;then space to blackout the backspace
        ; int 0x10
        ; mov al, 0x08        ;then the backsapce to move the cursor back
        ; int 0x10
        push si
        mov si, backspace
        call print_Service
        pop si
        jmp key_read_loop
    done_input: 
        mov byte [di], 0    ;adaugam terminatorul de sir
        ret
;******************************************************
print_newline:
    mov si, newline
    call print_Service
    ret
;******************************************************
print_cursor:
    mov si, cursor
    call print_Service
    ret
;******************************************************
read_disk:
ret
;******************************************************
clear_screen:   
    pusha
    mov ah, 0x00
    mov al, 0x03   ;;;cea mai lenesa metoda, resetez video mode-ul
    int 0x10
    popa
    ret
;******************************************************
CMD_parser:
    ; pusha
    mov di, string_input_buffer
    cls_command:
        mov si, cls_cmd
        call str_cmp                        ;
        jne help_command
        call clear_screen
        ret
    help_command:
        mov di, string_input_buffer
        mov si, help_cmd
        call str_cmp
        jne version_command
        mov si, help_txt
        call print_Service
        ret
    version_command:
        mov di, string_input_buffer
        mov si, ver_cmd
        call str_cmp
        jne end
        mov si, version_id
        call print_Service
        ret
    ; popa
    ; CLI_color_change
;******************************************************

;**************************************************
;strcmp returns 0 on not equal strings, 1 on equal*;;that would be the idea, i should push the values to stack if i want it like that. 
;**************************************************                                                             ;right now i set flags
str_cmp:
    cld
    loop:
        lodsb           ;load into AL from SI
        scasb           ;scan the byte from AL and compare with DI
        jne mismatch    ;on match or mismatch return ####TODO find better way to return.  |POP bx, jne bx doesnt work
        test al, al     ;check for NULL
        je match
        jmp loop        
    match:
        ret
    mismatch:
        ret
;******************************************************

;************
;Variables  *
;************
string_input_buffer db 128, 0 ;;max 128 caractere + terminator sir
KernelTestString:
    db "Succesfully booted the kernel", 13, 10, 0
cursor: db "<OSDOS:/>", 0
cls_cmd db "cls", 0
help_cmd db "help", 0
help_txt db "Supported commands are: help, cls, ver",13,10,0
unknown_cmd db "Aintcha mistaking the command?",13,10,0
ver_cmd db "ver",0
version_id db "OSDOS V0.01",13,10,"Marc made <3",13,10,0
backspace: db 8 ,' ', 8, 0
newline: db 13, 10, 0
;**************************
;Kernel alignment/padding *
;**************************
times 512-($-$$) db 0
