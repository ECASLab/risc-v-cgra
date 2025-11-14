# ============================================================================
# FORWARD PASS - RED NEURONAL 2 CAPAS (matmul + ReLU)
# ============================================================================
# Forward pass de red neuronal: entrada[4] -> W1[4x8] + ReLU -> W2[8x10] -> salida[10]
# Realiza dos multiplicaciones matriciales con activación ReLU en la capa oculta
# Simula: input[4] -> matmul(W1[4x8]) -> ReLU -> matmul(W2[8x10]) -> output[10]
# a0: dirección input (4 valores)
# a1: dirección W1 (4x8 = 32 valores)
# a2: dirección W2 (8x10 = 80 valores)
# a3: dirección output (10 valores)
# a4: dirección buffer intermedio (8 valores)

forward_pass:
    # Capas 1: input[4] x W1[4x8] -> hidden[8]
    addi s0, zero, 0  # i = 0 (índice de salida en hidden)

hidden_loop:
    addi t5, zero, 0  # acumulador = 0
    addi s1, zero, 0  # k = 0 (índice en input)

hidden_accum:
    # Cargar input[k]
    slli t0, s1, 2
    add t1, a0, t0
    lw t3, 0(t1)

    # Calcular offset en W1: W1[k][i] -> k*8 + i
    addi t0, zero, 8
    multiply t0, s1, t0
    add t0, t0, s0
    slli t0, t0, 2
    add t1, a1, t0
    lw t4, 0(t1)

    # Acumular: t5 += input[k] * W1[k][i]
    multiply t3, t3, t4
    add t5, t5, t3

    addi s1, s1, 1
    addi t0, zero, 4
    slt t6, s1, t0
    bne t6, zero, hidden_accum

    # ReLU: max(0, t5)
    addi t0, zero, 0
    slt t6, t5, t0
    beq t6, zero, store_hidden
    addi t5, zero, 0

store_hidden:
    # Guardar hidden[i] en buffer intermedio
    slli t0, s0, 2
    add t1, a4, t0
    sw t5, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 8
    slt t6, s0, t0
    bne t6, zero, hidden_loop

    # Capa 2: hidden[8] x W2[8x10] -> output[10]
    addi s0, zero, 0  # i = 0 (índice de salida)

output_loop:
    addi t5, zero, 0  # acumulador = 0
    addi s1, zero, 0  # k = 0

output_accum:
    # Cargar hidden[k]
    slli t0, s1, 2
    add t1, a4, t0
    lw t3, 0(t1)

    # Calcular offset en W2: W2[k][i] -> k*10 + i
    addi t0, zero, 10
    multiply t0, s1, t0
    add t0, t0, s0
    slli t0, t0, 2
    add t1, a2, t0
    lw t4, 0(t1)

    # Acumular
    multiply t3, t3, t4
    add t5, t5, t3

    addi s1, s1, 1
    addi t0, zero, 8
    slt t6, s1, t0
    bne t6, zero, output_accum

    # Guardar output[i]
    slli t0, s0, 2
    add t1, a3, t0
    sw t5, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 10
    slt t6, s0, t0
    bne t6, zero, output_loop

    jalr zero, ra, 0