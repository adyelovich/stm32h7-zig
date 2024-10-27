ENTRY(reset_handler);

_estack = 0x20024000;

MEMORY {
    ITCMRAM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
    DTCMRAM (rwx) :  ORIGIN = 0x20000000, LENGTH = 128K
    AXIRAM (rwx) : ORIGIN = 0x24000000, LENGTH = 1M
    AHBRAM (rwx) : ORIGIN = 0x30000000, LENGTH = 128K
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 2M
}

SECTIONS {
    /* location counter is currently 0 */
    .vtable : {
        . = 0;
        /* put everything in all .vtable sections here and do not optimize
           them out */
        KEEP(*(.vtable))
        . = ALIGN(4); /* now align the location to a word */
    } >FLASH /* this goes at the base of FLASH */

    /* gcc outputs .text, .bss, .data, .rodata sections */
    .text : {
        . = ALIGN(4);
        KEEP(*(.text))
        . = ALIGN(4);
    } >FLASH

    .rodata : {
        . = ALIGN(4);
        *(.text)
        . = ALIGN(4);
    } >FLASH

    _sidata = LOADADDR(.data);

    .data : {
        . = ALIGN(4);
        *(.data)
        . = ALIGN(4);
        _edata = .;
    } >AXIRAM AT> FLASH

    . = ALIGN(4);
    .bss : {
        _sbss = .;
        __bss_start__ = .;
        *(.bss)
        . = ALIGN(4);
        _ebss = .;
        __bss_end__ = .;
    } >AXIRAM
}
