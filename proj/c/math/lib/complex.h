#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

typedef struct _complex comp;

struct _complex
{
	float real;
	float imag;
};

typedef struct _phasor phasor;

struct _phasor
{
	float amp;
	float phase;
};

float radian2degree(float rad);
float degree2radian(float deg);

void complex_print(comp z);
void phasor_print(phasor p);

void complex_add(comp z1, comp z2, comp *res);
void complex_sub(comp z1, comp z2, comp *res);
void complex_mul(comp z1, comp z2, comp *res);
void complex_div(comp z1, comp z2, comp *res);

void complex_scale(comp *z, float scale);
float magnitude(comp z);
void conjugate(comp *z);

void complex2phasor(comp z, phasor *res);
