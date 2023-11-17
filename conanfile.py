# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from conan import ConanFile
from conan.tools.files import copy
from conan.tools.layout import basic_layout
import os


required_conan_version = ">=2.0.6"


class libhal_cmake_util_conan(ConanFile):
    name = "libhal-cmake-util"
    version = "3.0.1"
    license = "Apache-2.0"
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://libhal.github.io/libhal-armcortex"
    description = ("A collection of CMake scripts for ARM Cortex ")
    topics = ("cmake", "libhal", "embedded", "embedded-systems", "firmware")
    exports_sources = ("cmake/*", "LICENSE")
    no_copy_source = True
    options = {
        "add_build_outputs": [True, False],
        "optimize_debug_build": [True, False]
    }
    default_options = {
        "add_build_outputs": True,
        "optimize_debug_build": True
    }

    def package_id(self):
        self.info.clear()

    def layout(self):
        basic_layout(self)

    def package(self):
        copy(self, "LICENSE", dst=os.path.join(
            self.package_folder, "licenses"),  src=self.source_folder)
        copy(self, "cmake/*.cmake", src=self.source_folder,
             dst=self.package_folder)
        copy(self, "cmake/*.conf", src=self.source_folder,
             dst=self.package_folder)

    def package_info(self):
        # Add toolchain.cmake to user_toolchain configuration info to be used
        # by CMakeToolchain generator
        build_outputs_path = os.path.join(
            self.package_folder, "cmake/build_outputs.cmake")
        optimize_debug_build_path = os.path.join(
            self.package_folder, "cmake/optimize_debug_build.cmake")
        build_path = os.path.join(
            self.package_folder, "cmake/build.cmake")
        colors_path = os.path.join(
            self.package_folder, "cmake/colors.cmake")
        clang_tidy_config_path = os.path.join(
            self.package_folder, "cmake/clang-tidy.conf")

        if self.options.add_build_outputs:
            self.conf_info.append(
                "tools.cmake.cmaketoolchain:user_toolchain",
                build_outputs_path)

        if self.options.optimize_debug_build:
            self.conf_info.append(
                "tools.cmake.cmaketoolchain:user_toolchain",
                optimize_debug_build_path)

        self.conf_info.append(
            "tools.cmake.cmaketoolchain:user_toolchain",
            colors_path)

        self.conf_info.append(
            "tools.cmake.cmaketoolchain:user_toolchain",
            build_path)


        self.output.info(
            f"clang_tidy_config_path: {clang_tidy_config_path}")
        self.output.info(
            f"add_build_outputs: {self.options.add_build_outputs}")
        self.output.info(
            f"optimize_debug_build: {self.options.optimize_debug_build}")
