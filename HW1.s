    .text 
    .globl main
main:
    
    li      a0, 3
    li      a1, 2
    li      a2, 0
    li      a3, 0
    jal     knightProbability
    #...略過
    mv      t0, a0
    li      a7, 2
    ecall
    li a7, 93       
    li a0, 0        
    ecall           

    # Input: n = 3, k = 2, row = 0, column = 0
    # knightProbability: Calculate knight move probability
    .text
    .globl knightProbability
knightProbability:
    # Arguments: a0 = n, a1 = k, a2 = row, a3 = column
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      a0, 20(sp)       
    sw      a1, 16(sp)       
    sw      a2, 12(sp)       
    sw      a3, 8(sp)       



    # Initialize DPtable with zeros
DP_initial:
    # i: t2, j: t3, t0 = n, t7 as curr position
    # Initialize DPtable with zeros
    li      t0, 0
    la      t1, DPtable         # Load DPtable base address into t1
    li      t2, 18              # Set the size of DPtable (3x3 table, adjust accordingly for other sizes)

DP_zero_full:
    sh      t0, 0(t1)           # Store zero into DPtable
    addi    t1, t1, 2           # Move to next word in DPtable
    addi    t2, t2, -2          # Decrease counter
    bnez    t2, DP_zero_full    # Repeat until DPtable is filled

    # Set DPtable[row][column] = 1.0 (in BF16 format)
Set_one_to_DPrc:
    # Call the custom multiplication function my_mul
    mv      a1, a2              # Copy row into a1 (first argument for my_mul), a0 = n (second argument for my_mul)
    call    my_mul              # Call my_mul function to calculate row * n, result in a0
    mv      t2, a0              # Store result back to t2
    lw      a0, 20(sp)
    lw      a1, 16(sp)
    add     t2, t2, a3          # Add column index
    slli    t2, t2, 1           # Each element is 2 bytes, so multiply index by 2

    la      t1, DPtable         # Reload base address of DPtable into t1
    add     t1, t1, t2          # t1 now points to DPtable[row][column]
    li      t0, 0x3f80          # Load BF16 representation of 1.0 into t0
    sh      t0, 0(t1)           # Store 1.0 (in BF16 format) to DPtable[row][column]



# Main loop: Iterate k times
    li      s3, 0               # Set loop counter i = 0
main_loop:
    bge     s3, a1, loop_end    # if i >= k, exit loop

    # Initialize TDPtable with zeros
    li      t0, 0
    la      t1, TDPtable        # Load TDPtable base address into t1
    li      t2, 18              # Set the size of TDPtable (3x3 table)

TDP_zero_full:
    sh      t0, 0(t1)           # Store zero into TDPtable
    addi    t1, t1, 2           # Move to next word in TDPtable
    addi    t2, t2, -2          # Decrease counter
    bnez    t2, TDP_zero_full   # Repeat until TDPtable is filled

    # Iterate over DPtable and update TDPtable
    li      s4, 0               # Set r = 0
iter_row:                       # Check if r == n, r: s4, c: s5, r*n: t6
    bge     s4, a0, row_done    # if r >= n, finish processing rows

    li      s5, 0               # Set c = 0
