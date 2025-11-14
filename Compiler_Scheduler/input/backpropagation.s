# ============================================================================
# BACKPROPAGATION - CÁLCULO DE GRADIENTES (capas simples)
# ============================================================================
# Backward pass: calcula gradientes dW, db, dx a partir de dL/doutput
# Entrada[4] -> W[4x3] -> Salida[3], propaga errores hacia atrás
# a0: dirección input (4 valores)
# a1: dirección W (4x3 = 12 valores)
# a2: dirección dL/doutput (gradientes de salida, 3 valores)
# a3: dirección dW (gradientes de pesos, 12 valores)
# a4: dirección db (gradientes de bias, 3 valores)
# a5: dirección dx (gradientes de entrada, 4 valores)

backprop:
    # Paso 1: db = dL/doutput (copiar directamente)
    addi s0, zero, 0  # i = 0

calc_db:
    slli t0, s0, 2
    add t1, a2, t0
    lw t3, 0(t1)
    add t1, a4, t0
    sw t3, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 3
    slt t6, s0, t0
    bne t6, zero, calc_db

    # Paso 2: dW[i][j] = dL/doutput[j] * input[i]
    addi s0, zero, 0  # i (entrada)

calc_dw_i:
    addi s1, zero, 0  # j (salida)

calc_dw_j:
    # Cargar input[i]
    slli t0, s0, 2
    add t1, a0, t0
    lw t3, 0(t1)

    # Cargar dL/doutput[j]
    slli t0, s1, 2
    add t1, a2, t0
    lw t4, 0(t1)

    # Calcular dW[i][j] = dL/doutput[j] * input[i]
    multiply t3, t3, t4

    # Almacenar en dW: índice = i*3 + j
    addi t0, zero, 3
    multiply t1, s0, t0
    add t1, t1, s1
    slli t1, t1, 2
    add t2, a3, t1
    sw t3, 0(t2)

    addi s1, s1, 1
    addi t0, zero, 3
    slt t6, s1, t0
    bne t6, zero, calc_dw_j

    addi s0, s0, 1
    addi t0, zero, 4
    slt t6, s0, t0
    bne t6, zero, calc_dw_i

    # Paso 3: dx[i] = sum_j(W[i][j] * dL/doutput[j])
    addi s0, zero, 0  # i (entrada)

calc_dx:
    addi t5, zero, 0  # acumulador = 0
    addi s1, zero, 0  # j (salida)

dx_accum:
    # Cargar W[i][j]
    addi t0, zero, 3
    multiply t1, s0, t0
    add t1, t1, s1
    slli t1, t1, 2
    add t2, a1, t1
    lw t3, 0(t2)

    # Cargar dL/doutput[j]
    slli t0, s1, 2
    add t1, a2, t0
    lw t4, 0(t1)

    # Acumular: dx += W[i][j] * dL/doutput[j]
    multiply t3, t3, t4
    add t5, t5, t3

    addi s1, s1, 1
    addi t0, zero, 3
    slt t6, s1, t0
    bne t6, zero, dx_accum

    # Guardar dx[i]
    slli t0, s0, 2
    add t1, a5, t0
    sw t5, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 4
    slt t6, s0, t0
    bne t6, zero, calc_dx

    jalr zero, ra, 0