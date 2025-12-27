BITS 16

db "RPFS"        ; magic
dw 1             ; version
dw 16            ; max files
dw 3             ; file table LBA
dw 10            ; data start LBA
times 512-($-$$) db 0
