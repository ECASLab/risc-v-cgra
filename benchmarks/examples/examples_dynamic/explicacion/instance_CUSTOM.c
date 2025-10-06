/*
 * This file is part of the C Benchmarks project.
 * Edited version for RISC-V RV32IM compilation with improved custom malloc/free
 * BALANCED VISUALIZATION VERSION
 *
 * Licensed under the GPL v2.1 License. 
 * See LICENSE file in the project root for full
 * license information.
 *
 * Author:
 * Dylan Garbanzo Fallas <dgarbanzof16@gmail.com>
 *
 */

#include <stdio.h>

// Status definitions
typedef enum { SUCCESS = 0, FAILURE = -1 } status_code;

typedef struct s {
  status_code code;
  char* message;
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

// Block header structure
typedef struct block_header {
  unsigned int size;              // Size of the block (excluding header)
  unsigned int is_free;           // 1 if free, 0 if allocated
  struct block_header *next;      // Next block in the free list
} block_header_t;

#define HEAP_SIZE 4096
#define HEADER_SIZE sizeof(block_header_t)
#define ALIGN_SIZE 4

static char heap[HEAP_SIZE];
static block_header_t *free_list_head = (block_header_t*)0;
static unsigned int allocator_initialized = 0;

// Statistics for visualization
static unsigned int total_allocs = 0;
static unsigned int total_frees = 0;

// Align size to 4 bytes
static unsigned int align(unsigned int size) {
  return (size + (ALIGN_SIZE - 1)) & ~(ALIGN_SIZE - 1);
}

// Initialize the allocator
static void init_allocator(void) {
  if (allocator_initialized) return;
  
  free_list_head = (block_header_t*)heap;
  free_list_head->size = HEAP_SIZE - HEADER_SIZE;
  free_list_head->is_free = 1;
  free_list_head->next = (block_header_t*)0;
  
  allocator_initialized = 1;
  
  printf("\n========================================\n");
  printf("MEMORY ALLOCATOR INITIALIZED\n");
  printf("========================================\n");
  printf("Heap size: %u bytes\n", HEAP_SIZE);
  printf("Header size: %u bytes\n", HEADER_SIZE);
  printf("Initial free space: %u bytes\n\n", HEAP_SIZE - HEADER_SIZE);
  printf("En memoria (dirección %p):\n", (void*)heap);
  printf("  [Header: size=%u, is_free=1, next=NULL] → %u bytes libres\n\n",
         HEAP_SIZE - HEADER_SIZE, HEAP_SIZE - HEADER_SIZE);
}

// Visualize heap state
static void visualize_heap(const char* context) {
  printf("\n--- Estado después de: %s ---\n", context);
  
  block_header_t *current = free_list_head;
  unsigned int block_num = 0;
  unsigned int total_free = 0;
  unsigned int total_used = 0;
  
  while (current != (block_header_t*)0) {
    printf("Block %u: ", block_num);
    
    if (current->is_free) {
      printf("[FREE ] %4u bytes", current->size);
      total_free += current->size;
    } else {
      printf("[USED ] %4u bytes", current->size);
      total_used += current->size;
    }
    
    // Add context for what's stored
    if (!current->is_free) {
      if (block_num == 0) printf("  ← int_matrix struct");
      else if (block_num == 1) printf("  ← int** data (row pointers)");
      else if (block_num >= 2) printf("  ← fila %u: int[2]", block_num - 2);
    } else {
      printf("  ← Espacio restante");
    }
    printf("\n");
    
    current = current->next;
    block_num++;
  }
  
  printf("\nTotal usado: %u bytes de datos + %u bytes de overhead (%u headers × %u)\n", 
         total_used, block_num * HEADER_SIZE, block_num, HEADER_SIZE);
  printf("--------------------------------------------------\n");
}

// Find a free block using first-fit strategy
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

// Split a block if it's large enough
static void split_block(block_header_t *block, unsigned int size) {
  if (block->size >= size + HEADER_SIZE + ALIGN_SIZE) {
    unsigned int original_size = block->size;
    block_header_t *new_block = (block_header_t*)((char*)block + HEADER_SIZE + size);
    new_block->size = block->size - size - HEADER_SIZE;
    new_block->is_free = 1;
    new_block->next = block->next;
    
    block->size = size;
    block->next = new_block;
    
    printf("   Split: %u bytes → %u bytes (usado) + %u bytes (libre)\n",
           original_size, size, new_block->size);
  }
}

// Coalesce adjacent free blocks
static void coalesce_blocks(void) {
  block_header_t *current = free_list_head;
  unsigned int coalesced = 0;
  
  while (current != (block_header_t*)0 && current->next != (block_header_t*)0) {
    char *current_end = (char*)current + HEADER_SIZE + current->size;
    char *next_start = (char*)current->next;
    
    if (current->is_free && current->next->is_free && current_end == next_start) {
      unsigned int old_current = current->size;
      unsigned int old_next = current->next->size;
      current->size += HEADER_SIZE + current->next->size;
      current->next = current->next->next;
      coalesced++;
      printf("   Coalesced: %u + %u + %u(header) → %u bytes\n",
             old_current, old_next, HEADER_SIZE, current->size);
    } else {
      current = current->next;
    }
  }
}

// Custom malloc implementation
void* custom_malloc(unsigned int size) {
  if (size == 0) return (void*)0;
  
  if (!allocator_initialized) {
    init_allocator();
  }
  
  size = align(size);
  
  printf("malloc(%u bytes):\n", size);
  printf("   1. Busca primer bloque libre ≥ %u bytes ✓\n", size);
  
  block_header_t *block = find_free_block(size);
  if (block == (block_header_t*)0) {
    printf("   ❌ FAILED (out of memory)\n");
    return (void*)0;
  }
  
  printf("   2. Encuentra bloque de %u bytes\n", block->size);
  printf("   3. Split (divide el bloque):\n");
  
  split_block(block, size);
  block->is_free = 0;
  total_allocs++;
  
  void* ptr = (void*)((char*)block + HEADER_SIZE);
  printf("   → SUCCESS (ptr=%p)\n", ptr);
  
  return ptr;
}

// Custom free implementation
void custom_free(void* ptr) {
  if (ptr == (void*)0) return;
  
  block_header_t *block = (block_header_t*)((char*)ptr - HEADER_SIZE);
  
  if ((char*)block < heap || (char*)block >= heap + HEAP_SIZE) {
    return;
  }
  
  printf("free(ptr=%p, size=%u bytes)\n", ptr, block->size);
  
  block->is_free = 1;
  total_frees++;
  
  coalesce_blocks();
}

// ============================================================================
// MATRIX FUNCTIONS
// ============================================================================

// Function prototypes
status int_matrix_alloc(int_matrix **input, unsigned int rows, unsigned int columns);
status int_matrix_free(int_matrix **input);
status int_matrix_sum(int_matrix **input1, int_matrix **input2, int_matrix **output);

// Matrix allocation with custom malloc
status int_matrix_alloc(int_matrix **input, unsigned int rows, unsigned int columns) {
  status output;
  output.code = SUCCESS;
  output.message = "OK";

  if (rows <= 1 || columns <= 1) {
    output.code = FAILURE;
    output.message = "Rows and columns only accepts positive integers greater than 1";
    return output;
  }

  if (*input != (int_matrix*)0) {
    output.code = FAILURE;
    output.message = "Object has already been assigned memory.";
    return output;
  }

  printf("\n╔════════════════════════════════════════╗\n");
  printf("║  Allocating %ux%u matrix               ║\n", rows, columns);
  printf("╚════════════════════════════════════════╝\n\n");

  int_matrix *matrix = (int_matrix *)custom_malloc(sizeof(int_matrix));
  if (matrix == (int_matrix*)0) {
    output.code = FAILURE;
    output.message = "Memory allocation failed";
    return output;
  }

  matrix->rows = rows;
  matrix->columns = columns;
  matrix->data = (int **)custom_malloc(rows * sizeof(int *));
  
  if (matrix->data == (int**)0) {
    output.code = FAILURE;
    output.message = "Memory allocation failed";
    return output;
  }

  for (unsigned int i = 0; i < rows; i++) {
    (matrix->data)[i] = (int *)custom_malloc(columns * sizeof(int));

    if ((matrix->data)[i] == (int*)0) {
      output.code = FAILURE;
      output.message = "Memory allocation failed";
      return output;
    }
  }
  
  *input = matrix;
  visualize_heap("allocación completa de matriz");
  return output;
}

// Matrix deallocation with custom free
status int_matrix_free(int_matrix **input) {
  status output;
  output.code = SUCCESS;
  output.message = "OK";

  if (*input == (int_matrix*)0) {
    output.code = FAILURE;
    output.message = "Object has not been assigned memory.";
    return output;
  }

  printf("\n╔════════════════════════════════════════╗\n");
  printf("║  Freeing %ux%u matrix                  ║\n", (*input)->rows, (*input)->columns);
  printf("╚════════════════════════════════════════╝\n\n");

  for (unsigned int i = 0; i < (*input)->rows; i++) {
    custom_free((*input)->data[i]);
  }
  
  custom_free((*input)->data);
  custom_free(*input);
  
  *input = (int_matrix*)0;
  visualize_heap("liberación completa de matriz");
  return output;
}

// Matrix addition
status int_matrix_sum(int_matrix **input1, int_matrix **input2, int_matrix **output) {
  status returned;
  returned.code = SUCCESS;
  returned.message = "OK";
  
  if (*input1 == (int_matrix*)0 || *input2 == (int_matrix*)0 || *output == (int_matrix*)0) {
    returned.code = FAILURE;
    returned.message = "All the int_matrix pointers have to be allocated.";
    return returned;
  }

  if (((*input1)->rows) != (*input2)->rows ||
      (*input1)->columns != (*input2)->columns ||
      (*input1)->rows != (*output)->rows ||
      (*input1)->columns != (*output)->columns ||
      (*input2)->rows != (*output)->rows ||
      (*input2)->columns != (*output)->columns) {
    returned.message = "Rows and Columns have to match in length.";
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
  
  printf("\n╔════════════════════════════════════════╗\n");
  printf("║   MATRIX ADDITION TEST (2x2)          ║\n");
  printf("╚════════════════════════════════════════╝\n");
  
  // Allocate matrices
  status alloc_status_one = int_matrix_alloc(&matrix_one, rowsAndColumns, rowsAndColumns);
  status alloc_status_two = int_matrix_alloc(&matrix_two, rowsAndColumns, rowsAndColumns);
  status alloc_status_output = int_matrix_alloc(&output, rowsAndColumns, rowsAndColumns);
  
  if (alloc_status_one.code != SUCCESS || 
      alloc_status_two.code != SUCCESS || 
      alloc_status_output.code != SUCCESS) {
    printf("\n[ERROR] Matrix allocation failed!\n");
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
  printf("\n╔════════════════════════════════════════╗\n");
  printf("║   Performing Matrix Addition          ║\n");
  printf("╚════════════════════════════════════════╝\n\n");
  
  status sum_status = int_matrix_sum(&matrix_one, &matrix_two, &output);
  
  if (sum_status.code == SUCCESS) {
    printf("Result matrix (all values should be 2):\n");
    for (unsigned int i = 0; i < rowsAndColumns; i++) {
      printf("  [ ");
      for (unsigned int j = 0; j < rowsAndColumns; j++) {
        printf("%d ", (output->data)[i][j]);
      }
      printf("]\n");
    }
  }

  // Free memory
  int_matrix_free(&matrix_one);
  int_matrix_free(&matrix_two);
  int_matrix_free(&output);

  printf("\n╔════════════════════════════════════════╗\n");
  printf("║   TEST COMPLETED                       ║\n");
  printf("╚════════════════════════════════════════╝\n\n");

  if (sum_status.code == SUCCESS) {
    return SUCCESS;
  } else {
    return FAILURE;
  }
}