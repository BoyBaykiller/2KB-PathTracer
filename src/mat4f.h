#ifndef MAT4F_H_
#define MAT4F_H_

#include "vec4f.h"
#include "vec3f.h"

typedef struct
{
    Vec4f Row0;
    Vec4f Row1;
    Vec4f Row2;
    Vec4f Row3;
} Mat4f;

#endif