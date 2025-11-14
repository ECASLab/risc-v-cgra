# ============================================================================
# SOFTMAX (normalización exponencial)
# ============================================================================
# Normalización de logits a probabilidades: softmax(x) = exp(x) / Σexp(x)
# Busca máximo para estabilidad, calcula exponenciales aproximadas y normaliza
# a0: dirección logits (5 valores)
# a1: dirección output (5 valores)
# a2: dirección buffer max_value
# a3: dirección buffer sum_exp

softmax:
    # Paso 1: Encontrar máximo (para estabilidad numérica)
    addi s0, zero, 0  # i = 0
    addi t5, zero, -2147483648  # max = -inf (mínimo int32)

find_max:
    slli t0, s0, 2
    add t1, a0, t0
    lw t3, 0(t1)

    slt t6, t5, t3
    beq t6, zero, skip_max
    addi t5, t3, 0

skip_max:
    addi s0, s0, 1
    addi t0, zero, 5
    slt t6, s0, t0
    bne t6, zero, find_max

    # Guardar max_value
    sw t5, 0(a2)

    # Paso 2: Calcular exp(x_i - max) y acumular suma
    addi s0, zero, 0  # i = 0
    addi t5, zero, 0  # sum_exp = 0

compute_exp:
    # logits[i] - max
    slli t0, s0, 2
    add t1, a0, t0
    lw t3, 0(t1)
    sub t3, t3, t5  # t3 = logits[i] - max

    # Aproximación simple exp: e^x ≈ 1 + x + x²/2 + x³/6
    # Para simplificar con ISA limitado: exp_approx = (256 + x*64) >> 8
    addi t4, zero, 256
    addi t0, zero, 64
    multiply t0, t3, t0
    add t4, t4, t0
    srai t4, t4, 8  # exp aproximado

    # Acumular suma
    add t5, t5, t4

    # Guardar exp(x_i - max) temporalmente
    slli t0, s0, 2
    add t1, a1, t0
    sw t4, 0(t1)

    addi s0, s0, 1
    addi t0, zero, 5
    slt t6, s0, t0
    bne t6, zero, compute_exp

    # Guardar sum_exp
    sw t5, 0(a3)

    # Paso 3: Normalizar: output[i] = exp[i] / sum_exp
    addi s0, zero, 0  # i = 0

normalize:
    slli t0, s0, 2
    add t1, a1, t0
    lw t3, 0(t1)  # exp[i]
    lw t4, 0(a3)  # sum_exp

    # Approximar división: (exp[i] << 16) / sum_exp (16 bits de precisión)
    slli t3, t3, 16
    # Simulación división iterativa simplificada
    addi t6, zero, 0  # cociente
    addi t0, zero, 16

div_loop:
    slt t1, sum_exp, t3
    beq t1, zero, skip_div_bit
    sub t3, t3, t4
    addi t6, t6, 1

skip_div_bit:
    slli t4, t4, 1
    addi t0, t0, -1
    addi t1, zero, 0
    slt t1, t1, t0
    bne t1, zero, div_loop

    sw t6, 0(a1)

    addi s0, s0, 1
    addi t0, zero, 5
    slt t6, s0, t0
    bne t6, zero, normalize

    jalr zero, ra, 0