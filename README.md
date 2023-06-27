# libhal-cmake-util

Generic cmake utilities such as macros, functions, and toolchains for all
categories of libhal libraries.

## Integration into Conan

Add the following line to the `requirements()` function of your library or
applications `conanfile.py`:

```python
def requirements(self):
  self.tool_requires("libhal-cmake-util/1.0.0")
```

## Package Options

This package comes with some options to customize its behavior. You can set
these options in the `tool_requires` function.

```python
def requirements(self):
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
provided to your CMake build project via the Conan CMake toolchain file.

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

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by
Google and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
