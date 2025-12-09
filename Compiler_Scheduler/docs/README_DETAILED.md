```markdown
# CGRA Compiler - Detailed Technical Documentation

---

## Phase 0.5: Pre-Processing Scripts (Optional)

### Purpose

Phase 0.5 provides optional Python-based utilities to validate and normalize RISC-V assembly code before entering the main compilation pipeline. These scripts catch common syntax errors early, standardize code format, and ensure compliance with the compiler's expectations. While optional, they significantly improve code quality and reduce compilation errors, especially when working with hand-written assembly or code generated from external tools.

### Key Components
- **asm_validator.py**: Comprehensive RISC-V assembly syntax validator
- **asm_normalizer.py**: Assembly code formatter and normalizer

---

### 0.5.1 Assembly Validator (`asm_validator.py`)

**Location**: `scripts/asm_validator.py`

**Purpose**: Performs static analysis on RISC-V assembly files to detect syntax errors, invalid instructions, malformed operands, and other issues before compilation begins.

**Validation Checks**:

1. **Instruction Format Validation**
   - Verifies that each instruction follows proper RISC-V syntax
   - Checks operand count matches instruction requirements
   - Example: `add x1, x2, x3` ✓ valid | `add x1, x2` ✗ missing operand

2. **Register Name Validation**
   - Ensures all register references are valid (x0-x31 or ABI names)
   - Detects typos like `x33`, `r5`, or invalid names
   - Accepts both numeric (x5) and ABI names (t0, a0, sp, etc.)
   - Example: `add x1, x2, x3` ✓ valid | `add x33, x2, x3` ✗ invalid register

3. **Immediate Value Range Checking**
   - Validates immediate values are within instruction-specific bounds
   - I-type immediates: [-2048, 2047] (12-bit signed)
   - S-type immediates: [-2048, 2047] (12-bit signed)
   - B-type immediates: [-4096, 4094] (13-bit signed, even)
   - U-type immediates: [0, 1048575] (20-bit unsigned)
   - J-type immediates: [-1048576, 1048574] (21-bit signed, even)
   - Example: `addi x1, x2, 2047` ✓ valid | `addi x1, x2, 5000` ✗ out of range

4. **Opcode Recognition**
   - Checks that all instruction mnemonics are recognized RV32I opcodes
   - Supported instruction set: RV32I (base) + mul from RV32M
   - Detects misspellings or unsupported instructions
   - Example: `add x1, x2, x3` ✓ valid | `addr x1, x2, x3` ✗ unknown opcode

5. **Label Format Validation**
   - Ensures labels follow proper naming conventions
   - Labels must end with colon (:)
   - Label names must be valid identifiers
   - Example: `loop:` ✓ valid | `loop` ✗ missing colon

6. **Directive Validation**
   - Validates assembler directives (.text, .data, .word, etc.)
   - Checks directive syntax and operands
   - Example: `.word 100` ✓ valid | `.word` ✗ missing operand
   
---

### 0.5.2 Assembly Normalizer (`asm_normalizer.py`)

**Location**: `scripts/asm_normalizer.py`

**Purpose**: Transforms assembly code into a standardized format with consistent spacing, register naming, and style conventions. Particularly useful when combining code from multiple sources or converting from other assembly formats.

**Normalization Operations**:

1. **Register Alias Conversion**
   - Converts ABI register names to canonical numeric form
   - Improves consistency across different coding styles
   - Mapping examples:
     - `zero` → `x0` (hardwired zero)
     - `ra` → `x1` (return address)
     - `sp` → `x2` (stack pointer)
     - `gp` → `x3` (global pointer)
     - `tp` → `x4` (thread pointer)
     - `t0-t6` → `x5-x7, x28-x31` (temporaries)
     - `s0-s11` → `x8-x9, x18-x27` (saved registers)
     - `a0-a7` → `x10-x17` (function arguments)
   - Example: `add ra, sp, zero` → `add x1, x2, x0`

2. **Whitespace Standardization**
   - Normalizes spacing between instruction components
   - Standard format: `<opcode><space><operands separated by ", ">`
   - Removes trailing whitespace
   - Ensures consistent indentation
   - Example: `add    x1,x2,   x3` → `add x1, x2, x3`

3. **Label Formatting**
   - Ensures labels are left-aligned (column 0)
   - Instructions are indented consistently (2 or 4 spaces)
   - Example:
     ```assembly
     loop:add x1, x2, x3    →    loop:
     ```
     becomes:
     ```assembly
     loop:
         add x1, x2, x3
     ```

4. **Comment Preservation**
   - Retains inline comments with consistent spacing
   - Aligns comments to a standard column (e.g., column 40)
   - Preserves comment content exactly
   - Example: `add x1,x2,x3#sum` → `add x1, x2, x3      # sum`

5. **Empty Line Normalization**
   - Removes excessive blank lines (max 1 consecutive)
   - Ensures single blank line between code sections
   - Removes trailing empty lines at end of file

6. **Directive Formatting**
   - Standardizes assembler directive format
   - Example: `.text` remains `.text`, `.data` remains `.data`
---

## Phase 1: Parsing and Control Flow Analysis

### Purpose

Phase 1 parses RISC-V RV32IM assembly code, builds the Control Flow Graph (CFG), and detects loop structures. This establishes the foundation for dependency analysis and scheduling.

### Key Components
- **Lexer & Parser**: Tokenizes and parses RISC-V assembly instructions
- **CFG Builder**: Constructs basic blocks and control flow edges
- **Loop Detector**: Identifies natural loops using dominance analysis

---

## Phase 2: Dependency Analysis and Optimization Preparation

### Purpose

Phase 2 transforms the parsed instructions and CFG from Phase 1 into a dependency-aware representation suitable for parallel scheduling on CGRA architectures. It identifies all data dependencies (RAW, WAR, WAW), computes the critical path, and analyzes register pressure to guide scheduling decisions.

### Components

