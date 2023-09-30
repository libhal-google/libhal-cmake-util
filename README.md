# libhal-cmake-util

Generic cmake utilities such as macros, functions, and toolchains for all
categories of libhal libraries.

This package is a REQUIREMENT for libhal libraries using cmake.

## Integration into Conan

Add the following line to the `build_requirements()` method of your library or
applications `conanfile.py`:

```python
def build_requirements(self):
  self.tool_requires("libhal-cmake-util/1.0.0")
```

**NOTE**: the `tool_requires` line can also go in the `requirements()` method or
in the `tool_requires` attribute, but the standard way of doing this is in
libhal is a `build_requirements()` method.

## Package Options

This package comes with some options to customize its behavior. You can set
these options in the `tool_requires` function.

```python
def build_requirements(self):
  self.tool_requires("libhal-cmake-util/1.0.0",
      options={
        "add_build_outputs": True,
        "optimize_debug_build": True,
      })
```

### Option: `add_build_outputs` (Default: `True`)

When the `add_build_outputs` option is set to `True`, a range of post-build
utility functions are made available. These functions generate additional files
and information derived from the final binary or .elf file. These functions are
provided to your CMake build project via the Conan CMake toolchain file. If
you are using `conan build` along with the `CMakeToolchain` generator, then
these functions will be made available in your `CMakeLists.txt` build script.

- `libhal_generate_intel_hex(elf_file)`: transforms the provided elf file into
  an Intel HEX (.hex) file.

- `libhal_generate_binary(elf_file)`: turns the provided elf file into a binary
  (.bin) file, a format often used for device flashing.

- `libhal_disassemble(elf_file)`: breaks down the elf file into assembly code,
- providing a platform for detailed analysis.

- `libhal_disassemble_with_source(elf_file)`:  like the one above, disassembles
  the elf file into assembly code for in-depth analysis. However, it also
  integrates the source code with the disassembly, facilitating the mapping of
  lines of code to the corresponding assembly instructions.

- `libhal_print_size_info(elf_file)`: prints out the size
  information for the different sections of the elf file.

- `libhal_full_post_build(elf_file)`: executes a comprehensive post-build
  process, which includes the following functions:
  - `libhal_generate_intel_hex()`
  - `libhal_generate_binary()`
  - `libhal_disassemble()`
  - `libhal_disassemble_with_source()`
  - `libhal_print_size_info()`

- `libhal_post_build(elf_file)`: performs a selective post-build process,
  executing the following functions:
  - `libhal_generate_intel_hex()`
  - `libhal_generate_binary()`
  - `libhal_print_size_info()`

### Option: `optimize_debug_build` (Default: `True`)

Setting `optimize_debug_build` to `True` modifies the `Debug` build type
optimization level from `-O0 -g` to `-Og -g`. The `-Og` option offers a balance
similar to `-O1`, but with modifications designed to enhance the debugging
experience. However, these changes can increase the binary size compared to
`-O1`.

This option is particularly crucial because the `-O0` setting (no optimization)
often leads to large binary sizes. These oversized binaries may not fit on a
device when a more robust debugging experience is required.

Why does this matter? At higher optimization levels, much of the source code can
be optimized away, making step-through debugging appear erratic. You might
experience skipped lines of code, inlined constructors that are difficult to
interpret, and ephemeral stack variables that may disappear between lines of the
same scope due to optimization. These factors can significantly complicate
on-chip debugging.

**NOTE**: this field is **REQUIRED** by all open source libhal libraries in
order to reduce their library's binary size in debug mode.

## Build functions

This package automatically injects libhal cmake utility functions:

### `libhal_test_and_make_library()`

Builds and tests a library. This function must be used in place of using
`libhal_unit_test` and `libhal_make_library` separately.

```cmake
libhal_test_and_make_library([LIBRARY_NAME <library_name>]
                             [SOURCES <files...>]
                             [INCLUDES <directories...>]
                             [PACKAGES <packages...>]
                             [LINK_LIBRARIES <link_libraries...>])
```

- `LIBRARY_NAME` name of the library (e.g. libhal-lpc40, libhal-util)
- `SOURCES` is a list of source files to include in the package build and unit
  tests.
- `TEST_SOURCES` is a list of source unit test source files used to build the
  unit test executable. This will not be included in the library package build.
- `INCLUDES` is a list of include directories for the build process. Note that
  the `include` and `src` directories are already included for you.
- `PACKAGES` list of packages to automatically find and make available for the
  package build.
