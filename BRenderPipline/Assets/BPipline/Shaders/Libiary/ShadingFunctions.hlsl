#ifndef SHADING_FUNCTIONS_INCLUDE
#define SHADING_FUNCTIONS_INCLUDE

#if _BRDF_LUT || _BSDF_LUT || _BSSSDF_LUT
struct ShadingParams
{
    int lightIndex;
    half roughness;
    half3 n;
    half3 v;
    half ndotv;
    half expoure;
    float depth;
    float3 pos_world;
    float4 pos_clip;
    half3 albedo;
    half3 specular;
    GI gi;
};

half3 GetCustomeObjPointLightShading(half3 pointLightColor, half4 point_light_params, ShadingParams params)
{
    return pointLightColor * point_light_params.w * saturate(dot(normalize(point_light_params.xyz), params.n)) * params.albedo;
}
#endif

#if _BRDF_LUT || _BSDF_LUT || _BSSSDF_LUT
half3 GetGIShadingFromLUT(ShadingParams params, half ao)
{
    half3 f = params.specular + (1.0 - params.specular) * SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(params.ndotv, 1.0), 0).r;
    return (params.albedo * params.gi.diffuse + params.specular * f * params.gi.specular) * ao;
}
inline void GetCustomeGIShadingFromLUT(in ShadingParams params, in half oneMinusMetallic, in half roughness, in half3 col, in half2 strength, in half ao, out half3 brdfCol_diffuse, out half3 brdfCol_specular)
{
    half3 f = SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(params.ndotv, 1.0), 0).r;
    brdfCol_diffuse = params.albedo * params.gi.diffuse * ao * col * strength.y;
    brdfCol_specular = lerp(params.specular, saturate(2.0 - params.roughness - oneMinusMetallic), f) * params.gi.specular * ao * strength.x;
}
#endif

#if _BRDF_LUT
inline void BRDF_FromLUT_DirLight(in ShadingParams params, out half3 brdfCol_diffuse, out half3 brdfCol_specular)
{
    half3 l = _DirectionalLightDirections[params.lightIndex].xyz;
    half3 h = normalize(l + params.v);
    half ldoth = DotClamped(l, h);
    half ndoth = DotClamped(params.n, h);
    half ndotl = saturate(DotClamped(params.n, l) + params.expoure);

    half3 fgd = half3(
        SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ldoth, 1.0), 0).r,
        SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ndoth, ldoth), 0).g,
        SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(params.roughness, ndoth), 0).b
    );
    half3 f = params.specular + (1.0 - params.specular) * fgd.x;
    half g = 1.0 / fgd.y - 1.0;
    g = min(1.0, (min(params.ndotv * g, ndotl * g)));
    half d = 1.0 / fgd.z - 1.0;
    half3 shadowAtten = GetDirectionalShadowAttenuation(params.lightIndex, params.gi.shadowMask, params.depth, params.pos_world, params.pos_clip.xy, params.n);
    brdfCol_diffuse = (1.0 - f) * params.albedo * min(ndotl, shadowAtten) * _DirectionalLightColors[params.lightIndex].rgb;
    brdfCol_specular = _DirectionalLightColors[params.lightIndex].rgb * 0.7854 * f * g * d / params.ndotv;
}
#endif

#if _BRDF_LUT || _BSDF_LUT || _BSSSDF_LUT
inline void BRDF_FromLUT_OtherLight(in ShadingParams params, out half3 brdfCol_diffuse, out half3 brdfCol_specular)
{
    float3 dir = _OtherLightPositions[params.lightIndex].xyz - params.pos_world;
    half3 l = normalize(dir);
    half3 h = normalize(l + params.v);
    half ndotl = saturate(DotClamped(l, params.n) + params.expoure);
    half ndoth = DotClamped(h, params.n);
    half ldoth = DotClamped(l, h);
    half3 fgd = half3(
        SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ldoth, 1.0), 0).r,
        SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ndoth, ldoth), 0).g,
        SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(params.roughness, ndoth), 0).b
    );
    half3 f = params.specular + (1.0 - params.specular) * fgd.x;
    half g = 1.0 / fgd.y - 1.0;
    g = min(1.0, (min(params.ndotv * g, ndotl * g)));
    half d = 1.0 / fgd.z - 1.0;

    half4 spotAngles = _OtherLightSpotAngles[params.lightIndex];
    half spotAtten = Square(saturate(dot(_OtherLightDirections[params.lightIndex].xyz, l)) * spotAngles.x + spotAngles.y);
    half dstSqr = max(dot(dir, dir), 0.0001);
    half rangeAtten = Square(saturate(1.0 - Square(dstSqr * _OtherLightPositions[params.lightIndex].w)));
    half atten = spotAtten * rangeAtten / dstSqr;
    // half3 shadowAtten = GetOtherLightShadowAttenuation(params.lightIndex, params.shadowData);
    brdfCol_diffuse = (1.0 - f) * params.albedo * min(ndotl, atten) * _OtherLightColors[params.lightIndex].rgb;
    brdfCol_specular = _OtherLightColors[params.lightIndex].rgb * f * g * d / params.ndotv;
}
#endif

