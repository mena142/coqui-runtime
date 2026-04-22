#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/adc.h"
#include "pico/binary_info.h"
#include "mquickjs.h" // mQuickJS wrapper for memory management

// --- MEMORY CONFIGURATION ---
// QuickJS requires aligned memory for its heap.
#define JS_POOL_SIZE (64 * 1024)
static uint64_t js_pool_aligned[JS_POOL_SIZE / 8] __attribute__((aligned(8)));

// --- HARDWARE CONFIGURATION ---
#ifndef PICO_DEFAULT_LED_PIN
#define PICO_DEFAULT_LED_PIN 25 // Standard Pico LED
#endif

// Helper to read internal temperature sensor
float read_onboard_temp() {
    adc_select_input(4);
    uint16_t raw = adc_read();
    const float conversion_factor = 3.3f / (1 << 12);
    float voltage = raw * conversion_factor;
    return 27.0f - (voltage - 0.706f) / 0.001721f;
}

int main() {
    stdio_init_all();
    adc_init();
    adc_set_temp_sensor_enabled(true);

    // Give serial/USB time to attach
    sleep_ms(2000);
    printf("\n\n--- 🐸 coquiOS INIT ---\n");
    printf("Author: Cohoba Digital\n");

    // --- QUICKJS INITIALIZATION ---
    // Troubleshooting Note: JS_NewContext is where HardFaults usually occur 
    // if memory is unaligned or pool size is insufficient.
    printf("SYSTEM: Initializing JS Context...\n");
    JSContext *ctx = JS_NewContext((uint8_t *)js_pool_aligned, JS_POOL_SIZE, NULL, 4096);
    
    if (ctx) {
        printf("STATUS: JS_ENGINE_OK\n");
        // Test evaluation
        JS_Eval(ctx, "const a = 1; const b = 2; a + b;", 31, "<input>", 0);
    } else {
        printf("STATUS: JS_ENGINE_FAILED\n");
    }

    // --- HARDWARE HEARTBEAT ---
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);

    while (true) {
        float current_temp = read_onboard_temp();
        
        // Output format parsed by Dashboard/TUI
        printf("TEMP:%.1f\n", current_temp);
        
        gpio_put(PICO_DEFAULT_LED_PIN, 1);
        sleep_ms(100);
        gpio_put(PICO_DEFAULT_LED_PIN, 0);
        sleep_ms(900);
    }

    return 0;
}