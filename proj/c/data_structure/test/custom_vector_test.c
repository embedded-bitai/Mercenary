#include <stdio.h>
#include "custom_vector.h"

int main(void)
{
    VECTOR_OF(int) int_vec;
    VECTOR_OF(double) dbl_vec;
    int i, cnt = 1;

    VECTOR_INIT(int_vec);
    VECTOR_INIT(dbl_vec);

    for (i = 0; i < 100; ++i) {
        VECTOR_PUSH_BACK(int_vec, cnt);
        VECTOR_PUSH_BACK(dbl_vec, cnt++);
    }

    for (i = 0; i < 100; ++i) {
        printf("int_vec[%d] = %d\n", i, VECTOR_AT(int_vec, i));
        printf("dbl_vec[%d] = %f\n", i, VECTOR_AT(dbl_vec, i));
    }

    VECTOR_FREE(int_vec);
    VECTOR_FREE(dbl_vec);

    return 0;
}