#if _BSDF_LUT
half3 BSDF_FromLUT_DirLight(ShadingParams params, half shift, half3 binormal, half4 shifts_specularWidths, half4 exponents_specStrengths, half3 specCol1, half3 specCol2)
{
    half3 l = _DirectionalLightDirections[params.lightIndex].xyz;
    half3 h = normalize(l + params.v);
    half ndotl = saturate(DotClamped(l, params.n) + params.expoure);
    half ndoth = DotClamped(h, params.n);
    half ldoth = DotClamped(l, h);
    half3 f = params.fresnelCol + (1.0 - params.fresnelCol) * SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ndotl, 1.0), 0).r;
    half g = 1.0 / SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ndoth, ldoth), 0).g - 1.0;

    binormal = -binormal;
    half3 t1 = normalize(binormal + (shifts_specularWidths.x + shift) * params.n);
    half3 t2 = normalize(binormal + (shifts_specularWidths.y + shift) * params.n);
    half t1doth = dot(t1, h);
    half t2doth = dot(t2, h);
    g = min(1.0, (min(params.ndotv * g, saturate(max(t1doth, t2doth)) * g)));

    half dirAtten1 = smoothstep(shifts_specularWidths.z, 0.0, t1doth);
    half dirAtten2 = smoothstep(shifts_specularWidths.w, 0.0, t2doth);

    half3 d1 = SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(t1doth * t1doth, exponents_specStrengths.x), 0).a * 1.0 * specCol1 * exponents_specStrengths.z;
    half3 d2 = SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(t2doth * t2doth, exponents_specStrengths.y), 0).a * 1.0 * specCol2 * params.albedo * 2.0 * exponents_specStrengths.w;
    half3 df = d1 + d2;

    half3 shadowAtten = GetDirectionalShadowAttenuation(params.lightIndex, params.gi.shadowMask, params.depth, params.pos_world, params.pos_clip.xy, params.n);
    return ((1.0 - f) * params.albedo * ndotl + params.specular * f * g * df / params.ndotv) * _DirectionalLightColors[params.lightIndex].rgb * shadowAtten;
}
#endif

#if _BSSSDF_LUT
half3 BSSSDF_FromLUT_DirLight(ShadingParams params)
{
    half3 l = _DirectionalLightDirections[params.lightIndex].xyz;
    half3 h = normalize(l + params.v);
    half r = fwidth(params.n) / fwidth(params.pos_world);
    half ndotl = saturate(DotClamped(l, params.n) + params.expoure);
    half3 ndotl_sss = SAMPLE_TEXTURE2D_LOD(_LUT_SSS, sampler_LUT_SSS, half2(ndotl, r), 0);
    half ndoth = DotClamped(h, params.n);
    half ldoth = DotClamped(l, h);
    half3 f = params.fresnelCol + (1.0 - params.fresnelCol) * SAMPLE_TEXTURE2D_LOD(_LUT, sampler_LUT, half2(ndotl, 1.0), 0).r;
    half g = 1.0 / SAMPLE_TEXTURE2D(_LUT, sampler_LUT, half2(ndoth, ldoth)).g - 1.0;
    g = min(1.0, (min(params.ndotv * g, ndotl * g)));
    half d = 1.0 / SAMPLE_TEXTURE2D(_LUT, sampler_LUT, half2(params.roughness, ndoth)).b - 1.0;
    half3 shadowAtten = GetDirectionalShadowAttenuation(params.lightIndex, params.gi.shadowMask, params.depth, params.pos_world, params.pos_clip.xy, params.n);
    return ((1.0 - f) * params.albedo * ndotl_sss + params.specular * f * g * d / params.ndotv) * _DirectionalLightColors[params.lightIndex].rgb * shadowAtten;
}
#endif


#if _HalfLambert
struct ShadingParams
{
    int lightIndex;
    half expoure;
    half2 gloss_glossBase;
    float depth;
    float3 pos_world;
    float4 pos_clip;
    half3 n;
    half3 v;
    half3 albedo;
    half3 specular;
    GI gi;
};

half3 GetGIShading_Half_Lambert(ShadingParams params, half ao)
{
    return params.albedo * params.gi.diffuse * ao;
}
half3 Half_Lambert_DirLight(ShadingParams params)
{
    half3 l = _DirectionalLightDirections[params.lightIndex].xyz;
    half3 h = normalize(l + params.v);
    half ndotl = saturate(DotClamped(l, params.n) + params.expoure);
    half ndoth = DotClamped(h, params.n);
    half3 shadowAtten = GetDirectionalShadowAttenuation(params.lightIndex, params.gi.shadowMask, params.depth, params.pos_world, params.pos_clip.xy, params.n);
    half3 specular = pow(ndoth, params.gloss_glossBase.x * params.gloss_glossBase.y) * params.specular;
    return (params.albedo * ndotl * (1.0 - specular) + specular) * _DirectionalLightColors[params.lightIndex].rgb * shadowAtten;
}

half3 Half_Lambert_OtherLight(ShadingParams params)
{
    float3 dir = _OtherLightPositions[params.lightIndex].xyz - params.pos_world;
    half3 l = normalize(dir);
    half3 h = normalize(l + params.v);
    half ndotl = saturate(DotClamped(l, params.n) + params.expoure);
    half ndoth = DotClamped(h, params.n);

    half4 spotAngles = _OtherLightSpotAngles[params.lightIndex];
    half spotAtten = Square(saturate(dot(_OtherLightDirections[params.lightIndex].xyz, l)) * spotAngles.x + spotAngles.y);
    half dstSqr = max(dot(dir, dir), 0.0001);
    half rangeAtten = Square(saturate(1.0 - Square(dstSqr * _OtherLightPositions[params.lightIndex].w)));
    half atten = spotAtten * rangeAtten / dstSqr;
    // half3 shadowAtten = GetOtherLightShadowAttenuation(params.lightIndex, params.shadowData);
    half3 specular = pow(ndoth, params.gloss_glossBase.x * params.gloss_glossBase.y) * params.specular;
    return (params.albedo * ndotl * (1.0 - specular) + specular) * _OtherLightColors[params.lightIndex].rgb * atten /** * shadowAtten **/;
}
#endif

#if _CommonNoLight
half3 GetGIShading_Common_NoLight(GI gi, half3 albedo, half ao)
{
    return albedo * gi.diffuse * ao;
}
#endif

#endif