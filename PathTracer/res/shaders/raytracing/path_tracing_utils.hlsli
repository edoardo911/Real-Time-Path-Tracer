#define DIRECTIONAL_LIGHT_DISTANCE 60

#define PI 3.14159265

/*
    Random number generator from ZijingPeng on GitHub
    https://github.com/ZijingPeng/DXR-Hybrid-Rendering/blob/main/CommonPasses/Data/CommonPasses/thinLensUtils.hlsli
*/
uint initRand(uint val0, uint val1, uint backoff = 16)
{
    uint v0 = val0, v1 = val1, s0 = 0;

    [unroll]
    for(uint n = 0; n < backoff; n++)
    {
        s0 += 0x9e3779b9;
        v0 += ((v1 << 4) + 0xa341316c) ^ (v1 + s0) ^ ((v1 >> 5) + 0xc8013ea4);
        v1 += ((v0 << 4) + 0xad90777d) ^ (v0 + s0) ^ ((v0 >> 5) + 0x7e95761e);
    }
    return v0;
}

float nextRand(inout uint s)
{
    s = (1664525u * s + 1013904223u);
    return float(s & 0x00FFFFFF) / float(0x01000000);
}

float3 randomDirectionCube(uint seed)
{
    return normalize(float3(nextRand(seed), nextRand(seed), nextRand(seed)) * 2.0F - 1.0F);
}

float3 cosWeight(Texture2D blueNoise, uint2 pos, float3 normal, float power)
{
    float2 u = blueNoise[pos].xy;
    
    float cosTheta = pow(u.x, 1.0 / (power + 1.0));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
    float phi = 2.0 * PI * u.y;

    float x = sinTheta * cos(phi);
    float y = sinTheta * sin(phi);
    float z = cosTheta;

    float3 up = abs(normal.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 tangent = normalize(cross(up, normal));
    float3 bitangent = cross(normal, tangent);

    return normalize(x * tangent + y * bitangent + z * normal);
}

float3 VNDF(float3 rayDir, float3 normal, float roughness, Texture2D blueNoise, uint2 pos)
{
    float alpha = roughness * roughness;
    float2 u = blueNoise[pos].xy;
    
    float3 up = abs(normal.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 T = normalize(cross(up, normal));
    float3 B = cross(normal, T);
    
    float3 Vh = normalize(float3(alpha * dot(rayDir, T), alpha * dot(rayDir, B), dot(rayDir, normal)));
    
    float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
    float3 T1 = lensq > 0.0 ? float3(-Vh.y, Vh.x, 0.0) / sqrt(lensq) : float3(1, 0, 0);
    float3 T2 = cross(Vh, T1);
    
    float r = sqrt(u.x);
    float phi = 2.0 * PI * u.y;
    float t1 = r * cos(phi);
    float t2 = r * sin(phi);
    float s = 0.5 * (1.0 + Vh.z);
    t2 = (1.0 - s) * sqrt(1.0 - t1 * t1) + s * t2;
    
    float3 Nh = t1 * T1 + t2 * T2 + sqrt(max(1.0 - t1 * t1 - t2 * t2, 0.0)) * Vh;
    
    float3 m = normalize(float3(alpha * Nh.x, alpha * Nh.y, max(Nh.z, 0.0)));
    return normalize(T * m.x + B * m.y + normal * m.z);
}

float3 VNDF(float3 rayDir, float3 normal, float roughness, float2 u)
{
    float alpha = roughness * roughness;
    
    float3 up = abs(normal.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 T = normalize(cross(up, normal));
    float3 B = cross(normal, T);
    
    float3 Vh = normalize(float3(alpha * dot(rayDir, T), alpha * dot(rayDir, B), dot(rayDir, normal)));
    
    float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
    float3 T1 = lensq > 0.0 ? float3(-Vh.y, Vh.x, 0.0) / sqrt(lensq) : float3(1, 0, 0);
    float3 T2 = cross(Vh, T1);
    
    float r = sqrt(u.x);
    float phi = 2.0 * PI * u.y;
    float t1 = r * cos(phi);
    float t2 = r * sin(phi);
    float s = 0.5 * (1.0 + Vh.z);
    t2 = (1.0 - s) * sqrt(1.0 - t1 * t1) + s * t2;
    
    float3 Nh = t1 * T1 + t2 * T2 + sqrt(max(1.0 - t1 * t1 - t2 * t2, 0.0)) * Vh;
    
    float3 m = normalize(float3(alpha * Nh.x, alpha * Nh.y, max(Nh.z, 0.0)));
    return normalize(T * m.x + B * m.y + normal * m.z);
}

//disk sampling
float3 calcShadowDirectionDL(float3 lightDir, float lightRadius, float2 xi)
{
    float r = lightRadius * sqrt(xi.x);
    float theta = 2.0 * PI * xi.y;
    
    float2 disk = r * float2(cos(theta), sin(theta));
    
    float3 up = abs(lightDir.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 tangent = normalize(cross(up, lightDir));
    float3 bitangent = cross(lightDir, tangent);
    return normalize(lightDir + disk.x * tangent + disk.y * bitangent);
}

//sphere sampling
float3 calcShadowDirectionPL(float3 worldOrigin, float3 lightPos, float lightRadius, float2 xi)
{
    float z = 1.0 - 2.0 * xi.x;
    float r = sqrt(max(0.0, 1.0 - z * z));
    float phi = 2.0 * PI * xi.y;
    
    float3 targetPos = lightPos + float3(r * cos(phi), r * sin(phi), z) * lightRadius;
    return targetPos - worldOrigin;
}

//hemisphere sampling
float3 calcShadowDirectionSL(float3 worldOrigin, float3 lightPos, float3 lightDir, float lightRadius, float2 xi)
{
    float z = 1.0 - xi.x;
    float r = sqrt(max(0.0, 1.0 - z * z));
    float phi = 2.0 * PI * xi.y;
    
    float3 localPos = float3(r * cos(phi), r * sin(phi), z) * lightRadius;
    
    float3 up = abs(lightDir.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 tangent = normalize(cross(up, lightDir));
    float3 bitangent = cross(lightDir, tangent);
    
    float3 targetPos = lightPos + tangent * localPos.x + bitangent * localPos.y + lightDir * localPos.z;
    return targetPos - worldOrigin;
}