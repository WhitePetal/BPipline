#ifndef POST_PROCESS_STACK_INCLUDE
#define POST_PROCESS_STACK_INCLIDE
#include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

TEXTURE2D(_PostProcessSource);
#ifdef _MULTI_RENDER_TARGET
TEXTURE2D(_AddBuffer);
#endif
TEXTURE2D(_DepthBuffer);
TEXTURE2D(_PostProcessBlend);
SAMPLER(sampler_linear_clamp);

CBUFFER_START(UnityPostProcess)
    float4 _PostProcessSource_TexelSize;
    half4 _BlurOffset;
    half _ACES_Tonemapping_Factor;
    float4 _Width_Height_Factors;
    half4 _BloomFactor;
    float4 _AO_Scales;
    half4 _CircleSize_EdageSize;
    half4 _Hexagon_EdageSize;
    half4 _RhombusSize_EdageSize;
    half4 _RadialRGBCenter;
    half4 _RGBOffset_Iteration;
    half4 _RadialBlurCenter_ClearRange;
    half4 _RadialBlurRadius_Iteration;
CBUFFER_END

// ----------------------------------- Copy
    struct Varyings
    {
        float4 pos_clip : SV_POSITION;
        float2 uv_screen : TEXCOORD0;
    };

    Varyings DefaultPassVertex(uint vertexID : SV_VertexID)
    {
        Varyings o;
        o.pos_clip = float4(
            vertexID <= 1 ? -1.0 : 3.0,
            vertexID == 1 ? 3.0 : -1.0,
            0.0, 1.0
        );
        o.uv_screen = float2(
            vertexID <= 1 ? 0.0 : 2.0,
            vertexID == 1 ? 2.0 : 0.0
        );
        if(_ProjectionParams.x < 0.0) o.uv_screen.y = 1.0 - o.uv_screen.y;
        return o;
    }

    half4 CopyPassFragment(Varyings i) : SV_TARGET
    {
        return SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
    }
// ---------------------------------------------

// ------------------------------------------- Blends
    // vertex => default
    // blend-add
    half4 BlendAddFragment(Varyings i) : SV_TARGET
    {
        half4 c = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        half4 blend = SAMPLE_TEXTURE2D_LOD(_PostProcessBlend, sampler_linear_clamp, i.uv_screen, 0);
        return half4(c.rgb + blend.rgb, c.a);
    }
    // blendMul
    half4 BlendMulFragment(Varyings i) : SV_TARGET
    {
        half4 c = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        half4 blend = SAMPLE_TEXTURE2D_LOD(_PostProcessBlend, sampler_linear_clamp, i.uv_screen, 0);
        return half4(c.rgb * blend.rgb, c.a);
    }
    // blendMulR
    half4 BlendMulRFragment(Varyings i) : SV_TARGET
    {
        half4 c = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        half blend = SAMPLE_TEXTURE2D_LOD(_PostProcessBlend, sampler_linear_clamp, i.uv_screen, 0).r;
        return half4(c.rgb * blend, c.a);
    }
// ------------------------------------------------

// -------------------------------- GaussianBlur
    struct Varyings_GaussianBlur
    {
        float4 pos_clip : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 uv0 : TEXCOORD1;
        float4 uv1 : TEXCOORD2;
        float4 uv2 : TEXCOORD3;
    };

    Varyings_GaussianBlur GaussianBlurPassVertex(uint vertexID : SV_VertexID)
    {
        Varyings_GaussianBlur o;
        o.pos_clip = float4(
            vertexID <= 1 ? -1.0 : 3.0,
            vertexID == 1 ? 3.0 : -1.0,
            0.0, 1.0
        );
        o.uv = float2(
            vertexID <= 1 ? 0.0 : 2.0,
            vertexID == 1 ? 2.0 : 0.0
        );
        if(_ProjectionParams.x < 0.0) o.uv.y = 1.0 - o.uv.y;

        float4 offset = _BlurOffset.xyxy * float4(1.0, 1.0, -1.0, -1.0);
        o.uv0 = o.uv.xyxy + offset;
        o.uv1 = o.uv.xyxy + offset * 2.0;
        o.uv2 = o.uv.xyxy + offset * 3.0;
        return o;
    }

    half4 GaussianBlurFragment(Varyings_GaussianBlur i) : SV_TARGET
    {
        half4 source = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv, 0);
        half3 col = source.rgb * 0.4;
        col += 0.15 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv0.xy, 0).rgb;
        col += 0.15 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv0.zw, 0).rgb;
        col += 0.10 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv1.xy, 0).rgb;
        col += 0.10 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv1.zw, 0).rgb;
        col += 0.05 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv2.xy, 0).rgb;
        col += 0.05 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv2.zw, 0).rgb;
        return half4(col, source.a);
    }
