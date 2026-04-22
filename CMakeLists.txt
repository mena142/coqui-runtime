cmake_minimum_required(VERSION 3.13)
include(pico_sdk_import.cmake)
project(coqui_mjs C CXX ASM)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

pico_sdk_init()

add_executable(coqui_mjs
    main.c
    hardware.c
    stubs.c
    mquickjs/mquickjs.c
    mquickjs/cutils.c
)

target_include_directories(coqui_mjs PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/mquickjs
)

target_compile_definitions(coqui_mjs PRIVATE 
    CONFIG_TINY_JS=1
    CONFIG_NO_REGEXP=1
    CONFIG_NO_BIGINT=1
)

target_compile_options(coqui_mjs PRIVATE
    -O0 -mthumb -mcpu=cortex-m0plus
    -fno-inline -fno-optimize-sibling-calls -mno-unaligned-access
)

target_link_libraries(coqui_mjs pico_stdlib hardware_gpio hardware_adc pico_float pico_double m)
pico_enable_stdio_usb(coqui_mjs 1)
pico_add_extra_outputs(coqui_mjs)