# CGRA Compiler - Compiler for Reconfigurable Architecture

A complete compiler that transforms RISC-V RV32IM assembly code into optimized VLIW binary code.
---

## What Does This Compiler Do?

This compiler takes programs written in RISC-V assembly and optimizes them for parallel execution on a CGRA architecture with 4 Processing Elements (PEs). The result is VLIW binary code that can execute up to 4 instructions simultaneously, maximizing performance in Machine Learning applications and numerical processing.

**Key Features:**

- Data dependency analysis (RAW, WAR, WAW)
- Critical path detection and parallelism analysis (ILP)
- Round-Robin bus arbitration scheduling
- Intelligent register partitioning
- 128-bit VLIW code generation
- Support for ML operations (matrix multiplication, softmax, etc.)

---

## How Does It Work? - 4-Phase Pipeline

The compiler processes code in 4 sequential stages:

### Phase 0.5: Pre-Processing Scripts (Optional)

**Goal:** Validate and normalize RISC-V assembly code before compilation.

**Tools:**
- **asm_validator.py:** Validates syntax and detects errors
- **asm_normalizer.py:** Standardizes code format and register names

**Outputs:**
- Validation reports with error details
- Normalized assembly code ready for compilation

---

### Phase 1: Parsing and Control Flow Analysis

**Goal:** Parse RISC-V assembly code and build the Control Flow Graph (CFG).

**Process:**
1. **Lexer:** Tokenizes source code into instructions, registers, and operands
2. **Parser:** Syntactically analyzes each RISC-V instruction
3. **CFG Builder:** Constructs basic blocks and control edges
4. **Loop Detector:** Identifies natural loops using dominance analysis

**Outputs:**
- Parsed instruction list
- Control Flow Graph (text and GraphViz)
- Detected loops with headers and back-edges

---

### Phase 2: Dependency Analysis and Optimization Preparation

**Goal:** Analyze dependencies between instructions and prepare code for parallelization.

**Process:**
1. **Dependency Analyzer:** Detects data dependencies:
   - **RAW (Read After Write):** True dependencies that must be respected
   - **WAR (Write After Read):** Anti-dependencies
   - **WAW (Write After Write):** Output dependencies
   - **MEMORY:** Conservative dependencies between load/store operations

2. **DFG Builder:** Constructs the Data Flow Graph (DFG)
   - Nodes: Instructions with timing attributes
   - Edges: RAW dependencies (data path)

3. **Critical Path Analysis:** Calculates critical path using ASAP/ALAP
   - **EST (Earliest Start Time):** Earliest possible start time
   - **LST (Latest Start Time):** Latest allowable start time
   - **Slack:** Scheduling flexibility (LST - EST)
   - Identifies critical instructions (slack = 0)

4. **Register Pressure Analysis:** Analyzes register pressure
   - Calculates live ranges for each register
   - Detects spilling needs (> 32 live registers)
   - Generates per-cycle pressure metrics

**Outputs:**
- Complete dependency graph
- Data Flow Graph with metrics
- Critical path and ILP analysis
- Register pressure report

---

### Phase 3: Scheduling, Partitioning, and Mapping

**Goal:** Generate an optimal parallel schedule respecting dependencies and hardware resources.

**Process:**
1. **Register Partitioner:** Distributes 32 registers among 4 PEs
   - Greedy algorithm with load balancing
   - Each PE owns approximately 8 registers
   - Minimizes inter-PE communication

2. **PE Mapper:** Assigns each instruction to a specific PE
   - Strategy based on register ownership
   - Places instructions where results are generated
   - Minimizes data movement

3. **Bus Arbiter:** Controls shared bus access
   - **Round-Robin Policy:** Rotation PE0 to PE1 to PE2 to PE3
   - **Quantum Time:** 1 cycle per PE
   - Tracks contention and statistics

4. **List Scheduler:** Schedules instructions cycle-by-cycle
   - Priority based on critical path
   - Respects data dependencies
   - Considers resource availability (bus, PEs)
   - Allows multiple instructions per cycle (if no contention)

**Outputs:**
- Detailed cycle-by-cycle schedule
- Instruction to PE mapping
- Register partitioning per PE
- Bus arbitration statistics
- Performance metrics (speedup, IPC, efficiency)
- ASCII Gantt chart visualization

---

### Phase 4: VLIW Code Generation

**Goal:** Convert schedule into executable VLIW binary code.

**Process:**
1. **Instruction Encoding:** Each instruction encodes to 32 bits
2. **VLIW Packing:** Groups 4 instructions into 128 bits (one per PE)
3. **Multi-format Generation:**
   - .bin - Raw binary (little-endian)
   - .hex - Readable hexadecimal with comments
   - .mem - Verilog format for readmemh
   - _detailed.txt - Complete decoding with mnemonics

**Outputs:**
- VLIW code in 4 formats
- Utilization statistics
- Operation distribution
- Compression metrics (NOPs vs operations)

---

## Performance Metrics

The compiler generates detailed metrics:

- **Makespan:** Total execution cycles
- **Speedup:** Acceleration vs sequential execution
- **IPC (Instructions Per Cycle):** Instructions per cycle
- **Efficiency:** Speedup / Number of PEs x 100%
- **ILP (Instruction-Level Parallelism):** Total instructions / Critical path
- **Bus Utilization:** Percentage of shared bus usage
- **PE Utilization:** Work distribution among PEs

---

## Project Structure

The project is organized in the following directories:

- config/ - Hardware configuration (CGRA and latency parameters)
- input/ - Assembly input files (.s files)
- output/ - Compilation results (logs, CFG, DFG, schedule, VLIW code)
- src/ - Compiler source code organized by compilation phase
- docs/ - Additional technical documentation

---

## Building and Running

### Prerequisites

- **C++17 Compiler:** g++ 7.0+ or MSVC 2017+
- **Make:** GNU Make
- **Optional:** GraphViz (for graph visualization)
- **Platform:** Linux, macOS, or Windows with WSL (recommended)

**Note for Windows Users:** It is strongly recommended to use WSL (Windows Subsystem for Linux) to avoid compatibility issues with paths, makefiles, and UNIX tools.