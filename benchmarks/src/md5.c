/*
 * This file is part of the C Benchmarks project.
 *
 * Licensed under the GPL v2.1 License. 
 * See LICENSE file in the project root for full
 * license information.
 *
 * Authors:
 * Diego Avila <dandida95@gmail.com>
 * Luis G. Leon Vega <luis.leon@ieee.org>
 *
 */

#include "include/md5.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

// Constants for MD5
unsigned int leftRotate(unsigned int x, unsigned int n) {
  return (x << n) | (x >> (32 - n));
}
// MD5 Functions
uint32_t F(uint32_t X, uint32_t Y, uint32_t Z) { return (X & Y) | (~X & Z); }
uint32_t G(uint32_t X, uint32_t Y, uint32_t Z) { return (X & Z) | (Y & ~Z); }
uint32_t H(uint32_t X, uint32_t Y, uint32_t Z) { return X ^ Y ^ Z; }
uint32_t I(uint32_t X, uint32_t Y, uint32_t Z) { return Y ^ (X | ~Z); }

// MD5 Transformation Constants
const uint32_t K[] = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a,
  0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
  0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
  0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
  0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
  0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391};

// MD5 Shift Amounts
const uint32_t S[] = {7,  12, 17, 22, 7,  12, 17, 22, 7,  12, 17, 22, 7,
                      12, 17, 22, 5,  9,  14, 20, 5,  9,  14, 20, 5,  9,
                      14, 20, 5,  9,  14, 20, 4,  11, 16, 23, 4,  11, 16,
                      23, 4,  11, 16, 23, 4,  11, 16, 23, 6,  10, 15, 21,
                      6,  10, 15, 21, 6,  10, 15, 21, 6,  10, 15, 21};

// MD5 Hashing Function
void md5(const uint8_t *initial_msg, size_t len, uint8_t *digest) {
  uint8_t msg[64] = {0};
  uint64_t bit_len = len * 8;
  memcpy(msg, initial_msg, len);

  // Padding
  msg[len] = 0x80;
  if (len < 56) {
    memcpy(&msg[56], &bit_len, 8);
  }

  // Initial Hash Values
  uint32_t A = 0x67452301;
  uint32_t B = 0xefcdab89;
  uint32_t C = 0x98badcfe;
  uint32_t D = 0x10325476;

  // Process each 512-bit chunk
  uint32_t M[16];
  memcpy(M, msg, 64);

  uint32_t a = A, b = B, c = C, d = D;

  for (uint32_t i = 0; i < 64; i++) {
    uint32_t F_val, g;
    if (i < 16) {
      F_val = F(b, c, d);
      g = i;
    } else if (i < 32) {
      F_val = G(b, c, d);
      g = (5 * i + 1) % 16;
    } else if (i < 48) {
      F_val = H(b, c, d);
      g = (3 * i + 5) % 16;
    } else {
      F_val = I(b, c, d);
      g = (7 * i) % 16;
    }

    uint32_t temp = d;
    d = c;
    c = b;
    b = b + leftRotate((a + F_val + K[i] + M[g]), S[i]);
    a = temp;
  }

  // Add the transformed values
  A += a;
  B += b;
  C += c;
  D += d;
  // Store the hash in digest
  memcpy(digest, &A, 4);
  memcpy(digest + 4, &B, 4);
  memcpy(digest + 8, &C, 4);
  memcpy(digest + 12, &D, 4);
}

// Convert digest to hex string
void print_md5(uint8_t *digest) {
  for (int i = 0; i < 16; i++) printf("%02x", digest[i]);
  printf("\n");
}
