# This file is part of the C Benchmarks project.
# 
# Licensed under the GPL v2.1 License. 
# See LICENSE file in the project root for full license information.
# 
# Authors: 
# Diego Avila <dandida95@gmail.com>
# Luis G. Leon Vega <luis.leon@ieee.org>
#

sources = []

# subdir('testbenches')

project_inc += [include_directories('.')]

libgcd_src = [files('gcd.c')]
libmd5_src = [files('md5.c')]
matrix_src = [files('matrix.c')]
sources += [libmd5_src,libgcd_src,matrix_src]


lib_gcd = shared_library('gcd',
libgcd_src,
include_directories: [project_inc],
install: true,
dependencies: [project_deps]
)

lib_md5 = shared_library('mcd',
    libmd5_src,
    include_directories: [project_inc],
    install: true,
    dependencies: [project_deps]
)

lib_matrix = shared_library('matrix',
    sources: matrix_src,
    install: true,
    include_directories: [project_inc],
    dependencies: [project_deps]
)

gcd_dep = declare_dependency(link_with: lib_gcd)
md5_dep = declare_dependency(link_with: lib_md5)
matrix_dep = declare_dependency(link_with: lib_matrix)

shared_libs += [lib_gcd,lib_md5,lib_matrix]

project_deps += [gcd_dep,md5_dep,matrix_dep]

src += sources
