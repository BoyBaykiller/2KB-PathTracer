#include "mat4f.h"
#include "vec3f.h"

// Mat4f LookAt()
// {
//     Vec3f z = Vector3.Normalize(eye - target);
//     Vec3f x = Vector3.Normalize(Vector3.Cross(up, z));
//     Vec3f y = Vector3.Normalize(Vector3.Cross(z, x));

//     Matrix4 result;

//     result.Row0.X = x.X;
//     result.Row0.Y = y.X;
//     result.Row0.Z = z.X;
//     result.Row0.W = 0;
//     result.Row1.X = x.Y;
//     result.Row1.Y = y.Y;
//     result.Row1.Z = z.Y;
//     result.Row1.W = 0;
//     result.Row2.X = x.Z;
//     result.Row2.Y = y.Z;
//     result.Row2.Z = z.Z;
//     result.Row2.W = 0;
//     result.Row3.X = -((x.X * eye.X) + (x.Y * eye.Y) + (x.Z * eye.Z));
//     result.Row3.Y = -((y.X * eye.X) + (y.Y * eye.Y) + (y.Z * eye.Z));
//     result.Row3.Z = -((z.X * eye.X) + (z.Y * eye.Y) + (z.Z * eye.Z));
//     result.Row3.W = 1;

//     return result;
// }
