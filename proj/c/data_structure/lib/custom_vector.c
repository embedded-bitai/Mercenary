#include "custom_vector.h"

// TODO: init_custom_vector polymorphism
void init_u8_custom_vector(custom_vector *vec)
{
	vec->list = (u8 *)malloc(sizeof(u8) * 16);
}
