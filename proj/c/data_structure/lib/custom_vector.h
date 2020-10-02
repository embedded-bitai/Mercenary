#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

typedef int8_t          s8;
typedef uint8_t         u8;

typedef int16_t         s16;
typedef uint16_t        u16;

typedef int32_t         s32;
typedef uint32_t        u32;

typedef int64_t         s64;
typedef uint64_t        u64;

typedef struct _custom_vector
{
	void *list;
} custom_vector;

void init_custom_vector(custom_vector *);
