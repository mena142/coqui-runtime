#include "mquickjs.h"
#include <stdio.h>

// Stub number-to-string functions
void u64toa(char *buf, uint64_t n, int radix) {
    snprintf(buf, 32, "%llu", (unsigned long long)n);
}

void i64toa(char *buf, int64_t n) {
    snprintf(buf, 32, "%lld", (long long)n);
}

void u32toa(char *buf, uint32_t n) {
    snprintf(buf, 16, "%u", n);
}

void i32toa(char *buf, int32_t n) {
    snprintf(buf, 16, "%d", n);
}

void u64toa_radix(char *buf, uint64_t n, int radix) {
    snprintf(buf, 32, "%llu", (unsigned long long)n);
}

// Stub floating point conversion functions
double js_atod(const char *s) {
    return 0.0;
}

void js_dtoa(char *buf, double d) {
    snprintf(buf, 32, "%g", d);
}

int js_dtoa_max_len(double d) {
    return 32;
}

// Dummy implementations to satisfy linker
int js_atod1(const char *s, double *pval) {
    *pval = 0.0;
    return 0;
}

int js_dtoa2(char *buf, double d) {
    js_dtoa(buf, d);
    return 0;
}