#### 2.1 Configuration System
- **Location**: `src/config/`
- **Function**: Loads hardware parameters and operation latencies from YAML files
- **Configuration Files**: `config/cgra_config.yaml`, `config/latency_config.yaml`

**Hardware Configuration (`cgra_config.yaml`)**:
- Number of Processing Elements (PEs): Default 4
- Shared register file: 32 registers × 32 bits
- Memory banks: 4 banks for parallel access
- Bus arbitration: Round-robin policy
- Instruction memory capacity: 255 instructions (scalable)

**Latency Configuration (`latency_config.yaml`)**:
Based on thesis Figures 4.6-4.10:
- **Load operations** (lb, lh, lw, lbu, lhu): 3 cycles
- **Store operations** (sb, sh, sw): 5 cycles
- **ALU operations** (add, sub, and, or, xor, sll, srl, sra, slt, sltu): 2 cycles
- **ALU immediate** (addi, andi, ori, xori, slli, srli, srai, slti, sltiu): 2 cycles
- **Multiply** (mul): 4 cycles
- **Branch** (beq, bne, blt, bge): 3 cycles
- **Jump** (jal): 3 cycles
- **Special** (lui): 1 cycle

#### 2.2 Dependency Analyzer
- **Location**: `src/dependency/`
- **Function**: Detects all data dependencies between instructions
- **Output**: Complete dependency graph with classified edges

**Dependency Types**:

1. **RAW (Read After Write)** - True Dependencies
   ```assembly
   add t0, t1, t2    # Write to t0
   sub t3, t0, t4    # Read from t0 → RAW dependency
   ```
   - Must be respected: consumer cannot execute before producer finishes
   - Critical for correctness

2. **WAR (Write After Read)** - Anti-Dependencies
   ```assembly
   add t3, t0, t4    # Read from t0
   addi t0, t1, 5    # Write to t0 → WAR dependency
   ```
   - Can be eliminated with register renaming
   - Important in architectures without hardware renaming (like this CGRA)

3. **WAW (Write After Write)** - Output Dependencies
   ```assembly
   addi t0, t1, 5    # Write to t0
   add t0, t2, t3    # Write to t0 → WAW dependency
   ```
   - Can be eliminated with register renaming
   - Affects instruction reordering

4. **MEMORY** - Memory Dependencies
   ```assembly
   sw t0, 0(a0)      # Store to memory
   lw t1, 0(a0)      # Load from memory → MEMORY dependency
   ```
   - Conservative strategy: assume all loads/stores may alias
   - Store → Load: RAW memory dependency
   - Store → Store: Preserve order (WAW memory)
   - Load → Load: Can execute in parallel (no dependency)

#### 2.3 Data Flow Graph Builder
- **Location**: `src/dfg/`
- **Function**: Constructs a directed acyclic graph (DAG) representing data flow
- **Output**: DFG with nodes (instructions) and edges (RAW dependencies only)

**DFG Node Attributes**:
- Instruction index (reference to original code)
- Operation type and operands
- Latency (from configuration)
- Earliest Start Time (EST) - computed via ASAP scheduling
- Latest Start Time (LST) - computed via ALAP scheduling
- Slack = LST - EST (scheduling flexibility)
- Critical path flag (slack = 0)
- Predecessors (data dependencies coming in)
- Successors (data dependencies going out)

**Graph Properties**:
- **Root nodes**: Instructions with no predecessors (e.g., constant loads, argument reads)
- **Leaf nodes**: Instructions with no successors (e.g., stores, returns, branches)
- **DAG structure**: No cycles within a single iteration (loop-carried dependencies handled separately)

#### 2.4 Critical Path Analysis
- **Location**: `src/analysis/CriticalPath.h/cpp`
- **Function**: Identifies the longest dependency chain determining minimum execution time
- **Algorithm**: ASAP (As Soon As Possible) + ALAP (As Late As Possible) scheduling

**Critical Path Computation**:

1. **ASAP (Forward Pass)**:
   ```
   For each node in topological order:
       EST(node) = max(EST(pred) + latency(pred) for all predecessors)
   ```
   - Nodes with no predecessors: EST = 0
   - Propagates earliest possible start times forward

2. **ALAP (Backward Pass)**:
   ```
   Makespan = max(EST(node) + latency(node) for all nodes)
   
   For each node in reverse topological order:
       LST(node) = min(LST(succ) - latency(node) for all successors)
   ```
   - Leaf nodes: LST = makespan - latency
   - Propagates latest allowable start times backward

3. **Slack Calculation**:
   ```
   Slack(node) = LST(node) - EST(node)
   ```
   - Slack = 0: Node is on critical path (cannot be delayed)
   - Slack > 0: Node has scheduling flexibility

4. **Critical Path Identification**:
   - Start from the final node (highest finish time)
   - Trace back through predecessors with slack = 0
   - When multiple predecessors have slack = 0, choose one (tie-breaking)

**Metrics**:
- **Critical Path Length**: Total cycles on the longest path (makespan)
- **ILP (Instruction-Level Parallelism)**: Total instructions / Critical path length
  - ILP < 1.0: Highly serial code
  - ILP ≈ 1.0: Some parallelism available
  - ILP > 1.5: Good parallelization potential

**Interpretation**:
- Critical path defines the theoretical minimum execution time
- No amount of parallelization can reduce time below this bound
- Instructions on critical path should be prioritized in scheduling
- Instructions with high slack can be delayed to reduce resource conflicts

#### 2.5 Register Pressure Analysis
- **Location**: `src/analysis/RegisterPressure.h/cpp`
- **Function**: Determines register usage over time to detect potential spilling needs
- **Output**: Live ranges, pressure per cycle, spilling requirements

**Live Range Computation**:

1. **Identify First Definition and Last Use**:
   ```
   For each register R:
       birth(R) = first instruction that writes to R
       death(R) = last instruction that reads from R
       
   Special case - input arguments:
       If R is read before written → birth(R) = 0
   ```

