#ifndef __HEAP_SORT_H__
#define __HEAP_SORT_H__

#include <stdio.h>
#include <curses.h>

void heap_sort_swap(int *, int *);
void adjust(int *, int);
void make_heap(int *);
void heapify(int *, int, int);
void heap_sort_with_num(int *, int);

#endif
