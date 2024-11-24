    .global reset_handler
    .global get_CONTROL_REG

    .section .vtable,"a",%progbits
    .type nvic_vectors, %object
nvic_vectors:
    .word _estack
    .word reset_handler
    .word nmi_handler
    .word hard_fault_handler
    .word mem_mng_handler
    .word bus_fault_handler
    .word usage_handler
    .rept 2
    .word 0
    .endr

    .balign 1024                ;@ just in case NVIC needs alignment

    .section .text
    
    .thumb_func
reset_handler:
    movw r0, #0x200
    movt r0, #0x2000
    mov sp, r0
    sub sp, #4

    bl tester
    
    bl main
    bx lr

    .thumb_func
tester:
    push {r7, lr}
    mov r0, #5
    mrs r0, CONTROL
    
    pop {r7, pc}

    .thumb_func
get_CONTROL_REG:
    mrs r0, CONTROL
    bx lr
    
    .thumb_func
nmi_handler:
    b nmi_handler

    .thumb_func
hard_fault_handler:
    b hard_fault_handler

    .thumb_func
mem_mng_handler:
    b mem_mng_handler

    .thumb_func
bus_fault_handler:
    b bus_fault_handler

    .thumb_func
usage_handler:
    b usage_handler
