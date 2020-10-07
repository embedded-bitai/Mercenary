#ifndef VECTOR_H
#define VECTOR_H

#include <stdlib.h>
#include <string.h>

typedef int8_t          s8;
typedef uint8_t         u8;

typedef int16_t         s16;
typedef uint16_t        u16;

typedef int32_t         s32;
typedef uint32_t        u32;

typedef int64_t         s64;
typedef uint64_t        u64;

typedef uint32_t        u_result;

typedef struct _vector_u8
{
    u8 *data;
    unsigned int size;
    unsigned int capacity;
} vector_u8;

#if 1
#define MAKE_VECTOR_TYPE(T) \
typedef struct _vector_##T vector_##T;	\
struct _vector_##T { \
    typeof (T) *data; \
    unsigned size; \
    unsigned capacity; \
}
#else
#define VECTOR_OF(T)	\
struct {	\
	typeof(T) *data;	\
	unsigned int size;	\
	unsigned int capacity;	\
}
#endif

#define VECTOR_INIT_ASSIGN(VEC, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    typeof (VAL) val = (VAL); \
    vec->data = malloc(sizeof *vec->data); \
    vec->size = vec->capacity = 1; \
    vec->data[0] = val; \
} while (0)

#define VECTOR_INIT_ASSIGN_N(VEC, N, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N); \
    typeof (VAL) val = (VAL); \
    vec->data = malloc(n * sizeof *vec->data); \
    vec->size = vec->capacity = n; \
    while (n-- > 0) \
        vec->data[n] = val; \
} while (0)

#define VECTOR_INIT_ASSIGN_PTR(VEC, N, PTR) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N); \
    typeof (*PTR) *ptr = (PTR); \
    vec->data = malloc(n * sizeof *vec->data); \
    vec->size = vec->capacity = n; \
    while (n-- > 0) \
        vec->data[n] = ptr[n]; \
} while (0)

inline void vector_init_reserve(vector_u8 *vec, int num)
{
	vec->data = (u8 *)malloc(num * sizeof(*vec->data));
	vec->size = 0;
	vec->capacity = num;
}

#if 0
#define VECTOR_INIT_RESERVE(VEC, N)		\
do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N); \
    vec->data = malloc(n * sizeof *vec->data); \
    vec->size = 0; \
    vec->capacity = n; \
} while (0)

#define VECTOR_INIT(VEC)		VECTOR_INIT_RESERVE((VEC), 1)
#define VECTOR_INIT_N(VEC, N)	VECTOR_INIT_RESERVE((VEC), (N))
#endif

#define VECTOR_SIZE(VEC) (VEC)->size

#define VECTOR_EMPTY(VEC) ((VEC).size == 0)

#define VECTOR_CAPACITY(VEC) (VEC).capacity

#define VECTOR_RESERVE(VEC, N) do { \
    typeof (VEC) *vec = &(VEC); \
    typeof (N) n = (N); \
    if (vec->capacity < n) { \
        vec->data = realloc(n * sizeof *vec->data); \
        vec->capacity = n; \
    } \
} while (0)

#define VECTOR_RESIZE(VEC, N, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N), i; \
    typeof (VAL) val = (VAL); \
    if (n > vec->capacity) \
        vec->data = realloc(vec->data, n * sizeof *vec->data); \
    for (i = vec->size; i < n; ++i) \
        vec->data[i] = val; \
    vec->size = n; \
} while (0)

#define VECTOR_SHRINK_TO_FIT(VEC) do { \
    typeof (VEC) *vec = &(VEC); \
    vec->data = realloc(vec->data, vec->size * sizeof *vec->data); \
    vec->capacity = vec->size; \
} while (0)

#define VECTOR_ASSIGN(VEC, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    typeof (VAL) val = (VAL); \
    vec->size = vec->capacity = 1; \
    vec->data = realloc(vec->data, sizeof *vec->data); \
    vec->data[0] = val; \
} while (0)

#define VECTOR_ASSIGN_N(VEC, N, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N); \
    typeof (VAL) val = (VAL); \
    vec->data = realloc(vec->data, n * sizeof *vec->data); \
    vec->size = vec->capacity = n; \
    while (n-- > 0) \
        vec->data[n] = val; \
} while (0)

#define VECTOR_ASSIGN_PTR(VEC, N, PTR) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N); \
    typeof (*PTR) *ptr = (PTR); \
    vec->data = realloc(vec->data, n * sizeof *vec->data); \
    while (n-- > 0) \
        vec->data[n] = ptr[n]; \
} while (0)

