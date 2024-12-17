;*************************
; Load ROOT DIR from disk*
;*************************
load_root:
    ;Compute 32*root dir entries/bytes per sector
    xor cx, cx
    xor dx, dx
    mov ax, 0x20                    ;32Byte dir entry
    mul WORD [bpb_dir_entries_count];total size of root dir
    div WORD [bpb_bytes_per_sector] ;sectors used by the dir
    xchg ax, cx
    ;Compute LBA address of the root and store into ax
    ;must be LBA2CHS converted
    ;ig some bioses can do the LBA2CHS automatically but its a bit too bothersome to worry bout that rn
    mov al, byte[bpb_fat_count];
    mul WORD [bpb_sectors_per_fat];
    add AX, word [bpb_reserved_sectors]

    ;Where the first data cluster begins:
    ;root dir size*(size of fats+bootloader sector+reserved sectors)
    mov word [DataSectorBegin], ax  ;size of root
    add word [DataSectorBegin], cx

    call LBA2CHS
    
    mov bx, RootOffset   ;try to load at 0x500
    mov dh, cl
    ; mov  byte [SectorsToRead], cl;     ;load num of sectors
    call read_sector

    mov cx, [bpb_dir_entries_count]
    mov di, RootOffset
    ; mov si, 0x500###
    ; call printService #debug lines
    .loop:
        push cx
        mov cx, 11          ;comparam file name (format 8.3 specific FAT12/16)
        mov si, KernelName
        push di
        rep cmpsb
        pop di
        je  load_fat
        pop cx
        add di, 32         ;next dir entry (32 bytes)
        loop .loop
        jmp load_error
;*****************************
;TODO BLOCK                 **
;*****************************
;FIX FAT loading and image loading. Mask MSB 4 bits on cluster if odd.
;If is even shift >>4 to discard lsb 4 bits of the next cluster 
;
    
load_fat:
    mov dx, WORD [di+0x001A]    ;add 26 bytes to get first cluster from root dir entry
    mov WORD [cluster], dx


    ;compute num of sect used by FATS   (num of fats * sectors per fats)
    xor ax, ax
    ;initialize track and head to 0
    mov byte [CurrentTrack], al
    mov byte [CurrentHead], al
    mov al, 1 ;;we read one Fat to stay withing boundaries
    mul word [bpb_sectors_per_fat]
    ; mov byte[SectorsToRead], al ;store num of sectors to read for all FATS
    mov dh,al
    ;;Load fat into memory
    mov bx, RootOffset   ;we load at offset 0x500
    mov cx, WORD [bpb_reserved_sectors]
    inc cx
    mov byte [CurrentSector], cl
    call read_sector

    mov bx, ImageOffset  ;adresa unde vrem sa incarcam primu cluster. #TODO modularizeaza 
    push bx
    ; mov BYTE []
load_image:
    mov ax, word [cluster]
    call cluster2LBA
    call LBA2CHS                ;am convertit din cluster->LBA->CHS
    
    xor dx, dx
    mov dh, byte [bpb_sectors_per_cluster]
    ; mov byte [SectorsToRead], dh    ;citim atatia sectori cati avem per cluster ca sa nu intram din greseala in urmatorul cluster
    pop bx
    call read_sector
    add bx, 0x200   ;advance the adress by 512 bytes, meaning 1 sector has been read into RAM
    push bx

    ;calculam noul cluster..
    ;in primul rand va trebui sa vedem daca este un cluster de pozitie para sau impara..daca estee par facem masca la biti, altfel scapam de cei mai putin semnificativi 4 biti ca sa nu intram in urmatorul cluster
    ;#TODO revamp loading images
    mov ax, word [cluster]

    mov cx, ax
    mov dx, ax
    shr dx, 0x01    ;impartirea prin shitfare ar trebui sa fie mai rapida
    add cx, dx      ;suma pentru 3/2
    mov bx, RootOffset   ;locatia pentru FAT in memorie
    add bx, cx      ;calculam indexul urmator
    mov dx, word [bx]   ;citim 2 bytes din FAT
    test ax, 0x01
    jnz load_oddCluster 

load_evenCluster:
    and dx, 0000111111111111b
    jmp done_loading
load_oddCluster:
    shr dx, 0x04
done_loading:
    mov word [cluster], dx
    cmp dx, 0x0FF0          ;sa vedem daca ajungem la EOF #TODO adauga si pentru bad sector
    jb load_image
load_root_end:
    pop bx
    pop bx
    ret
cluster2LBA:
    sub ax,0x02             ;adjust for cluster number(begins from the 2nd cluster)
    xor cx, cx
    mov cl, byte [bpb_sectors_per_cluster]
    mul cx
    add ax, word[DataSectorBegin]
    ret
LBA2CHS:
    ;***************************************************************
    ;absolute sector 	= 	(LBA % sectors per track) + 1
    ;absolute head   	= 	(LBA / sectors per track) % number of heads
    ;absolute track 	= 	 LBA / (sectors per track * number of heads)
    ;******************************************************************
    xor dx, dx                      ;prepare dx for ops
    div WORD [bpb_sectors_per_track]
    inc dl                          ;adjust for sector indexing from 0 
    mov byte [CurrentSector],dl
    xor dx, dx
    div word [bpb_heads]
    mov byte[CurrentHead], dl
    mov byte[CurrentTrack], al
    ret
    

read_sector:    
    push dx
    mov ah, 0x02                ; BIOS Read Sector function
    mov al, dh
    ; mov al, BYTE [SectorsToRead]; Number of sectors to read
    mov ch, BYTE [CurrentTrack]                   ; Cylinder 0
    mov cl, BYTE [CurrentSector];2                   ; Sector 2 (kernel start)
    mov dh, BYTE [CurrentHead]                  ; Head 0
    mov dl, 0x0                ; Drive 0 (first disk)

    int 0x13                    ; Call BIOS interrupt
    jc load_error               ; Jump if the load fails
    pop dx
    cmp dh,al
    jne load_error
    ret
    ; popa
    ; clc
    

load_error:
    mov ah, 0x0E                ; BIOS teletype output
    mov si, errString
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
