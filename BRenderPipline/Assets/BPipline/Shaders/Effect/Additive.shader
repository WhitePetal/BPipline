Shader "Effect/Additive"
{
    Properties
    {
        _BaseColor("Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness("Brightness", Range(0.0, 16.0)) = 1.0
        [VectorRange(0.0, 16.0, 0.0, 16.0, 0.0, 1.0)]_PostProcessFactors("辉光强度_辉光阈值_马赛克", Vector) = (1.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent"}

        Pass
        {
            Tags {"LightMode"="BShaderDefault"}
            Blend SrcAlpha One
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(half, _Brightness)
                UNITY_DEFINE_INSTANCED_PROP(half4, _PostProcessFactors)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.color = v.color * GET_PROP(_BaseColor);
                return o;
            }

            struct FragOutput
            {
                half4 color : SV_TARGET0;
                half4 flags : SV_TARGET1;
            };

            FragOutput frag (v2f i)
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * i.color;
                col.rgb *= GET_PROP(_Brightness);
                FragOutput output;
                output.color = col;
                output.flags = half4(1.0,
                0.0, 0.0, 0.0);
                return output;
            }
            ENDHLSL
        }
    }
}
