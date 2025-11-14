#!/usr/bin/env python3
"""
RISC-V Assembly Validator for CGRA ISA
"""

import sys
import re

class AsmValidator:
    def __init__(self):
        self.supported_opcodes = {
            'add', 'sub', 'multiply', 'and', 'or', 'xor', 
            'sll', 'srl', 'sra', 'slt', 'sltu',
            'addi', 'slti', 'sltiu', 'xori', 'ori', 'andi',
            'slli', 'srli', 'srai',
            'lw', 'lh', 'lhu', 'lb', 'lbu',
            'jalr',
            'sw', 'sh', 'sb',
            'beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu',
            'jal',
            'lui', 'auipc'
        }
        
        self.valid_registers = set()
        for i in range(32):
            self.valid_registers.add(f'x{i}')
        
        aliases = {
            'zero': 'x0', 'ra': 'x1', 'sp': 'x2', 'gp': 'x3', 'tp': 'x4',
            't0': 'x5', 't1': 'x6', 't2': 'x7',
            's0': 'x8', 'fp': 'x8', 's1': 'x9',
            'a0': 'x10', 'a1': 'x11', 'a2': 'x12', 'a3': 'x13',
            'a4': 'x14', 'a5': 'x15', 'a6': 'x16', 'a7': 'x17',
            's2': 'x18', 's3': 'x19', 's4': 'x20', 's5': 'x21',
            's6': 'x22', 's7': 'x23', 's8': 'x24', 's9': 'x25',
            's10': 'x26', 's11': 'x27',
            't3': 'x28', 't4': 'x29', 't5': 'x30', 't6': 'x31'
        }
        self.valid_registers.update(aliases.keys())
        
        self.r_type = {'add', 'sub', 'multiply', 'and', 'or', 'xor', 
                       'sll', 'srl', 'sra', 'slt', 'sltu'}
        self.i_type_alu = {'addi', 'slti', 'sltiu', 'xori', 'ori', 'andi'}
        self.i_type_shift = {'slli', 'srli', 'srai'}
        self.i_type_load = {'lw', 'lh', 'lhu', 'lb', 'lbu'}
        self.i_type_jalr = {'jalr'}
        self.s_type = {'sw', 'sh', 'sb'}
        self.b_type = {'beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu'}
        self.j_type = {'jal'}
        self.u_type = {'lui', 'auipc'}
        
        self.errors = []
        self.warnings = []
        self.stats = {
            'total_lines': 0,
            'instructions': 0,
            'labels': 0,
            'comments': 0,
            'directives': 0
        }
    
    def validate_file(self, filepath):
        try:
            with open(filepath, 'r') as f:
                lines = f.readlines()
            
            self.stats['total_lines'] = len(lines)
            
            for line_num, line in enumerate(lines, 1):
                self.validate_line(line, line_num)
            
            return self.print_report()
            
        except FileNotFoundError:
            print(f"[ERROR] Error: File not found: {filepath}")
            return False
        except Exception as e:
            print(f"[ERROR] Error: {e}")
            return False
    
    def validate_line(self, line, line_num):
        # Remove inline comments
        if '#' in line:
            code_part = line.split('#')[0]
        else:
            code_part = line
        
        code_part = code_part.strip()
        
        # Empty line
        if not code_part:
            if line.strip().startswith('#'):
                self.stats['comments'] += 1
            return
        
        # Pure comment
        if line.strip().startswith('#'):
            self.stats['comments'] += 1
            return
        
        # Label
        if code_part.endswith(':'):
            self.stats['labels'] += 1
            return
        
        # Directive
        if code_part.startswith('.'):
            self.stats['directives'] += 1
            return
        
        # Instruction - split only on first whitespace
        tokens = code_part.split(None, 1)
        if not tokens:
            return
        
        opcode = tokens[0].lower()
        operands_str = tokens[1] if len(tokens) > 1 else ''
        
        self.stats['instructions'] += 1
        self.validate_instruction(opcode, operands_str, line_num, code_part)
    
    def validate_instruction(self, opcode, operands_str, line_num, full_line):
        # Check if opcode is supported
        if opcode not in self.supported_opcodes:
            self.errors.append((line_num, f"Unsupported opcode: '{opcode}'", full_line))
            return
        
        # Parse operands
        ops = [op.strip() for op in operands_str.split(',')]
        
        # Validate based on instruction type
        if opcode in self.r_type:
            self.validate_r_type(opcode, ops, line_num, full_line)
        elif opcode in self.i_type_alu:
            self.validate_i_type_alu(opcode, ops, line_num, full_line)
        elif opcode in self.i_type_shift:
            self.validate_i_type_shift(opcode, ops, line_num, full_line)
        elif opcode in self.i_type_load:
            self.validate_i_type_load(opcode, ops, line_num, full_line)
        elif opcode in self.i_type_jalr:
            self.validate_jalr(opcode, ops, line_num, full_line)
        elif opcode in self.s_type:
            self.validate_s_type(opcode, ops, line_num, full_line)
        elif opcode in self.b_type:
            self.validate_b_type(opcode, ops, line_num, full_line)
        elif opcode in self.j_type:
            self.validate_j_type(opcode, ops, line_num, full_line)
        elif opcode in self.u_type:
            self.validate_u_type(opcode, ops, line_num, full_line)
    
    def validate_r_type(self, opcode, ops, line_num, full_line):
        if len(ops) != 3:
            self.errors.append((line_num, f"R-type expects 3 operands, got {len(ops)}", full_line))
            return
        
        rd, rs1, rs2 = ops
        
        if not self.is_valid_register(rd):
            self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
        if not self.is_valid_register(rs1):
            self.errors.append((line_num, f"Invalid source register 1: '{rs1}'", full_line))
        if not self.is_valid_register(rs2):
            self.errors.append((line_num, f"Invalid source register 2: '{rs2}'", full_line))
    
    def validate_i_type_alu(self, opcode, ops, line_num, full_line):
        if len(ops) != 3:
            self.errors.append((line_num, f"I-type ALU expects 3 operands, got {len(ops)}", full_line))
            return
        
        rd, rs1, imm_str = ops
        
        if not self.is_valid_register(rd):
            self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
        if not self.is_valid_register(rs1):
            self.errors.append((line_num, f"Invalid source register: '{rs1}'", full_line))
        
        try:
            imm = self.parse_immediate(imm_str)
            if not (-2048 <= imm <= 2047):
                self.errors.append((line_num, f"Immediate {imm} out of range [-2048, 2047]", full_line))
        except:
            self.errors.append((line_num, f"Invalid immediate value: '{imm_str}'", full_line))
    
    def validate_i_type_shift(self, opcode, ops, line_num, full_line):
        if len(ops) != 3:
            self.errors.append((line_num, f"Shift expects 3 operands, got {len(ops)}", full_line))
            return
        
        rd, rs1, shamt_str = ops
        
        if not self.is_valid_register(rd):
            self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
        if not self.is_valid_register(rs1):
            self.errors.append((line_num, f"Invalid source register: '{rs1}'", full_line))
        
        try:
            shamt = self.parse_immediate(shamt_str)
            if not (0 <= shamt <= 31):
                self.errors.append((line_num, f"Shift amount {shamt} out of range [0, 31]", full_line))
        except:
            self.errors.append((line_num, f"Invalid shift amount: '{shamt_str}'", full_line))
    
    def validate_i_type_load(self, opcode, ops, line_num, full_line):
        if len(ops) != 2:
            self.errors.append((line_num, f"Load expects 2 operands, got {len(ops)}", full_line))
            return
        
        rd = ops[0]
        mem_access = ops[1]
        
        if not self.is_valid_register(rd):
            self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
        
        # Parse offset(base)
        match = re.match(r'(-?\d+)\((\w+)\)', mem_access)
        if not match:
            self.errors.append((line_num, f"Invalid memory access format: '{mem_access}'", full_line))
            return
        
        offset_str, base = match.groups()
        
        if not self.is_valid_register(base):
            self.errors.append((line_num, f"Invalid base register: '{base}'", full_line))
        
        try:
            offset = int(offset_str)
            if not (-2048 <= offset <= 2047):
                self.errors.append((line_num, f"Offset {offset} out of range [-2048, 2047]", full_line))
        except:
            self.errors.append((line_num, f"Invalid offset: '{offset_str}'", full_line))
    
    def validate_jalr(self, opcode, ops, line_num, full_line):
        if len(ops) != 3:
            self.errors.append((line_num, f"JALR expects 3 operands, got {len(ops)}", full_line))
            return
        
        rd, rs1, offset_str = ops
        
        if not self.is_valid_register(rd):
            self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
        if not self.is_valid_register(rs1):
            self.errors.append((line_num, f"Invalid base register: '{rs1}'", full_line))
        
        try:
            offset = self.parse_immediate(offset_str)
            if not (-2048 <= offset <= 2047):
                self.errors.append((line_num, f"Offset {offset} out of range [-2048, 2047]", full_line))
        except:
            self.errors.append((line_num, f"Invalid offset: '{offset_str}'", full_line))
    
    def validate_s_type(self, opcode, ops, line_num, full_line):
        if len(ops) != 2:
            self.errors.append((line_num, f"Store expects 2 operands, got {len(ops)}", full_line))
            return
        
        rs2 = ops[0]
        mem_access = ops[1]
        
        if not self.is_valid_register(rs2):
            self.errors.append((line_num, f"Invalid source register: '{rs2}'", full_line))
        
        # Parse offset(base)
        match = re.match(r'(-?\d+)\((\w+)\)', mem_access)
        if not match:
            self.errors.append((line_num, f"Invalid memory access format: '{mem_access}'", full_line))
            return
        
        offset_str, base = match.groups()
        
        if not self.is_valid_register(base):
            self.errors.append((line_num, f"Invalid base register: '{base}'", full_line))
        
        try:
            offset = int(offset_str)
            if not (-2048 <= offset <= 2047):
                self.errors.append((line_num, f"Offset {offset} out of range [-2048, 2047]", full_line))
        except:
            self.errors.append((line_num, f"Invalid offset: '{offset_str}'", full_line))
    
    def validate_b_type(self, opcode, ops, line_num, full_line):
        if len(ops) != 3:
            self.errors.append((line_num, f"Branch expects 3 operands, got {len(ops)}", full_line))
            return
        
        rs1, rs2, label = ops
        
        if not self.is_valid_register(rs1):
            self.errors.append((line_num, f"Invalid source register 1: '{rs1}'", full_line))
        if not self.is_valid_register(rs2):
            self.errors.append((line_num, f"Invalid source register 2: '{rs2}'", full_line))
        
        if not self.is_valid_label(label):
            self.warnings.append((line_num, f"Unusual branch target: '{label}'"))
    
    def validate_j_type(self, opcode, ops, line_num, full_line):
        if len(ops) == 1:
            label = ops[0]
            if not self.is_valid_label(label):
                self.warnings.append((line_num, f"Unusual jump target: '{label}'"))
        elif len(ops) == 2:
            rd, label = ops
            if not self.is_valid_register(rd):
                self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
            if not self.is_valid_label(label):
                self.warnings.append((line_num, f"Unusual jump target: '{label}'"))
        else:
            self.errors.append((line_num, f"JAL expects 1 or 2 operands, got {len(ops)}", full_line))
    
    def validate_u_type(self, opcode, ops, line_num, full_line):
        if len(ops) != 2:
            self.errors.append((line_num, f"U-type expects 2 operands, got {len(ops)}", full_line))
            return
        
        rd, imm_str = ops
        
        if not self.is_valid_register(rd):
            self.errors.append((line_num, f"Invalid destination register: '{rd}'", full_line))
        
        try:
            imm = self.parse_immediate(imm_str)
            if not (0 <= imm <= 0xFFFFF):
                self.warnings.append((line_num, f"Immediate {imm} may be truncated to 20 bits"))
        except:
            self.errors.append((line_num, f"Invalid immediate value: '{imm_str}'", full_line))
    
    def is_valid_register(self, reg):
        return reg.lower() in self.valid_registers
    
    def is_valid_label(self, label):
        return bool(re.match(r'^[A-Za-z0-9_.]+$', label))
    
    def parse_immediate(self, imm_str):
        imm_str = imm_str.strip().strip(',')
        
        if imm_str.startswith('0x') or imm_str.startswith('0X'):
            return int(imm_str, 16)
        if imm_str.startswith('0b') or imm_str.startswith('0B'):
            return int(imm_str, 2)
        if imm_str.startswith('0') and len(imm_str) > 1 and imm_str[1].isdigit():
            return int(imm_str, 8)
        
        return int(imm_str)
    
    def print_report(self):
        print("\n" + "="*70)
        print("RISC-V ASSEMBLY VALIDATION REPORT")
        print("="*70)
        
        print("\nStatistics:")
        print(f"  Total lines:     {self.stats['total_lines']}")
        print(f"  Instructions:    {self.stats['instructions']}")
        print(f"  Labels:          {self.stats['labels']}")
        print(f"  Directives:      {self.stats['directives']}")
        print(f"  Comments:        {self.stats['comments']}")
        
        if self.errors:
            print(f"\n[ERROR] ERRORS FOUND: {len(self.errors)}")
            print("-" * 70)
            for line_num, error, code in self.errors:
                print(f"  Line {line_num}: {error}")
                print(f"    > {code}")
            print()
        
        if self.warnings:
            print(f"\n[WARNING] WARNINGS: {len(self.warnings)}")
            print("-" * 70)
            for line_num, warning in self.warnings:
                print(f"  Line {line_num}: {warning}")
            print()
        
        if not self.errors and not self.warnings:
            print("\n[SUCCESS] VALIDATION PASSED - No errors or warnings")
        elif not self.errors:
            print(f"\n[SUCCESS] VALIDATION PASSED - {len(self.warnings)} warnings (non-critical)")
        else:
            print(f"\n[ERROR] VALIDATION FAILED - {len(self.errors)} errors must be fixed")
        
        print("="*70 + "\n")
        
        return len(self.errors) == 0

def main():
    if len(sys.argv) != 2:
        print("Usage: python asm_validator.py <input.s>")
        sys.exit(1)
    
    validator = AsmValidator()
    is_valid = validator.validate_file(sys.argv[1])
    
    sys.exit(0 if is_valid else 1)

if __name__ == '__main__':
    main()