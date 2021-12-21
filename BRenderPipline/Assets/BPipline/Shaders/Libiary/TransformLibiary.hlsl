#ifndef TRANSFORM_LIBIARAY_INCLUDE
#define TRANSFORM_LIBIARAY_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

half3 ObjSpaceViewDir(float4 v )
{
    float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
    return normalize(objSpaceCameraPos - v.xyz);
}

half3 GetTangentSpaceViewDir(half4 tangent, half3 normal, half4 vertex)
{
    half3 binormal = cross(tangent.xyz, normal) * tangent.w;
    float3x3 objToTanMat = float3x3( tangent.xyz, binormal, normal);
    return mul(objToTanMat, ObjSpaceViewDir(vertex));
}

half3 GetWorldSpaceViewDir(float3 pos_world)
{
    return normalize(_WorldSpaceCameraPos - pos_world);
}

half3 UnpackNormalMapScale(half4 normal, half scale)
{
    #if defined(UNITY_NO_DXT5nm)
        return UnpackNormalRGB(normal, scale);
    #else
        return UnpackNormalmapRGorAG(normal, scale);
    #endif
}

half3 BlendNormals(half3 n1, half3 n2)
{
    return normalize(half3(n1.xy + n2.xy, n1.z*n2.z));
}

half3 GetNormalWorldFromMap(v2f i, half4 normal, half normalScale)
{
    i.tangent_world = normalize(i.tangent_world);
    i.normal_world = normalize(i.normal_world);
    i.binormal_world = normalize(i.binormal_world);
    half3 n_tangent = UnpackNormalMapScale(normal, normalScale);
    half3 n = normalize(
        n_tangent.x * i.tangent_world +
        n_tangent.y * i.binormal_world +
        n_tangent.z * i.normal_world
    );
    return n;
}

half3 GetBlendNormalWorldFromMap(v2f i, half4 mainNormal, half4 detilNormal, half mainScale, half detilScale, half detilMask)
{
    i.tangent_world = normalize(i.tangent_world);
    i.normal_world = normalize(i.normal_world);
    i.binormal_world = normalize(i.binormal_world);
    half3 mn = UnpackNormalMapScale(mainNormal, mainScale);
    half3 dn = UnpackNormalMapScale(detilNormal, detilScale);
    half3 n_tangent = lerp(mn, BlendNormals(mn, dn), detilMask);
    half3 n = normalize(
        n_tangent.x * i.tangent_world +
        n_tangent.y * i.binormal_world +
        n_tangent.z * i.normal_world
    );
    return n;
}

#endif