[bits 16]
[org 0x7e00]

jmp _start

%include "../include/boot/set_vbe_mode.asm"
%include "../include/boot/gdt32.asm"

_start:
	call vbe_mode_start

	cli
	lgdt [gdt_descriptor32]  		; Load Global Descriptor Table
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG32:entry32        	; Far jump to 32-bit entry point

	jmp $

[bits 32]

entry32:
	mov ax, DATA_SEG32
    mov ds, ax              ; Load data segment selector into DS
    mov es, ax              ; Load data segment selector into ES
    mov fs, ax              ; Load data segment selector into FS
    mov gs, ax              ; Load data segment selector into GS
    mov ss, ax              ; Load data segment selector into SS

    mov esp, 0x3000         ; Initialize stack pointer

	mov esi, mode_info_block
    mov edi, 0x9000
    mov ecx, 64
    rep movsd

	jmp 0x5000

	jmp $

[bits 16]

times 1024-($-$$) db 0

vbe_info_block:		; 'Sector' 2
	.vbe_signature: db 'VBE2'
	.vbe_version: dw 0          ; Should be 0300h? BCD value
	.oem_string_pointer: dd 0 
	.capabilities: dd 0
	.video_mode_pointer: dd 0
	.total_memory: dw 0
	.oem_software_rev: dw 0
	.oem_vendor_name_pointer: dd 0
	.oem_product_name_pointer: dd 0
	.oem_product_revision_pointer: dd 0
	.reserved: times 222 db 0
	.oem_data: times 256 db 0

mode_info_block:	; 'Sector' 3
    ;; Mandatory info for all VBE revisions
	.mode_attributes: dw 0
	.window_a_attributes: db 0
	.window_b_attributes: db 0
	.window_granularity: dw 0
	.window_size: dw 0
	.window_a_segment: dw 0
	.window_b_segment: dw 0
	.window_function_pointer: dd 0
	.bytes_per_scanline: dw 0

    ;; Mandatory info for VBE 1.2 and above
	.x_resolution: dw 0
	.y_resolution: dw 0
	.x_charsize: db 0
	.y_charsize: db 0
	.number_of_planes: db 0
	.bits_per_pixel: db 0               ; 15
	.number_of_banks: db 0
	.memory_model: db 0
	.bank_size: db 0
	.number_of_image_pages: db 0
	.reserved1: db 1

    ;; Direct color fields (required for direct/6 and YUV/7 memory models)
	.red_mask_size: db 0
	.red_field_position: db 0
	.green_mask_size: db 0
	.green_field_position: db 0
	.blue_mask_size: db 0
	.blue_field_position: db 0
	.reserved_mask_size: db 0
	.reserved_field_position: db 0
	.direct_color_mode_info: db 0

    ;; Mandatory info for VBE 2.0 and above
	.physical_base_pointer: dd 0     ; Physical address for flat memory frame buffer
	.reserved2: dd 0
	.reserved3: dw 0

    ;; Mandatory info for VBE 3.0 and above
	.linear_bytes_per_scan_line: dw 0
    .bank_number_of_image_pages: db 0
    .linear_number_of_image_pages: db 0
    .linear_red_mask_size: db 0
    .linear_red_field_position: db 0
    .linear_green_mask_size: db 0
    .linear_green_field_position: db 0
    .linear_blue_mask_size: db 0
    .linear_blue_field_position: db 0
    .linear_reserved_mask_size: db 0
    .linear_reserved_field_position: db 0
    .max_pixel_clock: dd 0

    .reserved4: times 190 db 0      ; Remainder of mode info block

times 2048 - ($ - $$) db 0
