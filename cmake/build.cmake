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

include(CheckCXXCompilerFlag)

# Save the path of this file resides, where ever conan (or any other package
# manger) puts it.
set(LIBHAL_UNIT_TEST_PATH ${CMAKE_CURRENT_LIST_DIR})

#[=======================================================================[.rst:
build
------------------

Build unit tests for libhal packages/projects

.. command:: libhal_unit_test

  .. code-block:: cmake

    libhal_unit_test([SOURCES <files...>]
                     [INCLUDES <directories...>]
                     [PACKAGES <packages...>]
                     [LINK_LIBRARIES <link_libraries...>])

  - SOURCES is a list of source files to include in the build for the unit
    test. The set of source files MUST include the project source files as
    well as the unit test source files.
  - INCLUDES is a list of include directires to be added to the executable.
    Note that the `include`, `src`, and `test` directories are already
    included for you.
  - PACKAGES list of packages to automatically find and make available for the
    unit test build. Packages needed by the package binary will also be needed
    for unit tests, so supply them here.
  - LINK_LIBRARIES list of the libraries to link into the unit test library.
    Packages needed by the package binary will also be needed for unit tests,
    so supply them here. DO NOT include the package/library that is being
    tested here. This can cause linker errors because the same definition of
    symbols will appear twice due to the files being compiled again in the
    SOURCES directory. Omitting the source files causing the linker error will
    cause those source files to be skipped during coverage. Clang and GCC both
    need to add instrumentation to the source files during compilation to
    enable coverage and package libraries are built without this
    instrumentation.

All libhal packages and projects must be compiled with this function to comply
with the libhal standards. This function does the following:

  1. Creates an target/executable named "unit_test"
  2. Accepts SOURCES and INCLUDE directories and provides them to the target
  3. Enables Address Sanitizer if the compiler supports it (issues warning if
  it does not)
  4. Applies clang-tidy checks to all files if the clang-tidy program is
     available on the system (issues warning if it does not)
  5. Add flags to enable code coverage for the unit test executable

This function requires that Boost.UT unit testing framework to be available
as a package. In conan, add this to your `build_requirements()` method:

  .. code-block:: python

    def build_requirements(self):
        self.tool_requires("libhal-cmake-util/1.1.0")
        self.test_requires("boost-ext-ut/1.1.9")

