    .text
    .globl fp32_to_bf16
fp32_to_bf16:   # return value put in a1 
    mv      fp, sp
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      fp, 8(sp)
    sw      a0, 4(sp)       #store a0 argument(fp32 number)

    # check NaN(((u.i & 0x7fffffff) > 0x7f800000))
    li      t0, 0x7FFFFFFF
    and     t1, a0, t0
    li      t0, 0x7f800000
    bgt     t1, t0, IsNaN # if t1 > 01 is NaN
    
    # not Nan
    li      t0, 0x7fff
    srli    t6, a0, 0x10
    andi    t1, t6, 1
    add     t0, t0, t1
    add     t0, a0, t0
    srli    a1, t0, 0x10
    addi    sp, sp, 16      
    ret
IsNaN:
    srli    t0, a0, 0x10
    ori     a0, t0, 64
    addi    sp, sp, 16   
    ret
    
    
    .text
    .globl bf16_to_fp32
bf16_to_fp32:
    mv      fp, sp
    addi    sp, sp, -16          # Save space on stack
    sw      ra, 12(sp)           # Save return address
    sw      fp, 8(sp)
    sw      a0, 4(sp)           # Save argument

    # 將16位BF16數值移到高16位
    slli    t0, a0, 16          # Move BF16 to high 16 bits of 32-bit FP32
    # 結果存回 a1，這裡 u.f = u.i (直接返回)
    mv      a0, t0              # Move the result to return register

    lw      ra, 12(sp)           # Restore return address
    addi    sp, sp, 16           # Restore stack
    jr      ra                  # Return

