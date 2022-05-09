#ifndef SHADER_UTIL_INCLUDE
#define SHADER_UTIL_INCLUDE

// 白噪声
half ValueNoise(half2 uv)
{
    half2 Noise_skew = uv + 0.2127 + uv.x * uv.y * 0.3713;
    half2 Noise_rnd = 4.789 * sin(489.123 * (Noise_skew));
    return frac(Noise_rnd.x * Noise_rnd.y * (1.0 + Noise_skew.x));
}

// 晶胞噪声
half voronoiNoise(half2 x, half u, half v )
{
    half2 p = floor(x);
    half2 f = frac(x);

    half k = 1.0 + 63.0*pow(1.0-v,4.0);
    half va = 0.0;
    half wt = 0.0;
    [unroll]
    for( int j=-2; j<=2; j++ )
        for( int i=-2; i<=2; i++ )
        {
            half2  g = half2(i, j);
            half3  o = ValueNoise( p + g )*half3(u,u,1.0);
            half2  r = g - f + o.xy;
            half d = dot(r,r);
            float w = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
            va += w*o.z;
            wt += w;
        }

    return va/wt;
}

// 白噪声 st：输入 n：随机种子
half random (float2 st, half n) {
    st = floor(st * n);
    return frac(sin(dot(st.xy, float2(12.123,78.233)))*43758.0);
}

float2 randVec(float2 value)
{
    float2 vec = float2(dot(value, float2(127.1, 337.1)), dot(value, float2(269.5, 183.3)));
    vec = 0.5 + 0.5 * frac(sin(vec) * 43758.123);
    return vec;
}

half4 randomPos(half4 vec, half4 noiseOffset, half frequency)
{
    // (half4(random(vec.xy, 2), random(vec.xy, 4), random(vec.zw, 2), random(vec.zw, 4)) - 0.5);
    return (half4(random(vec.xy, frequency), random(vec.xy, frequency), random(vec.zw, frequency), random(vec.zw, frequency)) - 0.5) * noiseOffset;
    // return (half4(tex2D(_NoiseMap, vec.xy).rg, tex2D(_NoiseMap, vec.zw).rg) - 0.5) * _NoiseStrength;
}

//柏林噪声
half perlinNoise(half2 uv)
{
    half a, b, c, d;
    half x0 = floor(uv.x); 
    half x1 = ceil(uv.x); 
    half y0 = floor(uv.y); 
    half y1 = ceil(uv.y); 
    half2 pos = frac(uv);
    a = dot(randVec(half2(x0, y0)), pos - half2(0, 0));
    b = dot(randVec(half2(x0, y1)), pos - half2(0, 1));
    c = dot(randVec(half2(x1, y1)), pos - half2(1, 1));
    d = dot(randVec(half2(x1, y0)), pos - half2(1, 0));
    half2 st = 6 * pow(pos, 5) - 15 * pow(pos, 4) + 10 * pow(pos, 3);
    a = lerp(a, d, st.x);
    b = lerp(b, c, st.x);
    a = lerp(a, b, st.y);
    return a;
}

float Square(float value)
{
    return value * value;
}

half Square(half value)
{
    return value * value;
}

float2 GetParallxOffset(half height, half3 view_tangent, half ParallxScale)
{
    return view_tangent.xy / view_tangent.z * height * ParallxScale;
}

