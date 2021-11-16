#ifndef VEC3F_H_
#define VEC3F_H_

typedef struct
{
    float X, Y, Z;
} Vec3f;

Vec3f vec3f(float X, float Y, float Z);

Vec3f vec3fAdd(Vec3f a, Vec3f b);
Vec3f vec3fSub(Vec3f a, Vec3f b);
Vec3f vec3fMul(Vec3f a, Vec3f b);
Vec3f vec3fDiv(Vec3f a, Vec3f b);

#endif
