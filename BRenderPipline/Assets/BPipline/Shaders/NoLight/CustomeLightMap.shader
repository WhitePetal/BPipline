Shader "NoLight/CustomeLightMap"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Albedo(RGB) A(AO)", 2D) = "white" {}
        _NormalTex("Normal Map", 2D) = "bump"{}
        [VectorRange(0.0, 2.0, 0.0, 1.0, 0.0, 4.0)]_NormalScale_AO_Brightness("NormalScale_AO_Brightness", Vector) = (1.0, 0.8, 1.0, 2.0)
        _LightMap("Light Map", 2D) = "white" {}
        _DirLightMap("DirLightMap", 2D) = "white" {}
        _ShadowMaskMap("ShadowMaskMap", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="BShaderDefault"}

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile_local __ _UseDirLightMap
            #pragma multi_compile_local __ _UseShadowMaskMap
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                half3 normal : NORMAL;
                #ifdef _UseDirLightMap
                half4 tangent : TANGENT;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 lightmapUV :TEXCOORD1;
                half3 normal_world : TEXCOORD2;
                #ifdef _UseDirLightMap
                half3 tangent_world : TEXCOORD2;
                half3 binormal_world : TEXCOORD3;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);

            #ifdef _UseDirLightMap
            TEXTURE2D(_DirLightMap)
            SAMPLER(sampler_DirLightMap)
            #endif

            #ifdef _UseShadowMaskMap
            TEXTURE2D(_ShadowMaskMap)
            SAMPLER(sampler_ShadowMaskMap)
            #endif

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(half3, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half3, _NormalScale_AO_Brightness)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #ifdef _UseDirLightMap
            #include "Assets/BPipline/Shaders/Libiary/TransformLibiary.hlsl"
            #endif

            #include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.normal_world = TransformObjectToWorldNormal(v.normal);
                #ifdef _UseDirLightMap
                o.tangent_world = TransformObjectToWorldDir(v.tangent.xyz);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;
                #endif
                o.uv = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.lightmapUV = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                ClipLOD(i.vertex.xy, unity_LODFade);

                #ifdef DIRLIGHTMAP_COMBINED
                half3 n = GetNormalWorldFromMap(i, SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv), GET_PROP(_NormalScale_AO_Brightness).x);
                #else
                half3 n = normalize(i.normal_world);
                #endif

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                col.rgb *= SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.lightmapUV) * GET_PROP(_BaseColor) * col.a;

                #ifdef _DirLightMap
                half3 l = SAMPLE_TEXTURE2D(_DirLightMap, sampler_DirLightMap, i.lightmapUV).rgb;
                half ndotl = dot(n, l - 0.5) + 0.5;
                col.rgb *= ndotl / max(1e-4, direction.w);
                #endif

                #ifdef _UseShadowMaskMap
                col.rgb *= SAMPLE_TEXTURE2D(_ShadowMaskMap, sampler_ShadowMaskMap, i.lightmapUV).r;
                #endif

                return half4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "CustomeLightMapInspector"
}
