#include <stdint.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "mquickjs.h"

// --- String Formatting (As before) ---
void u32toa(char *b, uint32_t n) { b[0]='0'; b[1]=0; }
void i32toa(char *b, int32_t n) { b[0]='0'; b[1]=0; }
void u64toa(char *b, uint64_t n, int r) { b[0]='0'; b[1]=0; }
void i64toa(char *b, int64_t n) { b[0]='0'; b[1]=0; }
void u64toa_radix(char *b, uint64_t n, int r) { b[0]='0'; b[1]=0; }

// --- Engine-Specific Math Bridge with Exception Handling ---

double js_fmod(double x, double y) {
    // RP2040 Exception: if y is 0, standard fmod returns NaN. 
    // Pico ROM might return 0 or Inf. We force standard JS behavior.
    if (y == 0.0) return NAN; 
    return fmod(x, y); 
}

double js_pow(double x, double y) {
    // RP2040 Exception: handling 0^0 or negatives to powers
    if (x == 1.0) return 1.0;
    if (y == 0.0) return 1.0;
    return pow(x, y); 
}

long js_lrint(double x) {
    // RP2040 Exception: prevent overflow/hang on huge floats
    if (isnan(x)) return 0;
    if (x > 2147483647.0) return 2147483647;
    if (x < -2147483648.0) return -2147483648;
    return lrint(x); 
}

// --- Conversions ---
double js_atod(const char *s) { return strtod(s, NULL); }
int js_dtoa2(char *b, double d) { return sprintf(b, "%g", d); }
void js_dtoa(char *b, double d) { js_dtoa2(b, d); }
int js_atod1(const char *s, double *v) {
    char *end; *v = strtod(s, &end);
    return (end == s) ? -1 : 0;
}
int js_dtoa_max_len(double d) { return 32; }