# Compiler and flags
CC = riscv64-unknown-elf-gcc
CFLAGS = -march=rv32im -mabi=ilp32 -nostartfiles -nodefaultlibs -nostdlib \
         -mno-relax -fno-builtin -fno-common -mcmodel=medany

OBJDUMP = riscv64-unknown-elf-objdump
QEMU = qemu-riscv32

# Source files
SOURCES = instance_CUSTOM.c multiply_CUSTOM.c

# Generated files
ELFS = $(SOURCES:.c=.elf)
ASMS = $(SOURCES:.c=.s)
DISASMS = $(SOURCES:.c=_disasm.s)
TEST_ELFS = test_instance.elf test_multiply.elf

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
NC = \033[0m

# Default target
all: $(ELFS)

# Build all assembly files
asm: $(ASMS)

# Build all disassembled files
disasm: $(DISASMS)

# Build test binaries
tests: $(TEST_ELFS)

# Pattern rules
%.elf: %.c
	@echo "Compiling $<..."
	@$(CC) $(CFLAGS) $< -o $@
	@echo "$(GREEN)✓ Generated $@$(NC)"

%.s: %.c
	@echo "Generating assembly for $<..."
	@$(CC) $(CFLAGS) -S $< -o $@
	@echo "$(GREEN)✓ Generated $@$(NC)"

%_disasm.s: %.elf
	@echo "Disassembling $<..."
	@$(OBJDUMP) -d $< > $@
	@echo "$(GREEN)✓ Generated $@$(NC)"

# Test targets
test_instance.elf: test_instance.c instance_CUSTOM.c
	@echo "Building test for instance_CUSTOM..."
	@$(CC) $(CFLAGS) -Wl,-e,_start $^ -o $@
	@echo "$(GREEN)✓ Generated $@$(NC)"

test_multiply.elf: test_multiply.c multiply_CUSTOM.c
	@echo "Building test for multiply_CUSTOM..."
	@$(CC) $(CFLAGS) -Wl,-e,_start $^ -o $@
	@echo "$(GREEN)✓ Generated $@$(NC)"

# Run tests
test: tests
	@echo "\n$(YELLOW)=== Running Tests ===$(NC)\n"
	@echo "Testing instance_CUSTOM.c (matrix sum)..."
	@if $(QEMU) ./test_instance.elf 2>/dev/null; then \
		echo "$(GREEN)✓ instance_CUSTOM: ALL TESTS PASSED$(NC)\n"; \
	else \
		EXIT_CODE=$$?; \
		echo "$(RED)✗ instance_CUSTOM: TEST FAILED (exit code $$EXIT_CODE)$(NC)"; \
		echo "  Exit codes: 1=alloc_m1 2=alloc_m2 3=alloc_result 4=sum_failed"; \
		echo "              5=result_wrong 6-8=free_failed 9=ptr_not_null\n"; \
	fi
	@echo "Testing multiply_CUSTOM.c (matrix multiplication)..."
	@if $(QEMU) ./test_multiply.elf 2>/dev/null; then \
		echo "$(GREEN)✓ multiply_CUSTOM: ALL TESTS PASSED$(NC)\n"; \
	else \
		EXIT_CODE=$$?; \
		echo "$(RED)✗ multiply_CUSTOM: TEST FAILED (exit code $$EXIT_CODE)$(NC)"; \
		echo "  Exit codes: 1-3=alloc_failed 4=multiply_failed 5=result_2x2_wrong"; \
		echo "              6=alloc_3x3_failed 7=multiply_3x3_failed 8=result_3x3_wrong 9=free_failed\n"; \
	fi

# Individual test targets
test_instance: test_instance.elf
	@echo "\n$(YELLOW)=== Testing instance_CUSTOM ===$(NC)"
	@if $(QEMU) ./test_instance.elf 2>/dev/null; then \
		echo "$(GREEN)✓ ALL TESTS PASSED$(NC)\n"; \
	else \
		EXIT_CODE=$$?; \
		echo "$(RED)✗ FAILED (exit code $$EXIT_CODE)$(NC)"; \
		echo "Exit codes: 1=alloc_m1 2=alloc_m2 3=alloc_result 4=sum_failed"; \
		echo "            5=result_wrong 6-8=free_failed 9=ptr_not_null\n"; \
	fi

test_multiply: test_multiply.elf
	@echo "\n$(YELLOW)=== Testing multiply_CUSTOM ===$(NC)"
	@if $(QEMU) ./test_multiply.elf 2>/dev/null; then \
		echo "$(GREEN)✓ ALL TESTS PASSED$(NC)\n"; \
	else \
		EXIT_CODE=$$?; \
		echo "$(RED)✗ FAILED (exit code $$EXIT_CODE)$(NC)"; \
		echo "Exit codes: 1-3=alloc_failed 4=multiply_failed 5=result_2x2_wrong"; \
		echo "            6=alloc_3x3_failed 7=multiply_3x3_failed 8=result_3x3_wrong 9=free_failed\n"; \
	fi

# Clean
clean:
	@rm -f $(ELFS) $(ASMS) $(DISASMS) $(TEST_ELFS) *.o
	@echo "$(GREEN)Cleaned all generated files$(NC)"

# Help
help:
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  all             - Build all .elf files (default)"
	@echo "  asm             - Generate all .s assembly files"
	@echo "  disasm          - Generate all disassembled files"
	@echo "  tests           - Build test executables"
	@echo "  test            - Run all tests"
	@echo "  test_instance   - Test instance_CUSTOM only"
	@echo "  test_multiply   - Test multiply_CUSTOM only"
	@echo "  clean           - Remove all generated files"
	@echo "  help            - Show this help message"

.PHONY: all asm disasm tests test test_instance test_multiply clean help