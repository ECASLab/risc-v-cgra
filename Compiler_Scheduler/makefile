# Compilador y flags
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -Iinclude -g
LDFLAGS =

# Configuración para compilación C a CGRA
RISCV_CC = riscv64-unknown-elf-gcc
RISCV_CFLAGS = -march=rv32im -mabi=ilp32 -nostartfiles -nodefaultlibs -nostdlib -mno-relax -fno-builtin -fno-common -mcmodel=medany
NORMALIZER = scripts/asm_normalizer.py
VALIDATOR = scripts/asm_validator.py

# Directorios de entrada
C_INPUT_DIR = input/c_base
ASM_INPUT_DIR = input

LDFLAGS =

# Detección de sistema operativo
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    RM = cmd /C del /Q /F
    RMDIR = cmd /C rmdir /S /Q
    MKDIR = cmd /C if not exist
    MKDIR_END = mkdir
    FIX_PATH = $(subst /,\,$1)
    EXE_EXT = .exe
    ECHO = echo
    CAT = type
    NULL = nul
else
    DETECTED_OS := $(shell uname -s)
    RM = rm -f
    RMDIR = rm -rf
    MKDIR = mkdir -p
    MKDIR_END = 
    FIX_PATH = $1
    EXE_EXT =
    ECHO = echo
    CAT = cat
    NULL = /dev/null
endif

# Directorios
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
CONFIG_DIR = config
INPUT_DIR = input
OUTPUT_DIR = output

