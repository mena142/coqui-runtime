#include "hardware.h"
#include "pico/stdlib.h"
#include "hardware/gpio.h"

static JSValue js_digital_write(JSContext *ctx, JSValue this_val, int argc, JSValue *argv)
{
    int pin, value;
    if (argc < 2 || JS_ToInt32(ctx, &pin, argv[0]) || JS_ToInt32(ctx, &value, argv[1]))
        return JS_EXCEPTION;
    gpio_put(pin, value);
    return JS_UNDEFINED;
}

static JSValue js_pin_mode(JSContext *ctx, JSValue this_val, int argc, JSValue *argv)
{
    int pin, mode;
    if (argc < 2 || JS_ToInt32(ctx, &pin, argv[0]) || JS_ToInt32(ctx, &mode, argv[1]))
        return JS_EXCEPTION;
    gpio_init(pin);
    gpio_set_dir(pin, mode ? GPIO_OUT : GPIO_IN);
    return JS_UNDEFINED;
}

void hardware_init(JSContext *ctx)
{
    JSValue hardware = JS_NewObject(ctx);

    JS_SetPropertyStr(ctx, hardware, "pinMode", JS_NewCFunctionParams(ctx, (uintptr_t)js_pin_mode, JS_UNDEFINED));
    JS_SetPropertyStr(ctx, hardware, "digitalWrite", JS_NewCFunctionParams(ctx, (uintptr_t)js_digital_write, JS_UNDEFINED));

    JSValue global = JS_GetGlobalObject(ctx);
    JS_SetPropertyStr(ctx, global, "hardware", hardware);
}
