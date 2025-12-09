# ╔══════════════════════════════════════════════════════════════════╗
# ║    CÓDIGO ASSEMBLY CON INICIALIZACIÓN DE REGISTROS              ║
# ║    Generado por CGRA Compiler - Phase 3                         ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Registros únicos detectados: 4
# Instrucciones originales: 203
#

# ============================================
# BLOQUE DE INICIALIZACIÓN DE REGISTROS
# Inicializa todos los registros usados a 0
# para evitar valores indefinidos (X)
# ============================================

    addi a3, zero, 0
    addi a4, zero, 0
    addi a5, zero, 0
    addi s0, zero, 0

# ============================================
# FIN BLOQUE DE INICIALIZACIÓN
# ============================================


# ============================================
# CÓDIGO ORIGINAL
# ============================================

seed:
    addi sp, sp, -64
    sw s0, 60(sp)
    addi s0, sp, 64
    sw zero, -20(s0)
    jal zero, .L2
.L6:
    lui a5, 269413
    addi a5, a5, 0
    addi a5, a5, -403
    sw a5, -52(s0)
    lui a5, 3
    addi a5, a5, 0
    addi a5, a5, 57
    sw a5, -56(s0)
    addi a5, zero, 0
    lw a4, 0(a5)
    lw a5, -52(s0)
    mul a4, a4, a5
    lw a5, -56(s0)
    add a4, a4, a5
    addi a5, zero, 0
    sw a4, 0(a5)
    addi a5, zero, 0
    lw a5, 0(a5)
    bge a5, zero, .L3
    addi a5, zero, 0
    lw a5, 0(a5)
    sub a4, zero, a5
    addi a5, zero, 0
    sw a4, 0(a5)
.L3:
    addi a5, zero, 0
    lw a5, 0(a5)
    sw a5, -32(s0)
    jal zero, .L4
.L5:
    lw a5, -32(s0)
    addi a5, a5, -30
    sw a5, -32(s0)
.L4:
    lw a4, -32(s0)
    addi a5, zero, 29
    blt a5, a4, .L5
    addi a4, zero, 0
    lw a5, -20(s0)
    slli a5, a5, 2
    add a5, a4, a5
    lw a4, -32(s0)
    sw a4, 0(a5)
    lw a5, -20(s0)
    addi a5, a5, 1
    sw a5, -20(s0)
.L2:
    lw a4, -20(s0)
    addi a5, zero, 99
    bge a5, a4, .L6
    sw zero, -20(s0)
    jal zero, .L7
.L11:
    lui a5, 269413
    addi a5, a5, 0
    addi a5, a5, -403
    sw a5, -52(s0)
    lui a5, 3
    addi a5, a5, 0
    addi a5, a5, 57
    sw a5, -56(s0)
    addi a5, zero, 0
    lw a4, 0(a5)
    lw a5, -52(s0)
    mul a4, a4, a5
    lw a5, -56(s0)
    add a4, a4, a5
    addi a5, zero, 0
    sw a4, 0(a5)
    addi a5, zero, 0
    lw a5, 0(a5)
    bge a5, zero, .L8
    addi a5, zero, 0
    lw a5, 0(a5)
    sub a4, zero, a5
    addi a5, zero, 0
    sw a4, 0(a5)
.L8:
    addi a5, zero, 0
    lw a5, 0(a5)
    sw a5, -32(s0)
    jal zero, .L9
.L10:
    lw a5, -32(s0)
    addi a5, a5, -30
    sw a5, -32(s0)
.L9:
    lw a4, -32(s0)
    addi a5, zero, 29
    blt a5, a4, .L10
    addi a4, zero, 0
    lw a5, -20(s0)
    slli a5, a5, 2
    add a5, a4, a5
    lw a4, -32(s0)
    sw a4, 0(a5)
    lw a5, -20(s0)
    addi a5, a5, 1
    sw a5, -20(s0)
.L7:
    lw a4, -20(s0)
    addi a5, zero, 99
    bge a5, a4, .L11
    sw zero, -20(s0)
    jal zero, .L12
.L13:
    addi a4, zero, 0
    lw a5, -20(s0)
    slli a5, a5, 2
    add a5, a4, a5
    sw zero, 0(a5)
    lw a5, -20(s0)
    addi a5, a5, 1
    sw a5, -20(s0)
.L12:
    lw a4, -20(s0)
    addi a5, zero, 99
    bge a5, a4, .L13
    sw zero, -20(s0)
    jal zero, .L14
.L19:
    sw zero, -24(s0)
    jal zero, .L15
.L18:
    sw zero, -36(s0)
    sw zero, -28(s0)
    jal zero, .L16
.L17:
    lw a4, -20(s0)
    addi a5, a4, 0
    slli a5, a5, 2
    add a5, a5, a4
    slli a5, a5, 1
    addi a4, a5, 0
    lw a5, -28(s0)
    add a5, a5, a4
    sw a5, -44(s0)
    lw a4, -28(s0)
    addi a5, a4, 0
    slli a5, a5, 2
    add a5, a5, a4
    slli a5, a5, 1
    addi a4, a5, 0
    lw a5, -24(s0)
    add a5, a5, a4
    sw a5, -48(s0)
    addi a4, zero, 0
    lw a5, -44(s0)
    slli a5, a5, 2
    add a5, a4, a5
    lw a4, 0(a5)
    addi a3, zero, 0
    lw a5, -48(s0)
    slli a5, a5, 2
    add a5, a3, a5
    lw a5, 0(a5)
    mul a5, a4, a5
    lw a4, -36(s0)
    add a5, a4, a5
    sw a5, -36(s0)
    lw a5, -28(s0)
    addi a5, a5, 1
    sw a5, -28(s0)
.L16:
    lw a4, -28(s0)
    addi a5, zero, 9
    bge a5, a4, .L17
    lw a4, -20(s0)
    addi a5, a4, 0
    slli a5, a5, 2
    add a5, a5, a4
    slli a5, a5, 1
    addi a4, a5, 0
    lw a5, -24(s0)
    add a5, a5, a4
    sw a5, -40(s0)
    addi a4, zero, 0
    lw a5, -40(s0)
    slli a5, a5, 2
    add a5, a4, a5
    lw a4, -36(s0)
    sw a4, 0(a5)
    lw a5, -24(s0)
    addi a5, a5, 1
    sw a5, -24(s0)
.L15:
    lw a4, -24(s0)
    addi a5, zero, 9
    bge a5, a4, .L18
    lw a5, -20(s0)
    addi a5, a5, 1
    sw a5, -20(s0)
.L14:
    lw a4, -20(s0)
    addi a5, zero, 9
    bge a5, a4, .L19
    sw zero, -20(s0)
    jal zero, .L20
.L21:
    addi a4, zero, 0
    lw a5, -20(s0)
    slli a5, a5, 2
    add a5, a4, a5
    lw a4, 0(a5)
    addi a3, zero, 0
    lw a5, -20(s0)
    slli a5, a5, 2
    add a5, a3, a5
    sw a4, 0(a5)
    lw a5, -20(s0)
    addi a5, a5, 1
    sw a5, -20(s0)
.L20:
    lw a4, -20(s0)
    addi a5, zero, 99
    bge a5, a4, .L21
.L22:
    jal zero, .L22

# ============================================
# FIN DEL CÓDIGO
# ============================================
