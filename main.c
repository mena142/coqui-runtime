#include <stdio.h>
#include <string.h>
#include "pico/stdlib.h"
#include "mquickjs.h"

#define JS_POOL_SIZE (64 * 1024)
static uint64_t js_pool_aligned[JS_POOL_SIZE / 8] __attribute__((aligned(16)));

int main(void) {
    stdio_init_all();
    for(int i=0; i<40; i++) { sleep_ms(100); }

    uint8_t *pool_ptr = (uint8_t *)js_pool_aligned;
    printf("\n\n--- RP2040 JS Execution ---\n");
    
    JSContext *ctx = JS_NewContext(pool_ptr, JS_POOL_SIZE, NULL, 0);

    if (ctx) {
        printf("✅ Engine Initialized.\n");
        
        // TEST 1: The "Naked" Integer (VM Integrity)
        printf(">> Test 1 (Direct VM): ");
        JSValue n = JS_NewInt32(ctx, 500);
        if (JS_VALUE_GET_INT(n) == 500) {
            printf("PASS\n");
        } else {
            printf("FAIL\n");
        }

        // TEST 2: The "Empty Eval" (Parser Test)
        // Does the parser survive an empty string?
        printf(">> Test 2 (Empty Eval): ");
        JSValue val = JS_Eval(ctx, "", 0, "<input>", 0);
        if (!JS_IsException(val)) {
            printf("PASS (Parser is alive)\n");
        } else {
            printf("FAIL (Parser Exception)\n");
        }

        // TEST 3: Single Digit (Lexer Test)
        printf(">> Test 3 (Lexer '1'): ");
        val = JS_Eval(ctx, "1", 1, "<input>", 0);
        if (!JS_IsException(val)) {
            printf("PASS (Result: %d)\n", (int)JS_VALUE_GET_INT(val));
        } else {
            printf("FAIL (Lexer Exception)\n");
        }
    }

    const uint LED_PIN = PICO_DEFAULT_LED_PIN;
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    while (true) {
        gpio_put(LED_PIN, 1); sleep_ms(100);
        gpio_put(LED_PIN, 0); sleep_ms(400);
    }
}