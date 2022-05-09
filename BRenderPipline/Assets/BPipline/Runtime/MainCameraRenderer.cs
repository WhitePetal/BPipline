using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public partial class MainCameraRenderer
{
	private ScriptableRenderContext context;
	private Camera camera;
	private CullingResults cullingResults;
	private PostProcessSettings postprocessSettings;

	private Lightings lightings = new Lightings();
	private PostProcessProfiler postprocessProfiler = new PostProcessProfiler();
	private static int colorBufferId = Shader.PropertyToID("_ColorBuffer");
	private static int addBufferId = Shader.PropertyToID("_AddBuffer");
	private static int depthBufferId = Shader.PropertyToID("_DepthBuffer");
	private static int postprocessId = Shader.PropertyToID("_PostProcessSource");

	private static RenderTargetIdentifier[] colorBufferIds =
	{
		colorBufferId,
		addBufferId
	};
	private static RenderBufferLoadAction[] colorBuffersLoadActions =
	{
		RenderBufferLoadAction.DontCare,
		RenderBufferLoadAction.DontCare
	};
	private static RenderBufferStoreAction[] colorBuffersStoreActions =
	{
		RenderBufferStoreAction.Store,
		RenderBufferStoreAction.Store
	};
	private static RenderBufferStoreAction[] colorBuffersStoreActions_PreDepth =
{
		RenderBufferStoreAction.DontCare,
		RenderBufferStoreAction.DontCare
	};
	public RenderTargetBinding renderTargetBinding_Default = new RenderTargetBinding(colorBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, depthBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
	public RenderTargetBinding renderTargetBinding_Default_PreDepth = new RenderTargetBinding(colorBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare, depthBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
	public RenderTargetBinding renderTargetBinding_MultiRender = new RenderTargetBinding(colorBufferIds, colorBuffersLoadActions, colorBuffersStoreActions, depthBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
	public RenderTargetBinding renderTargetBinding_MultiRender_PreDepth = new RenderTargetBinding(colorBufferIds, colorBuffersLoadActions, colorBuffersStoreActions_PreDepth, depthBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);

	private const string commandBufferName = "Render Camera";
	private CommandBuffer commandBuffer = new CommandBuffer()
	{
		name = commandBufferName
	};

	public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing, bool useLightsPerObject, bool useMultiRenderTarget, bool usePreDepth, int furRenderTimes,
		ShadowSetttings shadowSetttings, PostProcessSettings postprocessSettings)
	{
		this.context = context;
		this.camera = camera;
		this.postprocessSettings = postprocessSettings;

#if UNITY_EDITOR
		PreparBuffer();
		PrepareForSceneWindow();
#endif

		if (!Cull(shadowSetttings.maxDistance)) return;

		commandBuffer.BeginSample(SampleName);
		lightings.Setup(context, cullingResults, shadowSetttings, useLightsPerObject);
		postprocessProfiler.Setup(context, camera, postprocessSettings);
		commandBuffer.EndSample(SampleName);

		GenerateBuffers(useMultiRenderTarget);

        if (usePreDepth)
        {
			SetupPreDepth(useMultiRenderTarget);
			DrawPreDepth(useDynamicBatching, useGPUInstancing);
        }

		SetupForRender(usePreDepth, useMultiRenderTarget);

		DrawVisibleGeometry(useDynamicBatching, useGPUInstancing, useLightsPerObject, furRenderTimes);
#if UNITY_EDITOR
		DrawUnsupportShader();
		DrawGizmosBeforePostProcess();
#endif
        if (postprocessProfiler.isActive)
        {
            postprocessProfiler.Render(colorBufferId);
        }

#if UNITY_EDITOR
        DrawGizmosAfterPostProcess();
#endif
		Copy(colorBufferId, BuiltinRenderTextureType.CameraTarget, true);
		CleanUp();
		Submit();
	}

	private bool Cull(float maxShadowDistance)
	{
		if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
		{
			p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
			cullingResults = context.Cull(ref p);
			return true;
		}
		return false;
	}

	private void GenerateBuffers(bool useMultiRenderTarget)
	{
		if (postprocessProfiler.isActive)
		{
			if (postprocessSettings.hdr.enable) postprocessSettings.renderTextureFormat = RenderTextureFormat.DefaultHDR;
			else postprocessSettings.renderTextureFormat = RenderTextureFormat.Default;
		}
		commandBuffer.GetTemporaryRT(colorBufferId, camera.pixelWidth, camera.pixelHeight, 0, postprocessSettings.filterMode, postprocessSettings.renderTextureFormat, RenderTextureReadWrite.Default);
		if(useMultiRenderTarget) commandBuffer.GetTemporaryRT(addBufferId, camera.pixelWidth, camera.pixelHeight, 0, postprocessSettings.filterMode, RenderTextureFormat.Default, RenderTextureReadWrite.Linear);
		commandBuffer.GetTemporaryRT(depthBufferId, camera.pixelWidth, camera.pixelHeight, 24, FilterMode.Point, RenderTextureFormat.Depth);
	}

	private void SetupPreDepth(bool useMultiRenderTarget)
	{
		CameraClearFlags cameraClearFlags = camera.clearFlags;
		context.SetupCameraProperties(camera);
		commandBuffer.SetRenderTarget(useMultiRenderTarget ? renderTargetBinding_MultiRender_PreDepth : renderTargetBinding_Default_PreDepth);
		commandBuffer.ClearRenderTarget(cameraClearFlags < CameraClearFlags.Depth, true, Color.clear);
		commandBuffer.BeginSample(SampleName);
		ExecuteBuffer();
	}

	private void DrawPreDepth(bool useDynamicBatching, bool useGPUInstancing)
	{
		SortingSettings sortingSettings = new SortingSettings(camera)
		{
			criteria = SortingCriteria.CommonOpaque
		};
		DrawingSettings drawingSettings = new DrawingSettings(BPipline.bshaderTagIds[0], sortingSettings)
		{
			enableDynamicBatching = useDynamicBatching,
			enableInstancing = useGPUInstancing
		};
		FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
		drawingSettings.SetShaderPassName(0, BPipline.bshaderTagIds[0]);
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
		commandBuffer.EndSample(SampleName);
		ExecuteBuffer();
		context.Submit();
	}

	private void SetupForRender(bool usePreDepth, bool useMultiRenderTarget)
	{
		context.SetupCameraProperties(camera);
		CameraClearFlags cameraClearFlags = camera.clearFlags;
		if (postprocessProfiler.isActive)
		{
			if (cameraClearFlags < CameraClearFlags.Color) cameraClearFlags = CameraClearFlags.Color;
		}
		if (useMultiRenderTarget) commandBuffer.SetRenderTarget(renderTargetBinding_MultiRender);
		else commandBuffer.SetRenderTarget(renderTargetBinding_Default);
		commandBuffer.ClearRenderTarget(!usePreDepth, cameraClearFlags == CameraClearFlags.Color, cameraClearFlags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);
		commandBuffer.BeginSample(SampleName);
		ExecuteBuffer();
	}

	private void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing, bool useLightsPerObject, int furRenderTimes)
	{
		PerObjectData lightsPerObjectFlags = useLightsPerObject ? PerObjectData.LightData | PerObjectData.LightIndices : PerObjectData.None;

		// 不透明
		SortingSettings sortingSettings = new SortingSettings(camera)
		{
			criteria = SortingCriteria.CommonOpaque
		};
		DrawingSettings drawingSettings = new DrawingSettings(BPipline.bshaderTagIds[1], sortingSettings)
		{
			enableDynamicBatching = useDynamicBatching,
			enableInstancing = useGPUInstancing
		};
		FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
		drawingSettings.perObjectData = PerObjectData.ReflectionProbes |
			PerObjectData.Lightmaps |
			PerObjectData.ShadowMask |
			PerObjectData.OcclusionProbe |
			PerObjectData.LightProbe |
			PerObjectData.LightProbeProxyVolume |
			PerObjectData.OcclusionProbeProxyVolume |
			lightsPerObjectFlags;

		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

		// SkyBox
		context.DrawSkybox(camera);

		// Fur
		drawingSettings.SetShaderPassName(0, BPipline.bshaderTagIds[3]);
		sortingSettings.criteria = SortingCriteria.CommonOpaque;
		filteringSettings.renderQueueRange = RenderQueueRange.transparent;

		float furRate = 1.0f / furRenderTimes;
		for (int i = 0; i < furRenderTimes; ++i)
		{
			commandBuffer.SetGlobalFloat("_FurOffset", furRenderTimes);
			ExecuteBuffer();
			context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
		}

		// 透明
		sortingSettings.criteria = SortingCriteria.CommonOpaque;
		drawingSettings.sortingSettings = sortingSettings;
		drawingSettings.SetShaderPassName(0, BPipline.bshaderTagIds[1]);
		drawingSettings.SetShaderPassName(1, BPipline.bshaderTagIds[2]);
		filteringSettings.renderQueueRange = RenderQueueRange.transparent;
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
	}

	private void Copy(RenderTargetIdentifier source, RenderTargetIdentifier destination, bool clear = false)
	{
		commandBuffer.SetGlobalTexture(postprocessId, source);
		commandBuffer.SetRenderTarget(destination, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		if (clear)
		{
			commandBuffer.ClearRenderTarget(true, true, Color.clear);
		}
		commandBuffer.DrawProcedural(Matrix4x4.identity, postprocessSettings.Material, 0, MeshTopology.Triangles, 3);
	}

	private void Submit()
	{
		commandBuffer.EndSample(SampleName);
		ExecuteBuffer();
		context.Submit();
	}

	private void CleanUp()
	{
		lightings.Cleanup();
		commandBuffer.ReleaseTemporaryRT(colorBufferId);
		commandBuffer.ReleaseTemporaryRT(addBufferId);
		commandBuffer.ReleaseTemporaryRT(depthBufferId);
	}

	private void ExecuteBuffer()
	{
		context.ExecuteCommandBuffer(commandBuffer);
		commandBuffer.Clear();
	}
}
