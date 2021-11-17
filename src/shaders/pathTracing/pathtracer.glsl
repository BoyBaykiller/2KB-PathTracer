#version 430 core
#define FLOAT_MAX 3.4028235e+38
#define FLOAT_MIN -3.4028235e+38
#define EPSILON 0.001
#define PI 3.1415926586

layout(local_size_x = 32, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba32f) restrict uniform image2D ImgResult;

struct Material
{
    vec3 Albedo; // Base color
    float SpecularChance; // How reflective
    
    vec3 Emissiv; // How much light is emitted
    float SpecularRoughness; // How rough reflections are

    vec3 Absorbance; // How strongly light is absorbed
    float RefractionChance; // How transparent

    float RefractionRoughness; // How rough refractions are
    float IOR; // How strongly light gets refracted and the amout of light that is reflected
};

struct Cuboid 
{
    vec3 Min;
    vec3 Max;
    
    Material Material;
};

struct Sphere 
{
    vec3 Position;
    float Radius;

    Material Material;
};

struct HitInfo 
{
    float T;
    bool FromInside;
    vec3 NearHitPos;
    vec3 Normal;
    Material Material;
};

struct Ray 
{
    vec3 Origin;
    vec3 Direction;
};

layout(std140, row_major, binding = 0) uniform BasicDataUBO
{
    mat4 InvProjection;
	mat4 InvView;
	vec3 ViewPos;
    int RenderedFrame;
} basicDataUBO;

vec3 Radiance(Ray ray);
float BSDF(inout Ray ray, HitInfo hitInfo, out bool isRefractive);
bool RayTrace(Ray ray, out HitInfo hitInfo);
bool RaySphereIntersect(Ray ray, vec3 position, float radius, out float t1, out float t2);
bool RayCuboidIntersect(Ray ray, vec3 aabbMin, vec3 aabbMax, out float t1, out float t2);
vec3 CosineSampleHemisphere(vec3 normal);
vec2 UniformSampleUnitCircle();
vec3 GetNormal(vec3 spherePos, float radius, vec3 surfacePosition);
vec3 GetNormal(vec3 aabbMin, vec3 aabbMax, vec3 surfacePosition);
uint GetPCGHash(inout uint seed);
float GetRandomFloat01();
float GetSmallestPositive(float t1, float t2);
Ray GetWorldSpaceRay(mat4 inverseProj, mat4 inverseView, vec3 viewPos, vec2 normalizedDeviceCoords);
float FresnelSchlick(float cosTheta, float n1, float n2);

const int RAY_DEPTH = 13;
const int SPP = 1;

const float FOCAL_LENGTH = 20.0;
const float APERTURE_DIAMETER = 0.14;

const Cuboid cuboids[7] = Cuboid[]
(
    Cuboid(vec3(-20, -12.5025, -22.5), vec3(20, -12.4975, 2.5), Material(vec3(0.2, 0.04, 0.04), 0, vec3(0, 0, 0), 0.051, vec3(0, 0, 0), 0, 0, 1)),
    Cuboid(vec3(-6, 20.4925, 2.2499998), vec3(6, 20.497501, 9.75), Material(vec3(0.04, 0.04, 0.04), 0, vec3(4.585, 4.725, 2.565), 0, vec3(0, 0, 0), 0, 0, 1)),

    Cuboid(vec3(-20, -12.5, -22.5025), vec3(20, 12.5, -22.4975), Material(vec3(1, 1, 1), 0, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0, 1)),
    Cuboid(vec3(-20, -12.49, 2.1999998), vec3(20, 12.5, 2.5), Material(vec3(1, 1, 1), 0.04, vec3(0, 0, 0), 0, vec3(0.01, 0.01, 0.01), 0.954, 0, 1)),

    Cuboid(vec3(19.9975, -12.5, -22.5), vec3(20.0025, 12.5, 2.5), Material(vec3(0.8, 0.8, 0.4), 1, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0, 1)),
    Cuboid(vec3(-20.0025, -12.5, -22.5), vec3(-19.9975, 12.5, 2.5), Material(vec3(0.24, 0.6, 0.24), 0, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0, 1)),

    Cuboid(vec3(-16.5, -13.495, -16.5), vec3(-13.5, -7.495, -13.5), Material(vec3(1, 1, 1), 0, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0, 1))
);

