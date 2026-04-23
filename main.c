#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/adc.h"
#include "hardware/clocks.h"

/* --- CONFIGURATION --- */
#define HEARTBEAT_INTERVAL_MS 1000
#define ADC_VREF 3.3f
#define ADC_RANGE (1 << 12)
#define CONVERSION_FACTOR (ADC_VREF / ADC_RANGE)

/* --- SYSTEM METRICS --- */

/**
 * The RP2040 has a 1:3 voltage divider on VSYS connected to ADC 3.
 * This allows us to measure the input voltage (USB or Battery).
 */
float get_vsys_voltage() {
    adc_select_input(3);
    uint16_t raw = adc_read();
    // Multiply by 3 because of the internal voltage divider
    return raw * CONVERSION_FACTOR * 3.0f;
}

/**
 * Standard calculation for the RP2040 internal temperature sensor.
 */
float get_core_temp() {
    adc_select_input(4);
    uint16_t raw = adc_read();
    float voltage = raw * CONVERSION_FACTOR;
    // Formula from RP2040 Datasheet
    return 27.0f - (voltage - 0.706f) / 0.001721f;
}

/**
 * Estimates free RAM by calculating the space between the 
 * end of static data and the bottom of the stack.
 */
uint32_t get_free_ram() {
    extern char __StackLimit;
    extern char __bss_end__;
    return (uint32_t)(&__StackLimit - &__bss_end__);
}

/* --- MAIN EXECUTION --- */

int main() {
    // 1. Boost the internal voltage to support higher speeds
    // For 200MHz-250MHz, VREG_VOLTAGE_1_15 or 1_20 is usually needed.
    vreg_set_voltage(VREG_VOLTAGE_1_15);
    sleep_ms(10);

    // 2. Set the frequency in kHz (200,000 kHz = 200 MHz)
    // This function returns 'true' if the frequency is valid/achievable
    if (set_sys_clock_khz(180000, true)) {
        // Success!
    }
    // Initialize all standard I/O (USB Serial)
    stdio_init_all();

    // Initialize ADC hardware
    adc_init();
    adc_set_temp_sensor_enabled(true);
    
    // GPIO 29 is the VSYS monitoring pin on Standard Pico
    adc_gpio_init(29); 

    // Wait a moment for serial to stabilize
    sleep_ms(2000);

    while (true) {
        // Collect Data
        uint64_t uptime_s = to_ms_since_boot(get_absolute_time()) / 1000;
        uint32_t cpu_speed = clock_get_hz(clk_sys) / 1000000;
        float vsys = get_vsys_voltage();
        float temp = get_core_temp();
        uint32_t ram = get_free_ram();

        // Output Heartbeat JSON
        // Using a single printf ensures the JSON block arrives as one line
        printf("{\"status\":\"LIVE\",\"up\":%llu,\"mhz\":%u,\"vsys\":%.2f,\"temp\":%.1f,\"ram\":%u}\n",
               uptime_s, 
               cpu_speed, 
               vsys, 
               temp, 
               ram);

        // Wait for next heartbeat
        sleep_ms(HEARTBEAT_INTERVAL_MS);
    }

    return 0;
}