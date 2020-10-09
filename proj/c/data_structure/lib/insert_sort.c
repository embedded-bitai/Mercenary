#include "insert_sort.h"

void insert_sort(int *arr, int start, int end)
{
	int i, j, key, len = end - start;

	for (i = 1; i < len; i++)
	{
		key = arr[i];

		for (j = i - 1; j >= 0 && arr[j] > key; j--)
			arr[j + 1] = arr[j];

		arr[j + 1] = key;
	}
}
