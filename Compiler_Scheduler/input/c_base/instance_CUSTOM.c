/*
 * This file is part of the C Benchmarks project.
 * Minimal version for RISC-V RV32IM compilation with improved custom malloc/free
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
  int **data;
} int_matrix;

// ============================================================================
// IMPROVED CUSTOM MEMORY ALLOCATOR
// ============================================================================

typedef struct block_header {
  unsigned int size;
  unsigned int is_free;
  struct block_header *next;
} block_header_t;

#define HEAP_SIZE 4096
#define HEADER_SIZE sizeof(block_header_t)
#define ALIGN_SIZE 4

static char heap[HEAP_SIZE];
static block_header_t *free_list_head = (block_header_t*)0;
static unsigned int allocator_initialized = 0;

static unsigned int align(unsigned int size) {
  // Align to 4 bytes: (size + 3) & ~3
  // Equivalent to: (size + (ALIGN_SIZE - 1)) & ~(ALIGN_SIZE - 1)
  return (size + 3) & 0xFFFFFFFC;
}

static void init_allocator(void) {
  if (allocator_initialized) return;
  
  free_list_head = (block_header_t*)heap;
  free_list_head->size = HEAP_SIZE - HEADER_SIZE;
  free_list_head->is_free = 1;
  free_list_head->next = (block_header_t*)0;
  
  allocator_initialized = 1;
}

static block_header_t* find_free_block(unsigned int size) {
  block_header_t *current = free_list_head;
  
  while (current != (block_header_t*)0) {
    if (current->is_free && current->size >= size) {
      return current;
    }
    current = current->next;
  }
  
  return (block_header_t*)0;
}

static void split_block(block_header_t *block, unsigned int size) {
  if (block->size >= size + HEADER_SIZE + ALIGN_SIZE) {
    block_header_t *new_block = (block_header_t*)((char*)block + HEADER_SIZE + size);
    new_block->size = block->size - size - HEADER_SIZE;
    new_block->is_free = 1;
    new_block->next = block->next;
    
    block->size = size;
    block->next = new_block;
  }
}

static void coalesce_blocks(void) {
  block_header_t *current = free_list_head;
  
  while (current != (block_header_t*)0 && current->next != (block_header_t*)0) {
    char *current_end = (char*)current + HEADER_SIZE + current->size;
    char *next_start = (char*)current->next;
    
    if (current->is_free && current->next->is_free && current_end == next_start) {
      current->size += HEADER_SIZE + current->next->size;
      current->next = current->next->next;
    } else {
      current = current->next;
    }
  }
}

void* custom_malloc(unsigned int size) {
  if (size == 0) return (void*)0;
  
  if (!allocator_initialized) {
    init_allocator();
  }
  
  size = align(size);
  
  block_header_t *block = find_free_block(size);
  if (block == (block_header_t*)0) {
    return (void*)0;
  }
  
  split_block(block, size);
  block->is_free = 0;
  
  return (void*)((char*)block + HEADER_SIZE);
}

void custom_free(void* ptr) {
  if (ptr == (void*)0) return;
  
  block_header_t *block = (block_header_t*)((char*)ptr - HEADER_SIZE);
  
  if ((char*)block < heap || (char*)block >= heap + HEAP_SIZE) {
    return;
  }
  
  block->is_free = 1;
  coalesce_blocks();
}

// ============================================================================
// MATRIX FUNCTIONS
// ============================================================================

status int_matrix_alloc(int_matrix **input, unsigned int rows, unsigned int columns);
status int_matrix_free(int_matrix **input);
status int_matrix_sum(int_matrix **input1, int_matrix **input2, int_matrix **output);

status int_matrix_alloc(int_matrix **input, unsigned int rows, unsigned int columns) {
  status output;
  output.code = SUCCESS;

  if (rows <= 1 || columns <= 1) {
    output.code = FAILURE;
    return output;
  }

  if (*input != (int_matrix*)0) {
    output.code = FAILURE;
    return output;
  }

  int_matrix *matrix = (int_matrix *)custom_malloc(sizeof(int_matrix));
  if (matrix == (int_matrix*)0) {
    output.code = FAILURE;
    return output;
  }

  matrix->rows = rows;
  matrix->columns = columns;
  matrix->data = (int **)custom_malloc(rows * sizeof(int *));
  
  if (matrix->data == (int**)0) {
    output.code = FAILURE;
    return output;
  }

  for (unsigned int i = 0; i < rows; i++) {
    (matrix->data)[i] = (int *)custom_malloc(columns * sizeof(int));

    if ((matrix->data)[i] == (int*)0) {
      output.code = FAILURE;
      return output;
    }
  }
  
  *input = matrix;
  return output;
}

status int_matrix_free(int_matrix **input) {
  status output;
  output.code = SUCCESS;

  if (*input == (int_matrix*)0) {
    output.code = FAILURE;
    return output;
  }

  for (unsigned int i = 0; i < (*input)->rows; i++) {
    custom_free((*input)->data[i]);
  }
  
  custom_free((*input)->data);
  custom_free(*input);
  
  *input = (int_matrix*)0;
  return output;
}

status int_matrix_sum(int_matrix **input1, int_matrix **input2, int_matrix **output) {
  status returned;
  returned.code = SUCCESS;
  
  if (*input1 == (int_matrix*)0 || *input2 == (int_matrix*)0 || *output == (int_matrix*)0) {
    returned.code = FAILURE;
    return returned;
  }

  if (((*input1)->rows) != (*input2)->rows ||
      (*input1)->columns != (*input2)->columns ||
      (*input1)->rows != (*output)->rows ||
      (*input1)->columns != (*output)->columns ||
      (*input2)->rows != (*output)->rows ||
      (*input2)->columns != (*output)->columns) {
    returned.code = FAILURE;
    return returned;
  }

  for (unsigned int i = 0; i < (*output)->rows; i++) {
    for (unsigned int j = 0; j < (*output)->columns; j++) {
      (*output)->data[i][j] = (*input1)->data[i][j] + (*input2)->data[i][j];
    }
  }

  return returned;
}

int main(void) {
  int_matrix *matrix_one = (int_matrix*)0;
  int_matrix *matrix_two = (int_matrix*)0;
  int_matrix *output = (int_matrix*)0;
  const unsigned int rowsAndColumns = 2;
  
  // Allocate matrices
  status alloc_status_one = int_matrix_alloc(&matrix_one, rowsAndColumns, rowsAndColumns);
  status alloc_status_two = int_matrix_alloc(&matrix_two, rowsAndColumns, rowsAndColumns);
  status alloc_status_output = int_matrix_alloc(&output, rowsAndColumns, rowsAndColumns);
  
  if (alloc_status_one.code != SUCCESS || 
      alloc_status_two.code != SUCCESS || 
      alloc_status_output.code != SUCCESS) {
    return FAILURE;
  }

  // Fill matrices with 1s 
  for (unsigned int i = 0; i < rowsAndColumns; i++) {
    for (unsigned int j = 0; j < rowsAndColumns; j++) {
      (matrix_one->data)[i][j] = 1;
      (matrix_two->data)[i][j] = 1;
    }
  }

  // Perform matrix sum
  status sum_status = int_matrix_sum(&matrix_one, &matrix_two, &output);

  // Free memory
  status free_status = int_matrix_free(&matrix_one);
  free_status = int_matrix_free(&matrix_two);
  free_status = int_matrix_free(&output);

  if (sum_status.code == SUCCESS) {
    return SUCCESS;
  } else {
    return FAILURE;
  }
}