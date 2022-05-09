Shader "Hidden/PostProcessStack"
{
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/PostProcessStack.hlsl"
            #pragma multi_compile __ _MULTI_RENDER_TARGET
        ENDHLSL

        Pass
        {
            Name "Copy"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment CopyPassFragment
            ENDHLSL
        }

        Pass
        {
            Name "BlendAdd"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BlendAddFragment
            ENDHLSL
        }

        Pass
        {
            Name "BlendMul"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BlendMulFragment
            ENDHLSL
        }

        Pass
        {
            Name "BlendMulR"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BlendMulRFragment
            ENDHLSL
        }

        Pass
        {
            Name "GaussianBlur"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex GaussianBlurPassVertex
            #pragma fragment GaussianBlurFragment
            ENDHLSL
        }

        Pass
        {
            Name "BoxBlur"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex BoxBlurPassVertex
            #pragma fragment BoxBlurFragment
            ENDHLSL
        }

        Pass
        {
            Name "BloomExtract"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment BloomExtractFragment
            ENDHLSL
        }

        Pass
        {
            Name "ACES_ToneMapping"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment ACEST_ToneMapping_Fragment
            ENDHLSL
        }

        Pass
        {
            Name "FXAA"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment FXAA_Fragment
            ENDHLSL
        }

        // Pass
        // {
        //     Name "GetScreenSpaceNormal"
        //     HLSLPROGRAM
        //     #pragma target 3.5
        //     #pragma vertex GetScreenSpaceNormal_Vertex
        //     #pragma fragment GetScreenSpaceNormal_Fragment
        //     ENDHLSL
        // }

        Pass
        {
            Name "SSAO"
            HLSLPROGRAM
            #pragma target 3.5
            // #pragma vertex SSAO_Vertex
            // #pragma fragment SSAO_Fragment
            #pragma vertex DefaultPassVertex
            #pragma fragment FXAA_Fragment
            ENDHLSL
        }

        Pass
        {
            Name "PixelCircle"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment PixelCircle_Fragment
            ENDHLSL
        }

        Pass
        {
            Name "PixelHexagon"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment PixelHexagon_Fragment
            ENDHLSL
        }

        Pass
        {
            Name "PixelRhombus"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment PixelRhombus_Fragment
            ENDHLSL
        }

        Pass
        {
            Name "RadialRGBSplit"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment RadialRGBSplit_Fragment
            ENDHLSL
        }

        Pass
        {
            Name "RadialBlur"
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DefaultPassVertex
            #pragma fragment RadialBlur_Fragment
            ENDHLSL
        }
    }
}
