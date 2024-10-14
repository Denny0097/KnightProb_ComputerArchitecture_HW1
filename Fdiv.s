    .data
a:  .word 0x41200000  # float 10.0f
b:  .word 0x40A00000  # float 5.0f

    .text
    .globl Fdiv
# Function to perform floating-point division
Fdiv:
    # Load the values of a and b
    la   t0, a           # Load address of a into t0
    lw   t1, 0(t0)       # Load float a into t1 (in IEEE 754 format)

    la   t0, b           # Load address of b into t0
    lw   t2, 0(t0)       # Load float b into t2 (in IEEE 754 format)

    # Extract sign, exponent, and mantissa for a and b
    li   t3, 0x80000000  # Mask for sign bit
    and  t4, t1, t3      # Extract sign of a
    and  t5, t2, t3      # Extract sign of b
    xor  t6, t4, t5      # Result sign = a.sign ^ b.sign (XOR operation)

    # Extract exponents
    li   t3, 0x7F800000  # Mask for exponent
    and  t4, t1, t3      # Extract exponent of a
    and  t5, t2, t3      # Extract exponent of b
    srl  t4, t4, 23      # Right shift to get actual exponent of a
    srl  t5, t5, 23      # Right shift to get actual exponent of b
    sub  t7, t4, t5      # Subtract exponents (a.exp - b.exp)
    addi t7, t7, 127     # Add bias (127 for single-precision)

    # Extract mantissas
    li   t3, 0x007FFFFF  # Mask for mantissa
    and  t4, t1, t3      # Extract mantissa of a
    and  t5, t2, t3      # Extract mantissa of b
    or   t4, t4, 0x00800000  # Add implicit leading 1 to a's mantissa
    or   t5, t5, 0x00800000  # Add implicit leading 1 to b's mantissa

    # Perform integer division on mantissas
    div  t8, t4, t5      # Mantissa result = a.mantissa / b.mantissa

    # Normalize the result if needed (shift mantissa if necessary)
    li   t3, 0x00800000  # Normalization mask
1:  bge  t8, t3, 2f      # If normalized, skip the loop
    sll  t8, t8, 1       # Left shift mantissa (normalization)
    addi t7, t7, -1      # Adjust exponent
    j    1b              # Repeat until normalized
2:

    # Pack the result (combine sign, exponent, and mantissa)
    sll  t7, t7, 23      # Shift exponent into position
    and  t8, t8, 0x007FFFFF  # Mask the mantissa to 23 bits
    or   t9, t6, t7      # Combine sign and exponent
    or   t9, t9, t8      # Combine with mantissa

    # Store the result in memory
    la   t0, result      # Load address of result
    sw   t9, 0(t0)       # Store the result

    # End of program (halt)
    li   a0, 10          # Exit system call number
    ecall

    .data
result: .word 0x00000000 # Placeholder for result
