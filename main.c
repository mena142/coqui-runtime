#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pico/stdlib.h"
#include "mquickjs.h"
#include "hardware.h"

// 32KB is plenty for a "Hello World"
#define JS_POOL_SIZE (32 * 1024)

// Force 16-byte alignment. This will ensure the address ends in '0' (e.g., ...1370 or ...1380)
static uint8_t __attribute__((aligned(16))) js_pool_final[JS_POOL_SIZE];

int main(void)
{
    stdio_init_all();
    for(int i = 3; i > 0; i--) { printf("..%d\n", i); sleep_ms(1000); }

    printf("\n=== RP2040 QuickJS Strict Alignment Test ===\n");

    // Clear memory
    memset(js_pool_final, 0, JS_POOL_SIZE);
    
    printf("Pool Address: %p\n", (void*)js_pool_final);
    
    if (((uintptr_t)js_pool_final % 16) != 0) {
        printf("[WARNING] Address is NOT 16-byte aligned!\n");
    }

    printf("[Step 1] Calling JS_NewContext...\n");
    
    // We are passing NULL. If this fails, the issue is internal to the 
    // library's memory manager or the way it was compiled for Cortex-M0+.
    JSContext *ctx = JS_NewContext(js_pool_final, JS_POOL_SIZE, NULL);

    if (ctx == NULL) {
        printf("[FAIL] JS_NewContext returned NULL.\n");
    } else {
        printf("[SUCCESS] Context Created!\n");
        
        // Only run hardware_init if context is valid
        hardware_init(ctx);
        
        const char *script = "var a = 1; a;";
        JSValue res = JS_Eval(ctx, script, strlen(script), "test", 0);
        printf("Eval finished.\n");
        
        JS_FreeContext(ctx);
    }

    printf("=== End ===\n");
    while (true) { tight_loop_contents(); }
}