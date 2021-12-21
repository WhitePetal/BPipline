// Upgrade NOTE: commented out 'half4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable

// Upgrade NOTE: commented out 'half4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable

Shader "Lit/PBR/High/PBR_BRDF_LUT"
{
    Properties
    {
        [NoScaleOffset]_LUT("LUT", 2D) = "wihte" {}
        _MainTex ("Albedo", 2D) = "white" {}
        _DiffuseColor("Diffuse Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularColor("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [NoScaleOffset]_NormalTex("Normal Map", 2d) = "bump" {}
        [NoScaleOffset] _ParallxTex("ParallxTex", 2D) = "black" {}
        [VectorRange(0.31830989, 8, 0.25, 8, 0.0, 1.0, 0.0, 0.08)]_KdKsExpoureParalxScale("漫反射强度_镜面反射强度_曝光强度_视差强度", Vector) = (1.0, 1.0, 0.0, 0.04)
        [NoScaleOffset]_MRATex("Metallic(R) Roughness(G) AO(B)", 2D) = "white" {}
        [VectorRange(0.0, 1.0, 0.01, 1.0, 0.0, 1.0)]_MetallicRoughnessAO("金属度_粗糙度_AO", Vector) = (0.0, 0.8, 1.0)
        _EmissionMap("Emission RGB:Color A:Mask", 2D) = "black" {}
        _EmissionStrength("Emission Strength", Range(0.0, 10.0)) = 1.0
        _Fresnel("Fresnel0", Color) = (0.09, 0.09, 0.09, 1)
        _DetilTex("Detil", 2D) = "black" {}
        _DetilColor("Detil Color", Color) = (1.0, 1.0, 1.0, 1.0) 
        [NoScaleOffset]_DetilNormalTex("Detil Normal Map", 2D) = "bump" {}
        [VectorRange(0.0, 2.0, 0.0, 2.0)]_NormalScales("主法线强度_细节法线强度", Vector) = (1.0, 1.0, 0.0, 0.0)
        _PointLightColor("Point Light Color", Color) = (0.5492168, 0.6934489, 0.9622642, 1.0)
        [ObjPositionVector]_PointLightPos("Point Light Pos", Vector) = (1.0, .0, .0, 1.0)
        [NoScaleOffset]_AmbientTex("Ambient Tex", 2D) = "white" {}
        [VectorRange(0.0, 1.0, 0.0, 1.0)]_AmbientSpecStrength_SHStrength("环境光高光强度_SH Strength", Vector) = (0.5, 0.0, 0.0, 0.0)
        _AmbientColor("Ambient Color", Color) = (0.3, 0.3, 0.3, 1.0)

        _EmissionPointMask("Emission Point Mask", 2D) = "white" {}
        [HDR]_EmissionPointColor("Emission Point Color", Color) = (0.2, 0.4, 0.7)
        _EmissionPointDensity("Emission Point Density", Vector) = (128, 64, 0, 0)
        // _EmissionPointCutoff("Emission Point Cutoff", Range(0, 2)) = 0.5
        _EmissionPointNoiseOffset("Emission Point Noise Offset", Vector) = (0.0, 0.0, 0.0, 0.0)
        // _EmissionPointFrequency("Emission Point Frequency", Range(0, 10)) = 1
        _EmissionPointPulse("Emission Point Pulse", Vector) = (100, 1, 1, 1)
        [VectorRange(0.0, 2.0, 0.0, 10.0)]_EmissionPointCutoff_EmissionPointFrequency("闪点Cutout_闪电噪声频率", Vector) = (0.5, 1.0, 0.0, 0.0)
        
        _BloomColor("BloomColor", Color) = (1.0, 1.0, 1.0, 1.0)
        [VectorRange(0.0, 16.0, 0.0, 16.0, 0.0, 1.0)]_PostProcessFactors("辉光强度_辉光阈值_马赛克", Vector) = (0.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Pass
        {
            Tags {"LightMode"="BPreDepthPass"}
            Color(0.0, 0.0, 0.0, 0.0)
        }

        Pass
        {
            Tags {"LightMode"="BShaderDefault"}
            ZWrite Off
            ZTest Equal
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing

            #pragma multi_compile_local __ _PointLight
            #pragma multi_compile_local __ _HeightMap
            #pragma multi_compile_local __ _Emission
            #pragma multi_compile_local __ _EmissionPointLow _EmissionPointMid

            #pragma multi_compile __ _LIGHTS_PER_OBJECT
            #pragma multi_compile_local __ LOD_FADE_CROSSFADE
            // #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile __ _RECEIVE_SHADOWS
            #pragma multi_compile __ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            // #pragma shader_feature _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
            #pragma multi_compile __ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            #pragma multi_compile __ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE

            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/UnityShadow.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/UnityGI.hlsl"

            #define PI_INVERSE 0.31830989
            #define _BRDF_LUT 1

            struct a2v
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
                GI_ATTRIBUTE_DATA
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                half3 normal_world : TEXCOORD1;
                half3 tangent_world : TEXCOORD2;
                half3 binormal_world : TEXCOORD3;
                float4 pos_world : TEXCOORD4;
                #ifdef _HeightMap
                half3 view_tangent : TEXCOORD5;
                #endif
                #ifdef _PointLight
                half4 point_light_params : TEXCOORD6;
                #endif
                // #ifdef VERTEXLIGHT_ON
                // fixed3 vertexLight : TEXCOORD7;
                // #endif
                GI_VARYINGS_DATA
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #include "Assets/BPipline/Shaders/Libiary/TransformLibiary.hlsl"
            #include "Assets/BPipline/Shaders/Libiary/ShaderUtil.hlsl"

            TEXTURE2D(_LUT);
            SAMPLER(sampler_LUT);
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_DetilTex);
            SAMPLER(sampler_DetilTex);
            TEXTURE2D(_DetilNormalTex);
            SAMPLER(sampler_DetilNormalTex);
            TEXTURE2D(_MRATex);
            SAMPLER(sampler_MRATex);
            TEXTURE2D(_AmbientTex);
            SAMPLER(sampler_AmbientTex);

            #ifndef _EmissionPointOff
                TEXTURE2D(_EmissionPointMask);
                SAMPLER(sampler_EmissionPointMask);
            #endif

            #ifdef _HeightMap
                TEXTURE2D(_ParallxTex);
                SAMPLER(sampler_ParallxTex);
            #endif

            #ifdef _Emission
                TEXTURE2D(_EmissionMap);
                SAMPLER(sampler_EmissionMap);
            #endif

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                #ifdef _Emission
                    UNITY_DEFINE_INSTANCED_PROP(half, _EmissionStrength)
                #endif

                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _DetilTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half3, _DiffuseColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _DetilColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _Fresnel)
                UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _SpecularColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _MetallicRoughnessAO)
                UNITY_DEFINE_INSTANCED_PROP(half2, _NormalScales)
                UNITY_DEFINE_INSTANCED_PROP(half4, _KdKsExpoureParalxScale)

                #ifdef _PointLight
                    UNITY_DEFINE_INSTANCED_PROP(half3, _PointLightColor)
                    UNITY_DEFINE_INSTANCED_PROP(half3, _PointLightPos)
                #endif

                UNITY_DEFINE_INSTANCED_PROP(half2, _AmbientSpecStrength_SHStrength)

                #ifndef _EmissionPointOff
                    UNITY_DEFINE_INSTANCED_PROP(half2, _EmissionPointDensity)
                    UNITY_DEFINE_INSTANCED_PROP(float2, _EmissionPointCutoff_EmissionPointFrequency)
                    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionPointNoiseOffset)
                    UNITY_DEFINE_INSTANCED_PROP(half3, _EmissionPointColor)
                    UNITY_DEFINE_INSTANCED_PROP(half3, _EmissionGloss)
                    UNITY_DEFINE_INSTANCED_PROP(half2, _EmissionPointPulse)
                #endif

                UNITY_DEFINE_INSTANCED_PROP(half3, _BloomColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _PostProcessFactors)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #include "Assets/BPipline/Shaders/Libiary/ShadingFunctions.hlsl"

            v2f vert (a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                TRANSFER_GI_DATA(v, o);

                o.pos_world.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.pos_world.w = -TransformWorldToView(o.pos_world.xyz).z;
                o.vertex = TransformWorldToHClip(o.pos_world.xyz);
                o.uv.xy = v.texcoord * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.uv.zw = v.texcoord * GET_PROP(_DetilTex_ST).xy + GET_PROP(_DetilTex_ST).zw; // detil map
                o.normal_world = TransformObjectToWorldNormal(v.normal);
                o.tangent_world = TransformObjectToWorldDir(v.tangent.xyz);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;

                #ifdef _HeightMap
                o.view_tangent = GetTangentSpaceViewDir(v.tangent, v.normal, v.vertex);
                #endif

                #ifdef _PointLight
                o.point_light_params.xyz = GET_PROP(_PointLightPos) - v.vertex.xyz;
                o.point_light_params.w = 1.0 / max(dot(o.point_light_params.xyz, o.point_light_params.xyz), 0.001);
                o.point_light_params.xyz = mul(unity_ObjectToWorld, float4(GET_PROP(_PointLightPos), 1.0)).xyz - o.pos_world.xyz;
                #endif
                // #ifdef VERTEXLIGHT_ON
                // o.vertexLight = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2], unity_LightColor[3], unity_4LightAtten0, o.pos_world, o.normal_world);
                // #endif
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
                ClipLOD(i.vertex.xy, unity_LODFade.x);
                ShadingParams shadingParams;
                shadingParams.pos_world = i.pos_world.xyz;
                shadingParams.pos_clip = i.vertex;
                shadingParams.expoure = GET_PROP(_KdKsExpoureParalxScale).z;

                #ifdef _HeightMap
                half2 parallxOffset = GetParallxOffset(SAMPLE_TEXTURE2D(_ParallxTex, sampler_ParallxTex, i.uv.xy).r, normalize(i.view_tangent), GET_PROP(_KdKsExpoureParalxScale).w);
                i.uv += half4(parallxOffset, parallxOffset);
                #endif

                half4 detil = SAMPLE_TEXTURE2D(_DetilTex, sampler_DetilTex, i.uv.zw);
                half detilMask = detil.a;

                half3 MRA = SAMPLE_TEXTURE2D(_MRATex, sampler_MRATex, i.uv.xy).rgb;
                shadingParams.roughness = max(0.02, GET_PROP(_MetallicRoughnessAO).y * MRA.g);
                half oneMinusMetallic = 1.0 - MRA.r * GET_PROP(_MetallicRoughnessAO).x;
                half ao = saturate(1.0 - (1.0 - MRA.b) * GET_PROP(_MetallicRoughnessAO).z);
                shadingParams.fresnelCol = lerp(GET_PROP(_Fresnel), 0.047, oneMinusMetallic);

                shadingParams.albedo = lerp(GET_PROP(_DiffuseColor) * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb, 
                    GET_PROP(_DetilColor) * SAMPLE_TEXTURE2D(_DetilTex, sampler_DetilTex, i.uv.zw).rgb, detilMask) * GET_PROP(_KdKsExpoureParalxScale).x;
                // albedo *= albedo;
                shadingParams.specular = lerp(shadingParams.albedo, GET_PROP(_SpecularColor), oneMinusMetallic) * GET_PROP(_KdKsExpoureParalxScale).y;
                shadingParams.albedo *= oneMinusMetallic;

                shadingParams.depth = i.pos_world.w;
                shadingParams.n = GetBlendNormalWorldFromMap(i, SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv.xy), SAMPLE_TEXTURE2D(_DetilNormalTex, sampler_DetilNormalTex, i.uv.zw), GET_PROP(_NormalScales).x, GET_PROP(_NormalScales).y, detilMask);
                shadingParams.v = GetWorldSpaceViewDir(i.pos_world.xyz);
                shadingParams.ndotv = max(0.001, dot(shadingParams.v, shadingParams.n));

                shadingParams.gi = GetGI(GI_FRAGMENT_DATA(i), shadingParams.pos_world, shadingParams.n, shadingParams.v, GET_PROP(_AmbientColor), shadingParams.roughness, GET_PROP(_AmbientSpecStrength_SHStrength).y);

                half3 brdfCol = 0.0;
                // dir light
                for(int lightIndex = 0; lightIndex < _DirectionalLightCount; lightIndex++)
                {
                    shadingParams.lightIndex = lightIndex;
                    brdfCol += BRDF_FromLUT_DirLight(shadingParams);
                }

                // add light
                #if defined(_LIGHTS_PER_OBJECT)
                    for(int j = 0; j < min(unity_LightData.y, 8.0); j++)
                    {
                        int lightIndex = unity_LightIndices[(uint)j / 4][(uint)j % 4]; // 无符号数的除法和取模会更快
                        shadingParams.lightIndex = lightIndex;
                        brdfCol += BRDF_FromLUT_OtherLight(shadingParams);
                    }
                #else
                    for(int j = 0; j < _OtherLightCount; j++)
                    {
                        shadingParams.lightIndex = j;
                        brdfCol += BRDF_FromLUT_OtherLight(shadingParams);
                    }
                #endif

                #ifdef _PointLight
                brdfCol += GetCustomeObjPointLightShading(GET_PROP(_PointLightColor), i.point_light_params, shadingParams);
                #endif

                brdfCol += GetGIShadingFromLUT(shadingParams, ao);
                half3 col = brdfCol;
                #ifdef _Emission
                half4 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv.xy);
                col = (1.0 - emission.a) * col + emission.a * emission.rgb * GET_PROP(_EmissionStrength);
                #endif
                half3 pointEmission = 0.0;
                
                #ifndef _EmissionPointOff
                half emissionPointMask = SAMPLE_TEXTURE2D(_EmissionPointMask, sampler_EmissionPointMask, i.uv.xy).r;
                half emissionPoint = EmissionPoint(i.uv.xy, GET_PROP(_EmissionPointDensity), GET_PROP(_EmissionPointCutoff_EmissionPointFrequency).x, emissionPointMask, GET_PROP(_EmissionPointNoiseOffset), GET_PROP(_EmissionPointCutoff_EmissionPointFrequency).y,
                GET_PROP(_EmissionPointPulse).x, GET_PROP(_EmissionPointPulse).y);
                pointEmission = max(0.0, emissionPoint * GET_PROP(_EmissionPointColor));
                #endif

                col.rgb += pointEmission;
                half bloom = EncodeBloomLuminanceImpl(col.rgb, GET_PROP(_PostProcessFactors).x, GET_PROP(_PostProcessFactors).y);
                col.rgb = lerp(col.rgb, col.rgb * GET_PROP(_BloomColor), bloom);
                FragOutput output;
                output.color = half4(col, 1.0);
                output.flags = half4(bloom, 0.0, 0.0, 0.0);
                // col = lerp(col * _BloomColor, col, bloom);
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
            #pragma multi_compile_instancing
            #pragma multi_compile_local __ _PointLight
            #pragma multi_compile_local __ _HeightMap
            #pragma multi_compile_local __ _Emission
            #pragma multi_compile_local __ _EmissionPointLow _EmissionPointMid
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/BPipline/Shaders/Libiary/Common.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_DetilTex);
            SAMPLER(sampler_DetilTex);
            TEXTURE2D(_DetilNormalTex);
            SAMPLER(sampler_DetilNormalTex);
            TEXTURE2D(_MRATex);
            SAMPLER(sampler_MRATex);
            TEXTURE2D(_AmbientTex);
            SAMPLER(sampler_AmbientTex);

            #ifndef _EmissionPointOff
                TEXTURE2D(_EmissionPointMask);
                SAMPLER(sampler_EmissionPointMask);
            #endif

            #ifdef _Emission
                TEXTURE2D(_EmissionMap);
                SAMPLER(sampler_EmissionMap);
            #endif

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                #ifdef _Emission
                    UNITY_DEFINE_INSTANCED_PROP(half, _EmissionStrength)
                #endif

                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _DetilTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(half3, _DiffuseColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _DetilColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _Fresnel)
                UNITY_DEFINE_INSTANCED_PROP(half3, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _SpecularColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _MetallicRoughnessAO)
                UNITY_DEFINE_INSTANCED_PROP(half2, _NormalScales)
                UNITY_DEFINE_INSTANCED_PROP(half4, _KdKsExpoureParalxScale)

                #ifdef _PointLight
                    UNITY_DEFINE_INSTANCED_PROP(half3, _PointLightColor)
                    UNITY_DEFINE_INSTANCED_PROP(half3, _PointLightPos)
                #endif

                UNITY_DEFINE_INSTANCED_PROP(half2, _AmbientSpecStrength_SHStrength)

                #ifndef _EmissionPointOff
                    UNITY_DEFINE_INSTANCED_PROP(half2, _EmissionPointDensity)
                    UNITY_DEFINE_INSTANCED_PROP(float2, _EmissionPointCutoff_EmissionPointFrequency)
                    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionPointNoiseOffset)
                    UNITY_DEFINE_INSTANCED_PROP(half3, _EmissionPointColor)
                    UNITY_DEFINE_INSTANCED_PROP(half3, _EmissionGloss)
                    UNITY_DEFINE_INSTANCED_PROP(half2, _EmissionPointPulse)
                #endif

                UNITY_DEFINE_INSTANCED_PROP(half3, _BloomColor)
                UNITY_DEFINE_INSTANCED_PROP(half3, _PostProcessFactors)
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
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                v.vertex.xy = v.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                v.vertex.z = v.vertex.z > 0.0 ? FLT_MIN : 0.0;
                o.vertex = TransformWorldToHClip(v.vertex.xyz);
                o.uv.xy = v.uv * GET_PROP(_MainTex_ST).xy + GET_PROP(_MainTex_ST).zw;
                o.uv.zw = v.uv * GET_PROP(_DetilTex_ST).xy + GET_PROP(_DetilTex_ST).zw; // detil map
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                mainTex.rgb *= GET_PROP(_DiffuseColor).rgb;

                half4 detil = SAMPLE_TEXTURE2D(_DetilTex, sampler_DetilTex, i.uv.zw);
                half detilMask = detil.a;

                half3 MRA = SAMPLE_TEXTURE2D(_MRATex, sampler_MRATex, i.uv.xy).rgb;
                half roughness = max(0.02, GET_PROP(_MetallicRoughnessAO).y * MRA.g);
                half oneMinusMetallic = 1.0 - MRA.r * GET_PROP(_MetallicRoughnessAO).x;
                half ao = saturate(1.0 - (1.0 - MRA.b) * GET_PROP(_MetallicRoughnessAO).z);
                half3 fresnelCol = lerp(GET_PROP(_Fresnel), 0.09, oneMinusMetallic);

                half3 albedo = lerp(GET_PROP(_DiffuseColor) * mainTex.rgb, 
                    GET_PROP(_DetilColor) * SAMPLE_TEXTURE2D(_DetilTex, sampler_DetilTex, i.uv.zw).rgb, detilMask) * GET_PROP(_KdKsExpoureParalxScale).x;
                half3 specular = lerp(albedo, GET_PROP(_SpecularColor), oneMinusMetallic) * GET_PROP(_KdKsExpoureParalxScale).y;
                albedo *= oneMinusMetallic;

                float4 meta = 0.0;
                if(unity_MetaFragmentControl.x)
                {
                    meta.rgb += albedo;
                    meta.rgb += specular * roughness * 0.5;
                    // meta.rgb += specular * roughness * 0.5
                    meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
                }
                else if(unity_MetaFragmentControl.y)
                {
                    #ifdef _Emission
                    half4 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv.xy);
                    meta.rgb += emission.rgb * emission.a * GET_PROP(_EmissionStrength);
                    #endif
                    meta.rgb += GET_PROP(_AmbientColor);
                }
                meta.a = 1.0;
                return meta;
            }
            ENDHLSL
        }
    }
    CustomEditor "BRDF_LUT_Inspector"
}
