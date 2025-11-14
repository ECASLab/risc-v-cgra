# ============================================================================
# MATRIZ MULTIPLICACIÓN (matmul.s)
# ============================================================================
# Multiplica dos matrices A y B de 3x3, resultado en C
# Usa triple bucle anidado (i, j, k) para calcular C[i][j] = Σ A[i][k]*B[k][j]
# Los índices 2D se convierten a offsets lineales: (i*3 + j)*4 bytes
# Se usa slt+bne en lugar de blt (no disponible en ISA)
# a0: dirección de la matriz A
# a1: dirección de la matriz B
# a2: dirección de la matriz C
# Se asume que las matrices son de 3x3.

matmul:
    # Registros:
    # a0, a1, a2: Punteros base a A, B, C
    # t0, t1, t6: Usados para cálculos de direcciones y temporales
    # t3, t4: valores cargados de A y B
    # t5: acumulador para el producto punto
    # s0, s1, s2: contadores de bucle (i, j, k)

    addi s0, zero, 0  # i = 0
loop_i:
    addi s1, zero, 0  # j = 0
loop_j:
    addi s2, zero, 0  # k = 0
    addi t5, zero, 0  # Acumulador = 0

loop_k:
    # Calcular dirección y cargar A[i][k]
    addi t0, zero, 3
    multiply t0, s0, t0 # i * 3
    add t0, t0, s2    # i * 3 + k
    slli t0, t0, 2    # offset = (i * 3 + k) * 4
    add t1, a0, t0    # dirección = base_A + offset
    lw t3, 0(t1)      # t3 = A[i][k]

    # Calcular dirección y cargar B[k][j]
    addi t0, zero, 3
    multiply t0, s2, t0 # k * 3
    add t0, t0, s1    # k * 3 + j
    slli t0, t0, 2    # offset = (k * 3 + j) * 4
    add t1, a1, t0    # dirección = base_B + offset
    lw t4, 0(t1)      # t4 = B[k][j]

    # Acumular el producto
    multiply t3, t3, t4
    add t5, t5, t3

    # Incremento y condición del bucle k
    addi s2, s2, 1
    addi t0, zero, 3
    slt t6, s2, t0
    bne t6, zero, loop_k # Reemplazo de 'blt s2, 3, loop_k'

    # Calcular la dirección y guardar C[i][j]
    addi t0, zero, 3
    multiply t0, s0, t0 # i * 3
    add t0, t0, s1    # i * 3 + j
    slli t0, t0, 2    # offset = (i * 3 + j) * 4
    add t1, a2, t0    # dirección = base_C + offset
    sw t5, 0(t1)

    # Incremento y condición del bucle j
    addi s1, s1, 1
    addi t0, zero, 3
    slt t6, s1, t0
    bne t6, zero, loop_j # Reemplazo de 'blt s1, 3, loop_j'

    # Incremento y condición del bucle i
    addi s0, s0, 1
    addi t0, zero, 3
    slt t6, s0, t0
    bne t6, zero, loop_i # Reemplazo de 'blt s0, 3, loop_i'

    jalr zero, ra, 0
