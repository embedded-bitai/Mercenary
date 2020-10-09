#include <math.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if 0
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

void make_heap(int *heap, int *end)
{
    int i;
    //int num_of_elem = heap[0];
    int num_of_elem = end - heap;

    printf("Make_Heap for Loop size = %d\n", num_of_elem);

    for(i = num_of_elem / 2; i >= 1; i--)
        adjust(heap, i);
}

void insert_sort(int *arr, int *start, int *end)
{
    int i;
    int left = start - arr;
    int right = end - arr;

    for (i = left + 1; i <= right; i++)
    {
        int key = arr[i];
        int j = i - 1;

        while (j >= left && arr[j] > key)
        {
            arr[j + 1] = arr[j];
            j = j - 1;
        }

        arr[j + 1] = key;
    }

    return;
}

#endif

#if 0
void swap(int *a, int *b)
{
    int *tmp = a;
    a = b;
    b = tmp;
}

int *partition(int *arr, int low, int high)
{
    int pivot = arr[high];
    int j, i = (low - 1);

    for (j = low; j <= high - 1; j++)
    {
        if (arr[j] <= pivot)
        {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }

    swap(&arr[i + 1], &arr[high]);

    return arr + 1 + i;
}

int *median_of_three(int *a, int *b, int *c)
{
    if (*a < *b && *b < *c)
        return (b);

    if (*a < *c && *c <= *b)
        return (c);

    if (*b <= *a && *a < *c)
        return (a);

    if (*b < *c && *c <= *a)
        return (c);

    if (*c <= *a && *a < *b)
        return (a);

    if (*c <= *b && *b <= *c)
        return (b);
}

void heapify(int *arr, int n, int i)
{
    int largest = i; // Initialize largest as root 
    int l = 2*i + 1; // left = 2*i + 1 
    int r = 2*i + 2; // right = 2*i + 2 

    // If left child is larger than root 
    if (l < n && arr[l] > arr[largest])
        largest = l;

    // If right child is larger than largest so far 
    if (r < n && arr[r] > arr[largest])
        largest = r;

    // If largest is not root 
    if (largest != i)
    {
        swap(&arr[i], &arr[largest]);

        // Recursively heapify the affected sub-tree 
        heapify(arr, n, largest);
    }
}

// main function to do heap sort 
void heap_sort_with_num(int *arr, int n)
{
    // Build heap (rearrange array) 
    for (int i = n / 2 - 1; i >= 0; i--)
        heapify(arr, n, i);

    // One by one extract an element from heap 
    for (int i=n-1; i>0; i--)
    {
        // Move current root to end 
        swap(&arr[0], &arr[i]);

        // call max heapify on the reduced heap 
        heapify(arr, i, 0);
    }
}

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

void hybrid_sort_util(int *arr, int start, int end, int depth_limit)
{
    int *pivot;
	int *partition_point;
    int size = &arr[end] - &arr[start];

    if (size < 16)
    {
        insert_sort(arr, start, end);
        return;
    }

    if (depth_limit == 0)
    {
		heap_sort_with_num(arr, end - start);
        //make_heap_with_num(start, end - start);
        //sort_heap(start, end + 1);
		//adjust(start, end + 1);
        return;
    }

    pivot = median_of_three(&arr[start], &arr[start + size / 2], &arr[end]);

    swap(pivot, &arr[end]);

    partition_point = partition(arr, arr[start], arr[end]);
    hybrid_sort_util(arr, start, *(partition_point - 1), depth_limit - 1);
    hybrid_sort_util(arr, *(partition_point + 1), end, depth_limit - 1);
}

void hybrid_sort(int *arr, int start, int end)
{
	int depth_limit = 2 * log(&arr[end] - &arr[start]);

	printf("depth_limit = %d\n", depth_limit);

	hybrid_sort_util(arr, start, end, depth_limit);
}

void init_hybrid_arr(int *arr, int num)
{
	int i;

	srand(time(NULL));

	for (i = 0; i < num; i++)
		arr[i] = rand() % 10000 + 1;
}

void print_arr(int *arr, int len)
{
	int i;
	int cnt = 0;

	for(i = 0; i < len; i++)
	{
		if(++cnt % 16)
		{
			printf("%3d, ", arr[i]);
		}
		else
		{
			printf("%3d\n", arr[i]);
		}
	}
	printf("\n");
}

int main(void)
{
	int test[129] = { 0 };

	init_hybrid_arr(test, 128);
	hybrid_sort(test, 0, 128);
	print_arr(test, 128);

	return 0;
}
#endif