// -----------------------------------

// --------------------------------- BoxBlur
    struct Varyings_BoxBlur
    {
        float4 pos_clip : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 uv0 : TEXCOORD1;
        float4 uv1 : TEXCOORD2;
        float4 uv2 : TEXCOORD3;
        float4 uv3 : TEXCOORD4;
    };

    Varyings_BoxBlur BoxBlurPassVertex(uint vertexID : SV_VertexID)
    {
        Varyings_BoxBlur o;
        o.pos_clip = float4(
            vertexID <= 1 ? -1.0 : 3.0,
            vertexID == 1 ? 3.0 : -1.0,
            0.0, 1.0
        );
        o.uv = float2(
            vertexID <= 1 ? 0.0 : 2.0,
            vertexID == 1 ? 2.0 : 0.0
        );
        if(_ProjectionParams.x < 0.0) o.uv.y = 1.0 - o.uv.y;

        o.uv0 = o.uv.xyxy + _BlurOffset.xyxy * float4(1.0, 1.0, -1.0, -1.0);
        o.uv1 = o.uv.xyxy + _BlurOffset.xyxy * float4(-1.0, 1.0, 1.0, -1.0);
        o.uv2 = o.uv.xyxy + _BlurOffset.xyxy * float4(-1.0, 0.0, 1.0, 0.0);
        o.uv3 = o.uv.xyxy + _BlurOffset.xyxy * float4(0.0, 1.0, 0.0, -1.0);
        return o;
    }

    half4 BoxBlurFragment(Varyings_BoxBlur i) : SV_TARGET
    {
        half4 source = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv, 0);
        half3 col = source.rgb * 0.2;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv0.xy, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv0.zw, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv1.xy, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv1.zw, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv2.xy, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv2.zw, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv3.xy, 0).rgb;
        col += 0.1 * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv3.zw, 0).rgb;
        return half4(col, source.a);
    }
// -------------------------------------

// -------------------------------- Bloom
    // Extract
    // vertex => default
    half4 BloomExtractFragment(Varyings i) : SV_TARGET
    {
        half4 c = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        #ifdef _MULTI_RENDER_TARGET
        half4 flags = SAMPLE_TEXTURE2D_LOD(_AddBuffer, sampler_linear_clamp, i.uv_screen, 0);
        half val = DecodeBloomLuminanceImpl(flags.r);
        #else
        half val = DecodeBloomLuminanceImpl(c.a);
        #endif
        c.rgb *= val * _BloomFactor.rgb * _BloomFactor.a;
        return c;
    }
// --------------------------------------

// -------------------------------- ACES_ToneMapping
    // vertex => default
    half4 ACEST_ToneMapping_Fragment(Varyings i) : SV_TARGET
    {
        half4 c = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        return half4(ToneMapping_ACES_DS(c.rgb, _ACES_Tonemapping_Factor), c.a);
    }
// -----------------------------------

