# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function(libhal_generate_intel_hex elf_file)
  find_program(OBJCOPY ${CMAKE_OBJCOPY})

  # Create hex (intel hex) file
  add_custom_command(TARGET ${elf_file} POST_BUILD
    COMMAND ${OBJCOPY} -O ihex ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}
    ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}.hex)
endfunction()

function(libhal_generate_binary elf_file)
  find_program(OBJCOPY ${CMAKE_OBJCOPY})

  # Create bin (binary) file
  add_custom_command(TARGET ${elf_file} POST_BUILD
    COMMAND ${OBJCOPY} -O binary
    ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}
    ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}.bin)
endfunction()

function(libhal_disassemble elf_file)
  find_program(OBJDUMP ${CMAKE_OBJDUMP})

  # Create disassembly file
  add_custom_command(TARGET ${elf_file} POST_BUILD
    COMMAND ${OBJDUMP} --disassemble --demangle
    ${CMAKE_CURRENT_BINARY_DIR}/${elf_file} >
    ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}.S)
endfunction()

function(libhal_disassemble_with_source elf_file)
  find_program(OBJDUMP ${CMAKE_OBJDUMP})

  # Create disassembly file with source information
  add_custom_command(TARGET ${elf_file} POST_BUILD
    COMMAND ${OBJDUMP} --all-headers --source
    --disassemble --demangle ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}
    > ${CMAKE_CURRENT_BINARY_DIR}/${elf_file}.lst)
endfunction()

function(libhal_print_size_info elf_file)
  find_program(SIZE ${CMAKE_SIZE_UTIL})

  # Print executable size
  add_custom_command(TARGET ${elf_file} POST_BUILD
    COMMAND ${SIZE} ${CMAKE_CURRENT_BINARY_DIR}/${elf_file})
endfunction()

function(libhal_full_post_build elf_file)
  libhal_generate_intel_hex(${elf_file})
  libhal_generate_binary(${elf_file})
  libhal_disassemble(${elf_file})
  libhal_disassemble_with_source(${elf_file})
  libhal_print_size_info(${elf_file})
endfunction()

function(libhal_post_build elf_file)
  libhal_generate_intel_hex(${elf_file})
  libhal_generate_binary(${elf_file})
  libhal_print_size_info(${elf_file})
endfunction()