2. **Live Range**:
   ```
   LiveRange(R) = [birth(R), death(R)]
   ```
   - Register is "live" during this interval
   - Must be allocated to physical register throughout this range

**Pressure Calculation**:
```
For each time point T in [0, makespan]:
    Pressure(T) = count(registers R where T ∈ LiveRange(R))
```

**Metrics**:
- **Maximum Pressure**: Highest number of simultaneously live registers
- **Average Pressure**: Mean across all time points
- **Spilling Required**: Maximum pressure > Available registers (32)

**Analysis for ML Workloads**:
- **Dot Product**: Pressure peaks during accumulation (≈7 registers)
  - a0, a1, a2 (arguments), s0, s2 (loop vars), t4, t5 (loads)
- **Matrix Multiply**: Higher pressure due to nested loops (≈9 registers)
  - Loop counters (i, j, k), temporary addresses, loaded values
- **Vector Addition**: Low pressure (≈8 registers)
  - Minimal data reuse, short live ranges

**Spilling Strategy** (if pressure > 32):
- Identify registers with longest live ranges and lowest usage frequency
- Insert store instructions to memory at birth
- Insert load instructions from memory at uses
- Note: Spilling adds latency (5 cycles store + 3 cycles load = 8 cycles overhead)

---

## Phase 3: Scheduling, Register Partitioning, and Code Generation

### Purpose

Phase 3 is the culmination of the compilation pipeline, transforming the dependency graph into an executable parallel schedule for the CGRA hardware. It performs register allocation across PEs, maps instructions to hardware resources, schedules instructions respecting dependencies and bus constraints, and generates detailed output files for hardware configuration and performance analysis.

### Components

#### 3.1 Register Partitioning
- **Location**: `src/register_partitioning/`
- **Function**: Distributes the 32 shared registers across the 4 Processing Elements
- **Output**: Register-to-PE ownership mapping

**Partitioning Strategy**:
- **Goal**: Balance register usage across PEs to maximize parallelism
- **Input**: Register live ranges from Phase 2
- **Algorithm**: Greedy assignment with load balancing

**Partitioning Process**:
```
1. Sort registers by live range length (longest first)
2. For each register R:
     Assign R to PE with lowest current register count
3. Result: Each PE owns ≈8 registers (32 / 4 PEs)
```

**Register Ownership Rules**:
- Each register is exclusively owned by one PE
- Instructions accessing a register must communicate with owning PE
- Local operations (same PE) → No bus access required
- Remote operations (different PEs) → Bus arbitration required

**Example Partitioning**:
```
PE0: [a0, a1, t0, t1, s0, s1, ra, sp]      # 8 registers
PE1: [a2, a3, t2, t3, s2, s3, gp, tp]      # 8 registers  
PE2: [a4, a5, t4, t5, s4, s5, a6, a7]      # 8 registers
PE3: [t6, s6, s7, s8, s9, s10, s11, zero]  # 8 registers
```

**Impact on Scheduling**:
- Instructions with all operands on same PE → Can execute locally
- Instructions with operands on different PEs → Must request bus access
- Register partitioning quality directly affects bus contention

#### 3.2 PE Mapping
- **Location**: `src/mapping/`
- **Function**: Assigns each instruction to a Processing Element
- **Output**: Instruction-to-PE mapping

**Mapping Strategies**:

1. **Register-Based Mapping** (Primary Strategy)
   ```
   For instruction I with destination register Rd:
       PE(I) = owner_PE(Rd)
   ```
   - Natural mapping: place instruction where result is needed
   - Minimizes data movement
   - Works well for most computational patterns

2. **Dependency-Based Mapping** (Alternative)
   - Map instructions to same PE as their predecessors
   - Reduces inter-PE communication
   - Useful for highly dependent instruction chains

3. **Load-Balancing Mapping**
   - Distribute instructions evenly across PEs
   - Prevents PE underutilization
   - Applied when register-based mapping creates imbalance

**Mapping Example**:
```assembly
add t0, t1, t2    # Mapped to PE0 (t0 owned by PE0)
lw  t3, 0(a0)     # Mapped to PE1 (t3 owned by PE1)
mul t4, t0, t3    # Mapped to PE2 (t4 owned by PE2, needs bus for t0 and t3)
```

**Metrics**:
- **PE Utilization**: Instructions per PE / Total instructions
- **Balance Factor**: Standard deviation of PE utilization (lower = better)

#### 3.3 Bus Arbiter
- **Location**: `src/arbiter/`
- **Function**: Controls access to the shared bus connecting PEs
- **Algorithm**: Round-robin with contention tracking (based on thesis Section 4.1)

**Arbitration Policies**:

1. **Round-Robin** (Default)
   ```
   Priority order cycles: PE0 → PE1 → PE2 → PE3 → PE0 ...
   
   At cycle C:
       If multiple PEs request bus:
           Grant to PE with highest priority in current cycle
       Rotate priority for next cycle
   ```
   - **Fairness**: Each PE gets equal bus access over time
   - **Simplicity**: No complex priority logic
   - **Performance**: Predictable, low contention overhead

**Bus Access Requirements**:
- **Local operations**: No bus access needed
  - Branch instructions (beq, bne, jal)
  - ALU operations where all operands owned by same PE
  - Example: `add t0, t1, t2` on PE0 (if t0, t1, t2 all owned by PE0)

- **Remote operations**: Bus access required
  - Load/Store instructions (memory access)
  - Inter-PE communication (operands on different PEs)
  - Example: `add t0, t1, t2` on PE0 (if t1 owned by PE1 → needs bus)

**Arbitration Process**:
```
For each cycle C:
    1. Collect bus requests from all PEs
    2. If requests.size() == 0:
           No action needed
    3. If requests.size() == 1:
           Grant bus to requesting PE
    4. If requests.size() > 1:
           Record contention event
           Apply arbitration policy to select winner
           Grant bus to selected PE
    5. Non-granted PEs must wait until next cycle
```

