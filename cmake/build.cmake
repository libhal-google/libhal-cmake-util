# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS"BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include(CheckCXXCompilerFlag)

# Save the path of this file resides, where ever conan (or any other package
# manger) puts it.
set(LIBHAL_SCRIPT_PATH ${CMAKE_CURRENT_LIST_DIR})

# Colored LIBHAL text
set(LIBHAL_TITLE "${BoldMagenta}[LIBHAL]:${ColourReset}")

# Find clang-tidy
find_program(LIBHAL_CLANG_TIDY_PROGRAM NAMES "clang-tidy" DOC
  "Path to clang-tidy executable")

if(NOT LIBHAL_CLANG_TIDY_PROGRAM)
  message(STATUS "${LIBHAL_TITLE} clang-tidy not found.")
else()
  # Execute clang-tidy --version and parse the output
  execute_process(
    COMMAND ${LIBHAL_CLANG_TIDY_PROGRAM} --version
    OUTPUT_VARIABLE clang_tidy_version_output
  )

  # Regex to extract version number
  string(REGEX MATCH ".* version ([0-9]+)\\.([0-9]+)\\.([0-9]+)"
    _
    ${clang_tidy_version_output})
  set(clang_tidy_major_version ${CMAKE_MATCH_1})
  set(clang_tidy_minor_version ${CMAKE_MATCH_2})
  set(clang_tidy_patch_version ${CMAKE_MATCH_3})

  # Check if version is 15 or higher
  if(clang_tidy_major_version LESS 15)
    message(WARNING "clang-tidy version is too old. Version 15 or newer is required. Found: ${clang_tidy_major_version}.${clang_tidy_minor_version}.${clang_tidy_patch_version}")
  else()
    # Set clang-tidy as a CXX language standard option
    message(STATUS "${LIBHAL_TITLE} clang-tidy version ${clang_tidy_major_version}.${clang_tidy_minor_version}.${clang_tidy_patch_version} AVAILABLE!")
    set(LIBHAL_CLANG_TIDY_CONFIG_FILE
      "${LIBHAL_SCRIPT_PATH}/clang-tidy.conf")
    set(LIBHAL_CLANG_TIDY "${LIBHAL_CLANG_TIDY_PROGRAM}"
      "--config-file=${LIBHAL_CLANG_TIDY_CONFIG_FILE}")
  endif()
endif()

# Adds clang tidy check to target for host builds (skipped if a cross build)
function(_libhal_add_clang_tidy_check TARGET)
  if(NOT ${CMAKE_CROSSCOMPILING})
    set(CMAKE_CXX_CLANG_TIDY ${LIBHAL_CLANG_TIDY_PROGRAM})
    set_target_properties(${TARGET} PROPERTIES CXX_CLANG_TIDY
      "${LIBHAL_CLANG_TIDY}")
  else()
    message(STATUS "${LIBHAL_TITLE} Cross compiling, skipping clang-tidy checks for \"${TARGET}\"")
  endif()
endfunction()

