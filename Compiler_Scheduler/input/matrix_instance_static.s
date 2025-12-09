	.text
	.bss
matrix_one:
matrix_two:
output:
	.text
main:
	addi sp,sp,-32
	sw s0,28(sp)
	addi s0,sp,32
	sw zero,-20(s0)
	jal zero, .L2 # j .L2
.L3:
	addi a4, zero, 0 # lla a4, matrix_one (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	addi a4, zero, 1 # li a4, 1
	sw a4,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L2:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L3 # ble a4, a5, .L3
	sw zero,-20(s0)
	jal zero, .L4 # j .L4
.L5:
	addi a4, zero, 0 # lla a4, matrix_two (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	addi a4, zero, 1 # li a4, 1
	sw a4,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L4:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L5 # ble a4, a5, .L5
	sw zero,-20(s0)
	jal zero, .L6 # j .L6
.L7:
	addi a4, zero, 0 # lla a4, output (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	sw zero,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L6:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L7 # ble a4, a5, .L7
	sw zero,-20(s0)
	jal zero, .L8 # j .L8
.L9:
	addi a4, zero, 0 # lla a4, matrix_one (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a4,a5
	lw a4,0(a5)
	addi a3, zero, 0 # lla a3, matrix_two (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a3,a5
	lw a5,0(a5)
	add a4,a4,a5
	addi a3, zero, 0 # lla a3, output (unresolved)
	lw a5,-20(s0)
	slli a5,a5,2
	add a5,a3,a5
	sw a4,0(a5)
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L8:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L9 # ble a4, a5, .L9
	sw zero,-20(s0)
	jal zero, .L10 # j .L10
.L11:
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
.L10:
	lw a4,-20(s0)
	addi a5, zero, 99 # li a5, 99
	bge a5, a4, .L11 # ble a4, a5, .L11
.L12:
	jal zero, .L12 # j .L12