iter_col:                       # Check if c == n
    bge     s5, a0, col_done    # if c >= n, finish processing columns

    # Check if DPtable[r][c] > 0
    la      s1, DPtable         # Load DPtable base address into t1

    # Call the custom multiplication function my_mul
    mv      a0, s4              # Copy row r into a0 (first argument for my_mul)
    mv      a1, a0              # Copy n into a1 (second argument for my_mul)
    sw      s3, 4(sp)
    call    my_mul              # Call my_mul function to calculate r * n, result in a0
    lw      s3, 4(sp)
    mv      t6, a0              # Store result back to t6
    lw      a0, 20(sp)
    lw      a1, 16(sp)
    add     t6, t6, s5          # Add column index
    slli    t6, t6, 1           # Each element is 2 bytes, so multiply index by 2
    # t0: DP[r][c]'s position, s1: DPtalbe[r][c]
    add     s1, s1, t6          # s1 now points to DPtable[r][c]
    lw      t0, 0(s1)           # Load DPtable[r][c] into t0
    slli    t0, t0, 16          # trans bf16 to fp32
    beqz    t0, skip_calculate  # If DPtable[r][c] == 0, skip to next iteration
    # prob_fp32 /= 8.0f;
    mv      a0, t0
    li      a1, 3
    call    Fdiv
    mv      a4, a0              # a4: prob_fp32 /= 8.0f
    lw      a0, 20(sp)
    lw      a1, 16(sp)

    # update TDPtable
    # Convert BF16 to FP32 and divide by 8
    # s8: 8, j: s9
    li      s9, 0
    li      s8, 8
move_loop:
    sw      t0, 4(sp)       # temp store DPtable[r][c] val
    slli    t1, s9, 3       # j*2*4
    la      t0, moves        # use t0 for move array's position

    add     t0, t0, t1      # t0 = move + j*2*4,t0 now points to move[j][0]
    lw      t1, 0(t0)       # Load move[j][0]
    addi    t0, t0, 4
    lw      t2, 0(t0)       # Load move[j][1]
    add     t1, t1, s4      # t1 = r + move[j][0]
    add     t2, t2, s5      # t2 = c + move[j][1]
    
    ## if (moveRow >= 0 && moveRow < n && moveCol >= 0 && moveCol < n)
    bge     t1, a0, next_move
    blt     t1, x0, next_move
    bge     t2, a0, next_move
    blt     t2, x0, next_move
prop_calcu:
    
    #####
    mv      a1, t1              # Copy row into a1 (first argument for my_mul), a0 = n (second argument for my_mul)
    call    my_mul              # Call my_mul function to calculate row * n, result in a0
    mv      s6, a0              # Store result back to s6
    lw      a0, 20(sp)
    lw      a1, 16(sp)
    add     s6, s6, t2          # Add column index
    slli    s6, s6, 1           # Each element is 2 bytes, so multiply index by 2

    la      s7, TDPtable        # s7 now points to TDPtable
    add     s7, s7, s6          # s7 now points to TPtable[r][c]

    lw      t0, 0(s7)
    mv      a0, t0
    mv      a1, a4
    call    Fadd                # jump to  Fadd
    mv      t0, a0              # temp_fp32 += prob_fp32, a4: prob_fp32 /= 8.0f
    lw      a0, 20(sp)
    lw      a1, 16(sp)
    srli    t0, t0, 16          # tran temp_fp32 to bf16 format
    sh      t0, 0(s7)           # Store fp32_to_bf16(temp_fp32) to DPtable[row][column]
    #####
    lw      t0, 4(sp)

next_move:
    addi    t3, t3, 1
    addi    s9, s9, 1
    bge     s9, s8, skip_calculate
    j       move_loop




    # (For simplicity, floating point emulation should be handled here)
    # Store results back to TDPtable, updating neighboring cells based on knight moves

    # ... (Process knight moves logic and update TDPtable)

skip_calculate:
    addi    s5, s5, 1           # c++
    j       iter_col

col_done:
    addi    s4, s4, 1           # r++
    j       iter_row

row_done:
    # memcpy(DPtable, TDPtable, sizeof(DPtable))
    la      t1, DPtable         # Load DPtable base address into t1
    la      t2, TDPtable        # Load TDPtable base address into t2
    li      t3, 18              # Copy 18 bytes (3x3 table)
copy_loop:
    lw      t0, 0(t2)           # Load word from TDPtable
    sh      t0, 0(t1)           # Store word to DP
    addi    t1, t1, 2           # Move to next word in DPtable
    addi    t2, t2, 2           # Move to next word in TDPtable
    addi    t3, t3, -2          # Decrease counter
    bnez    t3, copy_loop       # Repeat until DPtable is updated

    addi    s3, s3, 1           # i++
    j       main_loop           # Continue main loop

