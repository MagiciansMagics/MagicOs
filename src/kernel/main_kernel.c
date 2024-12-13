#include "../../include/kernel/standard/memory.h"
#include "../../include/kernel/sys/x86_64/gdt.h"

void main()
{
    setup_gdt();
    for(;;);
}