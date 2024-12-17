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

    mov si, TestString
    call printService
    ; call load_kernel
    MOV     AX, 0x7000
    MOV     SS, AX
    MOV     BP, 0x8000
    MOV     SP, BP

    ; mov ax, 0x1000              ; Load kernel at memory address 0x1000
    ; mov es, ax                  ; Set extra segment to 0x1000
    ; mov ds, ax

    call load_root
    ; mov si, ImageOffset
    ; call printService
    jmp 0x0000:0x1000
    jmp $

    
%INCLUDE "../boot/functions.asm"
;************
;Variables  *
;************
TestString:
    db "woah its booting", 13, 10, 0
errString:
    db "404 kernel", 13, 10, 0
CurrentSector db 0
CurrentHead db 0
CurrentTrack    db 0
SectorsToRead db 0
DataSectorBegin dw 0
cluster dw 0
KernelName: db "KERNEL  BIN";DB "HELLO   TXT",0 ;
RootOffset equ 0x0500
ImageOffset equ 0x1000
;***********************************
;Kernel padding and boot signature *
;***********************************
times 510-($-$$) db 0 ; Fill remaining space with zeros
dw 0xAA55             ; Boot signature, alternative 0x55 0xAA 
