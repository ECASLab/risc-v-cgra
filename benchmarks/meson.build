#
# See LICENSE for more information about licensing
#  Copyright 2025
#
# Author: Diego Arturo Avila Torres <dandida95@gmail.com>
#         Luis G. Leon Vega <luis.leon@ieee.org>
#
#

project('testbenches',['c'],version: '0.1.0',
	default_options: [])

add_global_arguments('-Wno-ignored-qualifiers',
	language:'c')

c = meson.get_compiler('c')

src = []


# cflags
c_args = []

project_inc = [include_directories('.', 'include')]



# shared_libs

shared_libs = []


# dependencies

project_deps = []

subdir('include')

subdir('src')

subdir('examples')


# executables

exec = []


# src += [files('main.c')]


# main = executable('main',['main.c'], include_directories: [project_inc], link_with: [shared_libs],link_language: 'c')

developer_mode = get_option('developer-mode')
profiling_mode = get_option('profiling-mode')
if developer_mode
  c_args += ['--optimize=g']
  pre_commit = find_program('pre-commit', required: true, native: true)
  run_command(pre_commit, 'install', check: false)
  run_command(pre_commit, 'install', '--hook-type', 'commit-msg', check: false)
endif

if profiling_mode
  c_args += ['-DPROFILE_MODE']
endif