// ------------------------- 波函数集合 (phase: 初相位，frequency：频率，amplitude：振幅) ----------------------------------
    // 正弦
    half sin_wave(half phase, half frequency, half amplitude){
        return amplitude * sin(phase + _Time.y * frequency);
    }
    // 余弦
    half cos_wave(half phase, half frequency, half amplitude){
        return amplitude * cos(phase + _Time.y * frequency);
    }
    // 山型
    half hill_wave(half phase, half frequency, half amplitude){
        return amplitude * abs(sin(phase + _Time.y * frequency));
    }
    // 倒转山型
    half inverseHill_wave(half phase, half frequency, half amplitude){
        return amplitude * (1.0 - abs(sin(phase + _Time.y * frequency)));
    }
    // 锯齿
    half sawTooth_wave(half phase, half frequency, half amplitude){
        return amplitude * saturate(fmod(phase + _Time.y, 1.0));
    }
    // 倒转锯齿
    half inverseSawTooth_wave(half phase, half frequency, half amplitude){
        return amplitude * (1.0-saturate(fmod(phase + _Time.y, 1.0)));
    }
    // 指数锯齿
    half exponentialSawTooth_wave(half phase, half frequency, half amplitude){
        return amplitude * saturate(pow(frac(phase + _Time.y * frequency),10.0));
    }
    // 倒转指数锯齿
    half inverseExponentialSawTooth_wave(half phase, half frequency, half amplitude){
        return amplitude * (1.0-saturate(pow(fmod(phase + _Time.y * frequency,1.0),10.0)));
    }
    // 饱和指数锯齿
    half saturateExponentialSawTooth_wave(float phase, half frequency, half amplitude){
        return amplitude * saturate(saturate(pow(fmod(phase + _Time.y * frequency, 1.0), 10.0)) * 100.0);
    }
    // 三角型
    float triangle_wave(float phase, float frequency, float amplitude){
        return amplitude * abs(fmod(phase + _Time.y * frequency, 1.0) * 2.0 - 1.0);
    }
    // 梯型
    half trapezium_wave(half phase, half frequency, half amplitude){
        return amplitude * saturate(abs(fmod(phase + _Time.y * frequency, 1.0) * 2.0 - 1.0) * 2.0);
    }
    // 不连续三角形
    float discreteTriangle(float phase, float frequency, float amplitude){
        return amplitude * (1.0-saturate(abs(fmod(phase + _Time.y * frequency, 1.0) * 4.0 - 2.0)));
    }
    // 离散直角
    half rightAngle_wave(half phase, half frequency, half amplitude){
        return amplitude * round(sin(phase + _Time.y * frequency));
    }
    // 风波
    half wind_wave(half wind_scale, half wind_frequency, half3 wind_dir, half3 pos_world)
    {
        half phase_base = dot(wind_dir, pos_world);
        half wave = sin(_Time.y * wind_frequency);
        wave += sin(_Time.y * wind_frequency + phase_base);
        wave = wave * 2.0 - 2.0;
        wave += cos(_Time.y * wind_frequency * 2 + phase_base) - 0.5;
        return wave * wind_scale;
    }
// ----------------------------------------------------------------------------------------------------------------------

// 闪点 返回值：闪点亮度 参数：uv、闪点密度、闪点过滤阈值，闪点遮罩、噪声偏移、噪声频率(噪声偏移 和 频率 是防止生成的噪声出现重复)、闪点闪烁初相位，闪点闪烁频率
half EmissionPoint(float2 uv, float2 density, float cutoff, half mask, half4 noiseOffset, half noiseFrequency, half pulsePhase, half pulseFrequency)
{
    float emissionPoit = 0.0;
    float2 uv_graid = (uv.xy + noiseOffset.xy) * density;
    float2 uv_center = floor(uv_graid) + 0.5;
    float rand = random(uv_center, noiseFrequency);
    #ifdef _EmissionPointHeight
        half4 uv_center_rl = half4(uv_center.x + 1, uv_center.y, uv_center.x - 1, uv_center.y);
        half4 uv_center_tb = half4(uv_center.x, uv_center.y + 1, uv_center.x, uv_center.y - 1);
        half4 uv_center_rr = half4(uv_center.x + 1, uv_center.y + 1, uv_center.x + 1, uv_center.y - 1);
        half4 uv_center_ll = half4(uv_center.x - 1, uv_center.y - 1, uv_center.x - 1, uv_center.y + 1);

        half2 uv_random = uv_center + (half2(random(uv_center.xy, noiseFrequency), random(uv_center.xy, noiseFrequency)) - 0.5) * noiseOffset.xy;
        half4 uv_random_rl = uv_center_rl +randomPos(uv_center_rl, noiseOffset, noiseFrequency);
        half4 uv_random_tb = uv_center_tb + randomPos(uv_center_tb, noiseOffset, noiseFrequency);
        half4 uv_random_rr = uv_center_rr + randomPos(uv_center_rr, noiseOffset, noiseFrequency);
        half4 uv_random_ll = uv_center_ll + randomPos(uv_center_ll, noiseOffset, noiseFrequency);


        half r0 = dot(uv_random - uv_graid, uv_random - uv_graid);
        half r1 = dot(uv_random_rl.xy - uv_graid, uv_random_rl.xy - uv_graid);
        half r2 = dot(uv_random_rl.zw - uv_graid, uv_random_rl.zw - uv_graid);
        half r3 = dot(uv_random_tb.xy - uv_graid, uv_random_tb.xy - uv_graid);
        half r4 = dot(uv_random_tb.zw - uv_graid, uv_random_tb.zw - uv_graid);
        half4 rr0 = half4(r1, r2, r3, r4);
        half r5 = dot(uv_random_ll.xy - uv_graid, uv_random_ll.xy - uv_graid);
        half r6 = dot(uv_random_ll.zw - uv_graid, uv_random_ll.zw - uv_graid);
        half r7 = dot(uv_random_rr.xy - uv_graid, uv_random_rr.xy - uv_graid);
        half r8 = dot(uv_random_rr.zw - uv_graid, uv_random_rr.zw - uv_graid);
        half4 rr1 = half4(r5, r6, r7, r8);
        rr0 = smoothstep(0.0, cutoff, rr0);
        rr1 = smoothstep(0.0, cutoff, rr1);
        rr0 *= rr1;
        // half4 rt = smoothstep(0.0, cutoff, rr0);
        emissionPoit = 1.0 - smoothstep(0.0, cutoff, r0) * rr0.x * rr0.y * rr0.z * rr0.w;
    #elif defined(_EmissionPointMid)
        float2 uv_random = uv_center + (rand - 0.5);
        float2 dir = uv_random - uv_graid;
        emissionPoit = dot(dir, dir);
        float2 atten2 = abs(uv_graid - uv_center);
        float atten = 1.0 - atten2.x - atten2.y;
        // half4 rt = smoothstep(0.0, cutoff, rr0);
        emissionPoit = 1.0 - smoothstep(0.0, cutoff, emissionPoit);
        emissionPoit *= atten * atten;
    #elif defined(_EmissionPointLow)
        emissionPoit = rand;
        // half4 rt = smoothstep(0.0, cutoff, rr0);
        emissionPoit = 1.0 - smoothstep(0.0, cutoff, emissionPoit);
    #endif

    half wave = triangle_wave(rand * pulsePhase, pulseFrequency + pulseFrequency, .5);
    wave += sin_wave(rand * pulsePhase + pulsePhase, pulseFrequency, 0.5) + 0.5;
    emissionPoit *= wave;

    return emissionPoit * mask;
}

