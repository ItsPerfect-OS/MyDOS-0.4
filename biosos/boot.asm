BITS 16
ORG 0x7C00

start:
    mov ah, 0x0E
    mov al, '1'
    int 0x10

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov al, '2'
    int 0x10

    mov si, bootmsg
.print:
    lodsb
    or al, al
    jz .after_print
    mov ah, 0x0E
    int 0x10
    jmp .print

.after_print:
    mov al, '3'
    int 0x10

    ; ================= LOAD STAGE2 =================
    mov ah, 0x02        ; BIOS read sectors
    mov al, 7           ; 🔥 LOAD 7 SECTORS (RPFS)
    mov ch, 0
    mov cl, 2           ; sector 2
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x8000
    int 0x13
    jc disk_error

    ; ================= JUMP TO STAGE2 =================
    jmp 0x0000:0x8000

disk_error:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    jmp $

bootmsg db " BOOT OK ", 0

times 510-($-$$) db 0
dw 0xAA55
