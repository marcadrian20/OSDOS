[org 0x7C00]          ; Bootloader starts at memory address 0x7C00
[BITS 16]
;*********************************************
;    BIOS Parameter Block (BPB) for FAT12
;*********************************************
bpb:
    db 0xEB, 0x3C, 0x90       ; Jump short loader, nop
    bpb_oem:                    db "OSDOS0.1"             ; OEM name (8 bytes)
    bpb_bytes_per_sector:       dw 512                    ; Bytes per sector
    bpb_sectors_per_cluster:    db 1                      ; Sectors per cluster
    bpb_reserved_sectors:       dw 1                      ; Reserved sectors
    bpb_fat_count:              db 2                      ; Number of FATs
    bpb_dir_entries_count:      dw 0x0E0                    ; Root directory entries
    bpb_total_sectors:          dw 2880                   ; Total sectors for 1.44MB floppy
    bpb_media_descriptor_type:  db 0xF0                   ; Media descriptor
    bpb_sectors_per_fat:        dw 9                      ; Sectors per FAT
    bpb_sectors_per_track:      dw 18                     ; Sectors per track
    bpb_heads:                  dw 2                      ; Number of heads
    bdb_hidden_sectors:         dd 0                      ; Hidden sectors
    bdb_large_sector_count:     dd 0                      ; Total sectors (large)
    ebr_drive_number:           db 0                      ; Drive number
    db 0                      ; Reserved
    ebr_signature:              db 0x29                   ; Extended boot signature
    ebr_volume_id:              dd 0x12345678             ; Volume serial number
    ebr_volume_label:           db "OSDOS      "          ; Volume label (11 bytes)
    ebr_FAT_TYPE:               db "FAT12   "             ; File system type (8 bytes)

;************************************************************************************************
;On  bootsector entry setup data and extra segs, print test string and jump to loading from disk*
;************************************************************************************************
start:
    xor ax, ax ;val 0x0000
    mov ds, ax 
    mov es, ax
    ;set segments to 0x0000 since we assume loading at segment:offset 0x0000:0x7C00. Same as 0x7C00:0x0000, same phy. linear mem addr
    mov si, TestString
    call printService

;*************************
; Load ROOT DIR from disk*
;*************************
load_root:
    pusha
    mov BYTE [SectorsToRead], 0x0E  ;citim 14 sectoare
    mov BYTE [CurrentSector],0x14   ;sectorul curent este 19
    mov ax, 0x1000                  ;;Hacky way to read entire ROOT DIR ENTRY 
    mov es, ax
    xor bx, bx
    call read_sector
    popa
;***********************
; Load kernel from disk*
;***********************
load_kernel:
    mov ah, 0; reset disk sys
    int 0x13 ;; 
    mov ax, 0x1000              ; Load kernel at memory address 0x1000
    mov es, ax                  ; Set extra segment to 0x1000
    mov ds, ax
    mov ss, ax
    xor bx, bx                  ; Offset = 0x0000
    ; pusha
    ; call find_kernel
    ; popa
    mov BYTE [CurrentSector],   0x22 ;sector 34, inceput data area
    mov BYTE [SectorsToRead], 1
    call read_sector
    jmp 0x1000:0x0000        ; Jump to kernel at 0x1000:0x0000
    jmp $
find_kernel:
    mov cx, 14  ;14 entries, reach 0 -> doesnt exist
    mov di, 0x0000
    loop:
        push cx
        mov cx, 11          ;comparam file name (format 8.3 specific FAT12/16)
        mov si, KernelName
        push di
        repe cmpsb
        pop di
        je  load_fat
        pop cx
        add di, 32         ;next dir entry (32 bytes)
        loop loop
        jmp load_error
    
    
load_fat:
    mov dx, WORD [di+0x001A]
    mov WORD [cluster], dx
    mov bx, 0x200
    mov cx, WORD [bpb_reserved_sectors]
    inc cx
    call read_sector
    ; mov BYTE []
load_image:
    mov ax, word [cluster]
    call cluster2LBA

cluster2LBA:
    sub ax,0x02
    mul word [bpb_sectors_per_cluster]
    ret
LBA2CHS:
    ;***************************************************************
    ;absolute sector 	= 	(LBA % sectors per track) + 1
    ;absolute head   	= 	(LBA / sectors per track) % number of heads
    ;absolute track 	= 	 LBA / (sectors per track * number of heads)
    ;******************************************************************
    xor dx, dx
    div WORD [bpb_sectors_per_track]
    inc dl
    mov byte [CurrentSector],dl
    ; xor dx, dx
    ; div word [bpb_heads]
    ; mov byte[head], dl
    ; mov byte[track], al
    ret
load_cluster:
    mov ax, [cluster]
    call cluster2LBA
    xor cx, cx
    mov cl,[bpb_sectors_per_cluster]
    call read_sector
    ret

read_sector:    
    pusha
    mov ah, 0x02                ; BIOS Read Sector function
    mov al, BYTE [SectorsToRead]; Number of sectors to read
    mov ch, 0                   ; Cylinder 0
    mov cl, BYTE [CurrentSector];2                   ; Sector 2 (kernel start)
    mov dh, 0                   ; Head 0
    ; mov dl, 0x80                ; Drive 0 (first disk)

    int 0x13                    ; Call BIOS interrupt
    jc load_error               ; Jump if the load fails
    popa
    ret
    ; popa
    ; clc
    

load_error:
    mov ah, 0x0E                ; BIOS teletype output
    mov bx, errString
    call printService           ; Display 'E' for error
    ; Display BIOS error code
    jmp $
           ; Infinite loop to halt execution

printService:
    lodsb ;load from ds:si in AL
    or al, al ;aflam daca am atins caracter null
    jz end
    mov ah, 0x0e ;teletype 
    int 0x10
    jmp printService
end:
    ret

;************
;Variables  *
;************
TestString:
    db "woah its booting", 13, 10, 0
errString:
    db "404 kernel", 13, 10, 0
CurrentSector db 0
SectorsToRead db 0
cluster db 0
KernelName: db "KERNEL  BIN"
;***********************************
;Kernel padding and boot signature *
;***********************************
times 510-($-$$) db 0 ; Fill remaining space with zeros
dw 0xAA55             ; Boot signature, alternative 0x55 0xAA 
