/*
 * Test file for multiply_CUSTOM.c
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
extern status int_matrix_multiplication(int_matrix **input1, int_matrix **input2, int_matrix **output);
extern void custom_srand(unsigned int s);

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
    
    // Test 1: Alocar matrices 2x2 para prueba simple
    status s1 = int_matrix_alloc(&m1, 2, 2);
    if (s1.code != SUCCESS) {
        exit_program(1);
    }
    
    status s2 = int_matrix_alloc(&m2, 2, 2);
    if (s2.code != SUCCESS) {
        exit_program(2);
    }
    
    status s3 = int_matrix_alloc(&result, 2, 2);
    if (s3.code != SUCCESS) {
        exit_program(3);
    }
    
    // Test 2: Inicializar con matriz identidad y una matriz simple
    // m1 = [[1, 0], [0, 1]] (identidad)
    // m2 = [[2, 3], [4, 5]]
    m1->data[0][0] = 1; m1->data[0][1] = 0;
    m1->data[1][0] = 0; m1->data[1][1] = 1;
    
    m2->data[0][0] = 2; m2->data[0][1] = 3;
    m2->data[1][0] = 4; m2->data[1][1] = 5;
    
    // Test 3: Multiplicar (identidad * m2 = m2)
    status s4 = int_matrix_multiplication(&m1, &m2, &result);
    if (s4.code != SUCCESS) {
        exit_program(4);
    }
    
    // Test 4: Verificar resultado
    if (result->data[0][0] != 2 || result->data[0][1] != 3 ||
        result->data[1][0] != 4 || result->data[1][1] != 5) {
        exit_program(5);
    }
    
    // Test 5: Prueba con matrices 3x3
    int_matrix_free(&m1);
    int_matrix_free(&m2);
    int_matrix_free(&result);
    
    s1 = int_matrix_alloc(&m1, 3, 3);
    s2 = int_matrix_alloc(&m2, 3, 3);
    s3 = int_matrix_alloc(&result, 3, 3);
    
    if (s1.code != SUCCESS || s2.code != SUCCESS || s3.code != SUCCESS) {
        exit_program(6);
    }
    
    // m1 = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    // m2 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]] (identidad)
    int val = 1;
    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 3; j++) {
            m1->data[i][j] = val++;
            m2->data[i][j] = (i == j) ? 1 : 0;
        }
    }
    
    // Test 6: Multiplicar (m1 * identidad = m1)
    s4 = int_matrix_multiplication(&m1, &m2, &result);
    if (s4.code != SUCCESS) {
        exit_program(7);
    }
    
    // Verificar resultado
    val = 1;
    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 3; j++) {
            if (result->data[i][j] != val++) {
                exit_program(8);
            }
        }
    }
    
    // Test 7: Liberar memoria
    status s5 = int_matrix_free(&m1);
    status s6 = int_matrix_free(&m2);
    status s7 = int_matrix_free(&result);
    
    if (s5.code != SUCCESS || s6.code != SUCCESS || s7.code != SUCCESS) {
        exit_program(9);
    }
    
    exit_program(0);
}