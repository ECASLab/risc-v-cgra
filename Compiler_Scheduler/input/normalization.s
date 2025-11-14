# ============================================================================
# BATCH NORMALIZATION (normalización por lotes)
# ============================================================================
# Normaliza datos: (x - media) / sqrt(varianza + eps), luego escala con gamma y suma beta
# Procesa 3 muestras x 4 features, calcula estadísticas y normaliza
# a0: dirección input (12 valores: 3 muestras x 4 features)
# a1: dirección output (12 valores)
# a2: dirección gamma (4 valores)
# a3: dirección beta (4 valores)
# a4: dirección buffer para medias (4 valores)
# a5: dirección buffer para varianzas (4 valores)

batch_norm:
    # Paso 1: Calcular media por feature
    addi s0, zero, 0  # feature = 0

calc_mean:
    addi t5, zero, 0  # suma = 0
    addi s1, zero, 0  # muestra = 0

mean_accum:
    # Índice: muestra * 4 + feature
    addi t0, zero, 4
    multiply t1, s1, t0
    add t1, t1, s0
    slli t1, t1, 2
    add t2, a0, t1
    lw t3, 0(t2)

    add t5, t5, t3

    addi s1, s1, 1
    addi t0, zero, 3
    slt t6, s1, t0
    bne t6, zero, mean_accum

    # Media = suma / 3 (aproximado: suma >> 1 es suma/2)
    srai t5, t5, 1

    # Guardar media
    slli t0, s0, 2
    add t1, a4, t0
    sw t5, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 4
    slt t6, s0, t0
    bne t6, zero, calc_mean

    # Paso 2: Calcular varianza por feature
    addi s0, zero, 0  # feature = 0

calc_variance:
    addi t5, zero, 0  # suma_diff_sq = 0
    addi s1, zero, 0  # muestra = 0

    # Cargar media para este feature
    slli t0, s0, 2
    add t1, a4, t0
    lw t7, 0(t1)

var_accum:
    # Índice: muestra * 4 + feature
    addi t0, zero, 4
    multiply t1, s1, t0
    add t1, t1, s0
    slli t1, t1, 2
    add t2, a0, t1
    lw t3, 0(t2)

    # (x - media)
    sub t3, t3, t7

    # (x - media)²
    multiply t3, t3, t3

    add t5, t5, t3

    addi s1, s1, 1
    addi t0, zero, 3
    slt t6, s1, t0
    bne t6, zero, var_accum

    # Varianza = suma_diff_sq / 3
    srai t5, t5, 1

    # Guardar varianza
    slli t0, s0, 2
    add t1, a5, t0
    sw t5, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 4
    slt t6, s0, t0
    bne t6, zero, calc_variance

    # Paso 3: Normalizar y aplicar gamma/beta
    addi s0, zero, 0  # índice lineal

normalize_batchnorm:
    # Calcular feature = índice % 4
    addi t0, s0, 0
    addi t1, zero, 4

mod_loop:
    slt t6, t1, t0
    beq t6, zero, mod_done
    sub t0, t0, t1
    jal zero, mod_loop

mod_done:
    addi t1, t0, 0  # feature = resultado del módulo

    # Cargar x[índice]
    slli t0, s0, 2
    add t2, a0, t0
    lw t3, 0(t2)

    # Cargar media y varianza
    slli t0, t1, 2
    add t2, a4, t0
    lw t4, 0(t2)
    add t2, a5, t0
    lw t5, 0(t2)

    # (x - media) / sqrt(varianza + eps)
    sub t3, t3, t4
    addi t5, t5, 1  # eps = 1
    # sqrt aproximado: x >> 1
    srai t5, t5, 1

    # Aproximación división simplificada
    add t3, t3, t5
    srai t3, t3, 1

    # Cargar gamma y beta
    slli t0, t1, 2
    add t2, a2, t0
    lw t6, 0(t2)
    add t2, a3, t0
    lw t7, 0(t2)

    # output = gamma * normalized + beta
    multiply t3, t3, t6
    add t3, t3, t7

    # Guardar
    slli t0, s0, 2
    add t2, a1, t0
    sw t3, 0(t2)

    addi s0, s0, 1
    addi t0, zero, 12
    slt t6, s0, t0
    bne t6, zero, normalize_batchnorm

    jalr zero, ra, 0