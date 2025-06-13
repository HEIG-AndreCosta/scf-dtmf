cmake_minimum_required(VERSION 3.10)

project(DTMF C)

include(FetchContent)

set(ENABLE_EXTERNAL_LIBS
    OFF
    CACHE BOOL "Disable external libs")
set(BUILD_PROGRAMS
    OFF
    CACHE BOOL "Don't build libsndfile programs")
set(BUILD_EXAMPLES
    OFF
    CACHE BOOL "Don't build libsndfile examples")
set(BUILD_TESTING
    OFF
    CACHE BOOL "Don't build libsndfile tests")

FetchContent_Declare(
  libsndfile
  GIT_REPOSITORY https://github.com/libsndfile/libsndfile.git
  GIT_TAG 1.2.2
  GIT_SHALLOW TRUE)

FetchContent_MakeAvailable(libsndfile)

add_executable(
  dtmf_encdec
  src/main.c
  src/buffer.c
  src/dtmf.c
  src/file.c
  src/wave.c
  src/utils.c
  src/fft.c
  src/dtmf_encoder.c
  src/dtmf_decoder.c
  src/fpga.c)

target_include_directories(dtmf_encdec PRIVATE ${libsndfile_SOURCE_DIR}
                                               ../driver/)
target_link_libraries(dtmf_encdec PRIVATE sndfile m)
target_compile_options(dtmf_encdec PRIVATE -Wall -Wextra -pedantic -g)
add_dependencies(dtmf_encdec sndfile)
