#include "complex.h"

float radian2degree(float rad)
{
	return rad * 180.0f / M_PI;
}

float degree2radian(float deg)
{
	return deg * M_PI / 180.0f;
}

void complex_print(comp z)
{
	printf("Real: %.4f, Image: %.4f\n", z.real, z.imag);
}

void complex_add(comp z1, comp z2, comp *res)
{
	res->real = z1.real + z2.real;
	res->imag = z1.imag + z2.imag;
}

void complex_sub(comp z1, comp z2, comp *res)
{
	res->real = z1.real - z2.real;
	res->imag = z1.imag - z2.imag;
}

void complex_mul(comp z1, comp z2, comp *res)
{
	res->real = z1.real * z2.real - z1.imag * z2.imag;
	res->imag = z1.real * z2.imag + z2.real * z1.imag;
}

void complex_scale(comp *z, float scale)
{
	z->real *= scale;
	z->imag *= scale;
}

float magnitude(comp z)
{
	return sqrt(z.real * z.real + z.imag * z.imag);
}

void conjugate(comp *z)
{
	z->imag *= -1;
}

void complex_div(comp z1, comp z2, comp *res)
{
	float denom = z1.real * z1.real + z1.imag * z1.imag;
	
	conjugate(&z1);
	complex_mul(z1, z2, res);
	complex_scale(res, 1.0f / denom);
}

void complex2phasor(comp z, phasor *res)
{
	res->amp = sqrt(z.real * z.real + z.imag * z.imag);
	res->phase = atan2(z.imag, z.real);
}

void phasor_print(phasor p)
{
	printf("Amplitude: %.4f, Phase: %.4f\n", p.amp, p.phase);
}

void phasor2complex(phasor p, comp *res)
{
	res->real = p.amp * cos(p.phase);
	res->imag = p.amp * sin(p.phase);
}
