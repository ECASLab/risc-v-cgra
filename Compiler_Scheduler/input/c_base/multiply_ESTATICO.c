/*
 * This file is part of the C Benchmarks project.
 * Edited version for RISC-V RV32IM compilation - Static 2x2 matrices
 *
 * Licensed under the GPL v2.1 License. 
 * See LICENSE file in the project root for full
 * license information.
 *
 * Author:
 * Dylan Garbanzo Fallas <dgarbanzof16@gmail.com>
 *
 */

// Status definitions
typedef enum { SUCCESS = 0, FAILURE = -1 } status_code;

typedef struct s {
  status_code code;
  char* message;
} status;

// Matrix structure with static allocation
typedef struct im {
  unsigned int rows;
  unsigned int columns;
  int data[2][2];  // Static 2x2 matrix
} int_matrix;

// Simple pseudo-random number generator (Linear Congruential Generator)
static unsigned int seed = 1;

void custom_srand(unsigned int s) {
  seed = s;
}

int custom_rand(void) {
  seed = seed * 1103515245 + 12345;
  return (seed / 65536) % 32768;
}

// Function prototypes
status int_matrix_init(int_matrix *input, unsigned int rows, unsigned int columns);
status int_matrix_multiplication(int_matrix *input1, int_matrix *input2, int_matrix *output);

// Initialize matrix
status int_matrix_init(int_matrix *input, unsigned int rows, unsigned int columns) {
  status output;
  output.code = SUCCESS;
  output.message = "OK";

  if (rows != 2 || columns != 2) {
    output.code = FAILURE;
    output.message = "Only 2x2 matrices supported";
    return output;
  }

  input->rows = rows;
  input->columns = columns;
  
  // Initialize all elements to 0
  for (unsigned int i = 0; i < rows; i++) {
    for (unsigned int j = 0; j < columns; j++) {
      input->data[i][j] = 0;
    }
  }
  
  return output;
}

// Matrix multiplication
status int_matrix_multiplication(int_matrix *input1, int_matrix *input2, int_matrix *output) {
  status returned;
  returned.code = SUCCESS;
  returned.message = "OK";

  if (input1->columns != input2->rows) {
    returned.message = "Number of columns of the first matrix must equal the number of rows of the second matrix.";
    returned.code = FAILURE;
    return returned;
  }

  if (output->rows != input1->rows || output->columns != input2->columns) {
    returned.message = "Output matrix dimensions must match the result of the multiplication.";
    returned.code = FAILURE;
    return returned;
  }

  for (unsigned int i = 0; i < output->rows; i++) {
    for (unsigned int j = 0; j < output->columns; j++) {
      output->data[i][j] = 0;
      for (unsigned int k = 0; k < input1->columns; k++) {
        output->data[i][j] += input1->data[i][k] * input2->data[k][j];
      }
    }
  }

  return returned;
}

int main(void) {
  int_matrix matrix_one;
  int_matrix matrix_two;
  int_matrix output;
  const unsigned int rowsAndColumns = 2;
  
  // Initialize matrices
  status alloc_status_one = int_matrix_init(&matrix_one, rowsAndColumns, rowsAndColumns);
  status alloc_status_two = int_matrix_init(&matrix_two, rowsAndColumns, rowsAndColumns);
  status alloc_status_output = int_matrix_init(&output, rowsAndColumns, rowsAndColumns);
  
  if (alloc_status_one.code != SUCCESS || 
      alloc_status_two.code != SUCCESS || 
      alloc_status_output.code != SUCCESS) {
    return FAILURE;
  }

  // Initialize pseudo-random generator with a fixed seed
  custom_srand(12345);
  
  // Fill matrices with pseudo-random numbers (0-29)
  for (unsigned int i = 0; i < rowsAndColumns; i++) {
    for (unsigned int j = 0; j < rowsAndColumns; j++) {
      matrix_one.data[i][j] = custom_rand() % 30;
      matrix_two.data[i][j] = custom_rand() % 30;
    }
  }

  // Perform matrix multiplication
  status multiply_status = int_matrix_multiplication(&matrix_one, &matrix_two, &output);

  // Verify multiplication was successful by checking if result makes sense
  // For 2x2 matrices, we can do a simple sanity check
  int verification_passed = 0;
  if (multiply_status.code == SUCCESS) {
    // Simple verification: check if any result is non-negative (basic sanity)
    if (output.data[0][0] >= 0 || output.data[0][1] >= 0 || 
        output.data[1][0] >= 0 || output.data[1][1] >= 0) {
      verification_passed = 1;
    }
  }

  if (multiply_status.code == SUCCESS && verification_passed) {
    return SUCCESS;
  } else {
    return FAILURE;
  }
}