// -------------------------------- FXAA
    #define EDGE_THRESHOLD_MIN 0.0312
    #define EDGE_THRESHOLD_MAX 0.125
    #define FXAA_ITERATIONS 12
    #define SUBPIXEL_QUALITY 0.75
    half rgb2luma(half3 rgb)
    {
        return sqrt(dot(rgb, half3(0.299, 0.587, 0.114)));
    }

    // vertex => default
    half4 FXAA_Fragment(Varyings i) : SV_TARGET
    {
        half4 tex = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        half alpha = tex.a;
        half3 color_center = tex.rgb;
        half3 output = color_center;
        half luma_center = rgb2luma(color_center);

        half4 w_h = _Width_Height_Factors * 2.0;
        half luma_down = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(0.0, -w_h.w), 0).rgb);
        half luma_up = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(0.0, w_h.w), 0).rgb);
        half luma_left = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(-w_h.z, 0.0), 0).rgb);
        half luma_right = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(w_h.z, 0.0), 0).rgb);

        half luma_max = max(luma_center, max(max(luma_down, luma_up), max(luma_left, luma_right)));
        half luma_min = min(luma_center, min(min(luma_down, luma_up), min(luma_left, luma_right)));

        half luma_range = luma_max - luma_min;
        if(luma_range < max(EDGE_THRESHOLD_MIN, EDGE_THRESHOLD_MAX * luma_max)) return half4(output, alpha);

    // ------------------------------------- real FXAA
        half luma_down_left = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(-w_h.z, -w_h.w), 0).rgb);
        half luma_up_right = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(w_h.z, w_h.w), 0).rgb);
        half luma_up_left = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(-w_h.z, w_h.w), 0).rgb);
        half luma_down_right = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + float2(w_h.z, -w_h.w), 0).rgb);

        half luma_down_up = luma_down + luma_up;
        half luma_left_right = luma_left + luma_right;

        half luma_left_corners = luma_down_left + luma_up_left;
        half luma_down_coners = luma_down_left + luma_down_right;
        half luma_right_coners = luma_down_right + luma_up_right;
        half luma_up_coners = luma_up_right + luma_up_left;

        half edge_h = abs(-2.0 * luma_left + luma_left_corners) + abs(-2.0 * luma_center + luma_down_up) * 2.0 + abs(-2.0 * luma_right + luma_right_coners);
        half edge_v = abs(-2.0 * luma_up + luma_up_coners) + abs(-2.0 * luma_center + luma_left_right) * 2.0 + abs(-2.0 * luma_down + luma_down_coners);
        
        bool isHoriziontal = (edge_h >= edge_v);

        half luma1 = isHoriziontal ? luma_down : luma_left;
        half luma2 = isHoriziontal ? luma_up : luma_right;

        half gradient1 = luma1 - luma_center;
        half gradient2 = luma2 - luma_center;

        bool isSteepest1 = (abs(gradient1) >= abs(gradient2));

        half gradientScaled = 0.25 * max(abs(gradient1), abs(gradient2));

        float step_length = isHoriziontal ? _PostProcessSource_TexelSize.x : _PostProcessSource_TexelSize.y;
        half luma_local_average = 0.0;
        if(isSteepest1)
        {
            step_length = -step_length;
            luma_local_average = 0.5 * (luma1 + luma_center);
        }
        else
        {
            luma_local_average = 0.5 * (luma2 + luma_center);
        }

        float2 currentUV = i.uv_screen;
        if(isHoriziontal) currentUV.y += step_length * 0.5;
        else currentUV.x += step_length * 0.5;

        float2 offset = isHoriziontal ? float2(_PostProcessSource_TexelSize.x, 0.0) : float2(0.0, _PostProcessSource_TexelSize.y);
        float2 uv1 = currentUV - offset;
        float2 uv2 = currentUV + offset;

        half lumaEnd1 = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv1, 0).rgb);
        half lumaEnd2 = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv2, 0).rgb);
        lumaEnd1 -= luma_local_average;
        lumaEnd2 -= luma_local_average;

        bool reached1 = abs(lumaEnd1) >= gradientScaled;
        bool reached2 = abs(lumaEnd2) >= gradientScaled;
        bool reachedBoth = (reached1 && reached2);

        if(!reached1) uv1 -= offset;
        if(!reached2) uv2 += offset;

        const half QUALITY[12] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0};
        if(!reachedBoth)
        {
            for(int i = 2; i < FXAA_ITERATIONS; i++)
            {
                if(!reached1)
                {
                    lumaEnd1 = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv1, 0).rgb);
                    lumaEnd1 -= luma_local_average;
                }
                if(!reached2)
                {
                    lumaEnd2 = rgb2luma(SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv2, 0).rgb);
                    lumaEnd2 -= luma_local_average;
                }
                reached1 = abs(lumaEnd1) >= gradientScaled;
                reached2 = abs(lumaEnd2) >= gradientScaled;
                reachedBoth = (reached1 && reached2);
                if(!reached1) uv1 -= offset * QUALITY[i];
                if(!reached2) uv2 += offset * QUALITY[i];
                if(reachedBoth) break;
            }
        }

        float dst1 = isHoriziontal ? (i.uv_screen.x - uv1.x) : (i.uv_screen.y - uv1.y);
        float dst2 = isHoriziontal ? (uv2.x - i.uv_screen.x) : (uv2.y - i.uv_screen.y);

        bool isDir1 = dst1 < dst2;
        float dst_final = min(dst1, dst2);
        float edgeThickness = dst1 + dst2;
        float pixelOffset = -dst_final / edgeThickness + 0.5;

        bool isLumaCenterSmaller = luma_center < luma_local_average;
        bool correctVariation = ((isDir1 ? lumaEnd1 : lumaEnd2) < 0.0) != isLumaCenterSmaller;
        float final_offset = correctVariation ? pixelOffset : 0.0;

        half luma_average = (1.0 / 12.0) * (2.0 * (luma_down_up + luma_left_right) + luma_left_corners + luma_right_coners);
        float subPixel_offset1 = clamp(abs(luma_average - luma_center) / luma_range, 0.0, 1.0);
        float subPixel_offset2 = (-2.0 * subPixel_offset1 + 3.0) * subPixel_offset1 * subPixel_offset1;
        float subPixel_offset_final = subPixel_offset2 * subPixel_offset2 * SUBPIXEL_QUALITY;
        final_offset = max(final_offset, subPixel_offset_final);

        float2 final_uv = i.uv_screen;
        if(isHoriziontal) final_uv.y += final_offset * step_length;
        else final_uv.x += final_offset * step_length;
        half3 finalColor = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, final_uv, 0).rgb;
    // ------------------------------------- real FXAA
        return half4(finalColor, alpha);
    }
