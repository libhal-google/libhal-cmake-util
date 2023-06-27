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

# Use -Og which is like O1 with some changes to reduce code size and improve
# performance but still provide a great debugability. This should be used
# instead of the "Debug" build type.

set(CMAKE_C_FLAGS_DEBUG "-Og -g"
  CACHE INTERNAL "C Compiler options for release with debug info build type")
set(CMAKE_CXX_FLAGS_DEBUG "-Og -g"
  CACHE INTERNAL "C++ Compiler options for release with debug info build type")
