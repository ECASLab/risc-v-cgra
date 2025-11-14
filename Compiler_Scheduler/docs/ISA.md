# RISC-V Instruction Formats

## R Type Instruction
| funct7 | rs2 | rs1 | funct3 | rd | op |
|--------|-----|-----|--------|----|----|
| 7 bits | 5 bits | 5 bits | 3 bits | 5 bits | 7 bits |

## I Type Instruction
| imm11:0 | rs1 | funct3 | rd | op |
|---------|-----|--------|----|----|
| 12 bits | 5 bits | 3 bits | 5 bits | 7 bits |

## S Type Instruction
| imm12:5 | rs2 | rs1 | funct3 | imm4:0 | op |
|---------|-----|-----|--------|--------|----|
| 7 bits | 5 bits | 5 bits | 3 bits | 5 bits | 7 bits |

## U Type Instruction
| immhi | rd | op |
|-------|----|----|
| 20 bits | 5 bits | 7 bits |

## B Type Instruction
| imm12,10:5 | rs2 | rs1 | funct3 | imm4:1,11 | op |
|------------|-----|-----|--------|-----------|-----|
| 7 bits | 5 bits | 5 bits | 3 bits | 5 bits | 7 bits |

## J Type Instruction
| immhi 20, 10:1, 11, 19:12 | rd | op |
|---------------------------|----|----|
| 20 bits | 5 bits | 7 bits |

---

# Tabla 3.1: Instrucciones de RISC-V

| Op | Instrucciones | Tipo instrucción |
|---------|--------------|------------------|
| 0000011 | lb, lh, lw, lbu, lhu | I |
| 0010011 | addi, slli, slti, sltiu, xori, srli, srai, ori, andi | I |
| 0100011 | sb, sh, sw | S |
| 0110011 | add, sub, sll, slt, sltu, xor, srl, sra, or, and, multiply | R |
| 0110111 | load upper immediate | U |
| 1100011 | branch if equal, not equal | B |
| 1101111 | jump and link register | J |