**Contention Tracking**:
- **Total Contentions**: Number of cycles with multiple bus requests
- **Per-PE Contentions**: How many times each PE was denied access
- **Wait Cycles**: Total cycles PEs spent waiting for bus
- **Bus Utilization**: (Cycles with bus grant) / (Total cycles) × 100%


#### 3.4 List Scheduler
- **Location**: `src/scheduling/`
- **Function**: Generates cycle-accurate instruction schedule respecting dependencies and hardware constraints
- **Algorithm**: Priority-based list scheduling with bus arbitration

**Scheduling Algorithm**:
```
Initialize:
    ready_list = instructions with no unresolved dependencies
    cycle = 0
    scheduled = []

While ready_list or pending_instructions:
    For each instruction I in ready_list (sorted by priority):
        # Check resource availability
        target_PE = mapping[I]
        
        if I.requires_bus():
            success = arbiter.requestBusAccess(target_PE, cycle)
            if not success:
                continue  # Try next instruction or next cycle
        
        # Schedule instruction
        schedule(I, target_PE, cycle)
        scheduled.append(I)
        
        # Update dependencies
        for successor S of I:
            if all dependencies of S resolved:
                ready_list.add(S)
    
    # Allow multiple local operations per cycle
    if multiple instructions scheduled this cycle:
        All must be either:
            - Local operations (no bus), OR
            - One bus operation + multiple local operations
    
    cycle++
```

**Instruction Priority**:
1. **Critical path first**: Instructions with slack = 0 (highest priority)
2. **Dependency depth**: Instructions with more successors
3. **Resource availability**: Instructions whose target PE is idle

**Parallel Execution Rules**:
- **Within a cycle**: Multiple instructions CAN execute in parallel IF:
  - All are local operations (no bus access), OR
  - At most 1 instruction requires bus access
- **Bus constraint**: Only 1 PE can access the bus per cycle
- **Dependency constraint**: Consumer must wait for producer to complete

**Scheduling Metrics**:
- **Makespan**: Total execution cycles (lower = better)
- **Speedup**: Sequential cycles / Parallel cycles
- **Efficiency**: Speedup / Number of PEs × 100%
- **IPC (Instructions Per Cycle)**: Total instructions / Makespan
- **Bus Utilization**: Percentage of cycles with bus access

---

## Phase 4: VLIW Code Generation

### Purpose

Phase 4 generates Very Long Instruction Word (VLIW) binary code from the scheduled instructions. Each VLIW word is 128 bits wide (4 PEs × 32 bits), encoding the parallel execution of up to 4 instructions per cycle. This phase produces the final executable code that can be loaded into the CGRA's instruction memory.

### Components

#### 4.1 VLIW Generator
- **Location**: `src/vliw/`
- **Function**: Converts scheduled instructions into 128-bit VLIW words
- **Output**: Binary, hexadecimal, and Verilog-compatible instruction memory files

**VLIW Format (128 bits)**:
```
[127:96] PE3 Instruction (32 bits) - Most Significant
[95:64]  PE2 Instruction (32 bits)
[63:32]  PE1 Instruction (32 bits)
[31:0]   PE0 Instruction (32 bits) - Least Significant
```

**PE Instruction Format (32 bits)**:
```
[31:26] Opcode (6 bits)     - Operation code (up to 64 different operations)
[25:21] Rd (5 bits)         - Destination register (x0-x31)
[20:16] Rs1 (5 bits)        - Source register 1 (x0-x31)
[15:11] Rs2 (5 bits)        - Source register 2 (x0-x31)
[10:0]  Immediate (11 bits) - Signed immediate value [-1024, 1023]
```

**Opcode Mappings** (standard RISC-V encoding):

| Category | Opcode (7-bit) | Operations |
|----------|----------------|------------|
| NOP/Control | 0x13 (0010011) | nop |
| ALU Immediate | 0x13 (0010011) | addi, slti, sltiu, xori, ori, andi, slli, srli, srai |
| ALU Register | 0x33 (0110011) | add, sub, sll, slt, sltu, xor, srl, sra, or, and, mul |
| Load | 0x03 (0000011) | lb, lh, lw, lbu, lhu |
| Store | 0x23 (0100011) | sb, sh, sw |
| Branch | 0x63 (1100011) | beq, bne, blt, bge |
| Jump | 0x6F (1101111) | jal |
| Upper Immediate | 0x37 (0110111) | lui |

**NOP Encoding**:
- All fields set to 0: `0x00000000`
- Used when a PE has no instruction to execute in a given cycle

#### 4.2 Output Formats

The VLIW generator produces multiple output formats to support different use cases:

1. **Binary Format** (`phase4_vliw.bin`)
   - Raw binary file suitable for direct loading into hardware
   - Little-endian byte order
   - Each VLIW word = 16 bytes (128 bits)
   - Can be used with memory initialization tools

2. **Hexadecimal Format** (`phase4_vliw.hex`)
   - Human-readable hexadecimal representation
   - Includes comments with cycle information
   - Format: `PE3_PE2_PE1_PE0` (underscore-separated for clarity)
   - Example:
     ```
     # Cycle 0
     00000000_00000000_04000029_04200029
     ```

3. **Verilog Memory Format** (`phase4_vliw.mem`)
   - Compatible with Verilog `$readmemh` function
   - Pure hexadecimal, no comments
   - Each line = one 128-bit VLIW word
   - Example:
     ```
     0000000000000000040000290 4200029
     ```

4. **Detailed Format** (`phase4_vliw_detailed.txt`)
   - Complete breakdown of each VLIW word
   - Shows individual PE instructions with decoded mnemonics
   - Includes full 128-bit word representation
   - Example:
     ```
     CYCLE   0:
     ---------------------------------------------------------------
       PE0 [31:0]:   0x04200029 | addi rd=t5 rs1=zero imm=0
       PE1 [63:32]:  0x04000029 | addi rd=s0 rs1=zero imm=0
       PE2 [95:64]:  0x00000000 | nop
       PE3 [127:96]: 0x00000000 | nop
     
       Full 128-bit word: 0x00000000000000000400002904200029
     ```

