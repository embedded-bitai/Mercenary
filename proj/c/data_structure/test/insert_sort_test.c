#include "insert_sort.h"

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
	int arr[6] = {5, 2, 4, 6, 1, 3};

	insert_sort(arr, 0, 6);
	print_arr(arr, 6);

	return 0;
}
