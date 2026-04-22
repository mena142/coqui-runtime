#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware.h"
#include "hardware/adc.h"

// Define LED pin if SDK fails to find it
#ifndef PICO_DEFAULT_LED_PIN
#define PICO_DEFAULT_LED_PIN 25 
#endif

int main() {
    stdio_init_all();
    adc_init();
    adc_set_temp_sensor_enabled(true);
    
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);

    while (true) {
        adc_select_input(4);
        uint16_t raw = adc_read();
        float temp = 27.0f - ((raw * 3.3f / (1 << 12)) - 0.706f) / 0.001721f;
        
        printf("TEMP:%.1f\n", temp);
        gpio_put(PICO_DEFAULT_LED_PIN, 1);
        sleep_ms(500);
        gpio_put(PICO_DEFAULT_LED_PIN, 0);
        sleep_ms(500);
    }
}