	.text
	.bss
matrix_one:
matrix_two:
output:
seed:
	.word	12345
	.text
main:
	addi sp,sp,-64
	sw s0,60(sp)
	addi s0,sp,64
	sw zero,-20(s0)
	jal zero, .L2 # j .L2
.L6:
	lui a5, 269413 # li a5, 1103515648
	addi a5, a5, 0
	addi a5,a5,-403
	sw a5,-52(s0)
	lui a5, 3 # li a5, 12288
	addi a5, a5, 0
	addi a5,a5,57
	sw a5,-56(s0)
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a4,0(a5)
	lw a5,-52(s0)
	mul a4,a4,a5
	lw a5,-56(s0)
	add a4,a4,a5
	addi a5, zero, 0 # lla a5, seed (unresolved)
	sw a4,0(a5)
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a5,0(a5)
	bge a5,zero,.L3
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a5,0(a5)
	sub a4, zero, a5 # neg a4, a5
	addi a5, zero, 0 # lla a5, seed (unresolved)
	sw a4,0(a5)
.L3:
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a5,0(a5)
	sw a5,-32(s0)
	jal zero, .L4 # j .L4
.L5:
	lw a5,-32(s0)
	addi a5,a5,-30
	sw a5,-32(s0)
.L4:
	lw a4,-32(s0)
	addi a5, zero, 29 # li a5, 29
	blt a5, a4, .L5 # bgt a4, a5, .L5
	addi a4, zero, 0 # lla a4, matrix_one (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	lw a4,-32(s0)
	sw a4,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L2:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L6 # ble a4, a5, .L6
	sw zero,-20(s0)
	jal zero, .L7 # j .L7
.L11:
	lui a5, 269413 # li a5, 1103515648
	addi a5, a5, 0
	addi a5,a5,-403
	sw a5,-52(s0)
	lui a5, 3 # li a5, 12288
	addi a5, a5, 0
	addi a5,a5,57
	sw a5,-56(s0)
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a4,0(a5)
	lw a5,-52(s0)
	mul a4,a4,a5
	lw a5,-56(s0)
	add a4,a4,a5
	addi a5, zero, 0 # lla a5, seed (unresolved)
	sw a4,0(a5)
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a5,0(a5)
	bge a5,zero,.L8
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a5,0(a5)
	sub a4, zero, a5 # neg a4, a5
	addi a5, zero, 0 # lla a5, seed (unresolved)
	sw a4,0(a5)
.L8:
	addi a5, zero, 0 # lla a5, seed (unresolved)
	lw a5,0(a5)
	sw a5,-32(s0)
	jal zero, .L9 # j .L9
.L10:
	lw a5,-32(s0)
	addi a5,a5,-30
	sw a5,-32(s0)
.L9:
	lw a4,-32(s0)
	addi a5, zero, 29 # li a5, 29
	blt a5, a4, .L10 # bgt a4, a5, .L10
	addi a4, zero, 0 # lla a4, matrix_two (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	lw a4,-32(s0)
	sw a4,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L7:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L11 # ble a4, a5, .L11
	sw zero,-20(s0)
	jal zero, .L12 # j .L12
.L13:
	addi a4, zero, 0 # lla a4, output (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	sw zero,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L12:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L13 # ble a4, a5, .L13
	sw zero,-20(s0)
	jal zero, .L14 # j .L14
.L19:
	sw zero,-24(s0)
	jal zero, .L15 # j .L15
.L18:
	sw zero,-36(s0)
	sw zero,-28(s0)
	jal zero, .L16 # j .L16
.L17:
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	addi a4, a5, 0 # mv a4, a5
	lw a5,-28(s0)
	add a5,a5,a4
	sw a5,-44(s0)
	lw a4,-28(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	addi a4, a5, 0 # mv a4, a5
	lw a5,-24(s0)
	add a5,a5,a4
	sw a5,-48(s0)
	addi a4, zero, 0 # lla a4, matrix_one (unresolved)
	lw a5,-44(s0)
	slli a5,a5,2
	add a5,a4,a5
	lw a4,0(a5)
	addi a3, zero, 0 # lla a3, matrix_two (unresolved)
	lw a5,-48(s0)
	slli a5,a5,2
	add a5,a3,a5
	lw a5,0(a5)
	mul a5,a4,a5
	lw a4,-36(s0)
	add a5,a4,a5
	sw a5,-36(s0)
	lw a5,-28(s0)
	addi a5,a5,1
	sw a5,-28(s0)
.L16:
	lw a4,-28(s0)
	addi a5, zero, 9 # li a5, 9
	bge a5, a4, .L17 # ble a4, a5, .L17
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	addi a4, a5, 0 # mv a4, a5
	lw a5,-24(s0)
	add a5,a5,a4
	sw a5,-40(s0)
	addi a4, zero, 0 # lla a4, output (unresolved)
	lw a5,-40(s0)
	slli a5,a5,2
	add a5,a4,a5
	lw a4,-36(s0)
	sw a4,0(a5)
	lw a5,-24(s0)
	addi a5,a5,1
	sw a5,-24(s0)
.L15:
	lw a4,-24(s0)
	addi a5, zero, 9 # li a5, 9
	bge a5, a4, .L18 # ble a4, a5, .L18
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L14:
	lw a4,-20(s0)
	addi a5, zero, 9 # li a5, 9
	bge a5, a4, .L19 # ble a4, a5, .L19
	sw zero,-20(s0)
	jal zero, .L20 # j .L20
.L21:
	addi a4, zero, 0 # lla a4, output (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	lw a4,0(a5)
	addi a3, zero, 0 # lla a3, output (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a3,a5
	sw a4,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L20:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L21 # ble a4, a5, .L21
.L22:
	jal zero, .L22 # j .L22