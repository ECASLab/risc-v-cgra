	.text
int_matrix_init:
	addi sp,sp,-48
	sw s0,44(sp)
	addi s0,sp,48
	sw a0,-36(s0)
	sw a1,-40(s0)
	sw a2,-44(s0)
	sw zero,-28(s0)
	lw a4,-40(s0)
	addi a5, zero, 10 # li a5, 10
	bne a4,a5,.L2
	lw a4,-44(s0)
	addi a5, zero, 10 # li a5, 10
	beq a4,a5,.L3
.L2:
	addi a5, zero, -1 # li a5, -1
	sw a5,-28(s0)
	lw a5,-28(s0)
	jal zero, .L9 # j .L9
.L3:
	lw a5,-36(s0)
	lw a4,-40(s0)
	sw a4,0(a5)
	lw a5,-36(s0)
	lw a4,-44(s0)
	sw a4,4(a5)
	sw zero,-20(s0)
	jal zero, .L5 # j .L5
.L8:
	sw zero,-24(s0)
	jal zero, .L6 # j .L6
.L7:
	lw a3,-36(s0)
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	lw a4,-24(s0)
	add a5,a5,a4
	slli a5,a5,2
	add a5,a3,a5
	sw zero,8(a5)
	lw a5,-24(s0)
	addi a5,a5,1
	sw a5,-24(s0)
.L6:
	lw a4,-24(s0)
	lw a5,-44(s0)
	bltu a4,a5,.L7
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L5:
	lw a4,-20(s0)
	lw a5,-40(s0)
	bltu a4,a5,.L8
	lw a5,-28(s0)
.L9:
	addi a0, a5, 0 # mv a0, a5
	lw s0,44(sp)
	addi sp,sp,48
	jalr zero, ra, 0 # jr ra
int_matrix_sum:
	addi sp,sp,-48
	sw s0,44(sp)
	addi s0,sp,48
	sw a0,-36(s0)
	sw a1,-40(s0)
	sw a2,-44(s0)
	sw zero,-28(s0)
	lw a5,-36(s0)
	lw a4,0(a5)
	lw a5,-40(s0)
	lw a5,0(a5)
	bne a4,a5,.L11
	lw a5,-36(s0)
	lw a4,4(a5)
	lw a5,-40(s0)
	lw a5,4(a5)
	bne a4,a5,.L11
	lw a5,-36(s0)
	lw a4,0(a5)
	lw a5,-44(s0)
	lw a5,0(a5)
	bne a4,a5,.L11
	lw a5,-36(s0)
	lw a4,4(a5)
	lw a5,-44(s0)
	lw a5,4(a5)
	beq a4,a5,.L12
.L11:
	addi a5, zero, -1 # li a5, -1
	sw a5,-28(s0)
	lw a5,-28(s0)
	jal zero, .L18 # j .L18
.L12:
	sw zero,-20(s0)
	jal zero, .L14 # j .L14
.L17:
	sw zero,-24(s0)
	jal zero, .L15 # j .L15
.L16:
	lw a3,-36(s0)
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	lw a4,-24(s0)
	add a5,a5,a4
	slli a5,a5,2
	add a5,a3,a5
	lw a3,8(a5)
	lw a2,-40(s0)
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	lw a4,-24(s0)
	add a5,a5,a4
	slli a5,a5,2
	add a5,a2,a5
	lw a5,8(a5)
	add a3,a3,a5
	lw a2,-44(s0)
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	lw a4,-24(s0)
	add a5,a5,a4
	slli a5,a5,2
	add a5,a2,a5
	sw a3,8(a5)
	lw a5,-24(s0)
	addi a5,a5,1
	sw a5,-24(s0)
.L15:
	lw a5,-44(s0)
	lw a5,4(a5)
	lw a4,-24(s0)
	bltu a4,a5,.L16
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L14:
	lw a5,-44(s0)
	lw a5,0(a5)
	lw a4,-20(s0)
	bltu a4,a5,.L17
	lw a5,-28(s0)