half EncodeBloomLuminanceImpl(half3 color, half luminance, half threshold)
{
    half l = dot(color, half3(0.299f, 0.587f, 0.114f));
    l = max(l - threshold, 0.001) * luminance;
    l = l / (1.0 + l);
    return 1.0 - l;
}

half DecodeBloomLuminanceImpl(half flag)
{
    half l = max(1.0 - flag, 0.0001);
    l = 1.0 / ((1.0 / l) - 1.0);
    return l;
}

half3 ToneMapping_ACES(half3 color, half adapted_lum)
{
	const half A = 2.51;
	const half B = 0.03;
	const half C = 2.43;
	const half D = 0.59;
	const half E = 0.14;

	color *= adapted_lum;
	return (color * (A * color + B)) / (color * (C * color + D) + E);
}

half3 ToneMapping_ACES_DS(half3 color, half adapted_lum)
{
    color *= adapted_lum;
    return half3(
        dot(half3(0.613118, 0.341182, 0.0457873), color),
        dot(half3(0.0699341, 0.918103, 0.0119328), color),
        dot(half3(0.020463, 0.106769, 0.872716), color)
    );
}

half3 ACES_To_Linear(half3 col)
{
    half3 res = half3(
        dot(half3(1.7049, -0.62416, -0.0809141), col),
        dot(half3(-0.129553, 1.13837, -0.00876801), col),
        dot(half3(-0.0241261, -0.124633, 1.14882), col)
    );
    return max(0.0001, res);
}

half3 ACES_To_sRGB(half3 col)
{
    return sqrt(ACES_To_Linear(col));
}

half3 ToneMapping_ACES_To_sRGB(half3 color, half adapted_lum)
{
    return ACES_To_sRGB(color * adapted_lum);
}
inline float2 EncodeFloatRG( float v )
{
    float2 kEncodeMul = float2(1.0, 255.0);
    float kEncodeBit = 1.0/255.0;
    float2 enc = kEncodeMul * v;
    enc = frac (enc);
    enc.x -= enc.y * kEncodeBit;
    return enc;
}
inline float DecodeFloatRG( float2 enc )
{
    float2 kDecodeDot = float2(1.0, 1/255.0);
    return dot( enc, kDecodeDot );
}

#endif