#]=======================================================================]
function(libhal_unit_test)
  # Parse CMake function arguments
  set(options)
  set(one_value_args)
  set(multi_value_args SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(UNIT_TEST_ARGS "${options}" "${one_value_args}"
    "${multi_value_args}" ${ARGN})

  # Setup unit_test executable
  find_package(ut REQUIRED CONFIG)

  foreach(PACKAGE ${UNIT_TEST_ARGS_PACKAGES})
    find_package(${PACKAGE} REQUIRED)
  endforeach()

  add_executable(unit_test ${UNIT_TEST_ARGS_SOURCES})
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

  # By the end of the this block, CMAKE_REQUIRED_LINK_OPTIONS will be reset to
  # its original value
  block()
  set(CMAKE_REQUIRED_LINK_OPTIONS -fsanitize=address)
  check_cxx_compiler_flag(-fsanitize=address ADDRESS_SANITIZER_SUPPORT)
  endblock()

  if(${ADDRESS_SANITIZER_SUPPORT})
    message(STATUS "libhal[unit test]: Using Address Sanitizer")
    target_compile_options(unit_test PRIVATE -fsanitize=address)
    target_link_options(unit_test PRIVATE -fsanitize=address)
  else()
    message(WARNING "libhal[unit test]: Address Sanitizer not supported!")
  endif(${ADDRESS_SANITIZER_SUPPORT})

  # Check if clang-tidy exists on the system and if so, evaluate each file
  # against
  find_program(clang_tidy_exe NAMES "clang-tidy")

  # If ti exists, add it as an additional check for each source file
  if(DEFINED clang_tidy_exe)
    message(STATUS "libhal[unit test]: Using clang-tidy")
    set(config_file "${LIBHAL_UNIT_TEST_PATH}/clang-tidy.conf")
    set(clang_tidy "${clang_tidy_exe}" "--config-file=${config_file}")
    set_target_properties(unit_test PROPERTIES CXX_CLANG_TIDY "${clang_tidy}")
  else()
    message(WARNING "'clang-tidy' not available! Install it to run checks!")
  endif(DEFINED clang_tidy_exe)

  add_custom_target(run_tests ALL DEPENDS unit_test COMMAND unit_test)
endfunction()

#[=======================================================================[.rst:

Build libhal library

.. command:: libhal_make_library

  .. code-block:: cmake

    libhal_make_library([LIBRARY_NAME <library_name>]
                        [SOURCES <files...>]
                        [INCLUDES <directories...>]
                        [PACKAGES <packages...>]
                        [LINK_LIBRARIES <link_libraries...>])

  - LIBRARY_NAME name of the library (e.g. libhal-lpc40, libhal-util)
  - SOURCES is a list of source files to include in the package build.
  - INCLUDES is a list of include directires to be added to the executable.
    Note that the `include` and `src` directories are already included for you.
  - PACKAGES list of packages to automatically find and make available for the
    package build.
  - LINK_LIBRARIES list of the libraries to link into the library.

#]=======================================================================]
function(libhal_make_library)
  # Parse CMake function arguments
  set(options)
  set(one_value_args LIBRARY_NAME)
  set(multi_value_args SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(LIBRARY_ARGS "${options}" "${one_value_args}"
    "${multi_value_args}" ${ARGN})

  foreach(PACKAGE ${LIBRARY_ARGS_PACKAGES})
    find_package(${PACKAGE} REQUIRED)
  endforeach()

  add_library(${LIBRARY_ARGS_LIBRARY_NAME} ${LIBRARY_ARGS_SOURCES})
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

#[=======================================================================[.rst:

Build and validate unit tests and build packages

Recommended to use this function rather than libhal_unit_test and
libhal_make_library separately.

.. command:: libhal_test_and_make_library

  .. code-block:: cmake

    libhal_test_and_make_library([LIBRARY_NAME <library_name>]
                                 [SOURCES <files...>]
                                 [INCLUDES <directories...>]
                                 [PACKAGES <packages...>]
                                 [LINK_LIBRARIES <link_libraries...>])

  - LIBRARY_NAME name of the library (e.g. libhal-lpc40, libhal-util)
  - SOURCES is a list of source files to include in the package build and unit
    tests.
  - TEST_SOURCES is a list of source unit test source files used to build the
    unit test executable. This will not be included in the library package build.
  - INCLUDES is a list of include directires to be added to the executable.
    Note that the `include` and `src` directories are already included for you.
  - PACKAGES list of packages to automatically find and make available for the
    package build.
  - LINK_LIBRARIES list of the libraries to link into the library.

This function requires that Boost.UT unit testing framework to be available
as a package. In conan, add this to your `build_requirements()` method:

  .. code-block:: python

    def build_requirements(self):
        self.tool_requires("libhal-cmake-util/1.1.0")
        self.test_requires("boost-ext-ut/1.1.9")

#]=======================================================================]
function(libhal_test_and_make_library)
  set(options)
  set(one_value_args LIBRARY_NAME)
  set(multi_value_args SOURCES TEST_SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(BUILD_ARGS "${options}" "${one_value_args}"
    "${multi_value_args}" ${ARGN})

  if(NOT ${CMAKE_CROSSCOMPILING})
    libhal_unit_test(
      SOURCES ${BUILD_ARGS_SOURCES} ${BUILD_ARGS_TEST_SOURCES}
      INCLUDES ${BUILD_ARGS_INCLUDES}
      PACKAGES ${BUILD_ARGS_PACKAGES}
      LINK_LIBRARIES ${BUILD_ARGS_LINK_LIBRARIES}
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