using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class BPipline : RenderPipeline
{
	public static ShaderTagId[] bshaderTagIds = new ShaderTagId[4]
	{
		new ShaderTagId("BPreDepthPass"),
		new ShaderTagId("BShaderDefault"),
		new ShaderTagId("BTransparentBack"),
		new ShaderTagId("BFurPass"),
	};

	private bool useDynamicBatching, useGPUInstancing, useLightsPerObject, useMultiRenderTarget, usePreDepth;
	private ShadowSetttings shadowSetttings;
	private PostProcessSettings postprocessSettings;
	private MainCameraRenderer mainCameraRenderer = new MainCameraRenderer();
	private int furRenderTimes;

	public BPipline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatching, bool useLightsPerObject, bool useMultiRenderTarget, bool usePreDepth, int furRenderTimes, ShadowSetttings shadowSetttings, PostProcessSettings postprocessSettings)
	{
		this.useDynamicBatching = useDynamicBatching;
		this.useGPUInstancing = useGPUInstancing;
		this.shadowSetttings = shadowSetttings;
		this.postprocessSettings = postprocessSettings;
		this.useLightsPerObject = useLightsPerObject;
		this.useMultiRenderTarget = useMultiRenderTarget;
		this.usePreDepth = usePreDepth;
		this.furRenderTimes = furRenderTimes;
		GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatching;
		GraphicsSettings.lightsUseLinearIntensity = true;
#if UNITY_EDITOR
		InitializeForEditor();
#endif
	}

	protected override void Render(ScriptableRenderContext context, Camera[] cameras)
	{
		for (int i = 0; i < cameras.Length; ++i)
		{
			mainCameraRenderer.Render(context, cameras[i], useDynamicBatching, useGPUInstancing, useLightsPerObject, useMultiRenderTarget, usePreDepth, furRenderTimes, shadowSetttings, postprocessSettings);
		}
	}
}