// ------------------------------------

// // ------------------------------- Get Screen-Space-Normal
//     half3 GetScreenSapceNormal(float2 uv, float4 uv0)
//     {
//         float center_depth = DecodeFloatRG(SAMPLE_TEXTURE2D_LOD(_AddBuffer, sampler_linear_clamp, uv, 0).gb);
//         float s_depth =  DecodeFloatRG(SAMPLE_TEXTURE2D_LOD(_AddBuffer, sampler_linear_clamp, uv0.xy, 0).gb);
//         float t_depth = DecodeFloatRG(SAMPLE_TEXTURE2D_LOD(_AddBuffer, sampler_linear_clamp, uv0.zw, 0).gb);
//         return normalize(cross(float3(1.0, 0.0, (s_depth - center_depth) * _ProjectionParams.z), float3(0.0, 1.0, (t_depth - center_depth) * _ProjectionParams.z)));
//     }
//     struct Varyings_SSN
//     {
//         float4 pos_clip : SV_POSITION;
//         float2 uv : TEXCOORD0;
//         float4 uv0 : TEXCOORD1;
//     };
//     Varyings_SSN GetScreenSpaceNormal_Vertex(uint vertexID : SV_VertexID)
//     {
//         Varyings_SSN o;
//         o.pos_clip = float4(
//             vertexID <= 1 ? -1.0 : 3.0,
//             vertexID == 1 ? 3.0 : -1.0,
//             0.0, 1.0
//         );
//         o.uv = float2(
//             vertexID <= 1 ? 0.0 : 2.0,
//             vertexID == 1 ? 2.0 : 0.0
//         );
//         if(_ProjectionParams.x < 0.0) o.uv.y = 1.0 - o.uv.y;

//         o.uv0 = float4(o.uv + float2(_PostProcessSource_TexelSize.x, 0.0), o.uv + float2(0.0, _PostProcessSource_TexelSize.y));
//         return o;
//     }
//     half4 GetScreenSpaceNormal_Fragment(Varyings_SSN i) : SV_TARGET
//     {
//         // return SAMPLE_TEXTURE2D_LOD(_AddBuffer, sampler_linear_clamp, i.uv, 0).g;
//         return half4(0.5 * (GetScreenSapceNormal(i.uv, i.uv0) + 1.0), 1.0);
//     }
// // ---------------------------------------------------------------

