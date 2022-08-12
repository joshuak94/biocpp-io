# -----------------------------------------------------------------------------------------------------
# Copyright (c) 2006-2021, Knut Reinert & Freie Universität Berlin
# Copyright (c) 2016-2021, Knut Reinert & MPI für molekulare Genetik
# This file may be used, modified and/or redistributed under the terms of the 3-clause BSD-License
# shipped with this file and also available at: https://github.com/seqan/bio/blob/master/LICENSE.md
# -----------------------------------------------------------------------------------------------------
#
# This CMake module will try to find The BioC++ I/O library and its dependencies.  You can use
# it the same way you would use any other CMake module.
#
#   find_package (biocpp_io [REQUIRED] ...)
#
# Since this makes a difference for CMAKE, pay attention to the case.
#
# The BioC++ I/O library has the following platform requirements:
#
#   C++20
#   pthread
#
# The BioC++ I/O library requires the following libraries:
#
#   SeqAn3    -- the succinct data structure library
#
# The BioC++ I/O library has the following optional dependencies:
#
#   ZLIB      -- zlib compression library
#   BZip2     -- libbz2 compression library
#
# If you don't wish for these to be detected (and used), you may define BIOCPP_IO_NO_ZLIB,
# BIOCPP_IO_NO_BZIP2 respectively.
#
# If you wish to require the presence of ZLIB or BZip2, just check for the module before
# finding The BioC++ I/O library, e.g. "find_package (ZLIB REQUIRED)".
#
# Once the search has been performed, the following variables will be set.
#
#   BIOCPP_IO_FOUND            -- Indicate whether The BioC++ I/O library was found and requirements met.
#
#   BIOCPP_IO_VERSION          -- The version as string, e.g. "3.0.0"
#   BIOCPP_IO_VERSION_MAJOR    -- e.g. 3
#   BIOCPP_IO_VERSION_MINOR    -- e.g. 0
#   BIOCPP_IO_VERSION_PATCH    -- e.g. 0
#
#   BIOCPP_IO_INCLUDE_DIRS     -- to be passed to include_directories ()
#   BIOCPP_IO_LIBRARIES        -- to be passed to target_link_libraries ()
#   BIOCPP_IO_DEFINITIONS      -- to be passed to add_definitions ()
#   BIOCPP_IO_CXX_FLAGS        -- to be added to CMAKE_CXX_FLAGS
#
# Additionally, the following [IMPORTED][IMPORTED] targets are defined:
#
#   bio::bio          -- interface target where
#                                  target_link_libraries(target bio::bio)
#                              automatically sets
#                                  target_include_directories(target $BIOCPP_IO_INCLUDE_DIRS),
#                                  target_link_libraries(target $BIOCPP_IO_LIBRARIES),
#                                  target_compile_definitions(target $BIOCPP_IO_DEFINITIONS) and
#                                  target_compile_options(target $BIOCPP_IO_CXX_FLAGS)
#                              for a target.
#
#   [IMPORTED]: https://cmake.org/cmake/help/v3.10/prop_tgt/IMPORTED.html#prop_tgt:IMPORTED
#
# ============================================================================

cmake_minimum_required (VERSION 3.4...3.12)

# ----------------------------------------------------------------------------
# Set initial variables
# ----------------------------------------------------------------------------

