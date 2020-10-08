#include "heap_sort.h"

void adjust(int *heap_of_num, int i)  /*Function to arrange the elements in the heap*/
{
	int j;
	int copy;
	int num;
	int ref = 1;
	num = heap_of_num[0];

	printf("Adjust for Loop size = %d\n", num);

	while(2 * i <= num && ref == 1)
	{
		j = 2 * i;   
		if(j + 1 <= num && heap_of_num[j + 1] > heap_of_num[j])
			j = j + 1;

		if(heap_of_num[j] < heap_of_num[i])
			ref = 0;
		else
		{
			copy = heap_of_num[i];
			heap_of_num[i] = heap_of_num[j];
			heap_of_num[j] = copy;
			i = j;
		}
	}
}

void make_heap(int *heap)
{
	int i;
	int num_of_elem = heap[0];

	printf("Make_Heap for Loop size = %d\n", num_of_elem);

	for(i = num_of_elem / 2; i >= 1; i--)
		adjust(heap, i);
}
