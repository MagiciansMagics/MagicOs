#include <stdint.h>
#include "../../../../include/kernel/standard/memory.h"
#include "../../../../include/kernel/sys/x86_64/gdt.h"

struct gdt_entry_bits gdt [1+4+1];
struct tss_table tss;

void load_gdtr(struct gdtr GDTR)
{
    asm("lgdt %0\n\t"
        /* Reload segment registers */
        "mov %1, %%ds\n\t"
        "mov %1, %%es\n\t"
        "mov %1, %%fs\n\t"
        "mov %1, %%gs\n\t"
        "mov %1, %%ss\n\t"
        /* Perform far return to set CS */
        "pushl %2\n\t"
        "pushl $1f\n\t"
        "retf\n\t"
        "1:"
        :
        : "m"(GDTR),
          "a"(0x10) /* Data selector */
        , "i"(0x08) /* Code selector */
        : "memory");
}

void load_tss()
{
    asm("ltr %0" :: "r"(0x2b));
}

void write_tss(struct gdt_entry_bits *g)
{
   // Firstly, let's compute the base and limit of our entry into the GDT.
   uint32_t base = (uint32_t) &tss;
   uint32_t limit = sizeof(tss)-1; // TSS limit is 1 less than the actual size
 
   // Now, add our TSS descriptor's address to the GDT.
   g->limit_low=limit&0xFFFF;
   g->base_low=base&0xFFFFFF; //isolate bottom 24 bits
   g->accessed=1; //This indicates it's a TSS and not a LDT. This is a changed meaning
   g->read_write=0; //This indicates if the TSS is busy or not. 0 for not busy
   g->conforming_expand_down=0; //always 0 for TSS
   g->code=1; //For TSS this is 1 for 32bit usage, or 0 for 16bit.
   g->always_1=0; //indicate it is a TSS
   g->DPL=3; //same meaning
   g->present=1; //same meaning
   g->limit_high=(limit&0xF0000)>>16; //isolate top nibble
   g->available=0;
   g->always_0=0; //same thing
   g->big=0; //should leave zero according to manuals. No effect
   g->gran=0; //so that our computed GDT limit is in bytes, not pages
   g->base_high=(base&0xFF000000)>>24; //isolate top byte.
 
   // Ensure the TSS is initially zero'd.
   memory_set((uint8_t*)&tss, 0, sizeof(tss));
 
   tss.ss0  = 0x10;  // Set the kernel stack segment. (DATA)
   tss.esp0 = 0; // Set the kernel stack pointer.
   tss.iomap_base = sizeof(tss); // Set iomap_base to one more than the limit to disable IO bitmap
   //note that CS is loaded from the IDT entry and should be the regular kernel code segment
}

void set_kernel_stack(uint32_t stack) //this will update the ESP0 stack used when an interrupt occurs
{
   tss.esp0 = stack;
}

void setup_gdt() 
{
    struct gdtr gdt_descriptor;

    /* ring 0 GDT entries */

    struct gdt_entry_bits *code;
    struct gdt_entry_bits *data;
    
    code=(void*)&gdt[1]; //gdt is a static array of gdt_entry_bits or equivalent (defined in ../cpu/gdt.h)
    data=(void*)&gdt[2];
    code->limit_low=0xFFFF;
    code->base_low=0;
    code->accessed=0;
    code->read_write=1; //make it readable for code segments
    code->conforming_expand_down=0; //don't worry about this.. 
    code->code=1; //this is to signal it's a code segment
    code->always_1=1;
    code->DPL=0; //set it to ring 0
    code->present=1;
    code->limit_high=0xF;
    code->available=1;
    code->always_0=0;
    code->big=1; //signal it's 32 bits
    code->gran=1; //use 4k page addressing
    code->base_high=0;

    *data=*code; //copy it all over, cause most of it is the same
    data->code=0; //signal it's not code; so it's data.

    /* ring 3 GDT entries */

    struct gdt_entry_bits *code_user; //user-mode gdt entries
    struct gdt_entry_bits *data_user;

    code_user=(void*)&gdt[3];
    data_user=(void*)&gdt[4];
    *code_user = *code; //same as kernel code
    code_user->DPL=3; //set it to ring 3

    *data_user = *data; //same as kernel data
    data_user->DPL=3; //set it to ring 3

    /* TSS setup */

    struct gdt_entry_bits *tss_entry;
    tss_entry=(void*)&gdt[5];

    write_tss(tss_entry);

    gdt_descriptor.base = (uint32_t)&gdt;
    gdt_descriptor.limit = sizeof(gdt)-1;


    load_gdtr(gdt_descriptor);
    load_tss();
}