# make output globally quiet if required by find_package, this effects cmake functions like `check_*`
set(CMAKE_REQUIRED_QUIET_SAVE ${CMAKE_REQUIRED_QUIET})
set(CMAKE_REQUIRED_QUIET ${${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY})

# ----------------------------------------------------------------------------
# Greeter
# ----------------------------------------------------------------------------

string (ASCII 27 Esc)
set (ColourBold "${Esc}[1m")
set (ColourReset "${Esc}[m")

if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
    message (STATUS "${ColourBold}BioC++ I/O library:${ColourReset}")
endif ()

# ----------------------------------------------------------------------------
# Includes
# ----------------------------------------------------------------------------

include (CheckIncludeFileCXX)
include (CheckCXXSourceCompiles)
include (FindPackageHandleStandardArgs)

# ----------------------------------------------------------------------------
# Pretty printing and error handling
# ----------------------------------------------------------------------------

macro (bio_config_print text)
    if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
        message (STATUS "  ${text}")
    endif ()
endmacro ()

macro (bio_config_error text)
    if (${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED)
        message (FATAL_ERROR ${text})
    else ()
        if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
            message (WARNING ${text})
        endif ()
        return ()
    endif ()
endmacro ()

# ----------------------------------------------------------------------------
# Find The BioC++ I/O library include path
# ----------------------------------------------------------------------------

# Note that bio-config.cmake can be standalone and thus BIOCPP_IO_CLONE_DIR might be empty.
# * `BIOCPP_IO_CLONE_DIR` was already found in bio-config-version.cmake
# * `BIOCPP_IO_INCLUDE_DIR` was already found in bio-config-version.cmake
find_path (BIOCPP_IO_SUBMODULES_DIR NAMES submodules/seqan3 HINTS "${BIOCPP_IO_CLONE_DIR}" "${BIOCPP_IO_INCLUDE_DIR}/bio")

if (BIOCPP_IO_INCLUDE_DIR)
    bio_config_print ("The BioC++ I/O library include dir found:   ${BIOCPP_IO_INCLUDE_DIR}")
else ()
    bio_config_error ("The BioC++ I/O library include directory could not be found (BIOCPP_IO_INCLUDE_DIR: '${BIOCPP_IO_INCLUDE_DIR}')")
endif ()

# ----------------------------------------------------------------------------
# Detect if we are a clone of repository and if yes auto-add submodules
# ----------------------------------------------------------------------------

if (BIOCPP_IO_CLONE_DIR)
    bio_config_print ("Detected as running from a repository checkout…")
endif ()

if (BIOCPP_IO_SUBMODULES_DIR)
    file (GLOB submodules ${BIOCPP_IO_SUBMODULES_DIR}/submodules/*/include)
    foreach (submodule ${submodules})
        if (IS_DIRECTORY ${submodule})
            bio_config_print ("  …adding submodule include:  ${submodule}")
            set (BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS ${submodule} ${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS})
        endif ()
    endforeach ()
endif ()

# ----------------------------------------------------------------------------
# Options for CheckCXXSourceCompiles
# ----------------------------------------------------------------------------

# deactivate messages in check_*
set (CMAKE_REQUIRED_QUIET       1)
# use global variables in Check* calls
set (CMAKE_REQUIRED_INCLUDES    ${CMAKE_INCLUDE_PATH} ${BIOCPP_IO_INCLUDE_DIR} ${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS})
set (CMAKE_REQUIRED_FLAGS       ${CMAKE_CXX_FLAGS})

# ----------------------------------------------------------------------------
# Force-deactivate optional dependencies
# ----------------------------------------------------------------------------

# These two are "opt-in", because detected by CMake
# If you want to force-require these, just do find_package (zlib REQUIRED) before find_package(biocpp_io)
option (BIOCPP_IO_NO_ZLIB  "Don't use ZLIB, even if present." OFF)
option (BIOCPP_IO_NO_BZIP2 "Don't use BZip2, even if present." OFF)

# ----------------------------------------------------------------------------
# Require C++20
# ----------------------------------------------------------------------------

set (CMAKE_REQUIRED_FLAGS_SAVE ${CMAKE_REQUIRED_FLAGS})

set (CXXSTD_TEST_SOURCE
    "#if !defined (__cplusplus) || (__cplusplus < 201709L)
    #error NOCXX20
    #endif
    int main() {}")

check_cxx_source_compiles ("${CXXSTD_TEST_SOURCE}" CXX20_BUILTIN)

if (CXX20_BUILTIN)
    bio_config_print ("C++ Standard-20 support:    builtin")
else ()
    set (CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS_SAVE} -std=c++20")

    check_cxx_source_compiles ("${CXXSTD_TEST_SOURCE}" CXX20_FLAG)

    if (CXX20_FLAG)
        bio_config_print ("C++ Standard-20 support:    via -std=c++20")
    else ()
        bio_config_error ("The BioC++ I/O library requires C++20, but your compiler does not support it.")
    endif ()

    set (BIOCPP_IO_CXX_FLAGS "${BIOCPP_IO_CXX_FLAGS} -std=c++20")
endif ()

# ----------------------------------------------------------------------------
# Require C++ Concepts
# ----------------------------------------------------------------------------

#set (CMAKE_REQUIRED_FLAGS_SAVE ${CMAKE_REQUIRED_FLAGS})

#set (CXXSTD_TEST_SOURCE
    #"static_assert (__cpp_concepts >= 201507);
    #int main() {}")

#set (CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS_SAVE} ${BIOCPP_IO_CXX_FLAGS}")
#check_cxx_source_compiles ("${CXXSTD_TEST_SOURCE}" BIOCPP_IO_CONCEPTS)

#if (BIOCPP_IO_CONCEPTS_FLAG)
    #bio_config_print ("C++ Concepts support:       builtin")
#else ()
    #bio_config_error ("The BioC++ I/O library requires C++ Concepts, but your compiler does not support them.")
#endif ()

# ----------------------------------------------------------------------------
# thread support (pthread, windows threads)
# ----------------------------------------------------------------------------

set (THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package (Threads QUIET)

if (Threads_FOUND)
    set (BIOCPP_IO_LIBRARIES ${BIOCPP_IO_LIBRARIES} Threads::Threads)
    if ("${CMAKE_THREAD_LIBS_INIT}" STREQUAL "")
        bio_config_print ("Thread support:             builtin.")
    else ()
        bio_config_print ("Thread support:             via ${CMAKE_THREAD_LIBS_INIT}")
    endif ()
else ()
    bio_config_print ("Thread support:             not found.")
endif ()

# ----------------------------------------------------------------------------
# Require SeqAn3
# ----------------------------------------------------------------------------

find_package (SeqAn3 REQUIRED QUIET
              HINTS ${CMAKE_CURRENT_LIST_DIR}/../submodules/seqan3/build_system)

if (SEQAN3_FOUND)
    bio_config_print ("Required dependency:        SeqAn3 found.")
else ()
    bio_config_print ("The SeqAn3 library is required, but wasn't found. Get it from https://github.com/seqan/seqan3")
endif ()

# ----------------------------------------------------------------------------
# ZLIB dependency
# ----------------------------------------------------------------------------

if (NOT BIOCPP_IO_NO_ZLIB)
    find_package (ZLIB QUIET)
endif ()

if (ZLIB_FOUND)
    set (BIOCPP_IO_LIBRARIES         ${BIOCPP_IO_LIBRARIES}         ${ZLIB_LIBRARIES})
    set (BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS      ${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS}      ${ZLIB_INCLUDE_DIRS})
    set (BIOCPP_IO_DEFINITIONS       ${BIOCPP_IO_DEFINITIONS}       "-DBIOCPP_IO_HAS_ZLIB=1")
    bio_config_print ("Optional dependency:        ZLIB-${ZLIB_VERSION_STRING} found.")
else ()
    bio_config_print ("Optional dependency:        ZLIB not found.")
endif ()

# ----------------------------------------------------------------------------
# BZip2 dependency
# ----------------------------------------------------------------------------

if (NOT BIOCPP_IO_NO_BZIP2)
    find_package (BZip2 QUIET)
endif ()

if (NOT ZLIB_FOUND AND BZIP2_FOUND)
    # NOTE (marehr): iostream_bzip2 uses the type `uInt`, which is defined by
    # `zlib`. Therefore, `bzip2` will cause a ton of errors without `zlib`.
    message (AUTHOR_WARNING "Disabling BZip2 [which was successfully found], "
                            "because ZLIB was not found. BZip2 depends on ZLIB.")
    unset (BZIP2_FOUND)
endif ()

if (BZIP2_FOUND)
    set (BIOCPP_IO_LIBRARIES         ${BIOCPP_IO_LIBRARIES}         ${BZIP2_LIBRARIES})
    set (BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS      ${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS}      ${BZIP2_INCLUDE_DIRS})
    set (BIOCPP_IO_DEFINITIONS       ${BIOCPP_IO_DEFINITIONS}       "-DBIOCPP_IO_HAS_BZIP2=1")
    bio_config_print ("Optional dependency:        BZip2-${BZIP2_VERSION_STRING} found.")
else ()
    bio_config_print ("Optional dependency:        BZip2 not found.")
endif ()

# ----------------------------------------------------------------------------
# System dependencies
# ----------------------------------------------------------------------------

# librt
if ((${CMAKE_SYSTEM_NAME} STREQUAL "Linux") OR
    (${CMAKE_SYSTEM_NAME} STREQUAL "kFreeBSD") OR
    (${CMAKE_SYSTEM_NAME} STREQUAL "GNU"))
    set (BIOCPP_IO_LIBRARIES ${BIOCPP_IO_LIBRARIES} rt)
endif ()

# libexecinfo -- implicit
check_include_file_cxx (execinfo.h _BIOCPP_IO_HAVE_EXECINFO)
mark_as_advanced (_BIOCPP_IO_HAVE_EXECINFO)
if (_BIOCPP_IO_HAVE_EXECINFO)
    if ((${CMAKE_SYSTEM_NAME} STREQUAL "FreeBSD") OR (${CMAKE_SYSTEM_NAME} STREQUAL "OpenBSD"))
        bio_config_print ("Optional dependency:        libexecinfo found.")
        set (BIOCPP_IO_LIBRARIES ${BIOCPP_IO_LIBRARIES} execinfo elf)
    endif ()
else ()
    bio_config_print ("Optional dependency:        libexecinfo not found.")
endif ()

# ----------------------------------------------------------------------------
# Perform compilability test of platform.hpp (tests some requirements)
# ----------------------------------------------------------------------------

set (CXXSTD_TEST_SOURCE
     "#include <bio/io/platform.hpp>
     int main() {}")

# using try_compile instead of check_cxx_source_compiles to capture output in case of failure
file (WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.cxx" "${CXXSTD_TEST_SOURCE}\n")

try_compile (BIOCPP_IO_PLATFORM_TEST
             ${CMAKE_BINARY_DIR}
             ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.cxx
             CMAKE_FLAGS         "-DCOMPILE_DEFINITIONS:STRING=${CMAKE_CXX_FLAGS} ${BIOCPP_IO_CXX_FLAGS}"
                                 "-DINCLUDE_DIRECTORIES:STRING=${CMAKE_INCLUDE_PATH};${BIOCPP_IO_INCLUDE_DIR};${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS}"
             COMPILE_DEFINITIONS ${BIOCPP_IO_DEFINITIONS}
             LINK_LIBRARIES      ${BIOCPP_IO_LIBRARIES}
             OUTPUT_VARIABLE     BIOCPP_IO_PLATFORM_TEST_OUTPUT)

if (BIOCPP_IO_PLATFORM_TEST)
    bio_config_print ("The BioC++ I/O library platform.hpp build:  passed.")
else ()
    bio_config_error ("The BioC++ I/O library platform.hpp build:  failed!\n\
                        ${BIOCPP_IO_PLATFORM_TEST_OUTPUT}")
endif ()

# ----------------------------------------------------------------------------
# Finish find_package call
# ----------------------------------------------------------------------------

find_package_handle_standard_args (${CMAKE_FIND_PACKAGE_NAME} REQUIRED_VARS BIOCPP_IO_INCLUDE_DIR)

# Set BIOCPP_IO_* variables with the content of ${CMAKE_FIND_PACKAGE_NAME}_(FOUND|...|VERSION)
# This needs to be done, because `find_package(The BioC++ I/O library)` might be called in any case-sensitive way and we want to
# guarantee that BIOCPP_IO_* are always set.
foreach (package_var FOUND DIR ROOT CONFIG VERSION VERSION_MAJOR VERSION_MINOR VERSION_PATCH VERSION_TWEAK VERSION_COUNT)
    set (BIOCPP_IO_${package_var} "${${CMAKE_FIND_PACKAGE_NAME}_${package_var}}")
endforeach ()

# propagate BIOCPP_IO_INCLUDE_DIR into BIOCPP_IO_INCLUDE_DIRS
set (BIOCPP_IO_INCLUDE_DIRS ${BIOCPP_IO_INCLUDE_DIR} ${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS})

# ----------------------------------------------------------------------------
# Export targets
# ----------------------------------------------------------------------------

if (BIOCPP_IO_FOUND AND NOT TARGET bio::bio)
    separate_arguments (BIOCPP_IO_CXX_FLAGS_LIST UNIX_COMMAND "${BIOCPP_IO_CXX_FLAGS}")

    add_library (bio_bio INTERFACE)
    target_compile_definitions (bio_bio INTERFACE ${BIOCPP_IO_DEFINITIONS})
    target_compile_options (bio_bio INTERFACE ${BIOCPP_IO_CXX_FLAGS_LIST})
    target_link_libraries (bio_bio INTERFACE "${BIOCPP_IO_LIBRARIES}")
    # include bio/include/ as -I, because bio should never produce warnings.
    target_include_directories (bio_bio INTERFACE "${BIOCPP_IO_INCLUDE_DIR}")
    # include everything except bio/include/ as -isystem, i.e.
    # a system header which suppresses warnings of external libraries.
    target_include_directories (bio_bio SYSTEM INTERFACE "${BIOCPP_IO_DEPENDENCY_INCLUDE_DIRS}")
    add_library (bio::bio ALIAS bio_bio)
endif ()

set (CMAKE_REQUIRED_QUIET ${CMAKE_REQUIRED_QUIET_SAVE})

if (BIOCPP_IO_FIND_DEBUG)
  message ("Result for ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt")
  message ("")
  message ("  CMAKE_BUILD_TYPE            ${CMAKE_BUILD_TYPE}")
  message ("  CMAKE_SOURCE_DIR            ${CMAKE_SOURCE_DIR}")
  message ("  CMAKE_INCLUDE_PATH          ${CMAKE_INCLUDE_PATH}")
  message ("  BIOCPP_IO_INCLUDE_DIR          ${BIOCPP_IO_INCLUDE_DIR}")
  message ("")
  message ("  ${CMAKE_FIND_PACKAGE_NAME}_FOUND                ${${CMAKE_FIND_PACKAGE_NAME}_FOUND}")
  message ("  BIOCPP_IO_HAS_ZLIB             ${ZLIB_FOUND}")
  message ("  BIOCPP_IO_HAS_BZIP2            ${BZIP2_FOUND}")
  message ("")
  message ("  BIOCPP_IO_INCLUDE_DIRS         ${BIOCPP_IO_INCLUDE_DIRS}")
  message ("  BIOCPP_IO_LIBRARIES            ${BIOCPP_IO_LIBRARIES}")
  message ("  BIOCPP_IO_DEFINITIONS          ${BIOCPP_IO_DEFINITIONS}")
  message ("  BIOCPP_IO_CXX_FLAGS            ${BIOCPP_IO_CXX_FLAGS}")
  message ("")
  message ("  BIOCPP_IO_VERSION              ${BIOCPP_IO_VERSION}")
  message ("  BIOCPP_IO_VERSION_MAJOR        ${BIOCPP_IO_VERSION_MAJOR}")
  message ("  BIOCPP_IO_VERSION_MINOR        ${BIOCPP_IO_VERSION_MINOR}")
  message ("  BIOCPP_IO_VERSION_PATCH        ${BIOCPP_IO_VERSION_PATCH}")
endif ()