// // -------------------------------------------- SSAO
//     struct Varyings_SSAO
//     {
//         float4 pos_clip : SV_POSITION;
//         float2 uv : TEXCOORD0;
//     };
//     Varyings_SSAO SSAO_Vertex(uint vertexID : SV_VertexID)
//     {
//         Varyings_SSAO o;
//         o.pos_clip = float4(
//             vertexID <= 1 ? -1.0 : 3.0,
//             vertexID == 1 ? 3.0 : -1.0,
//             0.0, 1.0
//         );
//         o.uv = float2(
//             vertexID <= 1 ? 0.0 : 2.0,
//             vertexID == 1 ? 2.0 : 0.0
//         );
//         if(_ProjectionParams.x < 0.0) o.uv.y = 1.0 - o.uv.y;
//         return o;
//     }
//     half4 SSAO_Fragment(Varyings_SSAO i) : SV_TARGET
//     {
//         float4 uv0 = float4(i.uv + float2(_PostProcessSource_TexelSize.x, 0.0), i.uv + float2(0.0, _PostProcessSource_TexelSize.y));
//         float2 rv = (2.0 * randVec(i.uv) - 1.0) * _AO_Scales.yz;
//         float4 nuv0 = float4(i.uv + float2(rv.x, rv.y), i.uv + float2(-rv.x, rv.y));
//         float4 nuv1 = float4(i.uv + float2(-rv.x, -rv.y), i.uv + float2(rv.x, -rv.y));

//         float center_depth = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, i.uv, 0);
//         float s_depth = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, uv0.xy, 0);
//         float t_depth = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, uv0.zw, 0);
//         float rd = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, nuv0.xy, 0);
//         float ld = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, nuv0.zw, 0);
//         float ud = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, nuv1.xy, 0);
//         float dd = SAMPLE_DEPTH_TEXTURE_LOD(_DepthBuffer, sampler_linear_clamp, nuv1.zw, 0);


//         float3 normal = normalize(cross(float3(_PostProcessSource_TexelSize.x, 0.0, s_depth - center_depth), float3(0.0, _PostProcessSource_TexelSize.y, t_depth - center_depth)));

//         float3 c_pos = float3(i.uv, center_depth);
//         #if UNITY_REVERSED_Z
//             float3 r_pos = normalize(float3(nuv0.xy, rd) - c_pos);
//             float3 l_pos = normalize(float3(nuv0.zw, ld) - c_pos);
//             float3 u_pos = normalize(float3(nuv1.xy, ud) - c_pos);
//             float3 d_pos = normalize(float3(nuv1.zw, dd) - c_pos);
//         #else
//             float3 r_pos = normalize(c_pos - float3(nuv0.xy, rd));
//             float3 l_pos = normalize(c_pos - float3(nuv0.zw, ld));
//             float3 u_pos = normalize(c_pos - float3(nuv1.xy, ud));
//             float3 d_pos = normalize(c_pos - float3(nuv1.zw, dd));
//         #endif
//         float ao = 1.0 - _AO_Scales.x * (DotClamped(r_pos, normal) + DotClamped(l_pos, normal) +
//          DotClamped(u_pos, normal) + DotClamped(d_pos, normal));
//         return ao;
//     }
// // --------------------------------------------

// -------------------------------- PixelCircle
    // vertex => default
    half4 PixelCircle_Fragment(Varyings i) : SV_TARGET
    {
        half ln = step(0.5, floor(i.uv_screen.y * _CircleSize_EdageSize.y) % 2.0) * 0.5;
        i.uv_screen.x += ln / _CircleSize_EdageSize.x;
        float2 uv_col = floor(i.uv_screen * _CircleSize_EdageSize.xy) / _CircleSize_EdageSize.xy;
        float2 uv_circle = frac(i.uv_screen * _CircleSize_EdageSize.xy) * 2.0 - 1.0;
        half dstCirlcle = dot(uv_circle, uv_circle);
        half4 col = step(_CircleSize_EdageSize.z, 1.0 - dstCirlcle) * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv_col, 0);
        return col;
    }
// -----------------------------------------

