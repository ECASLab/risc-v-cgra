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

int seed = 12345;

void main(void) {
    int i, j, k;
    int value;
    int a, c;
    int sum;
    int idx_result, idx_a, idx_b;
    
    // Initialize matrix_one with random values
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        a = 1103515245;
        c = 12345;
        seed = (a * seed + c);
        if (seed < 0) {
            seed = -seed;
        }
        value = seed;
        while (value >= 30) {
            value = value - 30;
        }
        matrix_one[i] = value;
    }
    
    // Initialize matrix_two with random values
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        a = 1103515245;
        c = 12345;
        seed = (a * seed + c);
        if (seed < 0) {
            seed = -seed;
        }
        value = seed;
        while (value >= 30) {
            value = value - 30;
        }
        matrix_two[i] = value;
    }
    
    // Initialize output with zeros
    for (i = 0; i < MATRIX_TOTAL_ELEMENTS; i = i + 1) {
        output[i] = 0;
    }
    
    // Matrix multiplication: result[i][j] = sum(input1[i][k] * input2[k][j])
    for (i = 0; i < MATRIX_SIZE; i = i + 1) {
        for (j = 0; j < MATRIX_SIZE; j = j + 1) {
            sum = 0;
            for (k = 0; k < MATRIX_SIZE; k = k + 1) {
                idx_a = i * MATRIX_SIZE + k;
                idx_b = k * MATRIX_SIZE + j;
                sum = sum + (matrix_one[idx_a] * matrix_two[idx_b]);
            }
            idx_result = i * MATRIX_SIZE + j;
            output[idx_result] = sum;
        }
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
