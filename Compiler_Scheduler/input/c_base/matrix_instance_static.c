/*
 * This file is part of the C Benchmarks project.
 *
 * Licensed under the GPL v2.1 License. 
 * See LICENSE file in the project root for full
 * license information.
 *
 * Static memory version - RISC-V ISA compatible
 * No function calls to avoid jalr instruction
 *
 */

#define MATRIX_SIZE 10
#define MATRIX_TOTAL_ELEMENTS (MATRIX_SIZE * MATRIX_SIZE)

int matrix_one[MATRIX_TOTAL_ELEMENTS];
int matrix_two[MATRIX_TOTAL_ELEMENTS];
int output[MATRIX_TOTAL_ELEMENTS];

void main(void) {
    int i;
    
    // Initialize matrix_one with 1
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        matrix_one[i] = 1;
    }
    
    // Initialize matrix_two with 1
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        matrix_two[i] = 1;
    }
    
    // Initialize output with 0
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        output[i] = 0;
    }
    
    // Matrix sum
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        output[i] = matrix_one[i] + matrix_two[i];
    }
    
    // Results in output[i]
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        output[i] = output[i];
    }
    
    // Infinite loop to avoid return
    while (1) {
        i = i;
    }
}
