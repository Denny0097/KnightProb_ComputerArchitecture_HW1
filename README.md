# Assignment1: RISC-V Assembly and Instruction Pipeline
contributed by < [`姜冠宇`](https://github.com/Denny0097) >


## Introduction
### 688. Knight Probability in Chessboard
On an $n * n$ chessboard, a knight starts at the cell (row, column) and attempts to make exactly k moves. The rows and columns are 0-indexed, so the top-left cell is $(0, 0)$, and the bottom-right cell is $(n - 1, n - 1)$.

A chess knight has eight possible moves it can make, as illustrated below. Each move is two cells in a cardinal direction, then one cell in an orthogonal direction.

![image](https://hackmd.io/_uploads/SkbypaCCA.png)

Each time the knight is to move, it chooses one of eight possible moves uniformly at random (even if the piece would go off the chessboard) and moves there.

The knight continues moving until it has made exactly k moves or has moved off the chessboard.

Return the probability that the knight remains on the board after it has stopped moving.


Example 1:

Input: n = 3, k = 2, row = 0, column = 0
Output: 0.06250
Explanation: There are two moves (to $(1,2)$, $(2,1)$) that will keep the knight on the board.
From each of those positions, there are also two moves that will keep the knight on the board.
The total probability the knight stays on the board is 0.0625.


Example 2:

Input: n = 1, k = 0, row = 0, column = 0
Output: 1.00000
 

Constraints:

$1 <= n <= 25$
$0 <= k <= 100$
$0 <= row, column <= n - 1$


## Implementation
You can find the source code [here](https://github.com/Denny0097).


### Motivation

I use the bf16 format to store those arrays and the fp32 format at calculate time,  expecting it will have better space and computing performance.

### DP
(k,x,y): k mean step num, (x,y) mean cell
initially, knight is at cell (i,j)
 
>$(0,x,y) = 0$, when $x\neq i || y\neq j$
$(0,i,j) = 1$
$(k,x+2,y+1) = (k-1,x,y)/8$
$(k,x+2,y-1) = (k-1,x,y)/8$
$(k,x-2,y+1) = (k-1,x,y)/8$
$(k,x-2,y-1) = (k-1,x,y)/8$
$(k,x+1,y+2) = (k-1,x,y)/8$
$(k,x+1,y-2) = (k-1,x,y)/8$
$(k,x-1,y+2) = (k-1,x,y)/8$
$(k,x-1,y-2) = (k-1,x,y)/8$
$(k,x,y) = (k-1,x,y)$, except above

calculate the sum of prop that in chessboard


### c code for function knightProbabilit without FP transfer
```c=
double knightProbability(int n, int k, int row, int column){
    
    double DPtable[n][n];
    memset(DPtable, 0, sizeof(DPtable));
    DPtable[row][column] = 1;
    double Prop = 0.0;

    int moves[8][2] = {{2,1},{2,-1},{-2,1},{-2,-1},{1,2},{1,-2},{-1,2},{-1,-2}};

    for(int i = 0; i < k; i++){

        double TDP[n][n];          
        memset(TDP, 0, sizeof(TDP));
        
        for(int r = 0; r < n; r++){
            for(int c = 0; c < n; c++){
                for(int j = 0; j < 8; j++){
                    int moveRow = r + moves[j][0];
                    int moveCol = c + moves[j][1];
                    if(moveRow >= 0 && moveRow <= n-1 && moveCol >= 0 && moveCol <= n-1)
                        TDP[moveRow][moveCol] += DPtable[r][c]/8.0;
                }
            }    
        }
        memcpy(DPtable, TDP, sizeof(DPtable));

    }

    for (int i = 0; i < n; i++){
        for (int j = 0; j < n; j++){
            Prop += DPtable[i][j];
        }
    }
    return  Prop;
}
```





### c code for function fp32_to_bf16/ bf16_to_fp32
```c=
typedef struct {
    uint16_t bits;
} bf16_t;

// Inline function to convert FP32 to BF16
static inline bf16_t fp32_to_bf16(float s) {
       /*'''*/
}

// Inline function to convert BF16 back to FP32
static inline float bf16_to_fp32(bf16_t h) {
       /*'''*/
}
```


### **assembly** code for function fp32_to_bf16/ bf16_to_fp32
```riscv=

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
bf16_to_fp32:
    addi    sp, sp, -16          # Save space on stack
    sw      ra, 12(sp)           # Save return address
    sw      a0, 8(sp)           # Save argument

    # 將16位BF16數值移到高16位
    slli    t0, a0, 16          # Move BF16 to high 16 bits of 32-bit FP32
    # 結果存回 a1，這裡 u.f = u.i (直接返回)
    mv      a0, t0              # Move the result to return register

    lw      ra, 12(sp)           # Restore return address
    addi    sp, sp, 16           # Restore stack
    jr      ra                  # Return



```





### c code for function knightProbability
```c=
double knightProbability(int n, int k, int row, int column) {
    // Define DPtable and TDP as arrays of bf16_t
    bf16_t DPtable[n][n];
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            DPtable[i][j].bits = 0;
        }
    }

    // Set the initial probability to 1.0 and convert to BF16
    DPtable[row][column] = fp32_to_bf16(1.0f);
    float Prop = 0.0f;

    int moves[8][2] = {{2,1},{2,-1},{-2,1},{-2,-1},{1,2},{1,-2},{-1,2},{-1,-2}};
    for (int i = 0; i < k; i++) {
        bf16_t TDP[n][n];
        for (int r = 0; r < n; r++) {
            for (int c = 0; c < n; c++) {
                TDP[r][c].bits = 0;
            }
        }

        for (int r = 0; r < n; r++) {
            for (int c = 0; c < n; c++) {
                // Use FP32 for computation
                if (DPtable[r][c].bits > 0) {

                    float prob_fp32 = bf16_to_fp32(DPtable[r][c]);
                    prob_fp32 /= 8.0f;

                    for (int j = 0; j < 8; j++) {
                        int moveRow = r + moves[j][0];
                        int moveCol = c + moves[j][1];
                        if (moveRow >= 0 && moveRow < n && moveCol >= 0 && moveCol < n) {
                            float temp_fp32 = bf16_to_fp32(TDP[moveRow][moveCol]);
                            temp_fp32 += prob_fp32;
                            TDP[moveRow][moveCol] = fp32_to_bf16(temp_fp32);
                        }
                    }
                }
            }
        }
        memcpy(DPtable, TDP, sizeof(DPtable));
    }

    for the final result
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                Prop += bf16_to_fp32(DPtable[i][j]);
            }
        }
    return (double)Prop;
}
```


### assembly code for function knightProbability
Using ```Input: n = 3, k = 2, row = 0, column = 0``` as an example.
```riscv=
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
    li      s1, 0               # s1 = i
outer_loop:
   
    lw      a0, 20(sp)	
    bgt     s1, a0, return    
    
    # Inner loop (j = 0)
    li      s2, 0               # t2 = j
inner_loop:
    lw      a0, 20(sp)
    bgt     s2, a0, next_i      # if j >= n, branch to next outer loop

    # Calculate DPtable[i][j] address: base + (i * n + j) * 2
    mv      a1, s1
    call    my_mul              # t3 = i * n
    mv      t3, a0
    lw      a0, 20(sp)
    lw      a1, 16(sp)

    # test t3 val
    la      a0, str2
    li      a7, 4
    ecall

    mv      a0, t3
    li      a7, 1
    ecall
    
    la      a0, str5
    li      a7, 4
    ecall
    #

    add     t3, t3, s2          # t3 = i * n + j
    slli    t3, t3, 1           # t3 = (i * n + j) * 2
    
    # test t3 val
    la      a0, str2
    li      a7, 4
    ecall

    mv      a0, t3
    li      a7, 1
    ecall
    
    la      a0, str5
    li      a7, 4
    ecall
    #

    la      t0, DPtable      
    add     t3, t3, t0          # t3 = DPtable[i][j]'s position 

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
    addi    s2, s2, 1           # j++
    j       inner_loop          

next_i:
    # Increment i
    addi    s1, s1, 1           # i++
    # test 
    
    la      a0, str6
    li      a7, 4
    ecall
    
    mv      a0, s1
    li      a7, 1
    ecall
    
    la      a0, str3
    li      a7, 4
    ecall

    mv      a0, t6
    li      a7, 2
    ecall
    
    la      a0, str5
    li      a7, 4
    ecall
    
    # test
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
str2: .string "Test t3: : "
str3: .string " , "
str4: .string " test answer : "
str5: .string "\n"
str6: .string "round "

```


## Analysis


### Ripes Simulator
Testing the code using Ripes simulator.
| Execution info    | use BF16 to FP32  | 
|------------|----|
| Cycles| 2648  | 
| Instrs. retired | 1997| 
| CPI|  1.33| 
| IPC|  0.754| 
| Clock rate | 0 Hz


```=
00000000 <main>:
    0:        00300513        addi x10 x0 3
    4:        00200593        addi x11 x0 2
    8:        00000613        addi x12 x0 0
    c:        00000693        addi x13 x0 0
    10:        010000ef        jal x1 16 <knightProbability>
    14:        00050293        addi x5 x10 0
    18:        00200893        addi x17 x0 2
    1c:        00000073        ecall

00000020 <knightProbability>:
    20:        fe010113        addi x2 x2 -32
    24:        00112e23        sw x1 28 x2
    28:        00a12a23        sw x10 20 x2
    2c:        00b12823        sw x11 16 x2
    30:        00c12623        sw x12 12 x2
    34:        00d12423        sw x13 8 x2

00000038 <DP_initial>:
    38:        00000293        addi x5 x0 0
    3c:        10000317        auipc x6 0x10000
    40:        00430313        addi x6 x6 4
    44:        01200393        addi x7 x0 18

00000048 <DP_zero_full>:
    48:        00531023        sh x5 0 x6
    4c:        00230313        addi x6 x6 2
    50:        ffe38393        addi x7 x7 -2
    54:        fe039ae3        bne x7 x0 -12 <DP_zero_full>

00000058 <Set_one_to_DPrc>:
    58:        00060593        addi x11 x12 0
    5c:        00000097        auipc x1 0x0 <main>
    60:        24c080e7        jalr x1 x1 588
    64:        00050393        addi x7 x10 0
    68:        01412503        lw x10 20 x2
    6c:        01012583        lw x11 16 x2
    70:        00d383b3        add x7 x7 x13
    74:        00139393        slli x7 x7 1
    78:        10000317        auipc x6 0x10000
    7c:        fc830313        addi x6 x6 -56
    80:        00730333        add x6 x6 x7
    84:        000042b7        lui x5 0x4
    88:        f8028293        addi x5 x5 -128
    8c:        00531023        sh x5 0 x6
    90:        00000993        addi x19 x0 0

00000094 <main_loop>:
    94:        18b9d063        bge x19 x11 384 <sum_dp_table>
    98:        00000293        addi x5 x0 0
    9c:        10000317        auipc x6 0x10000
    a0:        fb630313        addi x6 x6 -74
    a4:        01200393        addi x7 x0 18

000000a8 <TDP_zero_full>:
    a8:        00531023        sh x5 0 x6
    ac:        00230313        addi x6 x6 2
    b0:        ffe38393        addi x7 x7 -2
    b4:        fe039ae3        bne x7 x0 -12 <TDP_zero_full>
    b8:        00000a13        addi x20 x0 0

000000bc <iter_row>:
    bc:        12aa5263        bge x20 x10 292 <row_done>
    c0:        00000a93        addi x21 x0 0

000000c4 <iter_col>:
    c4:        10aada63        bge x21 x10 276 <col_done>
    c8:        10000497        auipc x9 0x10000
    cc:        f7848493        addi x9 x9 -136
    d0:        000a0513        addi x10 x20 0
    d4:        00050593        addi x11 x10 0
    d8:        01312223        sw x19 4 x2
    dc:        00000097        auipc x1 0x0 <main>
    e0:        1cc080e7        jalr x1 x1 460
    e4:        00412983        lw x19 4 x2
    e8:        00050f93        addi x31 x10 0
    ec:        01412503        lw x10 20 x2
    f0:        01012583        lw x11 16 x2
    f4:        015f8fb3        add x31 x31 x21
    f8:        001f9f93        slli x31 x31 1
    fc:        01f484b3        add x9 x9 x31
    100:        0004a283        lw x5 0 x9
    104:        01029293        slli x5 x5 16
    108:        0c028463        beq x5 x0 200 <skip_calculate>
    10c:        00028513        addi x10 x5 0
    110:        00300593        addi x11 x0 3
    114:        00000097        auipc x1 0x0 <main>
    118:        1c0080e7        jalr x1 x1 448
    11c:        00050713        addi x14 x10 0
    120:        01412503        lw x10 20 x2
    124:        01012583        lw x11 16 x2
    128:        00000c93        addi x25 x0 0
    12c:        00800c13        addi x24 x0 8

00000130 <move_loop>:
    130:        00512223        sw x5 4 x2
    134:        003c9313        slli x6 x25 3
    138:        10000297        auipc x5 0x10000
    13c:        ec828293        addi x5 x5 -312
    140:        006282b3        add x5 x5 x6
    144:        0002a303        lw x6 0 x5
    148:        00428293        addi x5 x5 4
    14c:        0002a383        lw x7 0 x5
    150:        01430333        add x6 x6 x20
    154:        015383b3        add x7 x7 x21
    158:        06a35463        bge x6 x10 104 <next_move>
    15c:        06034263        blt x6 x0 100 <next_move>
    160:        06a3d063        bge x7 x10 96 <next_move>
    164:        0403ce63        blt x7 x0 92 <next_move>

00000168 <prop_calcu>:
    168:        00030593        addi x11 x6 0
    16c:        00000097        auipc x1 0x0 <main>
    170:        13c080e7        jalr x1 x1 316
    174:        00050b13        addi x22 x10 0
    178:        01412503        lw x10 20 x2
    17c:        01012583        lw x11 16 x2
    180:        007b0b33        add x22 x22 x7
    184:        001b1b13        slli x22 x22 1
    188:        10000b97        auipc x23 0x10000
    18c:        ecab8b93        addi x23 x23 -310
    190:        016b8bb3        add x23 x23 x22
    194:        000ba283        lw x5 0 x23
    198:        00028513        addi x10 x5 0
    19c:        00070593        addi x11 x14 0
    1a0:        00000097        auipc x1 0x0 <main>
    1a4:        1a8080e7        jalr x1 x1 424
    1a8:        00050293        addi x5 x10 0
    1ac:        01412503        lw x10 20 x2
    1b0:        01012583        lw x11 16 x2
    1b4:        0102d293        srli x5 x5 16
    1b8:        005b9023        sh x5 0 x23
    1bc:        00412283        lw x5 4 x2

000001c0 <next_move>:
    1c0:        001e0e13        addi x28 x28 1
    1c4:        001c8c93        addi x25 x25 1
    1c8:        018cd463        bge x25 x24 8 <skip_calculate>
    1cc:        f65ff06f        jal x0 -156 <move_loop>

000001d0 <skip_calculate>:
    1d0:        001a8a93        addi x21 x21 1
    1d4:        ef1ff06f        jal x0 -272 <iter_col>

000001d8 <col_done>:
    1d8:        001a0a13        addi x20 x20 1
    1dc:        ee1ff06f        jal x0 -288 <iter_row>

000001e0 <row_done>:
    1e0:        10000317        auipc x6 0x10000
    1e4:        e6030313        addi x6 x6 -416
    1e8:        10000397        auipc x7 0x10000
    1ec:        e6a38393        addi x7 x7 -406
    1f0:        01200e13        addi x28 x0 18

000001f4 <copy_loop>:
    1f4:        0003a283        lw x5 0 x7
    1f8:        00531023        sh x5 0 x6
    1fc:        00230313        addi x6 x6 2
    200:        00238393        addi x7 x7 2
    204:        ffee0e13        addi x28 x28 -2
    208:        fe0e16e3        bne x28 x0 -20 <copy_loop>
    20c:        00198993        addi x19 x19 1
    210:        e85ff06f        jal x0 -380 <main_loop>

00000214 <sum_dp_table>:
    214:        00000f93        addi x31 x0 0
    218:        00000313        addi x6 x0 0

0000021c <outer_loop>:
    21c:        04a35e63        bge x6 x10 92 <return>
    220:        00000393        addi x7 x0 0

00000224 <inner_loop>:
    224:        04a3d663        bge x7 x10 76 <next_i>
    228:        02a30e33        mul x28 x6 x10
    22c:        007e0e33        add x28 x28 x7
    230:        001e1e13        slli x28 x28 1
    234:        10000297        auipc x5 0x10000
    238:        e0c28293        addi x5 x5 -500
    23c:        005e0e33        add x28 x28 x5
    240:        000e1e83        lh x29 0 x28
    244:        000e8513        addi x10 x29 0
    248:        040000ef        jal x1 64 <bf16_to_fp32>
    24c:        00050f13        addi x30 x10 0
    250:        000f8593        addi x11 x31 0
    254:        00000097        auipc x1 0x0 <main>
    258:        0f4080e7        jalr x1 x1 244
    25c:        00050f93        addi x31 x10 0
    260:        01412503        lw x10 20 x2
    264:        01012583        lw x11 16 x2
    268:        00138393        addi x7 x7 1
    26c:        fb9ff06f        jal x0 -72 <inner_loop>

00000270 <next_i>:
    270:        00130313        addi x6 x6 1
    274:        fa9ff06f        jal x0 -88 <outer_loop>

00000278 <return>:
    278:        000f8513        addi x10 x31 0
    27c:        01c12083        lw x1 28 x2
    280:        02010113        addi x2 x2 32
    284:        00008067        jalr x0 x1 0

00000288 <bf16_to_fp32>:
    288:        ff010113        addi x2 x2 -16
    28c:        00112623        sw x1 12 x2
    290:        00a12423        sw x10 8 x2
    294:        01051293        slli x5 x10 16
    298:        00028513        addi x10 x5 0
    29c:        00c12083        lw x1 12 x2
    2a0:        01010113        addi x2 x2 16
    2a4:        00008067        jalr x0 x1 0

000002a8 <my_mul>:
    2a8:        00000293        addi x5 x0 0
    2ac:        00000313        addi x6 x0 0

000002b0 <mul_loop>:
    2b0:        0015f393        andi x7 x11 1
    2b4:        00038663        beq x7 x0 12 <skip_add>
    2b8:        00651e33        sll x28 x10 x6
    2bc:        01c282b3        add x5 x5 x28

000002c0 <skip_add>:
    2c0:        0015d593        srli x11 x11 1
    2c4:        00130313        addi x6 x6 1
    2c8:        fe0594e3        bne x11 x0 -24 <mul_loop>
    2cc:        00028513        addi x10 x5 0
    2d0:        00008067        jalr x0 x1 0

000002d4 <Fdiv>:
    2d4:        ff010113        addi x2 x2 -16
    2d8:        00112623        sw x1 12 x2
    2dc:        00a12423        sw x10 8 x2
    2e0:        00b12223        sw x11 4 x2
    2e4:        7f800e37        lui x28 0x7f800
    2e8:        01c57333        and x6 x10 x28
    2ec:        01735313        srli x6 x6 23
    2f0:        08000393        addi x7 x0 128
    2f4:        02735663        bge x6 x7 44 <Exp_post>
    2f8:        40b302b3        sub x5 x6 x11
    2fc:        01729293        slli x5 x5 23
    300:        80100e37        lui x28 0x80100
    304:        fffe0e13        addi x28 x28 -1
    308:        01c57333        and x6 x10 x28
    30c:        00536533        or x10 x6 x5
    310:        00c12083        lw x1 12 x2
    314:        00412583        lw x11 4 x2
    318:        01010113        addi x2 x2 16
    31c:        00008067        jalr x0 x1 0

00000320 <Exp_post>:
    320:        00b302b3        add x5 x6 x11
    324:        01729293        slli x5 x5 23
    328:        80100e37        lui x28 0x80100
    32c:        fffe0e13        addi x28 x28 -1
    330:        01c57333        and x6 x10 x28
    334:        00536533        or x10 x6 x5
    338:        00c12083        lw x1 12 x2
    33c:        00412583        lw x11 4 x2
    340:        01010113        addi x2 x2 16
    344:        00008067        jalr x0 x1 0

00000348 <Fadd>:
    348:        fe810113        addi x2 x2 -24
    34c:        00112a23        sw x1 20 x2
    350:        00512823        sw x5 16 x2
    354:        00612623        sw x6 12 x2
    358:        00712423        sw x7 8 x2
    35c:        01c12223        sw x28 4 x2
    360:        00812023        sw x8 0 x2
    364:        00050663        beq x10 x0 12 <return_num1>
    368:        00058863        beq x11 x0 16 <return_num2>
    36c:        0100006f        jal x0 16 <not_zero>

00000370 <return_num1>:
    370:        00058513        addi x10 x11 0
    374:        07c0006f        jal x0 124 <return_f>

00000378 <return_num2>:
    378:        0780006f        jal x0 120 <return_f>

0000037c <not_zero>:
    37c:        00050293        addi x5 x10 0
    380:        00058313        addi x6 x11 0
    384:        00129e93        slli x29 x5 1
    388:        018ede93        srli x29 x29 24
    38c:        00131f13        slli x30 x6 1
    390:        018f5f13        srli x30 x30 24
    394:        00800437        lui x8 0x800
    398:        1ff2f493        andi x9 x5 511
    39c:        0084e4b3        or x9 x9 x8
    3a0:        1ff37913        andi x18 x6 511
    3a4:        00896933        or x18 x18 x8
    3a8:        01eed863        bge x29 x30 16 <not_taken1>
    3ac:        41df0fb3        sub x31 x30 x29
    3b0:        01f4d4b3        srl x9 x9 x31
    3b4:        000f0e93        addi x29 x30 0

000003b8 <not_taken1>:
    3b8:        41ee8fb3        sub x31 x29 x30
    3bc:        01f95933        srl x18 x18 x31
    3c0:        012489b3        add x19 x9 x18
    3c4:        01000437        lui x8 0x1000
    3c8:        0089f4b3        and x9 x19 x8
    3cc:        00048663        beq x9 x0 12 <not_taken2>
    3d0:        0019d993        srli x19 x19 1
    3d4:        001e8e93        addi x29 x29 1

000003d8 <not_taken2>:
    3d8:        017e9e93        slli x29 x29 23
    3dc:        00800437        lui x8 0x800
    3e0:        fff40413        addi x8 x8 -1
    3e4:        0089f9b3        and x19 x19 x8
    3e8:        013ee533        or x10 x29 x19
    3ec:        00200893        addi x17 x0 2

000003f0 <return_f>:
    3f0:        01412083        lw x1 20 x2
    3f4:        01012283        lw x5 16 x2
    3f8:        00c12303        lw x6 12 x2
    3fc:        00812383        lw x7 8 x2
    400:        00412e03        lw x28 4 x2
    404:        00012403        lw x8 0 x2
    408:        01810113        addi x2 x2 24
    40c:        00008067        jalr x0 x1 0

```


### 5-stage pipelined processor
Ripes is a *five-stage*![截圖 2024-10-11 上午11.52.16](https://hackmd.io/_uploads/HkS_478yke.png)

#### IF
![截圖 2024-10-11 中午12.04.52](https://hackmd.io/_uploads/HJX54QIykl.png)

#### ID
![截圖 2024-10-11 中午12.05.13](https://hackmd.io/_uploads/r1ahN78ykg.png)


#### EX
![截圖 2024-10-11 中午12.05.28](https://hackmd.io/_uploads/BkcgSXI11e.png)

#### MEM
![截圖 2024-10-11 中午12.05.40](https://hackmd.io/_uploads/SkwZSm81ye.png)


#### WB
![截圖 2024-10-11 中午12.05.49](https://hackmd.io/_uploads/BJJzB7L1kg.png)


## Reference

* [Quiz1 of Computer Architecture (2024 Fall)](https://hackmd.io/@sysprog/arch2024-quiz1-sol)
* [LeetCode : 688. Knight Probability in Chessboard](https://leetcode.com/problems/knight-probability-in-chessboard/description/)
* [RISC-V 指令集架構介紹 - RV32I](https://tclin914.github.io/16df19b4/)
* [Lab1: RV32I Simulator](https://hackmd.io/@sysprog/H1TpVYMdB)

