#include "quick_sort.h"

void quick_sort_swap(int *arr, int a, int b)
{
	int tmp = arr[a];
	arr[a] = arr[b];
	arr[b] = tmp;
}

int partition(int *arr, int left, int right)
{
	int pivot = arr[left];
	int low = left + 1;
	int high = right;

	while(low <= high)
	{
		while(low <= right && pivot >= arr[low])
		{
			low++;
		}
		while(high >= (left + 1) && pivot <= arr[high])
		{
			high--;
		}
		if(low <= high)
		{
			quick_sort_swap(arr, low, high);
		}
	}

	quick_sort_swap(arr, left, high);

	return high;
}

void quick_sort(int *arr, int left, int right)
{
	if(left <= right)
	{
		int pivot = partition(arr, left, right);
		quick_sort(arr, left, pivot - 1);
		quick_sort(arr, pivot + 1, right);
	}
}
