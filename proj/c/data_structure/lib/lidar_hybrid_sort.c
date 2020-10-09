#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if 0
typedef struct _rplidar_response_measurement_node_t {
    u8    sync_quality;      // syncbit:1;syncbit_inverse:1;quality:6;
    u16   angle_q6_checkbit; // check_bit:1;angle_q6:15;
    u16   distance_q2;
} __attribute__((packed)) rplidar_response_measurement_node_t;

void swap(int *a, int *b)
{
    int *tmp = a;
    a = b;
    b = tmp;
}

void insert_sort(rplidar_response_measurement_node_t *arr,
                rplidar_response_measurement_node_t *start,
                rplidar_response_measurement_node_t *end)
{
    int i;
    int left = begin - arr;
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

int *partition(int *arr, int low, int high)
{
    int pivot = arr[high];
    int j, i = (low - 1);

    for (j = low; j <= high - 1; j++)
    {
        if (arr[j] <= pivot)
        {
            i++;
            swap(arr[i], arr[j]);
        }
    }

    swap(arr[i + 1], arr[high]);

    return arr + 1 + i;
}

int *median_of_three(int *a int *b, int *c)
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

void hybrid_sort(rplidar_response_measurement_node_t *arr, rplidar_response_measurement_node_t *start,
                rplidar_response_measurement_node_t *end, size_t count)
{
    int *pivot;
    int size = end - begin;

    if (size < 16)
    {
        insert_sort(arr, start, end);
        return;
    }

    if (count == 0)
    {
        make_heap(start, end + 1);
        sort_heap(start, end + 1);
        return;
    }

    pivot = median_of_three(start, start + size / 2, end);

    swap(pivot, end);

    partition_point = partition(arr, start - arr, end - arr);
    hybrid_sort(arr, start, partition_point - 1, count - 1);
    hybrid_sort(arr, partition_point + 1, end, count - 1);

    return;
}

int main(void)
{
	return 0;
}
#endif