const Sphere spheres[48] = Sphere[]
(
   Sphere(vec3(-12, -11.2, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-12, -7.033334, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0, vec3(0, 0, 0), 0.2, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-12, -2.866667, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0, vec3(0, 0, 0), 0.4, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-12, 1.3, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0, vec3(0, 0, 0), 0.6, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-12, 5.466666, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0, vec3(0, 0, 0), 0.8, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-12, 9.633332, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0, vec3(0, 0, 0), 1, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-7.6, -11.2, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.2, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-7.6, -7.033334, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.2, vec3(0, 0, 0), 0.2, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-7.6, -2.866667, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.2, vec3(0, 0, 0), 0.4, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-7.6, 1.3, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.2, vec3(0, 0, 0), 0.6, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-7.6, 5.466666, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.2, vec3(0, 0, 0), 0.8, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-7.6, 9.633332, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.2, vec3(0, 0, 0), 1, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-3.1999998, -11.2, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.4, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-3.1999998, -7.033334, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.4, vec3(0, 0, 0), 0.2, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-3.1999998, -2.866667, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.4, vec3(0, 0, 0), 0.4, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-3.1999998, 1.3, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.4, vec3(0, 0, 0), 0.6, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-3.1999998, 5.466666, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.4, vec3(0, 0, 0), 0.8, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-3.1999998, 9.633332, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.4, vec3(0, 0, 0), 1, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(1.2000008, -11.2, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.6, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(1.2000008, -7.033334, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.6, vec3(0, 0, 0), 0.2, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(1.2000008, -2.866667, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.6, vec3(0, 0, 0), 0.4, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(1.2000008, 1.3, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.6, vec3(0, 0, 0), 0.6, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(1.2000008, 5.466666, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.6, vec3(0, 0, 0), 0.8, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(1.2000008, 9.633332, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.6, vec3(0, 0, 0), 1, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(5.6000004, -11.2, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.8, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(5.6000004, -7.033334, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.8, vec3(0, 0, 0), 0.2, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(5.6000004, -2.866667, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.8, vec3(0, 0, 0), 0.4, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(5.6000004, 1.3, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.8, vec3(0, 0, 0), 0.6, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(5.6000004, 5.466666, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.8, vec3(0, 0, 0), 0.8, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(5.6000004, 9.633332, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 0.8, vec3(0, 0, 0), 1, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(10, -11.2, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 1, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(10, -7.033334, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 1, vec3(0, 0, 0), 0.2, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(10, -2.866667, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 1, vec3(0, 0, 0), 0.4, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(10, 1.3, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 1, vec3(0, 0, 0), 0.6, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(10, 5.466666, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 1, vec3(0, 0, 0), 0.8, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(10, 9.633332, -5), 1.3, Material(vec3(0.59, 0.59, 0.99), 1, vec3(0, 0, 0), 1, vec3(0, 0, 0), 0, 0.1, 1)),
    Sphere(vec3(-10.7, 3, -20), 1.3, Material(vec3(0.9, 0.25, 0.25), 0.02, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0.98, 0, 1.05)),
    Sphere(vec3(-10.7, -6, -20), 1.3, Material(vec3(1, 1, 1), 0.02, vec3(0, 0, 0), 0, vec3(0, 0, 0), 0.98, 0, 1.1)),
    Sphere(vec3(-6.7, 3, -20), 1.3, Material(vec3(0.9, 0.25, 0.25), 0.02, vec3(0, 0, 0), 0, vec3(0.16666667, 0.33333334, 0.5), 0.98, 0, 1.05)),
    Sphere(vec3(-6.7, -6, -20), 1.3, Material(vec3(1, 1, 1), 0.02, vec3(0, 0, 0), 0.16666667, vec3(0, 0, 0), 0.98, 0.16666667, 1.1)),
    Sphere(vec3(-2.6999998, 3, -20), 1.3, Material(vec3(0.9, 0.25, 0.25), 0.02, vec3(0, 0, 0), 0, vec3(0.33333334, 0.6666667, 1), 0.98, 0, 1.05)),
    Sphere(vec3(-2.6999998, -6, -20), 1.3, Material(vec3(1, 1, 1), 0.02, vec3(0, 0, 0), 0.33333334, vec3(0, 0, 0), 0.98, 0.33333334, 1.1)),
    Sphere(vec3(1.3000002, 3, -20), 1.3, Material(vec3(0.9, 0.25, 0.25), 0.02, vec3(0, 0, 0), 0, vec3(0.5, 1, 1.5), 0.98, 0, 1.05)),
    Sphere(vec3(1.3000002, -6, -20), 1.3, Material(vec3(1, 1, 1), 0.02, vec3(0, 0, 0), 0.5, vec3(0, 0, 0), 0.98, 0.5, 1.1)),
    Sphere(vec3(5.3, 3, -20), 1.3, Material(vec3(0.9, 0.25, 0.25), 0.02, vec3(0, 0, 0), 0, vec3(0.6666667, 1.3333334, 2), 0.98, 0, 1.05)),
    Sphere(vec3(5.3, -6, -20), 1.3, Material(vec3(1, 1, 1), 0.02, vec3(0, 0, 0), 0.6666667, vec3(0, 0, 0), 0.98, 0.6666667, 1.1)),
    Sphere(vec3(9.3, 3, -20), 1.3, Material(vec3(0.9, 0.25, 0.25), 0.02, vec3(0, 0, 0), 0, vec3(0.8333333, 1.6666666, 2.5), 0.98, 0, 1.05)),
    Sphere(vec3(9.3, -6, -20), 1.3, Material(vec3(1, 1, 1), 0.02, vec3(0, 0, 0), 0.8333333, vec3(0, 0, 0), 0.98, 0.8333333, 1.1))
);

uint rndSeed;
void main()
{
    ivec2 imgResultSize = imageSize(ImgResult);
    ivec2 imgCoord = ivec2(gl_GlobalInvocationID.x / imgResultSize.y, gl_GlobalInvocationID.x % imgResultSize.y);

    rndSeed = gl_GlobalInvocationID.x * 1973 + gl_GlobalInvocationID.y * 9277 + basicDataUBO.RenderedFrame * 2699 | 1;
    vec3 color = vec3(0);
    for (int i = 0; i < SPP; i++)
    {   
        vec2 subPixelOffset = vec2(GetRandomFloat01(), GetRandomFloat01()) - 0.5; // integrating over whole pixel eliminates aliasing
        vec2 ndc = (imgCoord + subPixelOffset) / imgResultSize * 2.0 - 1.0;
        Ray rayEyeToWorld = GetWorldSpaceRay(basicDataUBO.InvProjection, basicDataUBO.InvView, basicDataUBO.ViewPos, ndc);

        vec3 focalPoint = rayEyeToWorld.Origin + rayEyeToWorld.Direction * FOCAL_LENGTH;
        vec2 offset = APERTURE_DIAMETER * 0.5 * UniformSampleUnitCircle();
        
        rayEyeToWorld.Origin = (basicDataUBO.InvView * vec4(offset, 0.0, 1.0)).xyz;
        rayEyeToWorld.Direction = normalize(focalPoint - rayEyeToWorld.Origin);

        color += Radiance(rayEyeToWorld);
    }
    color /= SPP;
    vec3 lastFrameColor = imageLoad(ImgResult, imgCoord).rgb;

    color = mix(lastFrameColor, color, 1.0 / (basicDataUBO.RenderedFrame + 1));
    imageStore(ImgResult, imgCoord, vec4(color, 1.0));
}

vec3 Radiance(Ray ray)
{
    vec3 throughput = vec3(1.0);
    vec3 resultColor = vec3(0.0);

    HitInfo hitInfo;
    bool isRefractive;
    float rayProbability;
    for (int i = 0; i < RAY_DEPTH; i++)
    {
        if (RayTrace(ray, hitInfo))
        {
            // If ray did just pass through medium apply Beer's law
            if (hitInfo.FromInside)
            {
                hitInfo.Normal *= -1.0;
                throughput *= exp(-hitInfo.Material.Absorbance * hitInfo.T);
            }

            // Evaluating BSDF gives a new ray based on the hitPoints properties and the incomming ray,
            // the probability this ray would take its path 
            // and a bool indicating wheter the ray penetrates into the medium
            rayProbability = BSDF(ray, hitInfo, isRefractive);

            resultColor += hitInfo.Material.Emissiv * throughput;
            if (!isRefractive)
            {
                // The cosine term is already taken into account by the CosineSampleHemisphere function. Its weighting the random rays to a cosine distibution
                // throughput *= hitInfo.Material.Albedo * dot(ray.Direction, hitInfo.Normal);
                
                throughput *= hitInfo.Material.Albedo;
            }

            throughput /= rayProbability;
            
            // Russian Roulette, unbiased method to terminate rays and therefore lower render times (also reduces fireflies)
            {
                float p = max(throughput.x, max(throughput.y, throughput.z));
                if (GetRandomFloat01() > p)
                    break;

                throughput /= p;
            }
        }
        else
        {
            // https://www.shadertoy.com/view/WlBSzG
            float t = 0.5 * (ray.Direction.y + 1.0);
            vec3 col = ((1.0 - t) * vec3(1.0) + t * vec3(0.45, 0.6, 1.0)) * 0.1;

            resultColor += col * throughput;
            break;
        }
    }
    return resultColor;
}

float BSDF(inout Ray ray, HitInfo hitInfo, out bool isRefractive)
{
    isRefractive = false;

    float specularChance = hitInfo.Material.SpecularChance;
    float refractionChance = hitInfo.Material.RefractionChance;
    if (specularChance > 0.0)
    {
        specularChance = mix(specularChance, 1.0, FresnelSchlick(dot(-ray.Direction, hitInfo.Normal), hitInfo.FromInside ? hitInfo.Material.IOR : 1.0, !hitInfo.FromInside ? hitInfo.Material.IOR : 1.0));
        float diffuseChance = 1.0 - specularChance - refractionChance;
        refractionChance = 1.0 - specularChance - diffuseChance;
    }

    vec3 diffuseRay = CosineSampleHemisphere(hitInfo.Normal);
    float rayProbability = 1.0;
    //float isDiffuse = 1.0 - isSpecular - isRefractive;
    
    float raySelectRoll = GetRandomFloat01();
    if (specularChance > raySelectRoll)
    {
        ray.Direction = normalize(mix(reflect(ray.Direction, hitInfo.Normal), diffuseRay, hitInfo.Material.SpecularRoughness * hitInfo.Material.SpecularRoughness));
        rayProbability = specularChance;
    }
    else if (specularChance + refractionChance > raySelectRoll)
    {
        vec3 refractionRayDir = refract(ray.Direction, hitInfo.Normal, hitInfo.FromInside ? hitInfo.Material.IOR / 1.0 : 1.0 / hitInfo.Material.IOR);
        refractionRayDir = normalize(mix(refractionRayDir, CosineSampleHemisphere(-hitInfo.Normal), hitInfo.Material.RefractionRoughness * hitInfo.Material.RefractionRoughness));
        ray.Direction = refractionRayDir;
        rayProbability = refractionChance;
        isRefractive = true;
    }
    else
    {
        ray.Direction = diffuseRay;
        rayProbability = 1.0 - specularChance - refractionChance;
    }
    
    ray.Origin = hitInfo.NearHitPos + ray.Direction * EPSILON;
    return max(rayProbability, EPSILON);
}

bool RayTrace(Ray ray, out HitInfo hitInfo)
{
    hitInfo.T = FLOAT_MAX;
    float t1, t2;
    
    for (int i = 0; i < 48; i++)
    {
        vec3 pos = spheres[i].Position;
        float radius = spheres[i].Radius;
        if (RaySphereIntersect(ray, pos, radius, t1, t2) && t2 > 0.0 && t1 < hitInfo.T)
        {
            hitInfo.T = GetSmallestPositive(t1, t2);
            hitInfo.FromInside = hitInfo.T == t2;
            hitInfo.Material = spheres[i].Material;
            hitInfo.NearHitPos = ray.Origin + ray.Direction * hitInfo.T;
            hitInfo.Normal = GetNormal(pos, radius, hitInfo.NearHitPos);
        }
    }
    
    for (int i = 0; i < 7; i++)
    {
        vec3 aabbMin = cuboids[i].Min;
        vec3 aabbMax = cuboids[i].Max;
        if (RayCuboidIntersect(ray, aabbMin, aabbMax, t1, t2) && t2 > 0.0 && t1 < hitInfo.T)
        {
            hitInfo.T = GetSmallestPositive(t1, t2);
            hitInfo.FromInside = hitInfo.T == t2;
            hitInfo.Material = cuboids[i].Material;
            hitInfo.NearHitPos = ray.Origin + ray.Direction * hitInfo.T;
            hitInfo.Normal = GetNormal(aabbMin, aabbMax, hitInfo.NearHitPos);
        }
    }

    return hitInfo.T != FLOAT_MAX;
}

bool RaySphereIntersect(Ray ray, vec3 position, float radius, out float t1, out float t2)
{
    // Source: https://antongerdelan.net/opengl/raycasting.html
    t1 = t2 = FLOAT_MAX;

    vec3 sphereToRay = ray.Origin - position;
    float b = dot(ray.Direction, sphereToRay);
    float c = dot(sphereToRay, sphereToRay) - radius * radius;
    float discriminant = b * b - c;
    if (discriminant < 0.0)
        return false;

    float squareRoot = sqrt(discriminant);
    t1 = -b - squareRoot;
    t2 = -b + squareRoot;

    return true;
}

bool RayCuboidIntersect(Ray ray, vec3 aabbMin, vec3 aabbMax, out float t1, out float t2)
{
    // Source: https://medium.com/@bromanz/another-view-on-the-classic-ray-aabb-intersection-algorithm-for-bvh-traversal-41125138b525
    t1 = FLOAT_MIN;
    t2 = FLOAT_MAX;

    vec3 t0s = (aabbMin - ray.Origin) * (1.0 / ray.Direction);
    vec3 t1s = (aabbMax - ray.Origin) * (1.0 / ray.Direction);

    vec3 tsmaller = min(t0s, t1s);
    vec3 tbigger = max(t0s, t1s);

    t1 = max(t1, max(tsmaller.x, max(tsmaller.y, tsmaller.z)));
    t2 = min(t2, min(tbigger.x, min(tbigger.y, tbigger.z)));
    return t1 <= t2;
}

vec3 CosineSampleHemisphere(vec3 normal)
{
    // Source: https://blog.demofox.org/2020/05/25/casual-shadertoy-path-tracing-1-basic-camera-diffuse-emissive/

    float z = GetRandomFloat01() * 2.0 - 1.0;
    float a = GetRandomFloat01() * 2.0 * PI;
    float r = sqrt(1.0 - z * z);
    float x = r * cos(a);
    float y = r * sin(a);

    // Convert unit vector in sphere to a cosine weighted vector in hemisphere
    return normalize(normal + vec3(x, y, z));
}

vec2 UniformSampleUnitCircle()
{
    float angle = GetRandomFloat01() * 2.0 * PI;
    float r = sqrt(GetRandomFloat01());
    return vec2(cos(angle), sin(angle)) * r;
}

vec3 GetNormal(vec3 spherePos, float radius, vec3 surfacePosition)
{
    return (surfacePosition - spherePos) / radius;
}

vec3 GetNormal(vec3 aabbMin, vec3 aabbMax, vec3 surfacePosition)
{
    // Source: https://gist.github.com/Shtille/1f98c649abeeb7a18c5a56696546d3cf
    // step(edge,x) : x < edge ? 0 : 1

    vec3 halfSize = (aabbMax - aabbMin) * 0.5;
    vec3 centerSurface = surfacePosition - (aabbMax + aabbMin) * 0.5;
    
    vec3 normal = vec3(0.0);
    normal += vec3(sign(centerSurface.x), 0.0, 0.0) * step(abs(abs(centerSurface.x) - halfSize.x), EPSILON);
    normal += vec3(0.0, sign(centerSurface.y), 0.0) * step(abs(abs(centerSurface.y) - halfSize.y), EPSILON);
    normal += vec3(0.0, 0.0, sign(centerSurface.z)) * step(abs(abs(centerSurface.z) - halfSize.z), EPSILON);
    return normalize(normal);
}

uint GetPCGHash(inout uint seed)
{
    seed = seed * 747796405u + 2891336453u;
    uint word = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
    return (word >> 22u) ^ word;
}
 
float GetRandomFloat01()
{
    return float(GetPCGHash(rndSeed)) / 4294967296.0;
}

// Assumes t2 > t1
float GetSmallestPositive(float t1, float t2)
{
    return t1 < 0 ? t2 : t1;
}

Ray GetWorldSpaceRay(mat4 inverseProj, mat4 inverseView, vec3 viewPos, vec2 normalizedDeviceCoords)
{
    vec4 rayEye = inverseProj * vec4(normalizedDeviceCoords.xy, -1.0, 0.0);
    rayEye.zw = vec2(-1.0, 0.0);
    return Ray(viewPos, normalize((inverseView * rayEye).xyz));
}

float FresnelSchlick(float cosTheta, float n1, float n2)
{
    float r0 = (n1 - n2) / (n1 + n2);
    r0 *= r0;
    return r0 + (1.0 - r0) * pow(1.0 - cosTheta, 5.0);
}
