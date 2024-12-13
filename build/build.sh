clear
export PATH=/usr/local/i386elfgcc/bin:$PATH
rm -rf ../bin/
mkdir ../bin/

nasm -f bin ../src/boot/main_boot.asm -o ../bin/main_boot.bin
nasm -f bin ../src/boot/second_stage_boot.asm -o ../bin/second_stage_boot.bin
nasm -f elf ../src/boot/kernel32_loader.asm -o ../bin/kernel32_loader.o

i386-elf-gcc -m32 -ffreestanding -nostdinc -fno-pic -c ../src/kernel/main_kernel.c -o ../bin/main_kernel.o

i386-elf-gcc -m32 -ffreestanding -nostdinc -fno-pic -c ../include/kernel/standard/memory.c -o ../bin/memory.o

i386-elf-gcc -m32 -ffreestanding -nostdinc -fno-pic -c ../src/kernel/sys/x86_64/gdt.c -o ../bin/gdt64.o

i386-elf-ld -Ttext 0x5000 -o ../bin/main32_kernel.bin ../bin/kernel32_loader.o ../bin/main_kernel.o \
    ../bin/memory.o \
    ../bin/gdt64.o \
    --oformat binary

cat ../bin/main_boot.bin ../bin/second_stage_boot.bin ../bin/main32_kernel.bin > os.bin

qemu-system-x86_64 -drive format=raw,file=os.bin