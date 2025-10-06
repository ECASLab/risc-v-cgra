# Compiler and flags
CC = riscv64-unknown-elf-gcc
CFLAGS = -march=rv32im -mabi=ilp32 -nostartfiles -nodefaultlibs -nostdlib \
         -mno-relax -fno-builtin -fno-common -mcmodel=medany

OBJDUMP = riscv64-unknown-elf-objdump

# Source files
SOURCES = instance_ESTATICO.c multiply_ESTATICO.c

# Object files
OBJS = $(SOURCES:.c=.o)
ELFS = $(SOURCES:.c=.elf)
ASMS = $(SOURCES:.c=.s)
DISASMS = $(SOURCES:.c=_disasm.s)

# Default target: build all ELF files
all: $(ELFS)

# Build all assembly files
asm: $(ASMS)

# Build all disassembled files
disasm: $(DISASMS)

# Pattern rule to generate .elf from .c
%.elf: %.c
	$(CC) $(CFLAGS) $< -o $@
	@echo "Generated $@"

# Pattern rule to generate .s (assembly) from .c
%.s: %.c
	$(CC) $(CFLAGS) -S $< -o $@
	@echo "Generated $@"

# Pattern rule to generate disassembled .s from .elf
%_disasm.s: %.elf
	$(OBJDUMP) -d $< > $@
	@echo "Generated $@"

# Individual targets for instance_ESTATICO
instance_elf: instance_ESTATICO.elf

instance_asm: instance_ESTATICO.s

instance_disasm: instance_ESTATICO_disasm.s

# Individual targets for multiply_ESTATICO
multiply_elf: multiply_ESTATICO.elf

multiply_asm: multiply_ESTATICO.s

multiply_disasm: multiply_ESTATICO_disasm.s

# Clean all generated files
clean:
	rm -f $(OBJS) $(ELFS) $(ASMS) $(DISASMS)
	@echo "Cleaned all generated files"

# Help target
help:
	@echo "Available targets:"
	@echo "  all             - Build all .elf files (default)"
	@echo "  asm             - Generate all .s assembly files"
	@echo "  disasm          - Generate all disassembled files"
	@echo "  instance_elf    - Build only instance_ESTATICO.elf"
	@echo "  instance_asm    - Generate only instance_ESTATICO.s"
	@echo "  instance_disasm - Disassemble instance_ESTATICO.elf"
	@echo "  multiply_elf    - Build only multiply_ESTATICO.elf"
	@echo "  multiply_asm    - Generate only multiply_ESTATICO.s"
	@echo "  multiply_disasm - Disassemble multiply_ESTATICO.elf"
	@echo "  clean           - Remove all generated files"

.PHONY: all asm disasm clean help instance_elf instance_asm instance_disasm \
        multiply_elf multiply_asm multiply_disasm