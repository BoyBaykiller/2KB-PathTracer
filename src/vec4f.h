#ifndef VEC4F_H_
#define VEC4F_H_

typedef struct
{
    float X, Y, Z, W;
} Vec4f;

Vec4f vec4f(float X, float Y, float Z, float W);

Vec4f vec4fAdd(Vec4f a, Vec4f b);
Vec4f vec4fSub(Vec4f a, Vec4f b);
Vec4f vec4fMul(Vec4f a, Vec4f b);
Vec4f vec4fDiv(Vec4f a, Vec4f b);

#endif
