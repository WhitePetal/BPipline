using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
	private const string bufferName = "Shadows";
	private const int maxShadowedDirectionalLightCount = 4, maxShadowedOtherLightCount = 16,
		maxCascadeCount = 4;

	private static int
		dirShadowMapId = Shader.PropertyToID("_DirectionalShadowMap"),
		dirShadowMatrixsId = Shader.PropertyToID("_DirectionalShadowMatrixs"),
		shadowColorId = Shader.PropertyToID("_ShadowColor"),
		cascadeCountId = Shader.PropertyToID("_CascadeCount"),
		cascadeCullingSpheresId = Shader.PropertyToID("_CascadeCullingSpheres"),
		shadowDistanceFadeId = Shader.PropertyToID("_ShadowDistanceFade"),
		cascadeDataId = Shader.PropertyToID("_CascadeData"),
		shadowMapSizeId = Shader.PropertyToID("_ShadowMapSize"),
		otherShadowMapId = Shader.PropertyToID("_OtherShadowMap"),
		otherShadowMatrixsId = Shader.PropertyToID("_OtherShadowMatrixs");

	private static string[] directionalFilterKeywords =
	{
		"_DIRECTIONAL_PCF3",
		"_DIRECTIONAL_PCF5",
		"_DIRECTIONAL_PCF7"
	};
	public static string[] otherFilterKeywords =
	{
		"_OTHER_PCF3",
		"_OTHER_PCF5",
		"_OTHER_PCF7"
	};
	private static string[] cascadeBlendKeywords =
	{
		"_CASCADE_BLEND_SOFT",
		"_CASCADE_BLEND_DITHER"
	};
	private static string[] shadowMaskKeywords =
	{
		"_SHADOW_MASK_ALWAYS",
		"_SHADOW_MASK_DISTANCE"
	};

	private static Vector4[]
		cascadeCullingSpheres = new Vector4[maxCascadeCount],
		cascadeData = new Vector4[maxCascadeCount];
	private Matrix4x4[]
		dirShadowMatrixs = new Matrix4x4[maxShadowedDirectionalLightCount * maxCascadeCount],
		otherShadowMatrixs = new Matrix4x4[maxShadowedOtherLightCount];

	private Vector4 shadowMapSizes;

	public struct ShadowedDirectionalLight
	{
		public int visibleLightIndex;
		public float slopeScaleBias;
		public float nearPlaneOffset;

	}

	private ShadowedDirectionalLight[] shadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];

	private int shadowedDirectionalLightCount, shadowedOtherLightCount;

	private bool useShadowMask;

	private CommandBuffer commandBuffer = new CommandBuffer() { name = bufferName };

	private ScriptableRenderContext context;
	private CullingResults cullingResults;
	private ShadowSetttings shadowSetttings;

	public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSetttings shadowSetttings)
	{
		this.context = context;
		this.cullingResults = cullingResults;
		this.shadowSetttings = shadowSetttings;
		shadowedDirectionalLightCount = shadowedOtherLightCount = 0;
		useShadowMask = false;
	}

	public Vector4 ReserveDirectionalShadows(Light light, int visibleLightIndex)
	{
		if (shadowedDirectionalLightCount < maxShadowedDirectionalLightCount && 
			light.shadows != LightShadows.None && light.shadowStrength > 0f)
		{
			float maskChannel = -1;
			LightBakingOutput lightBaking = light.bakingOutput;
			if(lightBaking.lightmapBakeType == LightmapBakeType.Mixed && lightBaking.mixedLightingMode == MixedLightingMode.Shadowmask)
			{
				useShadowMask = true;
				maskChannel = lightBaking.occlusionMaskChannel;
			}

			if(!cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds outBounds))
			{
				return new Vector4(-light.shadowStrength, 0.0f, 0.0f, maskChannel);
			}

			shadowedDirectionalLights[shadowedDirectionalLightCount] = new ShadowedDirectionalLight()
			{
				visibleLightIndex = visibleLightIndex,
				slopeScaleBias = light.shadowBias,
				nearPlaneOffset = light.shadowNearPlane
			};
			return new Vector4(light.shadowStrength, shadowSetttings.directional.cascadeCount * shadowedDirectionalLightCount++,
				light.shadowNormalBias, maskChannel);
		}
		return new Vector4(0f, 0f, 0f, -1f);
	}

	public Vector4 ReserveOtherShadows(Light light, int visibleLightIndex)
    {
		if (light.shadows == LightShadows.None || light.shadowStrength <= 0.0f) return new Vector4(0.0f, 0.0f, 0.0f, -1.0f);

		float maskChannel = -1f;
		LightBakingOutput lightBaking = light.bakingOutput;
		if(lightBaking.lightmapBakeType == LightmapBakeType.Mixed && lightBaking.mixedLightingMode == MixedLightingMode.Shadowmask)
        {
			useShadowMask = true;
			maskChannel = lightBaking.occlusionMaskChannel;
        }
		if(shadowedOtherLightCount >= maxShadowedOtherLightCount || !cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds outBounds))
        {
			return new Vector4(-light.shadowStrength, 0.0f, 0.0f, maskChannel);
        }
		return new Vector4(light.shadowStrength, shadowedOtherLightCount++, 0.0f, maskChannel);
    }

	public void Render()
	{
		if(shadowedDirectionalLightCount > 0)
		{
			RenderDirectionalShadows();
		}
		else
		{
			commandBuffer.GetTemporaryRT(dirShadowMapId, 1, 1, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
		}
		if(shadowedOtherLightCount > 0)
        {
			RenderOtherShadows();
        }
        else
        {
			commandBuffer.SetGlobalTexture(otherShadowMapId, dirShadowMapId);
        }

		commandBuffer.BeginSample(bufferName);
		SetKeywords(shadowMaskKeywords, useShadowMask ? QualitySettings.shadowmaskMode == ShadowmaskMode.Shadowmask ? 0 : 1 : -1);

		// 即使没有方向光，其它光源的实时阴影也需要级联和淡入淡出系数
		commandBuffer.SetGlobalInt(cascadeCountId, shadowSetttings.directional.cascadeCount);
		float f = 1f - shadowSetttings.directional.cascadeFade;
		commandBuffer.SetGlobalVector(shadowDistanceFadeId, new Vector4(
			1.0f / shadowSetttings.maxDistance, 1.0f / shadowSetttings.distanceFade,
			1f / (1f - f * f)));
		commandBuffer.SetGlobalVector(shadowMapSizeId, shadowMapSizes);
		commandBuffer.EndSample(bufferName);
		ExecuteBuffer();
	}

	private void RenderDirectionalShadows()
	{
		int shadowMapSize = (int)shadowSetttings.directional.shadowMapSize;
		shadowMapSizes.x = shadowMapSize;
		shadowMapSizes.y = 1.0f / shadowMapSize;
		commandBuffer.GetTemporaryRT(dirShadowMapId, shadowMapSize, shadowMapSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
		commandBuffer.SetRenderTarget(dirShadowMapId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		commandBuffer.ClearRenderTarget(true, false, Color.clear);
		commandBuffer.BeginSample(bufferName);
		ExecuteBuffer();

		int tilesCount = shadowSetttings.directional.cascadeCount * shadowedDirectionalLightCount;
		int split = tilesCount <= 1 ? 1 : tilesCount <= 4 ? 2 : 4; // finalSize = size * size => finalSplit = split * split
		int tileSize = shadowMapSize / split;

		for(int i = 0; i < shadowedDirectionalLightCount; i++)
		{
			RenderDirectionalShadows(i, split, tileSize);
		}

		commandBuffer.SetGlobalVectorArray(cascadeCullingSpheresId, cascadeCullingSpheres);
		commandBuffer.SetGlobalVectorArray(cascadeDataId, cascadeData);
		commandBuffer.SetGlobalMatrixArray(dirShadowMatrixsId, dirShadowMatrixs);
		commandBuffer.SetGlobalColor(shadowColorId, shadowSetttings.shadowColor);

		SetKeywords(directionalFilterKeywords, (int)shadowSetttings.directional.filterMode - 1);
		SetKeywords(cascadeBlendKeywords, (int)shadowSetttings.directional.cascadeBlend - 1);

		commandBuffer.EndSample(bufferName);
		ExecuteBuffer();
	}
	private void RenderDirectionalShadows(int index, int split, int tileSize)
	{
		ShadowedDirectionalLight light = shadowedDirectionalLights[index];
		ShadowDrawingSettings shadowDrawingSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);
		int cascadeCount = shadowSetttings.directional.cascadeCount;
		int tileOffset = index * cascadeCount;
		Vector3 cascadeRatios = shadowSetttings.directional.CascadeRatios;
		float cullingFactor = Mathf.Max(0.0f, 1f - shadowSetttings.directional.cascadeFade);
		for (int i = 0; i < cascadeCount; i++)
		{
			cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(light.visibleLightIndex, i, cascadeCount, cascadeRatios, tileSize,
				light.nearPlaneOffset, out Matrix4x4 viewMatrix, out Matrix4x4 projMatrix, out ShadowSplitData shadowSplitData);
			shadowSplitData.shadowCascadeBlendCullingFactor = cullingFactor;
			shadowDrawingSettings.splitData = shadowSplitData;
			if (index == 0) // 所有方向光源的级联裁剪球都是一样的（裁剪球只基于相机，与光源无关）
			{
				SetCascadeData(i, shadowSplitData.cullingSphere, tileSize);
			}
			int tileIndex = tileOffset + i;
			dirShadowMatrixs[tileIndex] = ConvertToShadowMapMatrix(projMatrix * viewMatrix, SetTileViewport(tileIndex, split, tileSize), split);
			commandBuffer.SetViewProjectionMatrices(viewMatrix, projMatrix);
			commandBuffer.SetGlobalDepthBias(0f, light.slopeScaleBias);// 斜率比深度偏移 消除阴影粉刺
			ExecuteBuffer();
			context.DrawShadows(ref shadowDrawingSettings);
			commandBuffer.SetGlobalDepthBias(0f, 0f);
		}
	}
	private Vector2 SetTileViewport(int index, int split, float tileSize)
	{
		Vector2 offset = new Vector2(index % split, index / split);
		commandBuffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
		return offset;
	}
	private Matrix4x4 ConvertToShadowMapMatrix(Matrix4x4 m, Vector2 offset, int split)
	{
		if (SystemInfo.usesReversedZBuffer)
		{
			m.m20 = -m.m20;
			m.m21 = -m.m21;
			m.m22 = -m.m22;
			m.m23 = -m.m23;
		}
		float scale = 1f / split;
		m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
		m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
		m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
		m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
		m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
		m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
		m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
		m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
		m.m20 = 0.5f * (m.m20 + m.m30);
		m.m21 = 0.5f * (m.m21 + m.m31);
		m.m22 = 0.5f * (m.m22 + m.m32);
		m.m23 = 0.5f * (m.m23 + m.m33);
		return m;
	}

	private void RenderOtherShadows()
    {
		int shadowMapSize = (int)shadowSetttings.other.ShadowMapSize;
		shadowMapSizes.z = shadowMapSize;
		shadowMapSizes.w = 1.0f / shadowMapSize;
		commandBuffer.GetTemporaryRT(otherShadowMapId, shadowMapSize, shadowMapSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
		commandBuffer.SetRenderTarget(otherShadowMapId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		commandBuffer.ClearRenderTarget(true, false, Color.clear);
		commandBuffer.BeginSample(bufferName);
		ExecuteBuffer();
		int tiles = shadowedOtherLightCount;
		int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
		int tileSize = shadowMapSize / split;
		for(int i = 0; i < shadowedOtherLightCount; i++)
        {

        }

		commandBuffer.SetGlobalMatrixArray(otherShadowMatrixsId, otherShadowMatrixs);
		SetKeywords(otherFilterKeywords, (int)shadowSetttings.other.filterMode - 1);
		commandBuffer.EndSample(bufferName);
		ExecuteBuffer();
	}

	private void SetKeywords(string[] keywords, int enabledIndex)
	{
		for(int i = 0; i < keywords.Length; i++)
		{
			if (i == enabledIndex) commandBuffer.EnableShaderKeyword(keywords[i]);
			else commandBuffer.DisableShaderKeyword(keywords[i]);
		}
	}

	private void SetCascadeData(int index, Vector4 cullingSphere, float tileSize)
	{
		float texelSize = 2.0f * cullingSphere.w / tileSize;
		float filterSize = texelSize * ((float)shadowSetttings.directional.filterMode + 1.0f);
		cullingSphere.w -= filterSize;
		cullingSphere.w *= cullingSphere.w;
		cascadeCullingSpheres[index] = cullingSphere;
		cascadeData[index] = new Vector4(1f / cullingSphere.w, filterSize * 1.4142136f);
	}

	public void Cleanup()
	{
		commandBuffer.ReleaseTemporaryRT(dirShadowMapId);
		if (shadowedOtherLightCount > 0) commandBuffer.ReleaseTemporaryRT(otherShadowMapId);
		ExecuteBuffer();
	}

	private void ExecuteBuffer()
	{
		context.ExecuteCommandBuffer(commandBuffer);
		commandBuffer.Clear();
	}
}
