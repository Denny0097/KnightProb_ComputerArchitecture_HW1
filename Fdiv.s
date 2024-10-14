
    li      a0, 0x3f000000   #0.5
    li      a1, 3
    
    # a0: float val, a1: exp of 2
    # Function to perform floating-point division
    .text
    .globl Fdiv
Fdiv:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      a0, 8(sp)
    sw      a1, 4(sp)
    
    li      t3, 0x7f800000
    and     t1, a0, t3
    srli    t1, t1, 23
    bge     t1, 0x80, Exp_post  # check if exp of float num is postive

    sub     t0, t1, a1
    slli    t0, t0, 23
    
    li      t3, 0x800fffff
    and     t1, a0, t3
    or      a0, t1, t0
    lw      ra, 12(sp)
    lw      a1, 4(sp)
    addi    sp, sp, 16
    ret

Exp_post:
    add     t0, t1, a1
    slli    t0, t0, 23
    
    li      t3, 0x800fffff
    and     t1, a0, t3
    or      a0, t1, t0
    lw      ra, 12(sp)
    lw      a1, 4(sp)
    addi    sp, sp, 16
    ret

