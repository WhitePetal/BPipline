Shader "NoLight/CommonLightMapClip"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1.0, 1.0, 1.0, 1.0) 
        _MainTex ("Albeod(RGB) AO(A)", 2D) = "white" {}
        _NormalTex("NormalMap(RGB)", 2D) = "bump" {}
        [VectorRange(0.0, 2.0, 0.0, 1.0, 0.0, 4.0)]_NormalScale_AO_Brightness("NormalScale_AO_Brightness", Vector) = (1.0, 0.8, 1.0, 2.0)
        _AmbientColor("Ambient Color", Color) = (0.2, 0.2, 0.2, 0.0)
        [VectorRange(0.0, 2.0, 0.0, 2.0)]_PostProcessFactors("辉光强度_辉光阈值", Vector) = (1.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="BShaderDefault"}

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile __ DIRLIGHTMAP_COMBINED 
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            // #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile __ _RECEIVE_SHADOWS
            #pragma multi_compile __ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            // #pragma shader_feature _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
            #pragma multi_compile __ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            #pragma multi_compile __ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
            #pragma vertex vert
            #pragma fragment frag

            #define _NoGISpecular 1
            #define _CommonNoLight 1

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/UnityShadow.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/UnityGI.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                half3 normal : NORMAL;
                #ifdef DIRLIGHTMAP_COMBINED
                half4 tangent : TANGENT;
                #endif

                GI_ATTRIBUTE_DATA
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                half3 normal_world : TEXCOORD1;
                #ifdef DIRLIGHTMAP_COMBINED
                half3 tangent_world : TEXCOORD2;
                half3 binormal_world : TEXCOORD3;
                #endif

                float4 pos_world : TEXCOORD4;
                GI_VARYINGS_DATA
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #ifdef DIRLIGHTMAP_COMBINED
            #include "Assets/BPipline/Shaders/Libiary/TransformLibiary.hlsl"
            #endif

            #include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half3, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half3, _NormalScale_AO_Brightness)
                UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(half2, _PostProcessFactors)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #include "Assets/BPipline/Shaders/Libiary/ShadingFunctions.hlsl"

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                TRANSFER_GI_DATA(v, o);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.pos_world.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.pos_world.w = -TransformWorldToView(o.pos_world).z;

                o.normal_world = TransformObjectToWorldNormal(v.normal);
                #ifdef DIRLIGHTMAP_COMBINED
                o.tangent_world = TransformObjectToWorldDir(v.tangent.xyz);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;
                #endif

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
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                clip(mainTex.a - 0.5);
                half3 albedo = mainTex.rgb * GET_PROP(_BaseColor);

                #ifdef DIRLIGHTMAP_COMBINED
                half3 n = GetNormalWorldFromMap(i, SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv), GET_PROP(_NormalScale_AO_Brightness).x);
                #else
                half3 n = normalize(i.normal_world);
                #endif

                GI gi = GetGI(GI_FRAGMENT_DATA(i), i.pos_world, n, 1.0, GET_PROP(_AmbientColor), 1.0, 0.0);
                half3 col = GetGIShading_Common_NoLight(gi, albedo, 1.0);

                half3 shadowAtten = 1.0;
                for(int lightIndex = 0; lightIndex < _DirectionalLightCount; lightIndex++)
                {
                    shadowAtten *= GetDirectionalShadowAttenuation(lightIndex, gi.shadowMask, i.pos_world.w, i.pos_world.xyz, i.vertex.xy, n);
                }
                col *= shadowAtten * GET_PROP(_NormalScale_AO_Brightness).z;

                FragOutput output;
                output.color = half4(col, 1.0);
                output.flags = half4(EncodeBloomLuminanceImpl(col.rgb, GET_PROP(_PostProcessFactors).x, GET_PROP(_PostProcessFactors).y), 0.0, 0.0, 0.0);
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
                UNITY_DEFINE_INSTANCED_PROP(half3, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half3, _NormalScale_AO_Brightness)
                UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
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
                clip(col.a - 0.5);
                col.rgb *= GET_PROP(_NormalScale_AO_Brightness).z * GET_PROP(_BaseColor);
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
    CustomEditor "CommonLightMapInspector"
}

