#include <stdio.h>
#include "hardware.h"
#include "pico/stdlib.h"
#include "hardware/gpio.h"

static JSValue js_digital_write(JSContext *ctx, JSValue this_val, int argc, JSValue *argv)
{
    int pin, value;
    if (argc < 2) return JS_EXCEPTION;
    if (JS_ToInt32(ctx, &pin, argv[0])) return JS_EXCEPTION;
    if (JS_ToInt32(ctx, &value, argv[1])) return JS_EXCEPTION;
    gpio_put((uint)pin, value);
    return JS_UNDEFINED;
}

static JSValue js_pin_mode(JSContext *ctx, JSValue this_val, int argc, JSValue *argv)
{
    int pin, mode;
    if (argc < 2) return JS_EXCEPTION;
    if (JS_ToInt32(ctx, &pin, argv[0])) return JS_EXCEPTION;
    if (JS_ToInt32(ctx, &mode, argv[1])) return JS_EXCEPTION;
    gpio_init((uint)pin);
    gpio_set_dir((uint)pin, mode); 
    return JS_UNDEFINED;
}

void hardware_init(JSContext *ctx)
{
    JSValue global = JS_GetGlobalObject(ctx);

    printf("  [Step A] Binding pinMode...\n");
    JS_SetPropertyStr(ctx, global, "pinMode", 
        JS_NewCFunctionParams(ctx, (uintptr_t)js_pin_mode, JS_UNDEFINED));
    
    printf("  [Step B] Binding digitalWrite...\n");
    JS_SetPropertyStr(ctx, global, "digitalWrite", 
        JS_NewCFunctionParams(ctx, (uintptr_t)js_digital_write, JS_UNDEFINED));
    
    printf("  [Step C] Bindings Done.\n");
}