#define VECTOR_INSERT(VEC, POS, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned pos = (POS); \
    typeof (VAL) val = (VAL); \
    while (vec->size + 1 > vec->capacity) { \
        vec->capacity *= 2; \
        vec->data = realloc(vec->data, vec->capacity * sizeof *vec->data); \
    } \
    memmove(vec->data + pos + 1, vec->data + pos, (vec->size - pos) * sizeof val); \
    ++vec->size; \
    vec->data[pos] = val; \
} while (0)

#define VECTOR_INSERT_N(VEC, POS, N, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned pos = (POS), n = (N), i; \
    typeof (VAL) val = (VAL); \
    while (vec->size + n > vec->capacity) { \
        vec->capacity *= 2; \
        vec->data = realloc(vec->data, vec->capacity * sizeof *vec->data); \
    } \
    memmove(vec->data + pos + n, vec->data + pos, (vec->size - pos) * sizeof *vec->data); \
    for (i = 0; i < n; i++) \
        vec->data[pos + i] = val; \
    vec->size += n; \
} while (0)

#define VECTOR_INSERT_PTR(VEC, POS, N, PTR) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned pos = (POS), n = (N), i; \
    typeof (*PTR) *ptr = (PTR); \
    while (vec->size + n > vec->capacity) { \
        vec->capacity *= 2; \
        vec->data = realloc(vec->data, vec->capacity * sizeof *vec->data); \
    } \
    memmove(vec->data + pos + n, vec->data + pos, (vec->size - pos) * sizeof *vec->data); \
    for (i = 0; i < n; i++) \
        vec->data[pos + i] = ptr[i]; \
    vec->size += n; \
} while (0)

#define VECTOR_PUSH_BACK(VEC, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    typeof (*(vec->data)) val = VAL; \
	typeof (vec->data) tmp; \
    while (vec->size + 1 > vec->capacity) { \
        vec->capacity += 1; \
		tmp = (typeof(vec->data))malloc(sizeof(vec->data) * vec->capacity); \
		memmove(tmp, vec->data, sizeof(typeof(*(vec->data))) * vec->size); \
		free(vec->data); \
        vec->data = tmp; \
    } \
    vec->data[vec->size] = val; \
    vec->size += 1; \
} while (0)

#define VECTOR_PUSH_BACK_N(VEC, N, VAL) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N), i; \
    typeof (VAL) val = (VAL); \
    while (vec->size + n > vec->capacity) { \
        vec->capacity *= 2; \
        vec->data = realloc(vec->data, vec->capacity * sizeof *vec->data); \
    } \
    for (i = 0; i < n; ++i) \
        vec->data[vec->size + i] = val; \
    vec->size += n; \
} while (0)

#define VECTOR_PUSH_BACK_PTR(VEC, N, PTR) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned n = (N), i; \
    typeof (*PTR) *ptr = (PTR); \
    while (vec->size + n > vec->capacity) { \
        vec->capacity *= 2; \
        vec->data = realloc(vec->data, vec->capacity * sizeof *vec->data); \
    } \
    for (i = 0; i < n; ++i) \
        vec->data[vec->size + i] = ptr[i]; \
    vec->size += n; \
} while (0)

#define VECTOR_ERASE(VEC, POS) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned pos = (POS); \
    vec->size -= 1; \
    memmove(vec->data + pos, vec->data + pos + 1, (vec->size - pos) * sizeof *vec->data); \
} while (0)

#define VECTOR_ERASE_N(VEC, POS, N) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned pos = (POS), n = (N); \
    vec->size -= n; \
    memmove(vec->data + pos, vec->data + pos + n, (vec->size - pos) * sizeof *vec->data); \
} while (0)

#define VECTOR_POP_BACK(VEC) do { \
    (VEC).size -= 1; \
} while (0)

#define VECTOR_POP_BACK_N(VEC, N) do { \
    (VEC).size -= (N); \
} while (0)

#define VECTOR_CLEAR(VEC) do { \
    (VEC).size = 0; \
} while (0)

#define VECTOR_DATA(VEC) (VEC).data

#define VECTOR_AT(VEC, POS) (VEC).data[POS]

#define VECTOR_FRONT(VEC) (VEC).data[0]

#define VECTOR_BACK(VEC) (VEC).data[vec->size - 1]

#define VECTOR_FOR_EACH(VEC, VAR, DO) do { \
    typeof (VEC) *vec = &(VEC); \
    unsigned i = 0; \
    for (i = 0; i < vec->size; ++i) { \
        typeof (*vec->data) VAR = vec->data[i]; \
        DO; \
    } \
} while (0)

#define VECTOR_FREE(VEC) do { \
    typeof (VEC) *vec = &(VEC); \
    vec->size = 0; \
    vec->capacity = 0; \
    free(vec->data); \
} while(0)

#endif
