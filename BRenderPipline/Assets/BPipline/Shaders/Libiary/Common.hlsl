#ifndef CUSTOME_COMMON_LIBIARY
#define CUSTOME_COMMON_LIBIARY

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection

#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
    #define SHADOWS_SHADOWMASK
#endif
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

#define GET_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

// #define TRANSFORM_TEX(tex,name) (tex.xy * GET_PROP(name##_ST).xy + GET_PROP(name##_ST).zw)

float DotClamped(float3 a, float3 b)
{
    return saturate(dot(a, b));
}

half DotClamped(half3 a, half3 b)
{
    return saturate(dot(a, b));
}

void ClipLOD(float2 pos_clip, half fade)
{
    #if defined(LOD_FADE_CROSSFADE)
        half dither = InterleavedGradientNoise(pos_clip, 0.0);
        clip(fade + (fade < 0.0 ? dither : -dither));
    #endif
}

#endif