# Archivos fuente
SOURCES = $(wildcard $(SRC_DIR)/*.cpp) \
          $(wildcard $(SRC_DIR)/parser/*.cpp) \
          $(wildcard $(SRC_DIR)/cfg/*.cpp) \
          $(wildcard $(SRC_DIR)/loop/*.cpp) \
          $(wildcard $(SRC_DIR)/utils/*.cpp) \
          $(wildcard $(SRC_DIR)/config/*.cpp) \
          $(wildcard $(SRC_DIR)/dependency/*.cpp) \
          $(wildcard $(SRC_DIR)/dfg/*.cpp) \
          $(wildcard $(SRC_DIR)/analysis/*.cpp) \
          $(wildcard $(SRC_DIR)/register_partitioning/*.cpp) \
          $(wildcard $(SRC_DIR)/scheduling/*.cpp) \
          $(wildcard $(SRC_DIR)/mapping/*.cpp) \
          $(wildcard $(SRC_DIR)/output_generator/*.cpp) \
          $(wildcard $(SRC_DIR)/arbiter/*.cpp) \
          $(wildcard $(SRC_DIR)/vliw/*.cpp)

# Archivos objeto
OBJECTS = $(SOURCES:$(SRC_DIR)/%.cpp=$(BUILD_DIR)/%.o)

# Ejecutable
TARGET = $(BIN_DIR)/cgra_compiler$(EXE_EXT)

.PHONY: all clean run schedule dirs help combine translate

all: dirs $(TARGET)
	@echo "Compilacion exitosa"

dirs:
ifeq ($(OS),Windows_NT)
	@if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	@if not exist "$(BUILD_DIR)\parser" mkdir "$(BUILD_DIR)\parser"
	@if not exist "$(BUILD_DIR)\cfg" mkdir "$(BUILD_DIR)\cfg"
	@if not exist "$(BUILD_DIR)\loop" mkdir "$(BUILD_DIR)\loop"
	@if not exist "$(BUILD_DIR)\utils" mkdir "$(BUILD_DIR)\utils"
	@if not exist "$(BUILD_DIR)\config" mkdir "$(BUILD_DIR)\config"
	@if not exist "$(BUILD_DIR)\dependency" mkdir "$(BUILD_DIR)\dependency"
	@if not exist "$(BUILD_DIR)\dfg" mkdir "$(BUILD_DIR)\dfg"
	@if not exist "$(BUILD_DIR)\analysis" mkdir "$(BUILD_DIR)\analysis"
	@if not exist "$(BUILD_DIR)\register_partitioning" mkdir "$(BUILD_DIR)\register_partitioning"
	@if not exist "$(BUILD_DIR)\scheduling" mkdir "$(BUILD_DIR)\scheduling"
	@if not exist "$(BUILD_DIR)\mapping" mkdir "$(BUILD_DIR)\mapping"
	@if not exist "$(BUILD_DIR)\output_generator" mkdir "$(BUILD_DIR)\output_generator"
	@if not exist "$(BUILD_DIR)\arbiter" mkdir "$(BUILD_DIR)\arbiter"
	@if not exist "$(BUILD_DIR)\vliw" mkdir "$(BUILD_DIR)\vliw"
	@if not exist "$(BIN_DIR)" mkdir "$(BIN_DIR)"
	@if not exist "$(OUTPUT_DIR)" mkdir "$(OUTPUT_DIR)"
	@if not exist "$(INPUT_DIR)" mkdir "$(INPUT_DIR)"
	@if not exist "$(C_INPUT_DIR)" mkdir "$(C_INPUT_DIR)"
else
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/parser
	@mkdir -p $(BUILD_DIR)/cfg
	@mkdir -p $(BUILD_DIR)/loop
	@mkdir -p $(BUILD_DIR)/utils
	@mkdir -p $(BUILD_DIR)/config
	@mkdir -p $(BUILD_DIR)/dependency
	@mkdir -p $(BUILD_DIR)/dfg
	@mkdir -p $(BUILD_DIR)/analysis
	@mkdir -p $(BUILD_DIR)/register_partitioning
	@mkdir -p $(BUILD_DIR)/scheduling
	@mkdir -p $(BUILD_DIR)/mapping
	@mkdir -p $(BUILD_DIR)/output_generator
	@mkdir -p $(BUILD_DIR)/arbiter
	@mkdir -p $(BUILD_DIR)/vliw
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(INPUT_DIR)
	@mkdir -p $(C_INPUT_DIR)
endif

$(TARGET): $(OBJECTS)
	@echo "Enlazando ejecutable..."
	$(CXX) $(OBJECTS) -o $(TARGET) $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	@echo "Compilando $<..."
ifeq ($(OS),Windows_NT)
	@if not exist "$(dir $@)" mkdir "$(dir $@)"
else
	@mkdir -p $(dir $@)
endif
	$(CXX) $(CXXFLAGS) -c $< -o $@

translate:
	@echo ""
	@echo "========================================"
	@echo "C to CGRA ISA Compilation Pipeline"
	@echo "========================================"
	@echo ""
ifeq ($(OS),Windows_NT)
# Validar que se especificó FILE
	@if "%FILE%"=="" ( \
		echo Error: Especifica un archivo con FILE=nombre.c && \
		echo Ejemplo: make translate FILE=multiply.c && \
		exit /b 1 \
	)
# Validar que el archivo existe
	@if not exist "$(C_INPUT_DIR)\$(FILE)" ( \
		echo Error: Archivo $(C_INPUT_DIR)\$(FILE) no encontrado && \
		exit /b 1 \
	)
# Validar que el compilador RISC-V está disponible
	@where $(RISCV_CC) >nul 2>&1 || ( \
		echo Error: RISC-V compiler not found: $(RISCV_CC) && \
		echo    Please install the RISC-V GNU toolchain. && \
		exit /b 1 \
	)
	@echo Input:  $(C_INPUT_DIR)\$(FILE)
	@echo Output: $(ASM_INPUT_DIR)\$(notdir $(basename $(FILE))).s
	@cmd /c "echo."
	@echo [1/4] Compiling C to RISC-V assembly...
	@$(RISCV_CC) $(RISCV_CFLAGS) -S "$(C_INPUT_DIR)\$(FILE)" -o "$(notdir $(basename $(FILE)))_raw.s"
	@if %errorlevel% neq 0 ( \
		echo ✗ Compilation failed && \
		exit /b 1 \
	)
	@for /f %%c in ('type "$(notdir $(basename $(FILE)))_raw.s" ^| find /c /v ""') do @set LINES=%%c
	@echo ✓ Compilation successful: $(notdir $(basename $(FILE)))_raw.s
	@echo    %LINES% lines generated
	@cmd /c "echo."
	@echo [2/4] Normalizing assembly (expanding pseudo-instructions)...
	@python "$(NORMALIZER)" "$(notdir $(basename $(FILE)))_raw.s" "$(notdir $(basename $(FILE)))_normalized.s"
	@if %errorlevel% neq 0 ( \
		echo ✗ Normalization failed && \
		exit /b 1 \
	)
	@for /f %%c in ('type "$(notdir $(basename $(FILE)))_normalized.s" ^| find /c /v ""') do @set LINES=%%c
	@echo ✓ Normalization successful: $(notdir $(basename $(FILE)))_normalized.s
	@echo    %LINES% lines after normalization
	@cmd /c "echo."
	@echo [3/4] Validating assembly against CGRA ISA...
	@python "$(VALIDATOR)" "$(notdir $(basename $(FILE)))_normalized.s"
	@if %errorlevel% neq 0 ( \
		echo ✗ Validation failed - code contains unsupported instructions && \
		echo    Fix errors and run validation again && \
		exit /b 1 \
	)
	@echo ✓ Validation passed
	@cmd /c "echo."
	@echo [4/4] Finalizing output...
	@copy "$(notdir $(basename $(FILE)))_normalized.s" "$(ASM_INPUT_DIR)\$(notdir $(basename $(FILE))).s" >nul
	@del /Q /F "$(notdir $(basename $(FILE)))_raw.s" "$(notdir $(basename $(FILE)))_normalized.s"
	@echo ✓ Assembly ready: $(ASM_INPUT_DIR)\$(notdir $(basename $(FILE))).s
	@cmd /c "echo."
	@echo ========================================
	@echo ✓ Pipeline completed successfully!
	@echo ========================================
	@cmd /c "echo."
	@echo Ejemplo de pipeline completo:
	@echo   make clean
	@echo   make
	@echo   make translate FILE=multiply.c
	@echo   make run FILE=multiply.s
	@echo   make combine
	@cmd /c "echo."
	@echo NOTA: Los archivos .c deben estar en: $(C_INPUT_DIR)\
	@echo       Los archivos .s se generan en: $(ASM_INPUT_DIR)\
	@echo       Es recomendable colocar los archivos en estos directorios.
	@cmd /c "echo."
else
# Validar que se especificó FILE
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Especifica un archivo con FILE=nombre.c"; \
		echo "Ejemplo: make translate FILE=multiply.c"; \
		exit 1; \
	fi
# Validar que el archivo existe
	@if [ ! -f "$(C_INPUT_DIR)/$(FILE)" ]; then \
		echo "Error: Archivo $(C_INPUT_DIR)/$(FILE) no encontrado"; \
		exit 1; \
	fi
# Validar que el compilador RISC-V está disponible
	@if ! command -v $(RISCV_CC) > /dev/null 2>&1; then \
		echo "Error: RISC-V compiler not found: $(RISCV_CC)"; \
		echo "   Please install the RISC-V GNU toolchain."; \
		exit 1; \
	fi
# Definir nombres de archivos
	@BASENAME=$$(basename "$(FILE)" .c); \
	RAW_ASM="$${BASENAME}_raw.s"; \
	NORMALIZED_ASM="$${BASENAME}_normalized.s"; \
	OUTPUT_FILE="$(ASM_INPUT_DIR)/$${BASENAME}.s"; \
	echo "Input:  $(C_INPUT_DIR)/$(FILE)"; \
	echo "Output: $${OUTPUT_FILE}"; \
	echo ""; \
	\
	echo "[1/4] Compiling C to RISC-V assembly..."; \
	$(RISCV_CC) $(RISCV_CFLAGS) -S "$(C_INPUT_DIR)/$(FILE)" -o "$${RAW_ASM}"; \
	if [ $$? -eq 0 ]; then \
		LINES=$$(wc -l < "$${RAW_ASM}"); \
		echo "✓ Compilation successful: $${RAW_ASM}"; \
		echo "   $${LINES} lines generated"; \
	else \
		echo "✗ Compilation failed"; \
		exit 1; \
	fi; \
	echo ""; \
	\
	echo "[2/4] Normalizing assembly (expanding pseudo-instructions)..."; \
	python3 "$(NORMALIZER)" "$${RAW_ASM}" "$${NORMALIZED_ASM}"; \
	if [ $$? -eq 0 ]; then \
		LINES=$$(wc -l < "$${NORMALIZED_ASM}"); \
		echo "✓ Normalization successful: $${NORMALIZED_ASM}"; \
		echo "   $${LINES} lines after normalization"; \
	else \
		echo "✗ Normalization failed"; \
		exit 1; \
	fi; \
	echo ""; \
	\
	echo "[3/4] Validating assembly against CGRA ISA..."; \
	python3 "$(VALIDATOR)" "$${NORMALIZED_ASM}"; \
	if [ $$? -eq 0 ]; then \
		echo "✓ Validation passed"; \
	else \
		echo "✗ Validation failed - code contains unsupported instructions"; \
		echo "   Fix errors and run validation again"; \
		exit 1; \
	fi; \
	echo ""; \
	\
	echo "[4/4] Finalizing output..."; \
	cp "$${NORMALIZED_ASM}" "$${OUTPUT_FILE}"; \
	rm -f "$${RAW_ASM}" "$${NORMALIZED_ASM}"; \
	echo "✓ Assembly ready: $${OUTPUT_FILE}"; \
	echo ""; \
	\
	echo "========================================"; \
	echo "✓ Pipeline completed successfully!"; \
	echo "========================================"; \
	echo ""; \
	echo "Ejemplo de pipeline completo:"; \
	echo "  make clean"; \
	echo "  make"; \
	echo "  make translate FILE=multiply.c"; \
	echo "  make run FILE=multiply.s"; \
	echo "  make combine"; \
	echo ""; \
	echo "NOTA: Los archivos .c deben estar en: $(C_INPUT_DIR)/"; \
	echo "      Los archivos .s se generan en: $(ASM_INPUT_DIR)/"; \
	echo "      Es recomendable colocar los archivos en estos directorios."; \
	echo ""
endif

schedule:
ifeq ($(OS),Windows_NT)
	@if not exist "$(OUTPUT_DIR)" mkdir "$(OUTPUT_DIR)"
	@if exist "$(OUTPUT_DIR)\*.log" del /Q /F "$(OUTPUT_DIR)\*.log"
	@if "$(FILE)"=="" ( \
		echo Error: Especifica un archivo con FILE=nombre.s && \
		echo Ejemplo: make schedule FILE=multiply.s && \
		exit /b 1 \
	)
	@if not exist "$(ASM_INPUT_DIR)\$(FILE)" ( \
		echo Error: Archivo $(ASM_INPUT_DIR)\$(FILE) no encontrado && \
		exit /b 1 \
	)
	@echo Ejecutando compilador CGRA con $(FILE)...
	@$(TARGET) $(ASM_INPUT_DIR)\$(FILE)
else
	@rm -rf $(OUTPUT_DIR)/*.log
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Especifica un archivo con FILE=nombre.s"; \
		echo "Ejemplo: make schedule FILE=multiply.s"; \
		exit 1; \
	fi
	@if [ ! -f "$(ASM_INPUT_DIR)/$(FILE)" ]; then \
		echo "Error: Archivo $(ASM_INPUT_DIR)/$(FILE) no encontrado"; \
		exit 1; \
	fi
	@echo "Ejecutando compilador CGRA con $(FILE)..."
	@$(TARGET) $(ASM_INPUT_DIR)/$(FILE)
endif

run:
	@echo ""
	@echo "========================================"
	@echo "    CGRA Full Compilation Pipeline"
	@echo "========================================"
	@echo ""
ifeq ($(OS),Windows_NT)
# Validar que se especificó FILE
	@if "%FILE%"=="" ( \
		echo Error: Especifica un archivo con FILE=nombre.c o FILE=nombre.s && \
		echo Ejemplos: && \
		echo   make run FILE=multiply.c  ^(pipeline completo desde C^) && \
		echo   make run FILE=multiply.s  ^(solo scheduling desde assembly^) && \
		exit /b 1 \
	)
# Determinar si es archivo .c o .s
	@set "EXT=" && for %%A in ("$(FILE)") do set "EXT=%%~xA"
	@if "%EXT%"==".c" ( \
		echo [Pipeline Mode: C to VLIW] && \
		cmd /c "echo." && \
		echo Step 1/3: Translating C to Assembly... && \
		$(MAKE) translate FILE=$(FILE) && \
		cmd /c "echo." && \
		echo Step 2/3: Scheduling and Compiling... && \
		for %%F in ("$(FILE)") do $(MAKE) schedule FILE=%%~nF.s && \
		cmd /c "echo." && \
		echo Step 3/3: Combining outputs... && \
		$(MAKE) combine && \
		cmd /c "echo." && \
		echo ======================================== && \
		echo ✓ Full pipeline completed successfully! && \
		echo ======================================== && \
		cmd /c "echo." && \
		echo Output files in: $(OUTPUT_DIR)\ && \
		echo   - combined_output.txt ^(all phases^) && \
		echo   - phase4_vliw.bin ^(binary code^) && \
		echo   - phase4_vliw.hex ^(hex format^) && \
		echo   - phase4_vliw.mem ^(Verilog format^) \
	) else if "%EXT%"==".s" ( \
		echo [Pipeline Mode: Assembly to VLIW] && \
		cmd /c "echo." && \
		echo Step 1/2: Scheduling and Compiling... && \
		$(MAKE) schedule FILE=$(FILE) && \
		cmd /c "echo." && \
		echo Step 2/2: Combining outputs... && \
		$(MAKE) combine && \
		cmd /c "echo." && \
		echo ======================================== && \
		echo ✓ Pipeline completed successfully! && \
		echo ======================================== && \
		cmd /c "echo." && \
		echo Output files in: $(OUTPUT_DIR)\ && \
		echo   - combined_output.txt ^(all phases^) && \
		echo   - phase4_vliw.bin ^(binary code^) && \
		echo   - phase4_vliw.hex ^(hex format^) && \
		echo   - phase4_vliw.mem ^(Verilog format^) \
	) else ( \
		echo Error: FILE debe ser .c o .s && \
		echo Ejemplos: && \
		echo   make run FILE=multiply.c && \
		echo   make run FILE=multiply.s && \
		exit /b 1 \
	)
else
# Validar que se especificó FILE
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Especifica un archivo con FILE=nombre.c o FILE=nombre.s"; \
		echo "Ejemplos:"; \
		echo "  make run FILE=multiply.c  (pipeline completo desde C)"; \
		echo "  make run FILE=multiply.s  (solo scheduling desde assembly)"; \
		exit 1; \
	fi
# Determinar si es archivo .c o .s
	@EXT=$${FILE##*.}; \
	if [ "$$EXT" = "c" ]; then \
		echo "[Pipeline Mode: C to VLIW]"; \
		echo ""; \
		echo "Step 1/3: Translating C to Assembly..."; \
		$(MAKE) translate FILE=$(FILE); \
		echo ""; \
		echo "Step 2/3: Scheduling and Compiling..."; \
		BASENAME=$$(basename "$(FILE)" .c); \
		$(MAKE) schedule FILE="$${BASENAME}.s"; \
		echo ""; \
		echo "Step 3/3: Combining outputs..."; \
		$(MAKE) combine; \
		echo ""; \
		echo "========================================"; \
		echo "✓ Full pipeline completed successfully!"; \
		echo "========================================"; \
		echo ""; \
		echo "Output files in: $(OUTPUT_DIR)/"; \
		echo "  - combined_output.txt (all phases)"; \
		echo "  - phase4_vliw.bin (binary code)"; \
		echo "  - phase4_vliw.hex (hex format)"; \
		echo "  - phase4_vliw.mem (Verilog format)"; \
	elif [ "$$EXT" = "s" ]; then \
		echo "[Pipeline Mode: Assembly to VLIW]"; \
		echo ""; \
		echo "Step 1/2: Scheduling and Compiling..."; \
		$(MAKE) schedule FILE=$(FILE); \
		echo ""; \
		echo "Step 2/2: Combining outputs..."; \
		$(MAKE) combine; \
		echo ""; \
		echo "========================================"; \
		echo "✓ Pipeline completed successfully!"; \
		echo "========================================"; \
		echo ""; \
		echo "Output files in: $(OUTPUT_DIR)/"; \
		echo "  - combined_output.txt (all phases)"; \
		echo "  - phase4_vliw.bin (binary code)"; \
		echo "  - phase4_vliw.hex (hex format)"; \
		echo "  - phase4_vliw.mem (Verilog format)"; \
	else \
		echo "Error: FILE debe ser .c o .s"; \
		echo "Ejemplos:"; \
		echo "  make run FILE=multiply.c"; \
		echo "  make run FILE=multiply.s"; \
		exit 1; \
	fi
endif

combine:
ifeq ($(OS),Windows_NT)
	@echo Combinando archivos .txt en $(OUTPUT_DIR)\combined_output.txt...
	@if exist "$(OUTPUT_DIR)\combined_output.txt" del /Q /F "$(OUTPUT_DIR)\combined_output.txt"
	@for %%f in ($(OUTPUT_DIR)\phase*.txt) do ( \
		echo ----------------------- >> "$(OUTPUT_DIR)\combined_output.txt" && \
		echo %%~nxf >> "$(OUTPUT_DIR)\combined_output.txt" && \
		echo. >> "$(OUTPUT_DIR)\combined_output.txt" && \
		type "%%f" >> "$(OUTPUT_DIR)\combined_output.txt" && \
		echo. >> "$(OUTPUT_DIR)\combined_output.txt" \
	)
	@echo Archivos combinados en $(OUTPUT_DIR)\combined_output.txt
	@echo Eliminando archivos individuales...
	@for %%f in ($(OUTPUT_DIR)\phase*.txt) do del /Q /F "%%f"
	@if exist "$(OUTPUT_DIR)\*.dot" del /Q /F "$(OUTPUT_DIR)\*.dot"
	@echo Limpieza completa - solo queda combined_output.txt
else
	@echo "Combinando archivos .txt en $(OUTPUT_DIR)/combined_output.txt..."
	@rm -f $(OUTPUT_DIR)/combined_output.txt
	@for file in $(OUTPUT_DIR)/phase*.txt; do \
		if [ -f "$$file" ]; then \
			echo "-----------------------" >> $(OUTPUT_DIR)/combined_output.txt; \
			basename "$$file" >> $(OUTPUT_DIR)/combined_output.txt; \
			echo "" >> $(OUTPUT_DIR)/combined_output.txt; \
			cat "$$file" >> $(OUTPUT_DIR)/combined_output.txt; \
			echo "" >> $(OUTPUT_DIR)/combined_output.txt; \
		fi \
	done
	@echo "Archivos combinados en $(OUTPUT_DIR)/combined_output.txt"
	@echo "Eliminando archivos individuales..."
	@rm -f $(OUTPUT_DIR)/phase*.txt
	@rm -f $(OUTPUT_DIR)/*.dot
	@echo "Limpieza completa - solo queda combined_output.txt"
endif

clean:
	@echo "Limpiando archivos generados..."
ifeq ($(OS),Windows_NT)
	@if exist "$(BUILD_DIR)" rmdir /S /Q "$(BUILD_DIR)"
	@if exist "$(BIN_DIR)" rmdir /S /Q "$(BIN_DIR)"
	@if exist "$(OUTPUT_DIR)\*.txt" del /Q /F "$(OUTPUT_DIR)\*.txt"
	@if exist "$(OUTPUT_DIR)\*.dot" del /Q /F "$(OUTPUT_DIR)\*.dot"
	@if exist "$(OUTPUT_DIR)\*.cfg" del /Q /F "$(OUTPUT_DIR)\*.cfg"
	@if exist "$(OUTPUT_DIR)\*.png" del /Q /F "$(OUTPUT_DIR)\*.png"
	@if exist "$(OUTPUT_DIR)\*.log" del /Q /F "$(OUTPUT_DIR)\*.log"
	@if exist "$(OUTPUT_DIR)\*.bin" del /Q /F "$(OUTPUT_DIR)\*.bin"
	@if exist "$(OUTPUT_DIR)\*.hex" del /Q /F "$(OUTPUT_DIR)\*.hex"
	@if exist "$(OUTPUT_DIR)\*.mem" del /Q /F "$(OUTPUT_DIR)\*.mem"
	@if exist "$(OUTPUT_DIR)\*.mem" del /Q /F "$(OUTPUT_DIR)\*.elf"
	@if exist "$(OUTPUT_DIR)\*.mem" del /Q /F "$(OUTPUT_DIR)\*.s"

else
	@rm -rf $(BUILD_DIR)
	@rm -rf $(BIN_DIR)
	@rm -rf $(OUTPUT_DIR)/*.txt
	@rm -rf $(OUTPUT_DIR)/*.dot
	@rm -rf $(OUTPUT_DIR)/*.cfg
	@rm -rf $(OUTPUT_DIR)/*.png
	@rm -rf $(OUTPUT_DIR)/*.log
	@rm -rf $(OUTPUT_DIR)/*.bin
	@rm -rf $(OUTPUT_DIR)/*.hex
	@rm -rf $(OUTPUT_DIR)/*.mem
	@rm -rf $(OUTPUT_DIR)/*.elf
	@rm -rf $(OUTPUT_DIR)/*.s

endif
	@echo "Limpieza completa"

help:
	@echo "CGRA Compiler - Makefile"
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  make                       - Compilar el proyecto"
	@echo "  make run FILE=archivo      - Pipeline completo (C o assembly a VLIW)"
	@echo "  make translate FILE=archivo.c - Traducir C a assembly CGRA"
	@echo "  make schedule FILE=archivo.s  - Compilar assembly a VLIW"
	@echo "  make combine               - Combinar todos los .txt de output en uno solo"
	@echo "  make clean                 - Limpiar archivos generados"
	@echo "  make help                  - Mostrar esta ayuda"
	@echo ""
	@echo "Pipeline completo (recomendado):"
	@echo "  make clean"
	@echo "  make"
	@echo "  make run FILE=multiply.c   (desde C)"
	@echo "  O"
	@echo "  make run FILE=multiply.s   (desde assembly)"
	@echo ""
	@echo "Pipeline paso a paso (manual):"
	@echo "  make clean"
	@echo "  make"
	@echo "  make translate FILE=multiply.c"
	@echo "  make schedule FILE=multiply.s"
	@echo "  make combine"
	@echo ""
	@echo "NOTA: Los archivos .c deben estar en: input/c_base/"
	@echo "      Los archivos .s se generan en: input/"
	@echo ""
	@echo "Nota: todo código en .c tiene que realizarse teniendo en cuenta las siguientes limitaciones del ISA RISC-V:"
	@echo ""
	@echo "# RISC-V Instruction Formats"
	@echo ""
	@echo "## R Type Instruction"
	@echo "| funct7 | rs2 | rs1 | funct3 | rd | op |"
	@echo "|--------|-----|-----|--------|----|----|"
	@echo "| 7 bits | 5 bits | 5 bits | 3 bits | 5 bits | 7 bits |"
	@echo ""
	@echo "## I Type Instruction"
	@echo "| imm11:0 | rs1 | funct3 | rd | op |"
	@echo "|---------|-----|--------|----|----|"
	@echo "| 12 bits | 5 bits | 3 bits | 5 bits | 7 bits |"
	@echo ""
	@echo "## S Type Instruction"
	@echo "| imm12:5 | rs2 | rs1 | funct3 | imm4:0 | op |"
	@echo "|---------|-----|-----|--------|--------|----|"
	@echo "| 7 bits | 5 bits | 5 bits | 3 bits | 5 bits | 7 bits |"
	@echo ""
	@echo "## U Type Instruction"
	@echo "| immhi | rd | op |"
	@echo "|-------|----|----|"
	@echo "| 20 bits | 5 bits | 7 bits |"
	@echo ""
	@echo "## B Type Instruction"
	@echo "| imm12,10:5 | rs2 | rs1 | funct3 | imm4:1,11 | op |"
	@echo "|------------|-----|-----|--------|-----------|-----|"
	@echo "| 7 bits | 5 bits | 5 bits | 3 bits | 5 bits | 7 bits |"
	@echo ""
	@echo "## J Type Instruction"
	@echo "| immhi 20, 10:1, 11, 19:12 | rd | op |"
	@echo "|---------------------------|----|----|"
	@echo "| 20 bits | 5 bits | 7 bits |"
	@echo ""
	@echo "---"
	@echo ""
	@echo "# Tabla 3.1: Instrucciones de RISC-V"
	@echo ""
	@echo "| Op | Instrucciones | Tipo instrucción |"
	@echo "|---------|--------------|------------------|"
	@echo "| 0000011 | lb, lh, lw, lbu, lhu | I |"
	@echo "| 0010011 | addi, slli, slti, sltiu, xori, srli, srai, ori, andi | I |"
	@echo "| 0100011 | sb, sh, sw | S |"
	@echo "| 0110011 | add, sub, sll, slt, sltu, xor, srl, sra, or, and, multiply | R |"
	@echo "| 0110111 | load upper immediate | U |"
	@echo "| 1100011 | branch if equal, not equal | B |"
	@echo "| 1101111 | jump and link register | J |"
	@echo ""