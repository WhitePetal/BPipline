Shader "Other/Fur"
{
    Properties
    {
        _DiffuseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Texture", 2D) = "white" {}
        _FurShapeTex("R(FurShape) G(BaseShape)", 2D) = "black" {}
        [VectorRange(0.0, 2.0, 0.0, 2.0, 0.0, 4.0)]_FurBaseOffset_FurOfsset_FurLength("毛发粗细_毛发空隙偏移_毛发长度", Vector) = (0.0, 0.1, 1.0)
        _SpecCol1("一号高光颜色", Color) = (0.5, 0.5, 0.5, 1.0)
        _SpecCol2("二号高光颜色", Color) = (0.5, 0.5, 0.5, 1.0)
        [VectorRange(0.0, 8.0, 1.0, 8.0, 0.0, 8.0, 1.0, 8.0, 1.0, 0.0, 1.0, 600.0, 1.0, 0.0, 1.0, 600.0)]_SpecExp("一号高光偏移_二号高光偏移_一号高光宽窄_二号高光宽窄", Vector) = (-0.88, -1, 300, 300.0)
        _SpecStrength("高光强度", Range(0.0, 2.0)) = 1.0
        [VectorRange(0.0, 4.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)]_AO_AoOffset_LightFilter_LightExposure("AO_AoOffset_光照强度_暗部曝光", Vector) = (1.0, 0.1, 1.0, 0.2)
        _AmbientColor("环境光", Color) = (0.2, 0.2, 0.2, 1.0)
        [VectorRange(0.0, 2.0, 0.0, 1.0, 0.0, 1.0)]_FresnelStrength_FresnelRange_SHStrength("边缘光强度_边缘光范围_球协强度", Vector) = (1.0, 0.5, 0.0, 0.0)
        _GravityDir("重力方向", Vector) = (0.0, -1.0, 0.0, 0.0)
        _GravityScale("重力大小", Range(-20.0, 20.0)) = 1.0
        _WindDir("风力方向", Vector) = (1.0, -1.0, 0.5, 0.0)
        [VectorRange(0.0, 2.0, 1.0, 2.0, 1.0, 0.0, 1.0, 20.0, 0.0, 20.0, 1.0, 20.0, 0.0, 0.0, 0.0, 0.0)]_WindScale_WindFresquency_WindPhase("风力大小_风频率_坐标相位偏差大小", Vector) = (1.0, 2.0, 10.0, 0.0)
        [VectorRange(0.0, 16.0, 0.0, 16.0, 0.0, 1.0)]_PostProcessFactors("辉光强度_辉光阈值_马赛克", Vector) = (0.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }

        ZWrite Off
        HLSLINCLUDE
        #pragma multi_compile_local __ GRAVITY_ON
        #pragma multi_compile_local __ WIND_ON
        ENDHLSL

        Pass
        {
            Tags {"LightMode"="BMultiPass0"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert(a2v v) {return vert_fur(v, 0.1);}
            FragOutput frag(v2f i) {return frag_fur(i, 0.1);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass1"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert1
            #pragma fragment frag1
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert1(a2v v) {return vert_fur(v, 0.2);}
            FragOutput frag1(v2f i) {return frag_fur(i, 0.2);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass2"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert2
            #pragma fragment frag2
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert2(a2v v) {return vert_fur(v, 0.3);}
            FragOutput frag2(v2f i) {return frag_fur(i, 0.3);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass3"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert3
            #pragma fragment frag3
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert3(a2v v) {return vert_fur(v, 0.4);}
            FragOutput frag3(v2f i) {return frag_fur(i, 0.4);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass4"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert4
            #pragma fragment frag4
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert4(a2v v) {return vert_fur(v, 0.5);}
            FragOutput frag4(v2f i) {return frag_fur(i, 0.5);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass5"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert5
            #pragma fragment frag5
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert5(a2v v) {return vert_fur(v, 0.6);}
            FragOutput frag5(v2f i) {return frag_fur(i, 0.6);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass6"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert6
            #pragma fragment frag6
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert6(a2v v) {return vert_fur(v, 0.7);}
            FragOutput frag6(v2f i) {return frag_fur(i, 0.7);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass7"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert7
            #pragma fragment frag7
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert7(a2v v) {return vert_fur(v, 0.8);}
            FragOutput frag7(v2f i) {return frag_fur(i, 0.8);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass8"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert8
            #pragma fragment frag8
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert8(a2v v) {return vert_fur(v, 0.9);}
            FragOutput frag8(v2f i) {return frag_fur(i, 0.9);}

            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode"="BMultiPass9"}
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert9
            #pragma fragment frag9
            #include "Assets/BPipline/Shaders/Libiary/Fur.hlsl"

            v2f vert9(a2v v) {return vert_fur(v, 1.0);}
            FragOutput frag9(v2f i) {return frag_fur(i, 1.0);}

            ENDHLSL
        }
        Pass
        {
            Tags{"LightMode"="ShadowCaster"}
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert_shadow
            #pragma fragment frag_shadow

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            struct a2v_shadow
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f_shadow
            {
                float4 vertex : SV_POSITION;
                float4 uvs : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

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


            v2f_shadow vert_shadow (a2v_shadow v)
            {
                v2f_shadow o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertex = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
                #if UNITY_REVERSED_Z
                    o.vertex.z = min(o.vertex.z, o.vertex.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.vertex.z = max(o.vertex.z, o.vertex.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                o.uvs.xy = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.uvs.zw = v.uv * GET_PROP(_FurShapeTex_ST).xy + GET_PROP(_FurShapeTex_ST).zw;
                return o;
            }

            half4 frag_shadow (v2f_shadow i) : SV_Target
            {
                half baseShape = SAMPLE_TEXTURE2D(_FurShapeTex, sampler_FurShapeTex, i.uvs.xy).g + GET_PROP(_FurBaseOffset_FurOfsset_FurLength).x;
                half furShape = SAMPLE_TEXTURE2D(_FurShapeTex, sampler_FurShapeTex, i.uvs.zw).r * GET_PROP(_FurBaseOffset_FurOfsset_FurLength).z * baseShape;
                half shape = saturate(furShape + baseShape - 1.0);
                shape = step(0.5, shape) * 0.25;
                clip(shape);
                return 0.0;
            }
            ENDHLSL
        }
    }
    CustomEditor "Fur_Inspector"
}
