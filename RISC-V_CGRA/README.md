# risc-v-cgra
RISC-V CGRA

This is the verilog code for a CGRA architecture based on RISC-V ISA. 
The array is composed of 8 tiles of 16 processing elements each, that perform fragment instances of up to 64 instructions, controlled by a fragment instance table and an M bus. The tiles are connected via an S bus with S/T-link communication The Tile interface nodes control the flow of data inside the tile, translating a fragment instance address from the global memory into tile indices. 

The processing element is composed by an ALU with two operands (A and B) and a control unit. Instructions coming from the TIN determine whether to perform local data operations on the ALU or global memory operations. Results can be propagated to other PEs. 