// -------------------------------- PixelHexagon
    // vertex => default
    half DstHexagon(float2 uv)
    {
        const float3 k = float3(-0.866025404, 0.5, 0.577350269);
        uv = abs(uv);
        uv -= 2.0 * min(dot(k.xy, uv), 0.0) * k.xy;
        uv -= float2(clamp(uv.x, -k.z * 0.5, k.z * 0.5), 0.5);
        return length(uv) * sign(uv.y);
    }
    half4 PixelHexagon_Fragment(Varyings i) : SV_TARGET
    {
        half ln = step(0.5, floor(i.uv_screen.y * _Hexagon_EdageSize.y) % 2.0) * 0.5;
        i.uv_screen.x += ln / _Hexagon_EdageSize.x;
        float2 uv_col = floor(i.uv_screen * _Hexagon_EdageSize.xy) / _Hexagon_EdageSize.xy;
        float2 uv_shape = frac(i.uv_screen * _Hexagon_EdageSize.xy) * 2.0 - 1.0;
        half dst = DstHexagon(uv_shape);
        half4 col = step(_Hexagon_EdageSize.z, 1.0 - dst) * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv_col, 0);
        return col;
    }
// ---------------------------------------

// -------------------------------- PixelRhombus
    // vertex => default
    float ndot(float2 a, float2 b) {return a.x * b.x - a.y * b.y;}
    half DstRhombus(float2 uv, half2 b)
    {
        uv = abs(uv);
        half h = clamp(ndot(b - 2.0 * uv, b) / dot(b, b), -1.0, 1.0);
        half d = length(uv - 0.5 * b * float2(1.0 - h, 1.0 + h));
        return d * sign(uv.x * b.y + uv.y * b.x - b.x * b.y);
    }
    half4 PixelRhombus_Fragment(Varyings i) : SV_TARGET
    {
        half ln = step(0.5, floor(i.uv_screen.y * _RhombusSize_EdageSize.y) % 2.0) * 0.5;
        i.uv_screen.x += ln / _RhombusSize_EdageSize.x;
        float2 uv_col = floor(i.uv_screen * _RhombusSize_EdageSize.xy) / _RhombusSize_EdageSize.xy;
        float2 uv_rhombus = frac(i.uv_screen * _RhombusSize_EdageSize.xy) * 2.0 - 1.0;
        // uv_rhombus.x = cos(_Time.y) * uv_rhombus.x + sin(_Time.y) * uv_rhombus.y;
        // uv_rhombus.y = -sin(_Time.y) * uv_rhombus.x + cos(_Time.y) * uv_rhombus.y;
        half dstRhombus = DstRhombus(uv_rhombus, 0.5);
        half4 col = step(_RhombusSize_EdageSize.z, 1.0 - dstRhombus) * SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, uv_col, 0);
        return col;
    }
// ---------------------------------

// -------------------------------- RadialRGBSplit
    // vertex => default
    half4 RadialRGBSplit_Fragment(Varyings i) : SV_TARGET
    {
        float2 dir = (_RadialRGBCenter.xy - i.uv_screen);
        float dst = smoothstep(0.0, 1.0, dir.x * dir.x / _RadialRGBCenter.z + dir.y * dir.y / _RadialRGBCenter.w);
        dir *= dst;
        float2 rDir = dir + _RGBOffset_Iteration.x;
        float2 gDir = dir + _RGBOffset_Iteration.y;
        float2 bDir = dir + _RGBOffset_Iteration.z;

        half4 source = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        half3 col = 0.0;
        for(half k = 0.0; k < _RGBOffset_Iteration.w; k++)
        {
            col.r += SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen - rDir * k, 0).r;
            col.g += SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + gDir * 0.5 * k, 0).g;
            col.b += SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen + bDir * k, 0).b;
        }
        half f = 1.0 / _RGBOffset_Iteration.w;
        return half4(col * f, source.a);
    }
// ---------------------------------

// -------------------------------- RadialBlur
    // vertex => default
    half4 RadialBlur_Fragment(Varyings i) : SV_TARGET
    {
        float2 dir = (i.uv_screen - _RadialBlurCenter_ClearRange.xy);
        float mask = smoothstep(0.0, 1.0, dir.x * dir.x / _RadialBlurCenter_ClearRange.z + dir.y * dir.y / _RadialBlurCenter_ClearRange.w);
        half4 source = SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen, 0);
        half3 col = 0.0;
        dir *= _RadialBlurRadius_Iteration.xy;
        for(float k = 0.0; k < _RadialBlurRadius_Iteration.z; k++)
        {
            col += SAMPLE_TEXTURE2D_LOD(_PostProcessSource, sampler_linear_clamp, i.uv_screen - dir * k, 0).rgb;
        }
        return half4(lerp(source.rgb, col / _RadialBlurRadius_Iteration.z, mask), source.a);
    }
// ----------------------------------
#endif