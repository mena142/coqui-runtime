#include <stdio.h>
#include <string.h>
#include "pico/stdlib.h"
#include "mquickjs.h"

// Guaranteed 8-byte alignment by the compiler
#define JS_POOL_SIZE (12 * 1024)
static uint64_t js_pool_aligned[JS_POOL_SIZE / 8]; 

int main(void) {
    stdio_init_all();
    gpio_init(25);
    gpio_set_dir(25, GPIO_OUT);

    // USB Wait
    for(int i=0; i<5; i++) {
        gpio_put(25, 1); sleep_ms(100);
        gpio_put(25, 0); sleep_ms(100);
    }

    printf("=== RP2040 QuickJS: Survivalist Build ===\n");
    
    uint8_t *pool_ptr = (uint8_t *)js_pool_aligned;
    printf("Pool aligned at: %p\n", (void*)pool_ptr);

    // The moment of truth
    JSContext *ctx = JS_NewContext(pool_ptr, JS_POOL_SIZE, NULL);

    if (ctx) {
        printf("BOOT SUCCESS!\n");
        JSValue res = JS_Eval(ctx, "1+1", 3, "m", 0);
        printf("Result: %d\n", JS_VALUE_GET_INT(res));
    } else {
        printf("BOOT FAILED: Engine rejected memory.\n");
    }

    while (1) {
        gpio_put(25, 1); sleep_ms(500);
        gpio_put(25, 0); sleep_ms(500);
    }
}