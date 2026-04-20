cmake_minimum_required(VERSION 3.13)

set(PICO_SDK_PATH ${CMAKE_CURRENT_SOURCE_DIR}/pico-sdk)

include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(coqui_mjs C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

# Suppress picotool warning
set(PICOTOOL_FETCH_FROM_GIT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../picotool-cache)

# Safe minimal set of files that exist in mquickjs
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
    ${CMAKE_CURRENT_SOURCE_DIR}/mquickjs
)

target_link_libraries(coqui_mjs
    pico_stdlib
    pico_standard_link
    hardware_gpio
    hardware_adc
    hardware_pwm
)

pico_enable_stdio_usb(coqui_mjs 1)
pico_enable_stdio_uart(coqui_mjs 0)

pico_add_extra_outputs(coqui_mjs)
