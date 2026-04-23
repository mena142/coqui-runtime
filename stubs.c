#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "mquickjs.h"

// ================================================================
//  Minimal stubs required for MicroQuickJS on RP2040
// ================================================================

// --- Integer → String conversion (used heavily by js_vprintf) ---
void u32toa(char *buf, uint32_t n) {
    snprintf(buf, 16, "%u", n);
}

void i32toa(char *buf, int32_t n) {
    snprintf(buf, 16, "%d", n);
}

void u64toa(char *buf, uint64_t n, int radix) {
    snprintf(buf, 32, "%llu", (unsigned long long)n);
}

void i64toa(char *buf, int64_t n) {
    snprintf(buf, 32, "%lld", (long long)n);
}

void u64toa_radix(char *buf, uint64_t n, int radix) {
    snprintf(buf, 32, "%llu", (unsigned long long)n);
}

// --- Floating point conversion (used by parser and JS_ToString) ---
double js_atod(const char *s) {
    return strtod(s, NULL);
}

int js_atod1(const char *s, double *v) {
    char *end;
    *v = strtod(s, &end);
    return (end == s) ? -1 : 0;
}

void js_dtoa(char *buf, double d) {
    snprintf(buf, 32, "%g", d);
}

int js_dtoa2(char *buf, double d) {
    return snprintf(buf, 32, "%g", d);
}

int js_dtoa_max_len(double d) {
    return 32;
}

// =================================================================
//  IMPORTANT: Do NOT define these here — they already exist in libm.c
// =================================================================
// We leave js_fmod, js_pow, js_lrint to libm.c
// Do not add them again in this file.