.L18:
	addi a0, a5, 0 # mv a0, a5
	lw s0,44(sp)
	addi sp,sp,48
	jalr zero, ra, 0 # jr ra
main:
	addi sp,sp,-1280
	sw ra,1276(sp)
	sw s0,1272(sp)
	addi s0,sp,1280
	addi a5, zero, 10 # li a5, 10
	sw a5,-28(s0)
	addi a5,s0,-436
	lw a2,-28(s0)
	lw a1,-28(s0)
	addi a0, a5, 0 # mv a0, a5
	jal ra, int_matrix_init # call int_matrix_init
	addi a5, a0, 0 # mv a5, a0
	sw a5,-1256(s0)
	addi a5,s0,-844
	lw a2,-28(s0)
	lw a1,-28(s0)
	addi a0, a5, 0 # mv a0, a5
	jal ra, int_matrix_init # call int_matrix_init
	addi a5, a0, 0 # mv a5, a0
	sw a5,-1260(s0)
	addi a5,s0,-1252
	lw a2,-28(s0)
	lw a1,-28(s0)
	addi a0, a5, 0 # mv a0, a5
	jal ra, int_matrix_init # call int_matrix_init
	addi a5, a0, 0 # mv a5, a0
	sw a5,-1264(s0)
	lw a5,-1256(s0)
	bne a5,zero,.L20
	lw a5,-1260(s0)
	bne a5,zero,.L20
	lw a5,-1264(s0)
	beq a5,zero,.L21
.L20:
	addi a5, zero, -1 # li a5, -1
	jal zero, .L28 # j .L28
.L21:
	sw zero,-20(s0)
	jal zero, .L23 # j .L23
.L26:
	sw zero,-24(s0)
	jal zero, .L24 # j .L24
.L25:
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	lw a4,-24(s0)
	add a5,a5,a4
	slli a5,a5,2
	addi a5,a5,-16
	add a5,a5,s0
	addi a4, zero, 1 # li a4, 1
	sw a4,-412(a5)
	lw a4,-20(s0)
	addi a5, a4, 0 # mv a5, a4
	slli a5,a5,2
	add a5,a5,a4
	slli a5,a5,1
	lw a4,-24(s0)
	add a5,a5,a4
	slli a5,a5,2
	addi a5,a5,-16
	add a5,a5,s0
	addi a4, zero, 1 # li a4, 1
	sw a4,-820(a5)
	lw a5,-24(s0)
	addi a5,a5,1
	sw a5,-24(s0)
.L24:
	lw a4,-24(s0)
	lw a5,-28(s0)
	bltu a4,a5,.L25
	lw a5,-20(s0)
	addi a5,a5,1
	sw a5,-20(s0)
.L23:
	lw a4,-20(s0)
	lw a5,-28(s0)
	bltu a4,a5,.L26
	addi a3,s0,-1252
	addi a4,s0,-844
	addi a5,s0,-436
	addi a2, a3, 0 # mv a2, a3
	addi a1, a4, 0 # mv a1, a4
	addi a0, a5, 0 # mv a0, a5
	jal ra, int_matrix_sum # call int_matrix_sum
	addi a5, a0, 0 # mv a5, a0
	sw a5,-1268(s0)
	lw a5,-1268(s0)
	bne a5,zero,.L27
	lw a4,-1244(s0)
	addi a5, zero, 2 # li a5, 2
	bne a4,a5,.L27
	addi a5, zero, 0 # li a5, 0
	jal zero, .L28 # j .L28
.L27:
	addi a5, zero, -1 # li a5, -1
.L28:
	addi a0, a5, 0 # mv a0, a5
	lw ra,1276(sp)
	lw s0,1272(sp)
	addi sp,sp,1280
	jalr zero, ra, 0 # jr ra