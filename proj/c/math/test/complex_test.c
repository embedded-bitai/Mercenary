#include "complex.h"

int main(void)
{
	comp z1 = { 3, 4 };
	comp z2 = { 2, -3 };
	comp res;

	phasor p1;
	phasor p2;
	phasor custom;

	float rad = 1;
	float deg;

	complex_print(z1);
	complex_print(z2);

	complex_add(z1, z2, &res);
	complex_print(res);

	complex_sub(z1, z2, &res);
	complex_print(res);

	complex_mul(z1, z2, &res);
	complex_print(res);

	complex_div(z1, z2, &res);
	complex_print(res);

	complex2phasor(res, &custom);
	phasor_print(custom);
	deg = radian2degree(custom.phase);
	printf("phase = %.4f, deg = %.4f\n", custom.phase, deg);

	deg = radian2degree(rad);
	printf("rad = %.4f, deg = %.4f\n", rad, deg);

	rad = degree2radian(deg);
	printf("rad = %.4f, deg = %.4f\n", rad, deg);

	complex2phasor(z1, &p1);
	phasor_print(p1);
	deg = radian2degree(p1.phase);
	printf("phase = %.4f, deg = %.4f\n", p1.phase, deg);

	complex2phasor(z2, &p2);
	phasor_print(p2);
	deg = radian2degree(p2.phase);
	printf("phase = %.4f, deg = %.4f\n", p2.phase, deg);

	return 0;
}
