clear
export PATH=/usr/local/i386elfgcc/bin:$PATH
rm -rf ../bin/
mkdir ../bin/

set -x

nasm -g -f bin ../src/boot/main_boot.asm -o ../bin/main_boot.bin
nasm -g -f bin ../src/boot/second_stage_boot.asm -o ../bin/second_stage_boot.bin
nasm -g -f elf ../src/boot/kernel32_loader.asm -o ../bin/kernel32_loader.o

i386-elf-gcc -g -m32 -ffreestanding -fno-pic -c ../src/kernel/main_kernel.c -o ../bin/main_kernel.o

i386-elf-gcc -g -m32 -ffreestanding -fno-pic -c ../include/kernel/standard/memory.c -o ../bin/memory.o

i386-elf-gcc -g -m32 -ffreestanding -fno-pic -c ../src/kernel/sys/x86_64/gdt.c -o ../bin/gdt64.o

# Create main32_kernel.elf for debugging purposes
i386-elf-ld -Ttext 0x5000 -o ../bin/main32_kernel.elf ../bin/kernel32_loader.o ../bin/main_kernel.o \
    ../bin/memory.o \
    ../bin/gdt64.o

# Create main32_kernel.bin from main32_kernel.elf
i386-elf-objcopy -O binary ../bin/main32_kernel.elf ../bin/main32_kernel.bin
# Create objdump.txt to aid in debugging
i386-elf-objdump -DxS ../bin/main32_kernel.elf >objdump.txt

cat ../bin/main_boot.bin ../bin/second_stage_boot.bin ../bin/main32_kernel.bin > os.bin

# Extend os.bin to a 2MiB disk image
truncate -s 2M os.bin

qemu-system-x86_64 -drive format=raw,file=os.bin
