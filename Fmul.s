.data
    f1: .4byte 0x3fc00000  #1.5
    f2: .4byte 0x40700000  #3.75
    
    .text
    .globl fadd
fmul:
    # Arguments:
    # Return value in a0

    # Initialize result register
    li      t0, 0               # t0 will store the result (初始化結果為 0)
    li      t1, 0               # t1 is the bit position counter (初始位移量)

mul_loop:
    # Check if the least significant bit of a1 (multiplier) is 1
    andi    t2, a1, 1    # Extract the least significant bit of multiplier

    # If the bit is 1, add (multiplicand << t1) to the result
    beqz    t2, skip_add # If the bit is 0, skip addition
    sll     t3, a0, t1          # Shift multiplicand by t1 
    add     t0, t0, t3          # Add shifted multiplicand to result 

skip_add:
    # Shift multiplier right by 1 
    srli    a1, a1, 1
    addi    t1, t1, 1           # Increment the bit position counter 
    
    # Repeat for all bits 
    bnez    a1, mul_loop        # If a1 is not zero, repeat the loop

    # Store the result in a0 and return
    mv      a0, t0              # Move result to a0
    ret



    .text 
    .globl fadd
fadd:
    addi    sp, sp, -24
    sw      ra, 20(sp)
    sw      t0, 16(sp)
    sw      t1, 12(sp)
    sw      t2, 8(sp)
    sw      t3, 4(sp)
    sw      s0, 0(sp)


    beq     a0, zero, return_num1
    beq     a1, zero, return_num2
    j       not_zero

return_num1:                # when f1 = 0, return a1
    mv      a0, a1
    j       return

return_num2:                # when f2 = 0, return a0
    j       return

not_zero:
    mv      t0, a0
    mv      t1, a1          
    
    slli    t4, t0, 1       # don't need to get sign
    srli    t4, t4, 24      # exponent of f1
    slli    t5, t1, 1
    srli    t5, t5, 24      # exponent of f2

    li      s0, 0x800000
    andi    s1, t0, 0x1ff   # fraction of f1
    or      s1, s1, s0      # add hidden bit
    andi    s2, t1, 0x1ff   # fraction of f2
    or      s2, s2, s0      # add hidden bit

    bge     t4, t5, not_taken1  #if f1 > f2, branch to not_tacken1
    sub     t6, t5, t4      # else, shift = e2 - e1
    srl     s1, s1, t6      # right shift fraction1
    mv      t4, t5          # let t4 stroes the bigger exponent

not_taken1:
    sub     t6, t4, t5      # shift = e1 - e2
    srl     s2, s2, t6      # right shift fraction2
    add     s3, s1, s2      # result = fraction1 + fraction2

    li      s0, 0x1000000   # normalize the number
    and     s1, s3, s0
    beq     s1, zero, not_taken2
    srli    s3, s3, 1          # right shift the fraction
    addi    t4, t4, 1          # exponent+=1

not_taken2:
    slli    t4, t4, 23         # exponent << 23
    li      s0, 0x7FFFFF
    and     s3, s3, s0          # fraction & 0x7FFFFF
    or      a0, t4, s3           # concat the number

    li      a7, 2
    ecall
return:
    lw      ra, 20(sp)
    lw      t0, 16(sp)
    lw      t1, 12(sp)
    lw      t2, 8(sp)
    lw      t3, 4(sp)
    lw      s0, 0(sp)
    addi    sp, sp, 24
    ret