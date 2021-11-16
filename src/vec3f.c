#include "vec3f.h"

Vec3f vec3f(float X, float Y, float Z)
{
    return (Vec3f) {
        .X = X,
        .Y = Y,
        .Z = Z,
    };
}

Vec3f vec3fAdd(Vec3f a, Vec3f b)
{
    return vec3f(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
}
Vec3f vec3fSub(Vec3f a, Vec3f b)
{
    return vec3f(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
}
Vec3f vec3fMul(Vec3f a, Vec3f b)
{
    return vec3f(a.X * b.X, a.Y * b.Y, a.Z * b.Z);
}
Vec3f vec3fDiv(Vec3f a, Vec3f b)
{
    return vec3f(a.X / b.X, a.Y / b.Y, a.Z / b.Z);
}
