/*
 * Test file for instance_CUSTOM.c
 */

typedef enum { SUCCESS = 0, FAILURE = -1 } status_code;

typedef struct s {
  status_code code;
  char* message;
} status;

typedef struct im {
  unsigned int rows;
  unsigned int columns;
  int **data;
} int_matrix;

// Declaraciones externas
extern status int_matrix_alloc(int_matrix **input, unsigned int rows, unsigned int columns);
extern status int_matrix_free(int_matrix **input);
extern status int_matrix_sum(int_matrix **input1, int_matrix **input2, int_matrix **output);

void exit_program(int code) {
    asm volatile (
        "li a7, 93\n"
        "mv a0, %0\n"
        "ecall\n"
        : 
        : "r"(code)
        : "a0", "a7"
    );
    __builtin_unreachable();
}

void _start(void) {
    int_matrix *m1 = (int_matrix*)0;
    int_matrix *m2 = (int_matrix*)0;
    int_matrix *result = (int_matrix*)0;
    
    // Test 1: Alocar matrices 3x3
    status s1 = int_matrix_alloc(&m1, 3, 3);
    if (s1.code != SUCCESS) {
        exit_program(1);
    }
    
    status s2 = int_matrix_alloc(&m2, 3, 3);
    if (s2.code != SUCCESS) {
        exit_program(2);
    }
    
    status s3 = int_matrix_alloc(&result, 3, 3);
    if (s3.code != SUCCESS) {
        exit_program(3);
    }
    
    // Test 2: Inicializar matrices
    // m1 = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    // m2 = [[9, 8, 7], [6, 5, 4], [3, 2, 1]]
    int value1 = 1;
    int value2 = 9;
    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 3; j++) {
            m1->data[i][j] = value1++;
            m2->data[i][j] = value2--;
        }
    }
    
    // Test 3: Sumar matrices
    status s4 = int_matrix_sum(&m1, &m2, &result);
    if (s4.code != SUCCESS) {
        exit_program(4);
    }
    
    // Test 4: Verificar resultado (todas deben ser 10)
    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 3; j++) {
            if (result->data[i][j] != 10) {
                exit_program(5);
            }
        }
    }
    
    // Test 5: Liberar memoria
    status s5 = int_matrix_free(&m1);
    if (s5.code != SUCCESS) {
        exit_program(6);
    }
    
    status s6 = int_matrix_free(&m2);
    if (s6.code != SUCCESS) {
        exit_program(7);
    }
    
    status s7 = int_matrix_free(&result);
    if (s7.code != SUCCESS) {
        exit_program(8);
    }
    
    // Test 6: Verificar que los punteros estén en NULL después de free
    if (m1 != (int_matrix*)0 || m2 != (int_matrix*)0 || result != (int_matrix*)0) {
        exit_program(9);
    }
    
    exit_program(0);
}