#### 4.3 VLIW Generation Process

```
For each cycle in schedule:
    1. Create 128-bit VLIW word initialized to all NOPs
    2. For each instruction scheduled in this cycle:
        a. Encode instruction into 32-bit format:
           - Extract opcode from mnemonic
           - Map register names to 5-bit numbers
           - Pack immediate value into 11 bits
        b. Place encoded instruction in appropriate PE slot:
           - PE0 → bits [31:0]
           - PE1 → bits [63:32]
           - PE2 → bits [95:64]
           - PE3 → bits [127:96]
    3. Write VLIW word to all output formats
```

#### 4.4 Statistics and Metrics

The VLIW generator calculates and reports:

- **Total VLIW Words**: Number of 128-bit instruction words generated
- **Total Operations**: Count of actual instructions (excluding NOPs)
- **Total NOPs**: Number of empty PE slots
- **Total Slots**: Total PE slots available (VLIW words × 4 PEs)
- **Utilization**: Percentage of PE slots used for actual operations
- **Operation Distribution**: Histogram of operation types

Example output:
```
VLIW Configuration:
  Word Width: 128 bits (4 PEs × 32 bits)
  PE Instruction Format: 32 bits
    [31:26] Opcode (6 bits)
    [25:21] Rd (5 bits)
    [20:16] Rs1 (5 bits)
    [15:11] Rs2 (5 bits)
    [10:0]  Immediate (11 bits)

Generated Code:
  Total VLIW Words: 37
  Total Operations: 55
  Total NOPs: 93
  Total Slots: 148 (4 PEs)
  Utilization: 37.16%

Operation Distribution:
  addi        : 15
  add         : 8
  lw          : 6
  sw          : 2
  slt         : 4
  bne         : 4
  ...
```

#### 4.5 Integration with Hardware

The generated VLIW code can be used with CGRA hardware in several ways:

1. **Direct Memory Initialization**:
   - Load `phase4_vliw.bin` into instruction memory at boot time
   - Use memory-mapped I/O to transfer binary data

2. **Verilog Simulation**:
   - Use `phase4_vliw.mem` with `$readmemh` in testbenches
   - Example:
     ```verilog
     reg [127:0] inst_mem [0:255];
     initial begin
         $readmemh("phase4_vliw.mem", inst_mem);
     end
     ```

3. **FPGA Configuration**:
   - Convert hexadecimal format to COE files for Block RAM initialization
   - Use vendor-specific memory initialization tools

4. **Software Simulation**:
   - Parse detailed format for cycle-accurate simulation
   - Verify hardware behavior against compiler expectations

## Execution Pipeline
The compiler executes all 4 phases sequentially:

1. **Phase 1**: Parse assembly → Build CFG → Detect loops
   - Output: `phase1_*.txt`, `phase1_*.dot`

2. **Phase 2**: Analyze dependencies → Build DFG → Critical path → Register pressure
   - Output: `phase2_*.txt`, `phase2_*.dot`

3. **Phase 3**: Partition registers → Map to PEs → Schedule with arbiter → Generate reports
   - Output: `phase3_*.txt`

4. **Phase 4**: Generate VLIW binary code → Multiple output formats
   - Output: `phase4_vliw.{bin,hex,mem,txt}`

All output files are written to the `output/` directory.

## Source Code Architecture (`src/`)

This section details the internal structure of the compiler and how the different modules connect and interact with each other.

### Connection Overview

The data flow between modules follows the 4-phase pipeline:

```
main.cpp
    ↓
[PHASE 1] → parser/ → cfg/ → loop/
    ↓
[PHASE 2] → config/ → dependency/ → dfg/ → analysis/
    ↓
[PHASE 3] → register_partitioning/ → mapping/ → arbiter/ + scheduling/ → output_generator/
    ↓
[PHASE 4] → vliw/
    ↓
output/
```

### Module: `parser/` (Phase 1)

**Files:**
- `Lexer.h/cpp`: Lexical analysis
- `Parser.h/cpp`: Syntactic analysis
- `Instruction.h/cpp`: Instruction representation

**Responsibilities:**
- Tokenize RISC-V assembly code
- Parse individual instructions
- Extract operands, registers, and immediates
- Classify instruction types (ALU, load/store, branch, etc.)

**Outputs:**
- `std::vector<Instruction>`: List of parsed instructions

**Connections:**
- **Reads from:** `.s` files in `input/`
- **Feeds to:** `CFGBuilder` (cfg/) to build the CFG

---

### Module: `cfg/` (Phase 1)

**Files:**
- `BasicBlock.h/cpp`: Basic block representation
- `CFGBuilder.h/cpp`: Control Flow Graph builder

**Responsibilities:**
- Divide instructions into basic blocks
- Identify block leaders (branch targets, after branch, start)
- Build control edges (fall-through, branch-taken)
- Generate Control Flow Graph (CFG)

**Outputs:**
- `std::vector<BasicBlock>`: List of basic blocks
- `std::map<int, std::vector<int>>`: CFG graph (block → successors)

**Connections:**
- **Receives from:** `Parser` (parsed instructions)
- **Feeds to:** `LoopDetector` (loop/) to detect loops

---

### Module: `loop/` (Phase 1)

**Files:**
- `Loop.h/cpp`: Loop representation
- `LoopDetector.h/cpp`: Natural loop detection

**Responsibilities:**
- Calculate dominance analysis on the CFG
- Identify back-edges (edge → node that dominates the edge)
- Detect natural loops using back-edges
- Classify loop headers and loop bodies

**Outputs:**
- `std::vector<Loop>`: List of detected loops

