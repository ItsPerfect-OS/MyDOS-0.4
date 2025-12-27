BITS 16
ORG 0x8000

; ================= INIT =================

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    sti

    mov byte [current_dir], 0

    mov si, banner
    call print

shell:
    mov si, prompt
    call print
    call read_line
    call handle_cmd
    jmp shell

; ================= PRINT =================

print:
.next:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    ret

; ================= INPUT =================

read_line:
    mov di, cmd_buffer
.loop:
    mov ah, 0
    int 0x16
    cmp al, 13
    je .done
    cmp al, 8
    jne .store
    cmp di, cmd_buffer
    je .loop
    dec di
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .loop
.store:
    stosb
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    mov al, 0
    stosb
    ret

; ================= STRING =================

strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    cmp al, 0
    je .yes
    inc si
    inc di
    jmp .loop
.no:
    mov ax, 1
    ret
.yes:
    xor ax, ax
    ret

startswith:
.loop:
    mov al, [di]
    cmp al, 0
    je .yes
    cmp al, [si]
    jne .no
    inc si
    inc di
    jmp .loop
.no:
    mov ax, 1
    ret
.yes:
    xor ax, ax
    ret

; ================= COMMAND DISPATCH =================

handle_cmd:
    mov si, cmd_buffer
    cmp byte [si], 0
    je .ret

    mov di, cmd_help
    call strcmp
    jz cmd_help_fn

    mov di, cmd_cls
    call strcmp
    jz cmd_cls_fn

    mov di, cmd_ver
    call strcmp
    jz cmd_ver_fn

    mov di, cmd_fs
    call strcmp
    jz cmd_fs_fn

    mov di, cmd_format
    call strcmp
    jz cmd_format_fn

    mov di, cmd_dir
    call strcmp
    jz cmd_dir_fn

    mov di, cmd_shd
    call strcmp
    jz cmd_shd_fn

    mov di, cmd_reboot
    call strcmp
    jz cmd_reboot_fn

    mov di, cmd_echo
    call startswith
    jz cmd_echo_fn

    mov di, cmd_mkdir
    call startswith
    jz cmd_mkdir_fn

    mov di, cmd_cd
    call startswith
    jz cmd_cd_fn

    mov si, badcmd
    call print
.ret:
    ret

; ================= COMMANDS =================

cmd_help_fn:
    mov si, helpmsg
    call print
    ret

cmd_cls_fn:
    call clear_screen
    ret

cmd_ver_fn:
    mov si, vermsg
    call print
    ret

cmd_fs_fn:
    mov si, fsmsg
    call print
    ret

cmd_shd_fn:
    mov si, shdmsg
    call print
    ret

cmd_echo_fn:
    mov si, cmd_buffer
    add si, 5
    call print
    ret

cmd_reboot_fn:
    int 0x19

; ================= FORMAT =================

cmd_format_fn:
    mov si, fmtmsg
    call print

    mov cl, 3
    mov cx, 7
.clear:
    mov bx, zerobuf
    call write_sector
    inc cl
    loop .clear

    mov byte [current_dir], 0
    ret

; ================= DIR =================

cmd_dir_fn:
    mov bx, 0x9000
    mov cl, 3
    call read_sector

    mov si, bx
    mov cx, 16
    mov dl, [current_dir]

.next:
    cmp byte [si+16], 1
    jb .skip
    cmp byte [si+17], dl
    jne .skip
    push si
    call print
    mov si, newline
    call print
    pop si
.skip:
    add si, 32
    loop .next
    ret

; ================= MKDIR =================

cmd_mkdir_fn:
    mov bx, 0x9000
    mov cl, 3
    call read_sector

    mov si, bx
    mov cx, 16
.find:
    cmp byte [si+16], 0
    je .create
    add si, 32
    loop .find
    ret

.create:
    mov byte [si+16], 3
    mov al, [current_dir]
    mov [si+17], al

    mov di, si
    mov si, cmd_buffer
    add si, 6
    mov cx, 12
.copy:
    lodsb
    stosb
    loop .copy

    mov bx, 0x9000
    mov cl, 3
    call write_sector
    ret

; ================= CD =================

cmd_cd_fn:
    mov bx, 0x9000
    mov cl, 3
    call read_sector

    mov si, bx
    mov cx, 16
    mov dl, [current_dir]

.next:
    cmp byte [si+16], 3
    jne .skip
    cmp byte [si+17], dl
    jne .skip

    push si
    mov di, si
    mov si, cmd_buffer
    add si, 3
    call strcmp
    pop si
    jz .found

.skip:
    add si, 32
    loop .next
    ret

.found:
    mov ax, si
    sub ax, 0x9000
    mov bl, 32
    div bl
    mov [current_dir], al
    ret

; ================= DISK =================

read_sector:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dh, 0
    mov dl, 0x80
    int 0x13
    ret

write_sector:
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov dh, 0
    mov dl, 0x80
    int 0x13
    ret

; ================= VIDEO =================

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov ax, 0x0200
    xor bx, bx
    xor dx, dx
    int 0x10
    ret

; ================= DATA =================

banner  db 13,10,"MyDOS + RPFS v0.2",13,10,0
prompt  db 13,10,"> ",0
vermsg  db 13,10,"Version 0.4",13,10,0
fsmsg   db 13,10,"Filesystem: RPFS v0.2",13,10,0
shdmsg  db 13,10,"/",13,10,0
fmtmsg  db 13,10,"Formatting RPFS...",13,10,0
badcmd  db 13,10,"Bad command",13,10,0
newline db 13,10,0

helpmsg db 13,10,\
"help cls ver fs format",13,10,\
"dir mkdir cd pwd echo",13,10,\
"reboot",13,10,0

cmd_help   db "help",0
cmd_cls    db "cls",0
cmd_ver    db "ver",0
cmd_fs     db "fs",0
cmd_format db "format",0
cmd_dir    db "dir",0
cmd_shd    db "shd",0
cmd_echo   db "echo ",0
cmd_mkdir  db "mkdir ",0
cmd_cd     db "cd ",0
cmd_reboot db "reboot",0

current_dir db 0
cmd_buffer times 64 db 0
zerobuf times 512 db 0
