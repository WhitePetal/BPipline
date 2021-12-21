#ifndef FUR_LIBIARY_INCLUDE
#define FUR_LIBIARY_INCLUDE

#define _NoGISpecular 1

#include "Assets/BPipline/Shaders/Libiary/Common.hlsl"
#include "Assets/BPipline/Shaders/Libiary/UnityShadow.hlsl"
#include "Assets/BPipline/Shaders/Libiary/UnityGI.hlsl"

struct a2v
{
    float4 vertex : POSITION;
    half3 normal : NORMAL;
    half4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    GI_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 uvs : TEXCOORD0;
    float4 pos_world : TEXCOORD1;
    half3 normal_world : TEXCOORD2;
    half3 tangent_world : TEXCOORD3;
    half3 binormal_world : TEXCOORD4;
    GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
TEXTURE2D(_FurShapeTex); // R: FurShape ... G: BaseShape
SAMPLER(sampler_FurShapeTex);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    UNITY_DEFINE_INSTANCED_PROP(half3, _DiffuseColor)
    UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _FurShapeTex_ST)
    UNITY_DEFINE_INSTANCED_PROP(half4, _AO_AoOffset_LightFilter_LightExposure)
    UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
    UNITY_DEFINE_INSTANCED_PROP(half3, _FresnelStrength_FresnelRange_SHStrength)
    UNITY_DEFINE_INSTANCED_PROP(half3, _SpecCol1)
    UNITY_DEFINE_INSTANCED_PROP(half3, _SpecCol2)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SpecExp)
    UNITY_DEFINE_INSTANCED_PROP(half, _SpecStrength)

    UNITY_DEFINE_INSTANCED_PROP(half3, _FurBaseOffset_FurOfsset_FurLength)
    UNITY_DEFINE_INSTANCED_PROP(half3, _GravityDir)
    UNITY_DEFINE_INSTANCED_PROP(half, _GravityScale)
    UNITY_DEFINE_INSTANCED_PROP(half3, _WindDir)
    UNITY_DEFINE_INSTANCED_PROP(half3, _WindScale_WindFresquency_WindPhase)

    UNITY_DEFINE_INSTANCED_PROP(half3, _PostProcessFactors)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"
#include "Assets/BPipline/Shaders/Libiary/TransformLibiary.hlsl"

v2f vert_fur(a2v v, half fur_offset)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    TRANSFER_GI_DATA(v, o);
    o.pos_world.xyz = TransformObjectToWorld(v.vertex.xyz);
    o.normal_world = TransformObjectToWorldNormal(v.normal);
    o.tangent_world = TransformObjectToWorldDir(v.tangent.xyz);
    o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;

    half3 dir = o.normal_world;
    half3 dir_t = dir * GET_PROP(_FurBaseOffset_FurOfsset_FurLength).y * fur_offset;
    #ifdef GRAVITY_ON
        half3 add_dir = normalize(GET_PROP(_GravityDir)) * GET_PROP(_GravityScale);
        half3 target = dir_t + add_dir;
        dir += abs(dot(dir_t, target)) * add_dir;
    #endif
    #ifdef WIND_ON
        half3 add_dir_wind = normalize(GET_PROP(_WindDir));
        add_dir_wind = add_dir_wind * wind_wave(GET_PROP(_WindScale_WindFresquency_WindPhase).x, GET_PROP(_WindScale_WindFresquency_WindPhase).y, 
        add_dir_wind, o.pos_world.xyz * GET_PROP(_WindScale_WindFresquency_WindPhase).z);
        half3 target_wind = dir_t + add_dir_wind;
        dir += abs(dot(dir_t, target_wind)) * add_dir_wind;
    #endif
    o.pos_world.xyz += normalize(dir) * GET_PROP(_FurBaseOffset_FurOfsset_FurLength).y * fur_offset;

    o.pos_world.w = -TransformWorldToView(o.pos_world.xyz).z;
    o.pos = TransformWorldToHClip(o.pos_world.xyz);
    o.uvs.xy = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
    o.uvs.zw = v.uv * GET_PROP(_FurShapeTex_ST).xy + GET_PROP(_FurShapeTex_ST).zw;
    return o;
}

