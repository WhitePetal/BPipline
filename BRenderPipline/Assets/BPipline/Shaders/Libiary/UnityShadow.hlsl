#ifndef CUSTOME_UNITY_SHADOW_INCLUDE
#define CUSTOME_UNITY_SHADOW_INCLUDE
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"
#include "Assets/BPipline/Shaders/Libiary/UnityLight.hlsl"

#if defined(_DIRECTIONAL_PCF3)
    #define DIRECTIONAL_FILTER_SAMPLES 4
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
    #define DIRECTIONAL_FILTER_SAMPLES 9
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
    #define DIRECTIONAL_FILTER_SAMPLES 16
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowMap);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomeShadow)
    int _CascadeCount;
    float4 _ShadowDistanceFade;
    float4 _ShadowMapSize;
    float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
    float4 _CascadeData[MAX_CASCADE_COUNT];
    float4x4 _DirectionalShadowMatrixs[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
    half3 _ShadowColor;
CBUFFER_END

struct ShadowMask
{
    bool always;
    bool distance;
    float4 shadows;
};

struct ShadowData 
{
	int cascadeIndex;
	half cascadeBlend;
	half strength;
    ShadowMask shadowMask;
};

struct DirectionalShadowData
{
    half strength;
    int tileIndex;
    float normalBias;
    int shadowMaskChannel;
};


half FadedShadowStrength(float distance, float scale, float fade)
{
    return saturate((1.0 - distance * scale) * fade);
}

ShadowData GetShadowData(ShadowMask shadowMask_gi, float depth, float3 pos_world, float2 pos_clip)
{
    ShadowData data;
    data.shadowMask = shadowMask_gi;

    data.cascadeBlend = 1.0;
    data.strength = FadedShadowStrength(depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    int i;
    for(i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSpheres[i];
        float3 dstVec = pos_world - sphere.xyz;
        float dstSqr = dot(dstVec, dstVec);
        if(dstSqr < sphere.w)
        {
            float fade = FadedShadowStrength(dstSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
            if(i == _CascadeCount - 1)
            {
                data.strength *= fade;
            }
            else
            {
                data.cascadeBlend = fade;
            }
            break;
        }
    }

    half dither = InterleavedGradientNoise(pos_clip, 0);

    if(i == _CascadeCount && _CascadeCount > 0) data.strength = 0.0;
    #if defined(_CASCADE_BLEND_DITHER)
        else if(data.cascadeBlend < dither) i += 1;
    #endif
    #if !defined(_CASCADE_BLEND_SOFT)
        data.cascadeBlend = 1.0;
    #endif
    data.cascadeIndex = i;
    return data;
}

float SampleDirectionalShadowMap(float3 shadowcoord)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowMap, SHADOW_SAMPLER, shadowcoord);
}

half FilterDirectionalShadow(float3 shadowcoord)
{
    #if defined(DIRECTIONAL_FILTER_SETUP)
        // 在桌面端 weights 和 positions 需要为 float  OpenGLES3.x 则要求必须是 half
        real weights[DIRECTIONAL_FILTER_SAMPLES];
        real2 positions[DIRECTIONAL_FILTER_SAMPLES];
        float4 size = _ShadowMapSize.yyxx;
        DIRECTIONAL_FILTER_SETUP(size, shadowcoord.xy, weights, positions);
        float shadow = 0;
        for(int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; i++)
        {
            shadow += weights[i] * SampleDirectionalShadowMap(float3(positions[i].xy, shadowcoord.z));
        }
        return shadow;
    #else
        return SampleDirectionalShadowMap(shadowcoord);
    #endif
}

half GetBakedShadow(ShadowMask mask, int channel)
{
    half shadow = 1.0;
    if(mask.always || mask.distance)
    {
        if(channel >= 0) shadow = mask.shadows[channel];
    }
    return shadow;
}

half GetBakedShadow(ShadowMask mask, int channel, half strength)
{
    if(mask.always || mask.distance)
    {
        return lerp(1.0, GetBakedShadow(mask, channel), strength);
    }
    return 1.0;
}

half3 MixBakedAndRealtimeShadows(ShadowData shadowData, half shadow, int shadowMaskChannel, half strength)
{
    half baked = GetBakedShadow(shadowData.shadowMask, shadowMaskChannel);
    if(shadowData.shadowMask.always)
    {
        shadow = lerp(1.0, shadow, shadowData.strength);
        shadow = min(baked, shadow);
        half3 shadowCol = lerp(_ShadowColor, 1.0, shadow);
        return lerp(1.0, shadowCol, strength);
    }
    if(shadowData.shadowMask.distance)
    {
        shadow = lerp(baked, shadow, shadowData.strength);
        half3 shadowCol = lerp(_ShadowColor, 1.0, shadow);
        return lerp(1.0, shadowCol, strength);
    }

    half3 shadowCol = lerp(_ShadowColor, 1.0, shadow);
    return lerp(1.0, shadowCol, strength * shadowData.strength);
}

half3 GetDirectionalShadowAttenuation(int lightIndex, ShadowMask shadowMask, float depth, float3 pos_world, float2 pos_clip, half3 normal_world)
{
    #if !defined(_RECEIVE_SHADOWS)
        return 1.0;
    #endif
    half3 shadowCol;

    ShadowData shadowData = GetShadowData(shadowMask, depth, pos_world, pos_clip);
    DirectionalShadowData dirShadowData;
    dirShadowData.strength = _DirectionalLightShadowDatas[lightIndex].x;
    dirShadowData.shadowMaskChannel = _DirectionalLightShadowDatas[lightIndex].w;
    if(dirShadowData.strength * shadowData.strength <= 0.0)
    {
        half shadow = GetBakedShadow(shadowData.shadowMask, dirShadowData.shadowMaskChannel, abs(dirShadowData.strength));
        shadowCol = lerp(_ShadowColor, 1.0, shadow);
    }
    else
    {
        dirShadowData.tileIndex = _DirectionalLightShadowDatas[lightIndex].y + shadowData.cascadeIndex;
        dirShadowData.normalBias = _DirectionalLightShadowDatas[lightIndex].z;
        float3 normalBias = normal_world * dirShadowData.normalBias * _CascadeData[shadowData.cascadeIndex].y;
        float3 shadowcoord = mul(_DirectionalShadowMatrixs[dirShadowData.tileIndex], float4(pos_world + normalBias, 1.0)).xyz;
        half shadow = FilterDirectionalShadow(shadowcoord);
        if(shadowData.cascadeBlend < 1.0)
        {
            normalBias = normal_world * dirShadowData.normalBias * _CascadeData[shadowData.cascadeIndex + 1].y;
            shadowcoord =  mul(_DirectionalShadowMatrixs[dirShadowData.tileIndex + 1], float4(pos_world + normalBias, 1.0)).xyz;
            shadow = lerp(FilterDirectionalShadow(shadowcoord), shadow, shadowData.cascadeBlend);
        }
        
        shadowCol = MixBakedAndRealtimeShadows(shadowData, shadow, dirShadowData.shadowMaskChannel, dirShadowData.strength);
        // shadow = lerp(1.0, shadow, dirShadowData.strength);
    }
    
    return shadowCol;
}

struct OtherLightShadowData
{
    half strength;
    int shadowMaskChannel;
};

half3 GetOtherLightShadowAttenuation(int lightIndex, ShadowData shadowData)
{
    #if !defined(_RECEIVE_SHADOWS)
        return 1.0;
    #endif
    OtherLightShadowData data;
    data.strength = _OtherLightShadowDatas[lightIndex].x;
    data.shadowMaskChannel = _OtherLightShadowDatas[lightIndex].w;
    half shadow;
    if(data.strength * shadowData.strength <= 0.0)
    {
        shadow = GetBakedShadow(shadowData.shadowMask, data.shadowMaskChannel, data.strength);
    }
    else
    {
        shadow = 1.0;
        // shadow = MixBakedAndRealtimeShadows(shadowData, shadow, data.shadowMaskChannel, data.strength);
    }
    return lerp(_ShadowColor, 1.0, shadow);
}

#endif