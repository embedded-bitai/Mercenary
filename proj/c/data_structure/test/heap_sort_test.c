#include <stdio.h>
#include <curses.h>
#include "heap_sort.h"

int main(void)
{
	int heap[30] = { 0, 5, 3, 1, 4, 8, 10 };
	int num_of_elem = 6;
	int i;
	int last_elem;
	int copy_var;

	int arr[] = { 12, 11, 13, 5, 6, 7 };
    int n = sizeof(arr) / sizeof(arr[0]);
  
	heap[0] = num_of_elem;
	make_heap(heap);

	while(heap[0] > 1) /* Loop for the Sorting process */
	{
		printf("Process Sorting\n");
		last_elem = heap[0];
		copy_var = heap[1];
		heap[1] = heap[last_elem];
		heap[last_elem] = copy_var;
		heap[0]--;
		adjust(heap, 1);
	}
	printf("Sorted Array\n"); /* Printing the sorted Array */

	for(i = 1; i <= num_of_elem; i++)
		printf("%d ", heap[i]);

	printf("\n");

    heap_sort_with_num(arr, n);

	for(i = 0; i < n; i++)
		printf("%d ", arr[i]);

	printf("\n");

	return 0;
}
