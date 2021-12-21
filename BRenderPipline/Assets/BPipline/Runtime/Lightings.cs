using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Lightings
{
	private const int maxDirLightCount = 4, maxOtherLightCount = 64;
	private static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");
	private static int dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors");
	private static int dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections");
	private static int dirLightShadowDatasId = Shader.PropertyToID("_DirectionalLightShadowDatas");
	private static int otherLightCountId = Shader.PropertyToID("_OtherLightCount");
	private static int otherLightColorsId = Shader.PropertyToID("_OtherLightColors");
	private static int otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions");
	private static int otherLightDirectionsId = Shader.PropertyToID("_OtherLightDirections");
	private static int otherLightSpotAnglesId = Shader.PropertyToID("_OtherLightSpotAngles");
	private static int otherLightShadowDatasId = Shader.PropertyToID("_OtherLightShadowDatas");
	private static Vector4[] dirLightColors = new Vector4[maxDirLightCount];
	private static Vector4[] dirLightDirections = new Vector4[maxDirLightCount];
	private static Vector4[] dirLightShadowDatas = new Vector4[maxDirLightCount];
	private static Vector4[] otherLightColors = new Vector4[maxOtherLightCount];
	private static Vector4[] otherLightPositions = new Vector4[maxOtherLightCount];
	private static Vector4[] otherLightDirections = new Vector4[maxOtherLightCount];
	private static Vector4[] otherLightSpotAngles = new Vector4[maxOtherLightCount];
	private static Vector4[] otherLightShadowDatas = new Vector4[maxOtherLightCount];

	private static string lightsPerObjectKeyword = "_LIGHTS_PER_OBJECT";

	private Shadows shadows = new Shadows();

	private ScriptableRenderContext context;
	private CullingResults cullingResults;

	private const string bufferName = "Lighting";
	private CommandBuffer commandBuffer = new CommandBuffer() { name = bufferName };

	public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSetttings shadowSetttings, bool useLightsPerObject)
	{
		this.context = context;
		this.cullingResults = cullingResults;
		commandBuffer.BeginSample(bufferName);
		shadows.Setup(context, cullingResults, shadowSetttings);
		SetupLights(useLightsPerObject);
		shadows.Render();
		commandBuffer.EndSample(bufferName);
		ExecuteBuffer();
	}

	private void SetupLights(bool useLightsPerObject)
	{
		NativeArray<int> indexMap = useLightsPerObject ? cullingResults.GetLightIndexMap(Allocator.Temp) : default;
		NativeArray<VisibleLight> lights = cullingResults.visibleLights;
		int dirLightCount = 0, otherLightCount = 0;
		int i;
		for(i = 0; i < lights.Length; i++)
		{
			int newIndex = -1;
			VisibleLight light = lights[i];
			switch (light.lightType)
            {
				case LightType.Directional:
					if(dirLightCount < maxDirLightCount) SetupDirectionalLight(dirLightCount++, ref light);
					break;
				case LightType.Point:
					if (otherLightCount < maxOtherLightCount)
                    {
						newIndex = otherLightCount;
						SetupPointLight(otherLightCount++, ref light);
					}
					break;
				case LightType.Spot:
					if (otherLightCount < maxDirLightCount)
                    {
						newIndex = otherLightCount;
						SetupSpotLight(otherLightCount++, ref light);
					}
					break;
            }
			if (useLightsPerObject) indexMap[i] = newIndex;
		}
        if (useLightsPerObject)
        {
			// 为上面的可见光源分配完index后，剩下的都是不可见光源，index设为-1
			for(; i < indexMap.Length; i++)
            {
				indexMap[i] = -1;
            }
			cullingResults.SetLightIndexMap(indexMap);
			indexMap.Dispose();
			Shader.EnableKeyword(lightsPerObjectKeyword);
        }
        else
        {
			Shader.DisableKeyword(lightsPerObjectKeyword);
        }
		commandBuffer.SetGlobalInt(dirLightCountId, dirLightCount);
		if(dirLightCount > 0)
        {
			commandBuffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
			commandBuffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
			commandBuffer.SetGlobalVectorArray(dirLightShadowDatasId, dirLightShadowDatas);
		}

		commandBuffer.SetGlobalInt(otherLightCountId, otherLightCount);
		if(otherLightCount > 0)
        {
			commandBuffer.SetGlobalVectorArray(otherLightColorsId, otherLightColors);
			commandBuffer.SetGlobalVectorArray(otherLightPositionsId, otherLightPositions);
			commandBuffer.SetGlobalVectorArray(otherLightDirectionsId, otherLightDirections);
			commandBuffer.SetGlobalVectorArray(otherLightSpotAnglesId, otherLightSpotAngles);
			commandBuffer.SetGlobalVectorArray(otherLightShadowDatasId, otherLightShadowDatas);
        }
	}

	private void SetupDirectionalLight(int index, ref VisibleLight light)
	{
		dirLightColors[index] = light.finalColor;
		dirLightDirections[index] = -light.localToWorldMatrix.GetColumn(2);
		dirLightShadowDatas[index] = shadows.ReserveDirectionalShadows(light.light, index);
    }

	private void SetupPointLight(int index, ref VisibleLight light)
    {
		otherLightColors[index] = light.finalColor;
		Vector4 position = light.localToWorldMatrix.GetColumn(3);
		position.w = 1.0f / Mathf.Max(light.range * light.range, 0.0001f);
		otherLightPositions[index] = position;
		otherLightSpotAngles[index] = new Vector4(0.0f, 1.0f);
		otherLightShadowDatas[index] = shadows.ReserveOtherShadows(light.light, index);
    }

	private void SetupSpotLight(int index, ref VisibleLight light)
    {
		otherLightColors[index] = light.finalColor;
		Vector4 position = light.localToWorldMatrix.GetColumn(3);
		position.w = 1.0f / Mathf.Max(light.range * light.range, 0.0001f);
		otherLightPositions[index] = position;
		otherLightDirections[index] = -light.localToWorldMatrix.GetColumn(2);
		Light l = light.light;
		float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * l.innerSpotAngle);
		float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.spotAngle);
		float angleRangeInv = 1.0f / Mathf.Max(innerCos - outerCos, 0.001f);
		otherLightSpotAngles[index] = new Vector4(angleRangeInv, -outerCos * angleRangeInv);
		otherLightShadowDatas[index] = shadows.ReserveOtherShadows(light.light, index);
	}

	public void Cleanup()
	{
		shadows.Cleanup();
	}

	private void ExecuteBuffer()
	{
		context.ExecuteCommandBuffer(commandBuffer);
		commandBuffer.Clear();
	}
}
