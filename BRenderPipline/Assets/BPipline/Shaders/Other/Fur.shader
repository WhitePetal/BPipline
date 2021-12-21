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
        [VectorRange(0.0, 2.0, 0.0, 2.0, 0.0, 1.0)]_PostProcessFactors("辉光强度_辉光阈值_马赛克", Vector) = (0.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }

        ZWrite On
        HLSLINCLUDE
        #pragma multi_compile_local __ GRAVITY_ON
        #pragma multi_compile_local __ WIND_ON
        ENDHLSL

        Pass
        {
            Tags {"LightMode"="BFurPass"}
            Blend 0 SrcAlpha OneMinusSrcAlpha
            Blend 1 Off
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag
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
            half _FurOffset;

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

            v2f vert(a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                TRANSFER_GI_DATA(v, o);
                o.pos_world.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.normal_world = TransformObjectToWorldNormal(v.normal);
                o.tangent_world = TransformObjectToWorldDir(v.tangent.xyz);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;

                half fur_offset = _FurOffset;

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

            FragOutput frag(v2f i)
            {  
                UNITY_SETUP_INSTANCE_ID(i);
                half fur_offset = _FurOffset;
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
                half bloom = EncodeBloomLuminanceImpl(col.rgb, GET_PROP(_PostProcessFactors.x), GET_PROP(_PostProcessFactors.y));
                FragOutput output;
                output.color = half4(col, shape);
                output.flags = half4(bloom, 0.0, 0.0, 0.0);
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
            half _FurOffset;

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
