CODE_SEG32 equ gdt_code32 - gdt_start32
DATA_SEG32 equ gdt_data32 - gdt_start32

gdt_start32:
gdt_null32:
	dd 0x00
	dd 0x00
gdt_code32:
	dw 0xFFFF
	dw 0x00
	db 0x00
	db 10011010b
	db 11001111b
	db 0x00
gdt_data32:
	dw 0xFFFF
	dw 0x00
	db 0x00
	db 10010010b
	db 11001111b
	db 0x00
gdt_end32:
gdt_descriptor32:
	dw gdt_end32 - gdt_start32 - 1
	dd gdt_start32