loop_end:
sum_dp_table:
    # Arguments: 
    # a0 = n

    li      t6, 0               # t6 as Prop sum

    # Outer loop (i = 0)
    li      t1, 0               # t1 = i
outer_loop:

# test
    la      a0, str6
    li      a7, 4
    ecall
    la      a0, str3
    li      a7, 4
    ecall
    mv      a0, t1
    li      a7, 2
    ecall
    la      a0, str5
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 2
    ecall
# test
    lw      a0, 20(sp)
    bge     t1, a0, return    

    # Inner loop (j = 0)
    li      t2, 0               # t2 = j
inner_loop:
    bge     t2, a0, next_i      # if j >= n, branch to next outer loop

    # Calculate DPtable[i][j] address: base + (i * n + j) * 2
    mul     t3, t1, a0          # t3 = i * n
    add     t3, t3, t2          # t3 = i * n + j
    slli    t3, t3, 1           # t3 = (i * n + j) * 2
    la      t0, DPtable      
    add     t3, t3, t0          # t3 = DPtable[i][j] 

    # Load the BF16 value from DPtable[i][j] 
    lh      t4, 0(t3)           # load BF16 to t4

    # Call bf16_to_fp32 
    mv      a0, t4              # a0 = bf val
    jal     bf16_to_fp32        # call bf16_to_fp32, save return val at a0
    mv      t5, a0              # store fp val in t5
    mv      a1, t6
    call    Fadd                # t6 = t6 + t5


    mv      t6, a0
    lw      a0, 20(sp)
    lw      a1, 16(sp)

    # Increment j
    addi    t2, t2, 1           # j++
    j       inner_loop          

next_i:
    # Increment i
    addi    t1, t1, 1           # i++
    j       outer_loop            


return:
    mv      a0, t6
    lw      ra, 28(sp)
    addi    sp, sp, 32
    jr      ra                  # Return final result


    .text
    .globl bf16_to_fp32
bf16_to_fp32:
    addi    sp, sp, -16          # Save space on stack
    sw      ra, 12(sp)           # Save return address
    sw      a0, 8(sp)           # Save argument

    # 將16位BF16數值移到高16位
    slli    a0, a0, 16          # Move BF16 to high 16 bits of 32-bit FP32
    # 結果存回 a1，這裡 u.f = u.i (直接返回)
    lw      ra, 12(sp)           # Restore return address
    addi    sp, sp, 16           # Restore stack
    jr      ra                  # Return


    .text
    .globl my_mul
my_mul:
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
    li      t2, 0x80
    
    sub     t0, t1, a1
    slli    t0, t0, 23
    
    li      t3, 0x800fffff
    and     t1, a0, t3
    or      a0, t1, t0
    lw      ra, 12(sp)
    lw      a1, 4(sp)
    addi    sp, sp, 16
    ret



    .text 
    .globl fadd
Fadd:
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
    j       return_f

return_num2:                # when f2 = 0, return a0
    j       return_f

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
return_f:
    lw      ra, 20(sp)
    lw      t0, 16(sp)
    lw      t1, 12(sp)
    lw      t2, 8(sp)
    lw      t3, 4(sp)
    lw      s0, 0(sp)
    addi    sp, sp, 24
    ret



    .data
    .align 2

    # moves: Knight's possible moves
moves:
    .word   2, 1,   2, -1,   -2, 1,   -2, -1
    .word   1, 2,   1, -2,   -1, 2,   -1, -2

    .data
DPtable:
    .half  0, 0, 0, 0, 0, 0, 0, 0, 0
    
    .data
TDPtable:
    .half  0, 0, 0, 0, 0, 0, 0, 0, 0
str2: .string "Test case : "
str3: .string " , "
str4: .string " test answer : "
str5: .string "\n"
str6: .string "round "