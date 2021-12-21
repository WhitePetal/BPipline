Shader "Effect/Scroll2TexBlend"
{
    Properties
    {
        _MainTex1 ("Tex1(RBB)", 2D) = "white" {}
        _MainTex2("Tex2(RGB)", 2D) = "white" {}
        _MainTex_Wraps("Tex1 Wrap Mode_Tex2 Wrap Mode", Vector) = (0.0, 0.0, 0.0, 0.0)
        [VectorPop]_Scrolls("ScrollX_ScrollY_Scroll2X_Scroll2Y", Vector) = (1.0, 0.0, 1.0, 0.0)
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [VectorPop]_UVXX_MMultiplier("UVXX_Layer Multiplier", Vector) = (0.3, 2.0, 1.0, 1.0)
        [VectorRange(0.0, 16.0, 0.0, 16.0, 0.0, 1.0)]_PostProcessFactors("辉光强度_辉光阈值_马赛克", Vector) = (0.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "LightMode"="BShaderDefault" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half4 color : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex1);
            SAMPLER(sampler_MainTex1);
            TEXTURE2D(_MainTex2);
            SAMPLER(sampler_MainTex2);


            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex1_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex2_ST)
                UNITY_DEFINE_INSTANCED_PROP(half2, _MainTex_Wraps)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Scrolls)
                UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(half2, _UVXX_MMultiplier)
                UNITY_DEFINE_INSTANCED_PROP(half, _MMultiplier)
                UNITY_DEFINE_INSTANCED_PROP(half4, _PostProcessFactors)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = v.uv * GET_PROP(_MainTex1_ST).xy + GET_PROP(_MainTex1_ST).zw;
                o.uv.zw = v.uv * GET_PROP(_MainTex2_ST).xy + GET_PROP(_MainTex2_ST).zw;
                o.uv += frac(_Scrolls * _Time.x);
                o.color = GET_PROP(_UVXX_MMultiplier).y * GET_PROP(_Color) * v.color;
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
                i.uv.xy = lerp(i.uv.xy, saturate(i.uv.xy), GET_PROP(_MainTex_Wraps).x);
                half4 tex1 = SAMPLE_TEXTURE2D(_MainTex1, sampler_MainTex1, i.uv.xy);

                i.uv.zw += tex1.r * GET_PROP(_UVXX_MMultiplier).x;
                i.uv.zw = lerp(i.uv.zw, saturate(i.uv.zw), GET_PROP(_MainTex_Wraps).y);
                half4 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv.zw);
                half4 col = tex1 * tex2 * i.color;

                FragOutput output;
                output.color = col;
                output.flags = half4(EncodeBloomLuminanceImpl(col.rgb * col.a, GET_PROP(_PostProcessFactors).x, GET_PROP(_PostProcessFactors.y)), 0.0, 0.0, 0.0);
                return output;
            }
            ENDHLSL
        }
    }
}