**Connections:**
- **Receives from:** `CFGBuilder` (complete CFG)
- **Feeds to:** Phase 2 (loop information for loop-carried dependency analysis)

---

### Module: `config/` (Phase 2)

**Files:**
- `ConfigReader.h/cpp`: YAML configuration reader

**Responsibilities:**
- Load hardware parameters from `cgra_config.yaml`
- Load operation latencies from `latency_config.yaml`
- Validate configurations
- Provide centralized access to parameters

**Loaded Configuration:**
- Number of PEs
- Number of registers
- Latencies per instruction type
- Bus arbitration policy

**Connections:**
- **Reads from:** `config/*.yaml`
- **Feeds to:** All Phase 2 and Phase 3 modules that need latencies or hardware parameters

---

### Module: `dependency/` (Phase 2)

**Files:**
- `Dependency.h/cpp`: Dependency edge representation
- `DependencyAnalyzer.h/cpp`: Dependency analysis

**Responsibilities:**
- Detect RAW (Read After Write) dependencies
- Detect WAR (Write After Read) dependencies
- Detect WAW (Write After Write) dependencies
- Detect memory dependencies (load/store)
- Build complete dependency graph

**Algorithm:**
```
For each instruction I:
    For each instruction J before I:
        If J writes R and I reads R → RAW
        If J reads R and I writes R → WAR
        If J writes R and I writes R → WAW
        If J is store and I is load/store → MEMORY
```

**Outputs:**
- `std::vector<Dependency>`: List of all dependencies

**Connections:**
- **Receives from:** `Parser` (instructions), `ConfigReader` (for classification)
- **Feeds to:** `DFGBuilder` (dfg/) to build the DFG

---

### Module: `dfg/` (Phase 2)

**Files:**
- `DFGNode.h/cpp`: Data Flow Graph node
- `DFGBuilder.h/cpp`: DFG builder

**Responsibilities:**
- Build Data Flow Graph (DFG) from RAW dependencies
- Create DFG nodes with attributes:
  - Associated instruction
  - Latency (from `ConfigReader`)
  - EST, LST, Slack (initially uncalculated)
  - Predecessors and successors
- Generate DAG (Directed Acyclic Graph) structure

**Outputs:**
- `std::vector<DFGNode>`: DFG nodes
- `std::map<int, std::vector<int>>`: DFG edges (index → successors)

**Connections:**
- **Receives from:** `DependencyAnalyzer` (dependencies), `ConfigReader` (latencies)
- **Feeds to:** `CriticalPath` (analysis/) to calculate critical path

---

### Module: `analysis/` (Phase 2)

**Files:**
- `CriticalPath.h/cpp`: Critical path analysis
- `RegisterPressure.h/cpp`: Register pressure analysis

#### `CriticalPath`

**Responsibilities:**
- Execute ASAP (As Soon As Possible) scheduling - Forward pass
- Execute ALAP (As Late As Possible) scheduling - Backward pass
- Calculate Slack for each node: `Slack = LST - EST`
- Identify critical path (nodes with Slack = 0)
- Calculate metrics: makespan, ILP

**Algorithm:**
```
ASAP:
    For each node in topological order:
        EST(node) = max(EST(pred) + latency(pred))

ALAP:
    Makespan = max(EST(node) + latency(node))
    For each node in reverse topological order:
        LST(node) = min(LST(succ) - latency(node))

Slack:
    For each node:
        Slack(node) = LST(node) - EST(node)
```

**Outputs:**
- DFG with EST, LST, Slack calculated
- List of nodes on critical path
- Metrics: makespan, ILP

**Connections:**
- **Receives from:** `DFGBuilder` (DFG without timing)
- **Feeds to:** `Scheduler` (scheduling/) with priorities

#### `RegisterPressure`

**Responsibilities:**
- Calculate register live ranges
- Compute register pressure per cycle
- Detect spilling needs
- Generate pressure metrics

**Algorithm:**
```
For each register R:
    birth(R) = first write to R (or 0 if argument)
    death(R) = last read from R
    live_range(R) = [birth(R), death(R)]

For each cycle T:
    pressure(T) = count(registers R where T ∈ live_range(R))
```

**Outputs:**
- Live ranges per register
- Pressure per cycle
- Maximum pressure, average
- Spilling requirement

**Connections:**
- **Receives from:** `Parser` (instructions), `CriticalPath` (timing)
- **Feeds to:** `RegisterPartitioner` (register_partitioning/) for partitioning

---

### Module: `register_partitioning/` (Phase 3)

**Files:**
- `RegisterPartitioner.h/cpp`: Register partitioning

**Responsibilities:**
- Distribute 32 registers among 4 PEs
- Greedy strategy with load balancing
- Consider live ranges for intelligent decisions
- Assign register ownership

**Algorithm:**
```
1. Sort registers by live range length (descending)
2. For each register R:
     PE(R) = PE with lowest number of assigned registers
3. Result: Each PE has ~8 registers
```

**Outputs:**
- `std::map<std::string, int>`: register → PE owner

**Connections:**
- **Receives from:** `RegisterPressure` (live ranges)
- **Feeds to:** `PEMapper` (mapping/) for instruction mapping

---

### Module: `mapping/` (Phase 3)

**Files:**
- `PEMapper.h/cpp`: Instruction to PE mapping

**Responsibilities:**
- Assign each instruction to a specific PE
- Primary strategy: map to PE owning destination register
- Alternative strategies: dependency-based, load-balancing
- Generate instruction → PE mapping

**Algorithm:**
```
For each instruction I with destination register Rd:
    PE(I) = PE_owner(Rd)
```

**Outputs:**
- `std::map<int, int>`: instruction_index → PE

**Connections:**
- **Receives from:** `RegisterPartitioner` (register ownership)
- **Feeds to:** `Scheduler` (scheduling/) for scheduling

---

### Module: `arbiter/` (Phase 3)

**Files:**
- `Arbiter.h/cpp`: Shared bus arbiter

