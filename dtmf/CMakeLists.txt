cmake_minimum_required(VERSION 3.10)

project(DTMF C)

find_path(SNDFILE_INCLUDE_DIR sndfile.h REQUIRED)
find_library(SNDFILE_LIBRARY sndfile REQUIRED)

if(NOT SNDFILE_INCLUDE_DIR OR NOT SNDFILE_LIBRARY)
    message(FATAL_ERROR "libsndfile non trouvé. Assurez-vous que libsndfile1 et libsndfile1-dev sont installés.")
endif()

add_executable(dtmf_encdec 
                src/main.c
                src/buffer.c 
                src/dtmf.c 
                src/file.c 
                src/wave.c 
                src/utils.c 
                src/fft.c 
                src/dtmf_encoder.c 
                src/dtmf_decoder.c
)

target_include_directories(dtmf_encdec PRIVATE ${SNDFILE_INCLUDE_DIR})
target_link_libraries(dtmf_encdec PRIVATE ${SNDFILE_LIBRARY} -lm)
target_compile_options(dtmf_encdec PRIVATE -Wall -Wextra -pedantic -g)
