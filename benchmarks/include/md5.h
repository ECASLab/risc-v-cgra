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

#pragma once

#include <stdint.h>
#include <string.h>

unsigned int leftRotate(unsigned int x, unsigned int n);

void md5(const uint8_t *initial_msg, size_t len, uint8_t *digest);

void print_md5(uint8_t *digest);

uint32_t F(uint32_t X, uint32_t Y, uint32_t Z);

uint32_t G(uint32_t X, uint32_t Y, uint32_t Z);

uint32_t H(uint32_t X, uint32_t Y, uint32_t Z);

uint32_t I(uint32_t X, uint32_t Y, uint32_t Z);