**Responsibilities:**
- Implement Round-Robin arbitration policy
- Manage bus access requests per cycle
- Track contention and statistics
- Determine bus grants per cycle

**Round-Robin Policy:**
```
Cycle 0: PE0 has priority
Cycle 1: PE1 has priority
Cycle 2: PE2 has priority
Cycle 3: PE3 has priority
Cycle 4: PE0 has priority (rotates)
...
```

**Quantum Time:** 1 cycle per PE (immediate rotation)

**Outputs:**
- Bus grants per cycle
- Contention statistics
- Wait cycles per PE

**Connections:**
- **Receives from:** `Scheduler` (bus requests)
- **Feeds to:** `Scheduler` (bus grants)
- **Interaction:** Feedback loop during scheduling

---

### Module: `scheduling/` (Phase 3)

**Files:**
- `Scheduler.h/cpp`: List-based scheduler
- `ScheduledInstruction.h`: Scheduled instruction representation

**Responsibilities:**
- Implement list scheduling with priorities
- Respect data dependencies (from DFG)
- Consider hardware constraints (bus, PEs)
- Integrate with `Arbiter` for bus access
- Generate cycle-by-cycle schedule

**Algorithm:**
```
ready_list = instructions with no pending dependencies
cycle = 0

While there are instructions to schedule:
    For each instruction I in ready_list (sorted by priority):
        target_PE = mapping[I]
        
        If I requires bus:
            If arbiter.canAccessBus(target_PE, cycle):
                arbiter.requestBusAccess(target_PE, cycle)
            Else:
                continue  # Try next instruction
        
        Schedule I on target_PE at cycle
        Update successor dependencies
        
    cycle++
```

**Priorities:**
1. Instructions on critical path (slack = 0)
2. Instructions with more successors
3. Instructions whose PE is available

**Outputs:**
- `std::vector<ScheduledInstruction>`: List of scheduled instructions with cycle and PE
- Schedule per cycle

**Connections:**
- **Receives from:** `CriticalPath` (priorities), `PEMapper` (mapping), `DFGBuilder` (dependencies)
- **Interacts with:** `Arbiter` (bus requests and grants)
- **Feeds to:** `OutputGenerator` (output_generator/) and `VLIWGenerator` (vliw/)

---

### Module: `output_generator/` (Phase 3)

**Files:**
- `OutputGenerator.h/cpp`: Report generator

**Responsibilities:**
- Generate Phase 3 output files
- Create human-readable reports
- Calculate and present performance metrics
- Generate ASCII visualizations (Gantt charts)

**Generated Files:**
- `phase3_schedule.txt`: Cycle-by-cycle schedule
- `phase3_mapping.txt`: Instruction → PE mapping
- `phase3_register_partitioning.txt`: Registers per PE
- `phase3_arbiter_stats.txt`: Bus statistics
- `phase3_metrics.txt`: Performance metrics
- `phase3_visualization.txt`: ASCII Gantt chart
- `phase3_combined.txt`: Complete report

**Connections:**
- **Receives from:** `Scheduler`, `PEMapper`, `RegisterPartitioner`, `Arbiter`
- **Writes to:** `output/`

---

### Module: `vliw/` (Phase 4)

**Files:**
- `VLIWGenerator.h/cpp`: VLIW code generator

**Responsibilities:**
- Convert schedule to VLIW binary code
- Encode instructions in 32-bit format
- Pack 4 instructions into 128-bit VLIW words
- Generate multiple output formats

**Process:**
```
For each cycle:
    VLIW_word = [PE3_inst | PE2_inst | PE1_inst | PE0_inst]
    
    For each PE:
        If PE has instruction in this cycle:
            Encode instruction → 32 bits
            Insert at PE position in VLIW_word
        Else:
            Insert NOP (0x00000000)
    
    Write VLIW_word to output formats
```

**Instruction Encoding (32 bits):**
```
[31:26] Opcode (6 bits)
[25:21] Rd (5 bits)
[20:16] Rs1 (5 bits)
[15:11] Rs2 (5 bits)
[10:0]  Immediate (11 bits)
```

**Outputs:**
- `phase4_vliw.bin`: Raw binary
- `phase4_vliw.hex`: Hexadecimal with comments
- `phase4_vliw.mem`: Verilog format
- `phase4_vliw_detailed.txt`: Complete decoding

**Connections:**
- **Receives from:** `Scheduler` (complete schedule)
- **Writes to:** `output/`

---

### Module: `utils/` (Cross-cutting)

**Files:**
- `Logger.h/cpp`: Logging system

**Responsibilities:**
- Provide unified logging to all modules
- Levels: INFO, WARNING, ERROR, DEBUG
- Write to file (`compiler.log`) and console
- Timestamps and consistent formatting

**Connections:**
- **Used by:** All compiler modules

---

### Detailed Data Flow

```
1. main.cpp loads .s file

2. Parser reads file
   ↓ (vector<Instruction>)
   
3. CFGBuilder builds CFG
   ↓ (vector<BasicBlock>, CFG edges)
   
4. LoopDetector detects loops
   ↓ (vector<Loop>)
   
5. ConfigReader loads configuration
   ↓ (latencies, hardware params)
   
6. DependencyAnalyzer analyzes dependencies
   ↓ (vector<Dependency>)
   
7. DFGBuilder builds DFG
   ↓ (vector<DFGNode>, DFG edges)
   
8. CriticalPath calculates EST/LST/Slack
   ↓ (DFG with timing)
   
9. RegisterPressure analyzes pressure
   ↓ (live ranges, pressure metrics)
   
10. RegisterPartitioner partitions registers
    ↓ (map: register → PE)
    
11. PEMapper maps instructions
    ↓ (map: instruction → PE)
    
12. Scheduler + Arbiter schedule
    ↓ (vector<ScheduledInstruction>)
    
13. OutputGenerator generates Phase 3 reports
    ↓ (phase3_*.txt files)
    
14. VLIWGenerator generates binary code
    ↓ (phase4_vliw.* files)
    
15. End: VLIW code ready for hardware
```

