using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/BPipline")]
public class BPiplineAsset : RenderPipelineAsset
{
	[SerializeField]
	public bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatching = true, useLightsPerObject = true, useMultiRenderTarget = false, usePreDepth = true;
	[SerializeField]
	private ShadowSetttings shadowSetttings = default;
	[SerializeField]
	public PostProcessSettings postprocessSettings = default;
	[SerializeField]
	public int furRenderTimes = 10;

	protected override RenderPipeline CreatePipeline()
	{
		return new BPipline(useDynamicBatching, useGPUInstancing, useSRPBatching, useLightsPerObject, useMultiRenderTarget, usePreDepth, furRenderTimes, shadowSetttings, postprocessSettings);
	}
}
