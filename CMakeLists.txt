cmake_minimum_required(VERSION 3.13)

# Pico SDK is inside the project folder
set(PICO_SDK_PATH ${CMAKE_CURRENT_SOURCE_DIR}/pico-sdk)

include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(coqui_mjs C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

# Optional: ccache
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# Minimal MicroQuickJS sources + our files
set(MQUICKJS_SOURCES
    mquickjs/mquickjs.c
    mquickjs/cutils.c
    mquickjs/libm.c
)

add_executable(coqui_mjs
    main.c
    hardware.c
    stubs.c
    ${MQUICKJS_SOURCES}
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
    -O0
    -mthumb
    -mcpu=cortex-m0plus
    -fno-inline
    -fno-optimize-sibling-calls
    -mno-unaligned-access
)

target_link_libraries(coqui_mjs
    pico_stdlib
    hardware_gpio
    hardware_adc
    hardware_pwm
    pico_float
    pico_double
    m
)

pico_enable_stdio_usb(coqui_mjs 1)
pico_enable_stdio_uart(coqui_mjs 0)

pico_add_extra_outputs(coqui_mjs)