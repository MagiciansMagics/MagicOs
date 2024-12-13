disk_read:
    mov ah, 0x02
    mov dl, 0x80
    int 0x13
    
    jc disk_read_error

    ret

disk_read_error:
    mov ah, 0x0e
    mov al, 'E'
    int 0x10

    jmp $