function(libhal_make_library)
  # Parse CMake function arguments
  set(options USE_CLANG_TIDY)
  set(one_value_args LIBRARY_NAME)
  set(multi_value_args SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(LIBRARY_ARGS
    "${options}"
    "${one_value_args}"
    "${multi_value_args}"
    ${ARGN})

  foreach(PACKAGE ${LIBRARY_ARGS_PACKAGES})
    find_package(${PACKAGE} REQUIRED)
  endforeach()

  add_library(${LIBRARY_ARGS_LIBRARY_NAME} ${LIBRARY_ARGS_SOURCES})
  _libhal_add_clang_tidy_check(${LIBRARY_ARGS_LIBRARY_NAME})
  target_include_directories(${LIBRARY_ARGS_LIBRARY_NAME} PUBLIC
    include
    src
    ${LIBRARY_ARGS_INCLUDES})
  target_compile_features(${LIBRARY_ARGS_LIBRARY_NAME} PRIVATE cxx_std_20)
  target_compile_options(${LIBRARY_ARGS_LIBRARY_NAME} PRIVATE
    -g
    -Werror
    -Wall
    -Wextra
    -Wshadow)
  target_link_libraries(${LIBRARY_ARGS_LIBRARY_NAME} PUBLIC
    ${LIBRARY_ARGS_LINK_LIBRARIES})
  install(TARGETS ${LIBRARY_ARGS_LIBRARY_NAME})
endfunction()

function(libhal_unit_test)
  # Parse CMake function arguments
  set(options)
  set(one_value_args)
  set(multi_value_args SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(UNIT_TEST_ARGS
    "${options}"
    "${one_value_args}"
    "${multi_value_args}"
    ${ARGN})

  # Setup unit_test executable
  find_package(ut REQUIRED CONFIG)

  foreach(PACKAGE ${UNIT_TEST_ARGS_PACKAGES})
    find_package(${PACKAGE} REQUIRED)
  endforeach()

  add_executable(unit_test ${UNIT_TEST_ARGS_SOURCES})

  # By the end of the this block, CMAKE_REQUIRED_LINK_OPTIONS will be reset to
  # its original value
  block()
  set(CMAKE_REQUIRED_LINK_OPTIONS -fsanitize=address)
  check_cxx_compiler_flag(-fsanitize=address ADDRESS_SANITIZER_SUPPORT)
  endblock()

  if(${ADDRESS_SANITIZER_SUPPORT})
    message(STATUS "${LIBHAL_TITLE} Address Sanitizer available! Using it for tests!")
    target_compile_options(unit_test PRIVATE -fsanitize=address)
    target_link_options(unit_test PRIVATE -fsanitize=address)
  else()
    message(STATUS "${LIBHAL_TITLE} Address Sanitizer not supported!")
  endif(${ADDRESS_SANITIZER_SUPPORT})

  _libhal_add_clang_tidy_check(unit_test)

  target_include_directories(unit_test PUBLIC include tests src
    ${UNIT_TEST_ARGS_INCLUDES})
  target_compile_features(unit_test PRIVATE cxx_std_20)

  target_compile_options(unit_test PRIVATE
    --coverage
    -fprofile-arcs
    -ftest-coverage
    -Werror
    -Wall
    -Wextra
    -Wshadow
    -Wnon-virtual-dtor
    -Wno-gnu-statement-expression
    -pedantic)

  target_link_options(unit_test PRIVATE
    --coverage
    -fprofile-arcs
    -ftest-coverage)

  target_link_libraries(unit_test PRIVATE
    boost-ext-ut::ut
    ${UNIT_TEST_ARGS_LINK_LIBRARIES})

  add_custom_target(run_tests ALL DEPENDS unit_test COMMAND unit_test)
endfunction()

function(libhal_test_and_make_library)
  set(options)
  set(one_value_args LIBRARY_NAME)
  set(multi_value_args
    SOURCES
    TEST_SOURCES
    INCLUDES
    PACKAGES
    LINK_LIBRARIES
    TEST_PACKAGES
    TEST_LINK_LIBRARIES)
  cmake_parse_arguments(BUILD_ARGS
    "${options}"
    "${one_value_args}"
    "${multi_value_args}"
    ${ARGN})

  if(NOT ${CMAKE_CROSSCOMPILING})
    libhal_unit_test(
      SOURCES ${BUILD_ARGS_SOURCES} ${BUILD_ARGS_TEST_SOURCES}
      INCLUDES ${BUILD_ARGS_INCLUDES}
      PACKAGES
      ${BUILD_ARGS_PACKAGES}
      ${BUILD_ARGS_TEST_PACKAGES}
      LINK_LIBRARIES
      ${BUILD_ARGS_LINK_LIBRARIES}
      ${BUILD_ARGS_TEST_LINK_LIBRARIES}
    )
  endif()

  libhal_make_library(
    LIBRARY_NAME ${BUILD_ARGS_LIBRARY_NAME}
    SOURCES ${BUILD_ARGS_SOURCES}
    INCLUDES ${BUILD_ARGS_INCLUDES}
    PACKAGES ${BUILD_ARGS_PACKAGES}
    LINK_LIBRARIES ${BUILD_ARGS_LINK_LIBRARIES}
  )
endfunction()

function(libhal_build_demos)
  # Parse CMake function arguments
  set(options DISABLE_CLANG_TIDY)
  set(one_value_args)
  set(multi_value_args
    DEMOS
    SOURCES
    INCLUDES
    PACKAGES
    LINK_LIBRARIES
    LINK_FLAGS)
  cmake_parse_arguments(DEMO_ARGS
    "${options}"
    "${one_value_args}"
    "${multi_value_args}"
    ${ARGN})

  if(NOT DEFINED ENV{LIBHAL_PLATFORM} OR
    NOT DEFINED ENV{LIBHAL_PLATFORM_LIBRARY})
    message(FATAL_ERROR
      "${LIBHAL_TITLE}: Both LIBHAL_PLATFORM and LIBHAL_PLATFORM_LIBRARY "
      "environment variables must be defined. Make sure you are using the "
      "correct profile!")
  endif()

  message(STATUS "${LIBHAL_TITLE}: LIBHAL_PLATFORM = $ENV{LIBHAL_PLATFORM}")
  message(STATUS "${LIBHAL_TITLE}: LIBHAL_PLATFORM_LIBRARY = "
                 "libhal-$ENV{LIBHAL_PLATFORM}")

  find_package(libhal-$ENV{LIBHAL_PLATFORM_LIBRARY} REQUIRED)

  foreach(PACKAGE ${DEMO_ARGS_PACKAGES})
    find_package(${PACKAGE} REQUIRED)
  endforeach()

  set(startup_source_files main.cpp ${DEMO_ARGS_SOURCES})

  # Makes the platform/<platform_name>.cpp file optional
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/platforms/$ENV{LIBHAL_PLATFORM}.cpp")
      list(APPEND startup_source_files platforms/$ENV{LIBHAL_PLATFORM}.cpp)
  endif()

  add_library(startup_code ${startup_source_files})

  target_compile_features(startup_code PRIVATE cxx_std_20)
  target_include_directories(startup_code PUBLIC ${DEMO_ARGS_INCLUDES})
  target_compile_options(startup_code PRIVATE
    -g
    -Werror
    -Wall
    -Wextra
    -Wshadow
  )
  target_link_libraries(startup_code PRIVATE
    ${DEMO_ARGS_LINK_LIBRARIES}
    libhal::$ENV{LIBHAL_PLATFORM_LIBRARY}
  )

  if(NOT ${DEMO_ARGS_DISABLE_CLANG_TIDY})
    _libhal_add_clang_tidy_check(startup_code)
  endif()

  foreach(demo ${DEMO_ARGS_DEMOS})
    set(elf ${demo}.elf)
    message(STATUS "${LIBHAL_TITLE} Generating Demo for \"${elf}\"")
    add_executable(${elf} ${CMAKE_SOURCE_DIR}/applications/${demo}.cpp)
    target_compile_features(${elf} PRIVATE cxx_std_20)
    target_include_directories(${elf} PUBLIC ${DEMO_ARGS_INCLUDES})
    target_compile_options(${elf} PRIVATE
      -g
      -Werror
      -Wall
      -Wextra
      -Wshadow
    )
    target_link_libraries(${elf} PRIVATE
      startup_code
      ${DEMO_ARGS_LINK_LIBRARIES}
      libhal::$ENV{LIBHAL_PLATFORM_LIBRARY}
    )

    if(${CMAKE_CROSSCOMPILING})
      target_link_options(${elf} PRIVATE ${DEMO_ARGS_LINK_FLAGS})
      # Convert elf into .bin, .hex and other formats needed for programming
      # devices.
      libhal_post_build(${elf})
      libhal_disassemble(${elf})
    endif()

    if(NOT ${DEMO_ARGS_DISABLE_CLANG_TIDY})
      _libhal_add_clang_tidy_check(${elf})
    endif()
  endforeach()
endfunction()