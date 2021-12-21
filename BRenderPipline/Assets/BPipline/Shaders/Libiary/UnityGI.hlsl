#ifndef CUSTOME_UNITY_GI_INCLUDE
#define CUSTOME_UNITY_GI_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Assets/BPipline/Shaders/Libiary/UnityInput.hlsl"

#if defined(LIGHTMAP_ON)
TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);
#endif

#if defined(DIRLIGHTMAP_COMBINED)
TEXTURE2D(unity_LightmapInd);
SAMPLER(samplerunity_LightmapInd);
#endif

#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);
#endif

#ifndef LIGHTMAP_ON
TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
SAMPLER(samplerunity_ProbeVolumeSH);
#endif

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

#if defined(LIGHTMAP_ON)
    #define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
    #define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
    #define TRANSFER_GI_DATA(input, output) output.lightMapUV = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    #define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
    #define GI_ATTRIBUTE_DATA
    #define GI_VARYINGS_DATA
    #define TRANSFER_GI_DATA(input, output)
    #define GI_FRAGMENT_DATA(input) 0.0
#endif

struct GI
{
    half3 diffuse;
    half3 specular;
    ShadowMask shadowMask;
};

half3 SampleLightMap(float2 lightMapUV, half3 n)
{
    #if defined(LIGHTMAP_ON)
        #if defined(DIRLIGHTMAP_COMBINED)
            return SampleDirectionalLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), TEXTURE2D_ARGS(unity_LightmapInd, samplerunity_LightmapInd),
                lightMapUV, float4(1.0, 1.0, 0.0, 0.0), n,
                #if defined(UNITY_LIGHTMAP_FULL_HDR)
                    false,
                #else
                    true,
                #endif
                float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0));
        #else
            return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightMapUV, float4(1.0, 1.0, 0.0, 0.0),
                #if defined(UNITY_LIGHTMAP_FULL_HDR)
                    false,
                #else
                    true,
                #endif
                float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0));
        #endif
    #else
        return 0.0;
    #endif
}

half3 SampleLightProb(float3 pos_world, half3 normal_world)
{
    #if defined(LIGHTMAP_ON)
        return 0.0;
    #else
        if(unity_ProbeVolumeParams.x)
        {
            return SampleProbeVolumeSH4(
                TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
                pos_world, normal_world,
                unity_ProbeVolumeWorldToObject,
                unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.y,
                unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
            );
        }
        else
        {
            float4 coefficients[7];
            coefficients[0] = unity_SHAr;
            coefficients[1] = unity_SHAg;
            coefficients[2] = unity_SHAb;
            coefficients[3] = unity_SHBr;
            coefficients[4] = unity_SHBg;
            coefficients[5] = unity_SHBb;
            coefficients[6] = unity_SHC;
            return max(0.0, SampleSH9(coefficients, normal_world));
        }
    #endif
}

half4 SampleBakedShadows(float2 lightMapUV, float3 pos_world)
{
    #if defined(LIGHTMAP_ON)
        #if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
            return SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_ShadowMask, lightMapUV);
        #else
            return unity_ProbesOcclusion;
        #endif
    #else
        if(unity_ProbeVolumeParams.x)
        {
            return SampleProbeOcclusion(TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
            pos_world, unity_ProbeVolumeWorldToObject,
            unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
            unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz);
        }
        else
        {
            return unity_ProbesOcclusion;
        }
    #endif
}

half3 SampleEnvironment(half3 view_inver_world, half3 normal_world, half roughness)
{
    half3 uvw = reflect(view_inver_world, normal_world);
    half4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, roughness * 8.0);
    return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

GI GetGI(float2 lightMapUV, float3 pos_world, half3 normal_world, half3 view_inver_world, half3 ambientCol, half roughness, half sh)
{
    GI gi;
    gi.diffuse = SampleLightMap(lightMapUV, normal_world) + SampleLightProb(pos_world, normal_world) * sh + ambientCol;
    #if _NoGISpecular
    gi.specular = 0.0;
    #else
    gi.specular = SampleEnvironment(view_inver_world, normal_world, roughness) / (1.0 + roughness * roughness);
    #endif
    gi.shadowMask.always = false;
    gi.shadowMask.distance = false;
    gi.shadowMask.shadows = 1.0;

    #if defined(_SHADOW_MASK_ALWAYS)
        gi.shadowMask.always = true;
        gi.shadowMask.shadows = SampleBakedShadows(lightMapUV, pos_world);
    #elif defined(_SHADOW_MASK_DISTANCE)
        gi.shadowMask.distance = true;
        gi.shadowMask.shadows = SampleBakedShadows(lightMapUV, pos_world);
    #endif
    return gi;
}

#endif