half3 TShift(half3 tangent, half3 normal, half shift){
    return normalize(tangent + shift * normal);
}
half StrandSpecular(half tdoth, half exponent)
{
    half sqrtTdotH = sqrt(max(0.01, 1.0 - tdoth * tdoth));
    half dirAtten = smoothstep(-1.0 ,0.0 ,tdoth);    
    return dirAtten * pow(sqrtTdotH,exponent);
}

struct FragOutput
{
    half4 color : SV_TARGET0;
    half4 flags : SV_TARGET1;
};

FragOutput frag_fur(v2f i, half fur_offset)
{  
    UNITY_SETUP_INSTANCE_ID(i);
    half baseShape = SAMPLE_TEXTURE2D(_FurShapeTex, sampler_FurShapeTex, i.uvs.xy).g + GET_PROP(_FurBaseOffset_FurOfsset_FurLength).x;
    half furShape = SAMPLE_TEXTURE2D(_FurShapeTex, sampler_FurShapeTex, i.uvs.zw).r * GET_PROP(_FurBaseOffset_FurOfsset_FurLength).z * baseShape;
    half shape = saturate(furShape + baseShape - 1.0);
    half layer = fur_offset * fur_offset;
    shape = step(layer, shape) * (1.0 - layer);
    half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uvs.xy).rgb * GET_PROP(_DiffuseColor);

    half3 v = GetWorldSpaceViewDir(i.pos_world.xyz);
    GI gi = GetGI(GI_FRAGMENT_DATA(i), i.pos_world.xyz, i.normal_world, v, GET_PROP(_AmbientColor), 1.0, GET_PROP(_FresnelStrength_FresnelRange_SHStrength).z);
    half ndotv = DotClamped(i.normal_world, v);
    half3 fresenel = albedo * pow(1.0 - ndotv, GET_PROP(_FresnelStrength_FresnelRange_SHStrength).y * 10) * GET_PROP(_FresnelStrength_FresnelRange_SHStrength).x;
    
    half3 t1 = TShift(-i.binormal_world, i.normal_world, GET_PROP(_SpecExp).x + shape);
    half3 t2 = TShift(-i.binormal_world, i.normal_world, GET_PROP(_SpecExp).y + shape);
    half3 specCol1 = GET_PROP(_SpecCol1) * GET_PROP(_SpecStrength);
    half3 specCol2 = GET_PROP(_SpecCol2) * albedo * GET_PROP(_SpecStrength);


    half3 col = 0.0;
    // dir light
    for(int lightIndex = 0; lightIndex < _DirectionalLightCount; lightIndex++)
    {
        half3 l = _DirectionalLightDirections[lightIndex];
        half3 h = normalize(l + v);

        half ndotl = DotClamped(i.normal_world, l) + GET_PROP(_AO_AoOffset_LightFilter_LightExposure).w;
        half tdoth1 = dot(t1, h);
        half tdoth2 = dot(t2, h);

        col += (albedo + fresenel) * ndotl + specCol1 * StrandSpecular(tdoth1, GET_PROP(_SpecExp).z) +  specCol2 * StrandSpecular(tdoth2, GET_PROP(_SpecExp).w);
    }

    half ao = pow(saturate(fur_offset + GET_PROP(_AO_AoOffset_LightFilter_LightExposure).y), GET_PROP(_AO_AoOffset_LightFilter_LightExposure).x);
    col = (col + gi.diffuse) * ao * GET_PROP(_AO_AoOffset_LightFilter_LightExposure).z;
    FragOutput output;
    output.color = half4(col, shape);
    output.flags = half4(0.0, 0.0, 0.0, 0.0);
    return output;
}

#endif