/*
 * This file is part of the C Benchmarks project.
 * Edited version for RISC-V RV32IM compilation - Static 10x10 matrices
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
} status;

// Matrix structure
typedef struct im {
  unsigned int rows;
  unsigned int columns;
  int data[10][10];
} int_matrix;

// Function prototypes
status int_matrix_init(int_matrix *input, unsigned int rows, unsigned int columns);
status int_matrix_sum(int_matrix *input1, int_matrix *input2, int_matrix *output);

// Initialize matrix with static allocation
status int_matrix_init(int_matrix *input, unsigned int rows, unsigned int columns) {
  status output;
  output.code = SUCCESS;

  if (rows != 10 || columns != 10) {
    output.code = FAILURE;
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

// Matrix addition
status int_matrix_sum(int_matrix *input1, int_matrix *input2, int_matrix *output) {
  status returned;
  returned.code = SUCCESS;
  
  if (input1->rows != input2->rows || 
      input1->columns != input2->columns ||
      input1->rows != output->rows ||
      input1->columns != output->columns) {
    returned.code = FAILURE;
    return returned;
  }

  for (unsigned int i = 0; i < output->rows; i++) {
    for (unsigned int j = 0; j < output->columns; j++) {
      output->data[i][j] = input1->data[i][j] + input2->data[i][j];
    }
  }

  return returned;
}

int main(void) {
  int_matrix matrix_one;
  int_matrix matrix_two;
  int_matrix output;
  const unsigned int rowsAndColumns = 10;
  
  // Initialize matrices
  status alloc_status_one = int_matrix_init(&matrix_one, rowsAndColumns, rowsAndColumns);
  status alloc_status_two = int_matrix_init(&matrix_two, rowsAndColumns, rowsAndColumns);
  status alloc_status_output = int_matrix_init(&output, rowsAndColumns, rowsAndColumns);
  
  // Check if initialization was successful
  if (alloc_status_one.code != SUCCESS || 
      alloc_status_two.code != SUCCESS || 
      alloc_status_output.code != SUCCESS) {
    return FAILURE;
  }

  // Fill matrices with 1s
  for (unsigned int i = 0; i < rowsAndColumns; i++) {
    for (unsigned int j = 0; j < rowsAndColumns; j++) {
      matrix_one.data[i][j] = 1;
      matrix_two.data[i][j] = 1;
    }
  }

  // Perform matrix addition
  status sum_status = int_matrix_sum(&matrix_one, &matrix_two, &output);

  // Verify by checking one element and returning appropriate status
  if (sum_status.code == SUCCESS && output.data[0][0] == 2) {
    return SUCCESS;
  } else {
    return FAILURE;
  }
}