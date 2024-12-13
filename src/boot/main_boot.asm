[bits 16]
[org 0x7c00]

jmp _start

_start:
    xor ax, ax        ; AX = 0
    mov ds, ax        ; DS = 0
    mov bx, 0x7c00

    cli               ; Turn off interrupts for SS:SP update
                      ; to avoid a problem with buggy 8088 CPUs
    mov ss, ax        ; SS = 0x0000
    mov sp, bx        ; SP = 0x7c00
                      ; We'll set the stack starting just below
                      ; where the bootloader is at 0x0:0x7c00. The
                      ; stack can be placed anywhere in usable and
                      ; unused RAM.
    sti

    mov ah, 0x02       ; BIOS interrupt function: Read sector(s)
    mov al, 0x04       ; Number of sectors to read
    mov ch, 0x00       ; Cylinder number
    mov cl, 0x02       ; Starting sector number (sector 2)
    mov dh, 0x00       ; Head number
    mov dl, 0x80       ; Drive number (0x00 = first floppy, 0x80 = first hard disk)
    mov bx, 0x7e00     ; ES:BX = Buffer address to load the sectors
    int 0x13           ; Call BIOS disk interrupt

    jc disk_error      ; Jump if carry flag is set (error occurred)

    mov ah, 0x02       ; BIOS interrupt function: Read sector(s)
    mov al, 0x01       ; Number of sectors to read
    mov ch, 0x00       ; Cylinder number
    mov cl, 0x06       ; Starting sector number (sector 2)
    mov dh, 0x00       ; Head number
    mov dl, 0x80       ; Drive number (0x00 = first floppy, 0x80 = first hard disk)
    mov bx, 0x5000     ; ES:BX = Buffer address to load the sectors
    int 0x13           ; Call BIOS disk interrupt

    jc disk_error      ; Jump if carry flag is set (error occurred)

    jmp 0x7e00         ; Jump to the loaded code at 0x7e00

    jmp $

disk_error:
    mov ah, 0x0e
    mov al, 'F'
    int 0x10

    jmp $

times 510 - ($ - $$) db 0
dw 0xAA55