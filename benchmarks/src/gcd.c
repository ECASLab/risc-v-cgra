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

#include "include/gcd.h"

#include <stdio.h>

int gcd_euclid(unsigned int a, unsigned int b) {
  while (b != 0) {
    int temp = b;
    b = a % b;
    a = temp;
  }
  return a;
}

int binary_gcd(unsigned int a, unsigned int b) {
  if (a == 0) return b;
  if (b == 0) return a;

  // Find common factors of 2
  int shift;
  for (shift = 0; ((a | b) & 1) == 0; ++shift) {
    a >>= 1;
    b >>= 1;
  }

  // Remove factors of 2 from 'a'
  while ((a & 1) == 0) {
    a >>= 1;
  }

  do {
    // Remove factors of 2 from 'b'
    while ((b & 1) == 0) {
      b >>= 1;
    }

    // Ensure a <= b
    if (a > b) {
      int temp = a;
      a = b;
      b = temp;
    }

    b = b - a;  // Reduce b

  } while (b != 0);

  return a << shift;  // Restore common factors of 2
}
