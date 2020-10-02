#include "custom_vector.h"

int main(void)
{
	int custom_vector_num;
	custom_vector answer;

	// TODO: Use #define to make it polymorphism
	// init_custom_vector(&answer, "u8"), init_custom_vector(&answer, "u16"), etc ...
	init_custom_vector(&answer);
	custom_vector_num = custom_vector_size(answer);
	printf("custom_vector_num = %d\n", custom_vector_num);

	return 0;
}