---

## Directory Structure

```
Phase4/
│
├── config/                       # Hardware configuration
│   ├── cgra_config.yaml          # CGRA architecture parameters
│   └── latency_config.yaml       # Operation latencies (based on thesis)
│
├── input/                        # RISC-V assembly files
│   ├── backpropagation.s         # Neural network backpropagation
│   ├── forward_pass.s            # Neural network forward pass
│   ├── softmax.s                 # Softmax activation function
│   ├── normalization.s           # Batch normalization
│   └── matmul.s                  # Matrix multiplication
│
├── output/                       # Complete compilation results
│   ├── compiler.log              # Detailed execution log
│   │
│   ├── phase1_instructions.txt   # Parsed instruction list
│   ├── phase1_cfg.txt            # Control Flow Graph (text)
│   ├── phase1_cfg.dot            # Control Flow Graph (GraphViz)
│   ├── phase1_loops.txt          # Detected loops
│   │
│   ├── phase2_dependencies.txt   # All dependencies (RAW/WAR/WAW/MEMORY)
│   ├── phase2_dependencies.dot   # Dependency graph (GraphViz)
│   ├── phase2_dfg.txt            # Data Flow Graph (text)
│   ├── phase2_dfg.dot            # Data Flow Graph (GraphViz)
│   ├── phase2_critical_path.txt  # Critical path analysis
│   ├── phase2_register_pressure.txt  # Register pressure report
│   │
│   ├── phase3_schedule.txt       # Cycle-by-cycle execution schedule
│   ├── phase3_mapping.txt        # Instruction-to-PE mapping
│   ├── phase3_register_partitioning.txt  # Register ownership per PE
│   ├── phase3_arbiter_stats.txt  # Bus arbitration statistics
│   ├── phase3_metrics.txt        # Performance metrics (speedup, efficiency, IPC)
│   ├── phase3_hardware.txt       # Hardware configuration summary
│   ├── phase3_visualization.txt  # ASCII Gantt chart
│   ├── phase3_combined.txt       # All Phase 3 reports combined
│   │
│   ├── phase4_vliw.bin           # VLIW binary (raw 128-bit words)
│   ├── phase4_vliw.hex           # VLIW hexadecimal (human-readable)
│   ├── phase4_vliw.mem           # VLIW Verilog format ($readmemh)
│   └── phase4_vliw_detailed.txt  # VLIW detailed with decoded instructions
│
├── src/
│   ├── main.cpp                  # Orchestrates all 4 phases
│   │
│   ├── parser/                   # Phase 1: Parsing
│   │   ├── Lexer.h/cpp           # Tokenization
│   │   ├── Parser.h/cpp          # Instruction parsing
│   │   └── Instruction.h/cpp     # Instruction representation
│   │
│   ├── cfg/                      # Phase 1: Control Flow
│   │   ├── CFGBuilder.h/cpp      # CFG construction
│   │   └── BasicBlock.h/cpp      # Basic block representation
│   │
│   ├── loop/                     # Phase 1: Loop Detection
│   │   ├── LoopDetector.h/cpp    # Natural loop identification
│   │   └── Loop.h/cpp            # Loop representation
│   │
│   ├── config/                   # Phase 2: Configuration
│   │   └── ConfigReader.h/cpp    # YAML configuration loader
│   │
│   ├── dependency/               # Phase 2: Dependency Analysis
│   │   ├── Dependency.h/cpp      # Dependency edge representation
│   │   └── DependencyAnalyzer.h/cpp  # RAW/WAR/WAW/MEMORY detection
│   │
│   ├── dfg/                      # Phase 2: Data Flow Graph
│   │   ├── DFGNode.h/cpp         # DFG node with scheduling info
│   │   └── DFGBuilder.h/cpp      # DFG construction from dependencies
│   │
│   ├── analysis/                 # Phase 2: Optimization Analysis
│   │   ├── CriticalPath.h/cpp    # ASAP/ALAP scheduling
│   │   └── RegisterPressure.h/cpp  # Live range analysis
│   │
│   ├── register_partitioning/    # Phase 3: Register Allocation
│   │   └── RegisterPartitioner.h/cpp  # Register-to-PE assignment
│   │
│   ├── mapping/                  # Phase 3: PE Mapping
│   │   └── PEMapper.h/cpp        # Instruction-to-PE mapping
│   │
│   ├── arbiter/                  # Phase 3: Bus Arbitration
│   │   ├── Arbiter.h/cpp         # Round-robin bus arbiter
│   │   └── BusRequest.h          # Bus request representation
│   │
│   ├── scheduling/               # Phase 3: Instruction Scheduling
│   │   ├── Scheduler.h/cpp       # List scheduler with arbiter integration
│   │   └── ScheduledInstruction.h  # Scheduled instruction representation
│   │
│   ├── output_generator/         # Phase 3: Output Generation
│   │   └── OutputGenerator.h/cpp # Generates all Phase 3 output files
│   │
│   ├── vliw/                     # Phase 4: VLIW Generation
│   │   ├── VLIWGenerator.h       # VLIW code generator
│   │   └── VLIWGenerator.cpp     # Implementation
│   │
│   └── utils/
│       └── Logger.h/cpp          # Logging system
│
├── build/                        # Object files (generated)
│   ├── parser/
│   ├── cfg/
│   ├── loop/
│   ├── config/
│   ├── dependency/
│   ├── dfg/
│   ├── analysis/
│   ├── register_partitioning/
│   ├── mapping/
│   ├── arbiter/
│   ├── scheduling/
│   ├── output_generator/
│   ├── vliw/
│   └── utils/
│
├── bin/                          # Executable (generated)
│   └── cgra_compiler             # Final compiler binary
│
├── Makefile                      # Build system
└── README.md                     # This file
```

---