- `LINK_LIBRARIES` list of the libraries to link into the library.
- `TEST_PACKAGES` list of test packages to automatically find and make available
  for the package build.
- `TEST_LINK_LIBRARIES` list of the libraries to link into the unit tests. These
  libraries will be added to the library target.

This function requires that Boost.UT unit testing framework to be available
as a package. In conan, add this to your `build_requirements()` method:

```python
def build_requirements(self):
    self.tool_requires("libhal-cmake-util/2.1.0")
    self.test_requires("boost-ext-ut/1.1.9")
```

### `libhal_unit_test()`

Builds and executes unit tests for libhal. Use this for header only libraries
that do not generate library files, but do have build-able unit tests. If
non-test source files are present, then the libhal package MUST use the
`libhal_test_and_make_library()` function.

```cmake
libhal_unit_test([SOURCES <files...>]
                 [INCLUDES <directories...>]
                 [PACKAGES <packages...>]
                 [LINK_LIBRARIES <link_libraries...>])
```

- `SOURCES` is a list of source files to include in the build for the unit
  test. The set of source files MUST include the project source files as
  well as the unit test source files.
- `INCLUDES` is a list of include directires to be added to the executable.
  Note that the `include`, `src`, and `test` directories are already
  included for you.
- `PACKAGES` list of packages to automatically find and make available for the
  unit test build. Packages needed by the package binary will also be needed
  for unit tests, so supply them here.
- `LINK_LIBRARIES` list of the libraries to link into the unit test library.
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
3. Enables Address Sanitizer if the compiler supports it and issues warning if
   it does not.
4. Applies clang-tidy checks to all files if the clang-tidy program is
   available on the system (issues warning if it does not)
5. Add flags to enable code coverage for the unit test executable

This function requires that Boost.UT unit testing framework to be available
as a package. In conan, add this to your `build_requirements()` method:

```python
  def build_requirements(self):
      self.tool_requires("libhal-cmake-util/1.1.0")
      self.test_requires("boost-ext-ut/1.1.9")
```

### `libhal_make_library()`

Builds libhal libraries. Use this when unit tests are not available or necessary
but a package must be built.

```cmake
libhal_make_library([LIBRARY_NAME <library_name>]
                    [SOURCES <files...>]
                    [INCLUDES <directories...>]
                    [PACKAGES <packages...>]
                    [LINK_LIBRARIES <link_libraries...>])
```

- `LIBRARY_NAME` name of the library (e.g. libhal-lpc40, libhal-util)
- `SOURCES` is a list of source files to include in the package build.
- `INCLUDES` is a list of include directories to be added to the executable.
  Note that the `include` and `src` directories are already included for you.
- `PACKAGES` list of packages to automatically find and make available for the
  package build.
- `LINK_LIBRARIES` list of the libraries to link into the library.
- `USE_CLANG_TIDY` use this option to enable clang tidy checks for libraries.

### `libhal_build_demos()`

Builds a set of demos.

For this function to work, the directory structure must fit the following:

```tree
demos/
├── CMakeLists.txt
├── applications
│   ├── adc.cpp
│   ├── blinker.cpp
│   ├── can.cpp
│   ├── gpio.cpp
│   ├── i2c.cpp
│   ├── interrupt_pin.cpp
│   ├── pwm.cpp
│   ├── spi.cpp
│   ├── ...
│   └── uart.cpp
└── main.cpp
```

Where main contains the startup code and calls a common function that is
implemented across the demos in the `applications`` directory.

```cmake
libhal_build_demos([LIBRARY_NAME <library_name>]
                    [INCLUDES <directories...>]
                    [PACKAGES <packages...>]
                    [LINK_LIBRARIES <link_libraries...>]
                    [LINK_FLAGS <link_flags...>]
                    DISABLE_CLANG_TIDY)
```

- `DEMOS` names of the demos in the `application/` directory. The names must
  corrispond to the names of the `.cpp` files in the directory. For example,
  a demo name of `adc` must have a `adc.cpp` file in the `application/`
  directory.
- `INCLUDES` list of include directories. The list has no default and is
  empty.
- `PACKAGES` list of packages to automatically find and make available for the
  package build.
- `LINK_LIBRARIES` list of the libraries to link into the library.
- `LINK_FLAGS` linker flags for the demos.
- `DISABLE_CLANG_TIDY` option is used to disable clang-tidy checks for host
  builds.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by
Google and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
