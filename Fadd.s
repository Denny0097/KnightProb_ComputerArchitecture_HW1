.data
    f1: .4byte 0x3fc00000  #1.5
    f2: .4byte 0x40700000  #3.75
    
    .text
    .globl fadd
fadd:
    lw t0, f1
    lw t1, f2           #don't need to get sign
    
    beq t0, zero, return1  #if t0 is 0
    beq t1, zero, return2  #if t1 is 0 
    j not_zero
return1: #return t1
    mv a0, t1
    li a7, 2
    ecall
    li a7, 10
    ecall
return2: #return t0
    mv a0, t0
    li a7, 2
    ecall
    li a7, 10
    ecall
not_zero:
    slli t4, t0, 1
    srli t4, t4, 24     #exponent of f1
    slli t5, t1, 1
    srli t5, t5, 24     #exponent of f2

    li s0, 0x800000
    slli s1, t0, 9
    srli s1, s1, 9      #fraction of f1
    or s1, s1, s0       #add hidden bit
    slli s2, t1, 9
    srli s2, s2, 9      #fraction of f2
    or s2, s2, s0       #add hidden bit

    bge t4, t5, not_taken2
    sub t6, t5, t4      #shift = e2 - e1
    srl s1, s1, t6      #right shift fraction1
    mv t4, t5           #let t4 stroes the bigger exponent
not_taken2:
    sub t6, t4, t5      #shift = e1 - e2
    srl s2, s2, t6      #right shift fraction2
    add s3, s1, s2      #result = fraction1 + fraction2

    li s0, 0x1000000    #normalize the number
    and s1, s3, s0
    beq s1, zero, not_taken3
    srli s3, s3, 1      #right shift the fraction
    addi t4, t4, 1      #exponent+=1
not_taken3:
    slli t4, t4, 23     #exponent << 23
    li s0, 0x7FFFFF
    and s3, s3, s0      #fraction & 0x7FFFFF
    or a0, t4, s3       #concat the number

    li a7, 2            #print output
    ecall