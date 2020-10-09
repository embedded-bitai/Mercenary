#include "quick_sort.h"

void print_arr(int *arr, int len)
{
    int i;

    printf("arr:\n");

    for (i = 0; i < len; i++)
        printf("%5d", arr[i]);

    printf("\n");
}

int main(void)
{
	int test_arr[10] = { 5, 2, 123, 3345, 32, 93, 23, 9 };
	quick_sort(test_arr, 0, 7);
	print_arr(test_arr, 8);
	
	return 0;
}
