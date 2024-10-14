    .data
a:  .word 0x41200000  # float 10.0f
b:  .word 0x40A00000  # float 5.0f

    .text
    .globl Fdiv

    # a0: float val, a1: exp of 2
# Function to perform floating-point division
Fdiv:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      a0, 8(sp)
    sw      a1, 4(sp)
    andi    t1, a0, 0x7f800000
    srli    t1, t1, 23
    sub     t0, t1, a1
    slli    t0, t0, 23
    andi    t1, a0, 0x800fffff
    or      a0, t1, t0