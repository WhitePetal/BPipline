#ifndef CUSTOME_UNITY_LIGHT_INCLUDE
#define CUSTOME_UNITY_LIGHT_INCLUDE

#define MAX_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_OTHER_LIGHT_COUNT 64

struct Light
{
    half3 color;
    half3 directional;
    half atten;
};

CBUFFER_START(_CustomLight)
    int _DirectionalLightCount;
    half4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    half4 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
    half4 _DirectionalLightShadowDatas[MAX_DIRECTIONAL_LIGHT_COUNT];

    int _OtherLightCount;
    half4 _OtherLightColors[MAX_OTHER_LIGHT_COUNT];
    float4 _OtherLightPositions[MAX_OTHER_LIGHT_COUNT];
    half4 _OtherLightDirections[MAX_OTHER_LIGHT_COUNT];
    half4 _OtherLightSpotAngles[MAX_OTHER_LIGHT_COUNT];
    half4 _OtherLightShadowDatas[MAX_OTHER_LIGHT_COUNT];
CBUFFER_END

Light GetDirectionalLight(int index)
{
    Light light;
    light.color = _DirectionalLightColors[index].xyz;
    light.directional = _DirectionalLightDirections[index].xyz;
    return light;
}

#endif