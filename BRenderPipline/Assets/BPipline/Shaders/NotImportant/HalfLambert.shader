Shader "Lit/HalfLambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("Normal Tex", 2D) = "bump" {}
        _MGATex("Metallic(R) Gloss(G) AO(B)", 2D) = "white" {}
        _DiffuseColor("Diffuse Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularColor("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [VectorRange(0.0, 1.0, 0.0, 2.0, 0.0, 1.0, 0.0, 1.0)]_Metallic_NormalScale_SH_Gloss("金属度_法线强度_SHStrength_Gloss", Vector) = (0.0, 1.0, 0.8, 0.5)
        [VectorRange(0.31830989, 8, 0.25, 8, 0.0, 1.0, 0.0, 300.0)]_KdKsExpoureGlossBase("漫反射强度_镜面反射强度_曝光强度_高光系数", Vector) = (1.0, 1.0, 0.0, 100.0)
        _AO("AO", Range(0.0, 1.0)) = 1.0
        _AmbientColor("Ambient Color", Color) = (0.2, 0.2, 0.2, 0.0)
        [VectorRange(0.0, 2.0, 0.0, 2.0)]_PostProcessFactors("辉光强度_辉光阈值", Vector) = (1.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="BShaderDefault"}

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile __ _LIGHTS_PER_OBJECT
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            // #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile __ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            // #pragma shader_feature _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
            #pragma multi_compile __ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            #pragma multi_compile __ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
            #pragma multi_compile __ _RECEIVE_SHADOWS
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/UnityShadow.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/UnityGI.hlsl"

            #define _HalfLambert 1

            struct appdata
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                half3 normal_world : TEXCOORD1;
                half3 tangent_world : TEXCOORD2;
                half3 binormal_world : TEXCOORD3;
                float4 pos_world : TEXCOORD4;
                GI_VARYINGS_DATA
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #include "Assets/BPipline/Shaders/Libiary/TransformLibiary.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_MGATex);
            SAMPLER(sampler_MGATex);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half4, _KdKsExpoureGlossBase)
                UNITY_DEFINE_INSTANCED_PROP(half3, _SpecularColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _DiffuseColor)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Metallic_NormalScale_SH_Gloss)
                UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(half, _AO)
                UNITY_DEFINE_INSTANCED_PROP(half2, _PostProcessFactors)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #include "Assets/BPipline/Shaders/Libiary/ShadingFunctions.hlsl"

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                TRANSFER_GI_DATA(v, o);

                o.pos_world.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.pos_world.w = -TransformWorldToView(o.pos_world).z;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.normal_world = TransformObjectToWorldNormal(v.normal);
                o.tangent_world = TransformObjectToWorldDir(v.tangent.xyz);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;
                return o;
            }

            struct FragOutput
            {
                half4 color : SV_TARGET0;
                half4 flags : SV_TARGET1;
            };

            FragOutput frag (v2f i)
            {                
                UNITY_SETUP_INSTANCE_ID(i);
                ClipLOD(i.vertex.xy, unity_LODFade);
                ShadingParams shadingParams;
                shadingParams.pos_world = i.pos_world.xyz;
                shadingParams.pos_clip = i.vertex;
                shadingParams.depth = i.pos_world.w;
                shadingParams.expoure = GET_PROP(_KdKsExpoureGlossBase.z);

                half3 MGA = SAMPLE_TEXTURE2D(_MGATex, sampler_MGATex, i.uv).rgb;
                half metallic = MGA.r * GET_PROP(_Metallic_NormalScale_SH_Gloss).x;
                half gloss = MGA.g * GET_PROP(_Metallic_NormalScale_SH_Gloss).w;
                half ao = saturate(1.0 - (1.0 - MGA.b) * GET_PROP(_AO));

                shadingParams.gloss_glossBase = half2(gloss, GET_PROP(_KdKsExpoureGlossBase).w);
                shadingParams.albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * GET_PROP(_DiffuseColor) * GET_PROP(_KdKsExpoureGlossBase).x;
                shadingParams.specular = lerp(_SpecularColor, shadingParams.albedo, metallic) * GET_PROP(_KdKsExpoureGlossBase).y;

                shadingParams.n = GetNormalWorldFromMap(i, SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv), GET_PROP(_Metallic_NormalScale_SH_Gloss).y);
                shadingParams.v = GetWorldSpaceViewDir(i.pos_world.xyz);

                shadingParams.gi = GetGI(GI_FRAGMENT_DATA(i), shadingParams.pos_world, shadingParams.n, shadingParams.v, GET_PROP(_AmbientColor), 1.0, GET_PROP(_Metallic_NormalScale_SH_Gloss).z);

                half3 col = 0.0;
                for(int lightIndex = 0; lightIndex < _DirectionalLightCount; lightIndex++)
                {
                    shadingParams.lightIndex = lightIndex;
                    col += Half_Lambert_DirLight(shadingParams);
                }
                #if defined(_LIGHTS_PER_OBJECT)
                    for(int j = 0; j < min(unity_LightData.y, 8.0); j++)
                    {
                        int lightIndex = unity_LightIndices[(uint)j / 4][(uint)j % 4]; // 无符号数的除法和取模会更快
                        shadingParams.lightIndex = lightIndex;
                        col += Half_Lambert_DirLight(shadingParams);
                    }
                #else
                    for(int lightIndex = 0; lightIndex < _OtherLightCount; lightIndex++)
                    {
                        shadingParams.lightIndex = lightIndex;
                        col += Half_Lambert_DirLight(shadingParams);
                    }
                #endif

                col += GetGIShading_Half_Lambert(shadingParams, ao);

                FragOutput output;
                output.color = half4(col, 1.0);
                output.flags = half4(EncodeBloomLuminanceImpl(col.rgb, GET_PROP(_PostProcessFactors).x, GET_PROP(_PostProcessFactors).y), EncodeFloatRG(i.pos_world.w / _ProjectionParams.z), 0.0);
                return output;
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode"="ShadowCaster"}
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertex = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
                #if UNITY_REVERSED_Z
                    o.vertex.z = min(o.vertex.z, o.vertex.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.vertex.z = max(o.vertex.z, o.vertex.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return 0.0;
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode"="Meta"}
            Cull Off
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half4, _KdKsExpoureGlossBase)
                UNITY_DEFINE_INSTANCED_PROP(half3, _SpecularColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _DiffuseColor)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Metallic_NormalScale_SH_Gloss)
                UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(half, _AO)
                UNITY_DEFINE_INSTANCED_PROP(half2, _PostProcessFactors)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            bool4 unity_MetaFragmentControl;
            float unity_OneOverOutputBoost;
            float unity_MaxOutputValue;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                float2 lightMapUV : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                v.vertex.xy = v.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                v.vertex.z = v.vertex.z > 0.0 ? FLT_MIN : 0.0;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                col.rgb *= GET_PROP(_DiffuseColor).rgb;
                float4 meta = 0.0;
                if(unity_MetaFragmentControl.x)
                {
                    meta = col;
                    // meta.rgb += specular * roughness * 0.5
                    meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
                }
                else if(unity_MetaFragmentControl.y)
                {
                    // emission
                }
                meta.a = 1.0;
                return meta;
            }
            ENDHLSL
        }
    }
}
