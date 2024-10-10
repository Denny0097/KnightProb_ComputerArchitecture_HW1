    .text 
    .globl main
main:

    li      a0, 3
    li      a1, 2
    li      a2, 0
    li      a3, 0
    call    knightProbability

    mv      t0, a0
    #...略過

    li      a7, 10
    ecall



    .data
	.align	2
    # moves: Knight's possible moves
moves:
    .word   2, 1,   2, -1,   -2, 1,   -2, -1
    .word   1, 2,   1, -2,   -1, 2,   -1, -2

    # DPtable: 動態規劃表
    .data
DPtable:
    .space  18  

    .data
TDPtable:
    .space  18                        
    
    # Input: n = 3, k = 2, row = 0, column = 0
    # knightProbability: Calculate knight move probability
    .text
    .globl knightProbability
knightProbability:
    # Arguments: a0 = n, a1 = k, a2 = row, a3 = column
    mv      fp, sp              
    mv      fp, sp
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      fp, 24(sp)
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

init_DPtable:
    sh      t0, 0(t1)           # Store zero into DPtable
    addi    t1, t1, 2           # Move to next word in DPtable
    addi    t2, t2, -2          # Decrease counter
    bnez    t2, init_DPtable    # Repeat until DPtable is filled

    # Set DPtable[row][column] = 1.0 (in BF16 format)

    # Call the custom multiplication function my_mul
    mv      a1, a2              # Copy row into a1 (first argument for my_mul), a0 = n (second argument for my_mul)
    jal     my_mul              # Call my_mul function to calculate row * n, result in a0
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
    li      t3, 0               # Set loop counter i = 0
main_loop:
    bge     t3, a1, loop_end    # if i >= k, exit loop

    # Initialize TDPtable with zeros
    li      t0, 0
    la      t1, TDPtable        # Load TDPtable base address into t1
    li      t2, 18              # Set the size of TDPtable (3x3 table)

init_TDPtable:
    sh      t0, 0(t1)           # Store zero into TDPtable
    addi    t1, t1, 2           # Move to next word in TDPtable
    addi    t2, t2, -2          # Decrease counter
    bnez    t2, init_TDPtable   # Repeat until TDPtable is filled

    # Iterate over DPtable and update TDPtable
    li      t4, 0               # Set r = 0
iter_row:
    bge     t4, a0, row_done    # if r >= n, finish processing rows

    li      t5, 0               # Set c = 0
iter_col:
    bge     t5, a0, col_done    # if c >= n, finish processing columns

    # Check if DPtable[r][c] > 0
    la      t1, DPtable         # Load DPtable base address into t1

    # Call the custom multiplication function my_mul
    mv      a0, t4              # Copy row r into a0 (first argument for my_mul)
    mv      a1, a0              # Copy n into a1 (second argument for my_mul)
    sw      t3, 4(sp)
    jal     my_mul              # Call my_mul function to calculate r * n, result in a0
    lw      t3, 4(sp)
    mv      t6, a0              # Store result back to t6
    sw      a0, 20(sp)
    sw      a1, 16(sp)
    add     t6, t6, t5          # Add column index
    slli    t6, t6, 1           # Each element is 2 bytes, so multiply index by 2
    add     t1, t1, t6          # t1 now points to DPtable[r][c]
    lw      t0, 0(t1)           # Load DPtable[r][c] into t0

    beqz    t0, skip_moves      # If DPtable[r][c] == 0, skip to next iteration

    # Convert BF16 to FP32 and divide by 8
    # (For simplicity, floating point emulation should be handled here)
    # Store results back to TDPtable, updating neighboring cells based on knight moves

    # ... (Process knight moves logic and update TDPtable)

skip_moves:
    addi    t5, t5, 1           # c++
    j       iter_col

col_done:
    addi    t4, t4, 1           # r++
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

    addi    t3, t3, 1           # i++
    j       main_loop           # Continue main loop

loop_end:
sum_dp_table:
    # Arguments: 
    # a0 = n

    li      t6, 0               # t6 as counter

    # Outer loop (i = 0)
    li      t1, 0               # t1 = i
outer_loop:
    bge     t1, a0, return    

    # Inner loop (j = 0)
    li      t2, 0               # t2 = j
inner_loop:
    bge     t2, a0, next_i      # 如果 j >= n，跳到下一個外層迴圈

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
    lw      a0, 20(sp)

    # Accumulate the result 
    add     t6, t6, t5          # t6 = t6 + t5

    # Increment j
    addi    t2, t2, 1           # j++
    j       inner_loop          

next_i:
    # Increment i
    addi    t1, t1, 1           # i++
    j       outer_loop            


return:
    mv      a0, t6
    addi    sp, sp, 32
    ret                         # Return final result




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









    .text
    .globl my_mul
my_mul:
    # Arguments:
    # a4: multiplicand (被乘數)
    # a5: multiplier (乘數)
    # Return value in a0

    # Initialize result register
    li      t0, 0               # t0 will store the result (初始化結果為 0)
    li      t1, 0               # t1 is the bit position counter (初始位移量)

mul_loop:
    # Check if the least significant bit of a1 (multiplier) is 1
    andi    t2, a1, 1    # Extract the least significant bit of multiplier

    # If the bit is 1, add (multiplicand << t1) to the result
    beqz    t2, skip_add # If the bit is 0, skip addition
    sll     t3, a0, t1          # Shift multiplicand by t1 (左移被乘數)
    add     t0, t0, t3          # Add shifted multiplicand to result (加到結果中)

skip_add:
    # Shift multiplier right by 1 (右移乘數)
    srli    a1, a1, 1
    addi    t1, t1, 1           # Increment the bit position counter (增加位移量)
    
    # Repeat for all bits (32位的整數)
    bnez    a1, mul_loop        # If a1 is not zero, repeat the loop

    # Store the result in a0 and return
    mv      a0, t0              # Move result to a0
    ret