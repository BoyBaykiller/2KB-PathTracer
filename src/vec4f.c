#include "vec4f.h"

Vec4f vec4f(float X, float Y, float Z, float W)
{
    return (Vec4f) {
        .X = X,
        .Y = Y,
        .Z = Z,
        .W = W,
    };
}

Vec4f vec4fAdd(Vec4f a, Vec4f b)
{
    return vec4f(a.X + b.X, a.Y + b.Y, a.Z + b.Z, a.W + b.W);
}
Vec4f vec4fSub(Vec4f a, Vec4f b)
{
    return vec4f(a.X - b.X, a.Y - b.Y, a.Z - b.Z, a.W - b.W);
}
Vec4f vec4fMul(Vec4f a, Vec4f b)
{
    return vec4f(a.X * b.X, a.Y * b.Y, a.Z * b.Z, a.W * b.W);
}
Vec4f vec4fDiv(Vec4f a, Vec4f b)
{
    return vec4f(a.X / b.X, a.Y / b.Y, a.Z / b.Z, a.W / b.W);
}
