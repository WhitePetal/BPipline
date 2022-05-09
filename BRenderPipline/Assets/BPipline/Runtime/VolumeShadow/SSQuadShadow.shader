Shader "Unlit/SSQuadShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        ZWrite Off
        ZTest Off

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            uniform sampler2D _TestQTreeTex;
            uniform int _TestQTreeWidth;
            uniform float4x4 _FrustumCornerRay;
            int _GridNum;
            float _GridSize_Inv;

            // 这个在要在片元里面计算，并且计算步骤太多，舍弃，采用射线插值法
            float4 GetWorldPositionFromDepthValue(float2 uv, float linearDepth)
            {
                float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;
                float height = 2 * camPosZ / unity_CameraProjection._m11;
                float width = _ScreenParams.x / _ScreenParams.y * height;

                float camPosX = width * uv.x - width * 0.5;
                float camPosY = height * uv.y - height * 0.5;
                float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
                return mul(unity_CameraToWorld, camPos);
            }

            int4 GetTreeValue(int index)
            {
                return tex2D(_TestQTreeTex, float2(index % _TestQTreeWidth, index / _TestQTreeWidth) / _TestQTreeWidth);
            }

            half ShadowValue(float3 wpos)
            {
                int x = wpos.x * _GridSize_Inv + 0.5;
                int y = wpos.y * _GridSize_Inv + 0.5;
                int z = wpos.z * _GridSize_Inv + 0.5;
                int index = 0;
                int size = _GridNum;
                [unroll(10)]
                while(1)
                {
                    int4 node = GetTreeValue(index);
                    int flag = node.w % 10;
                    node.w = node.w / 10;
                    
                    if(node.w == 0) return 1-flag;
                    if(size == 1) return 1;
                    int childIndex = 0;
                    int cSize = size >> 1;
                    if(x > node.x + cSize) childIndex++;
                    if(y > node.y + cSize) childIndex += 2;
                    if(z > node.z + cSize) childIndex += 4;
                    index = node.w + childIndex;
                    size = cSize;
                }
                return 1;
            }

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 interpolateRay : TEXCOORD1;
            };

            v2f vert(appdata_img v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

                float2 uv = v.texcoord;
                #if UNITY_UV_STARTS_AT_TOP
                    if (_MainTex_TexelSize.y < 0.0)
                        uv = uv * float2(1.0, -1.0) + float2(0.0, 1.0);
                #endif
                o.uv = uv;
                // 射线插值法构建世界坐标
                int index= 0;
                if (v.texcoord.x < 0.5 && v.texcoord.y > 0.5) {
                    index = 0;
                } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                    index = 1;
                }  else if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
                    index = 2;
                } else {
                    index = 3;
                }
                o.interpolateRay = _FrustumCornerRay[index];
						
				return o;
			}


            fixed4 frag (v2f i) : SV_Target
            {
                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float linearDepth = Linear01Depth(rawDepth);
                float3 worldPos = _WorldSpaceCameraPos.xyz + linearDepth * i.interpolateRay.xyz;
                // 为了避免自阴影，可以把坐标沿光方向偏移。但是又会导致漏光问题
                // worldPos += _WorldSpaceLightPos0.xyz * 5.5;
                // return float4(worldPos, 1.0);
                float atten = 1.0;
                return ShadowValue(worldPos);
                // 因为四叉树对应的是平面，所以地平面上面的地方认为不在阴影范围，只有地平面受阴影
                // atten = lerp(ShadowValue(worldPos + half3(0.0, 0.0, 0.2)), 1, saturate(worldPos.y * 100.0));
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert_img
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _TestQTreeMaskTex;
            float4 _TestQTreeMaskTex_TexelSize;
            static float2 position[12] = 
            {
                float2(-0.326212f, -0.40581f),
                float2(-0.840144f, -0.07358f),
                float2(-0.695914f, 0.457137f),
                float2(-0.203345f, 0.620716f),
                float2(0.96234f, -0.194983f),
                float2(0.473434f, -0.480026f),
                float2(0.519456f, 0.767022f),
                float2(0.185461f, -0.893124f),
                float2(0.507431f, 0.064425f),
                float2(0.89642f, 0.412458f),
                float2(-0.32194f, -0.932615f),
                float2(-0.791559f, -0.59771f)
            };

            fixed4 frag (v2f_img i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                half atten = tex2D(_TestQTreeMaskTex, i.uv);
                for(int k = 0; k < 12; ++k)
                {
                    atten += tex2D(_TestQTreeMaskTex, i.uv + position[k] * _TestQTreeMaskTex_TexelSize.xy * 2.0);
                }
                return col * lerp(0, 1.0, (pow(atten * 0.077, 3) + 0.3) * 0.769);
            }
            ENDCG
        }
    }
}
