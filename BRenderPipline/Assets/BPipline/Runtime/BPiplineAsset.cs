using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/BPipline")]
public class BPiplineAsset : RenderPipelineAsset
{
	[SerializeField]
	public bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatching = true, useLightsPerObject = true;
	[SerializeField]
	private ShadowSetttings shadowSetttings = default;
	[SerializeField]
	public PostProcessSettings postprocessSettings = default;

	protected override RenderPipeline CreatePipeline()
	{
		return new BPipline(useDynamicBatching, useGPUInstancing, useSRPBatching, useLightsPerObject, shadowSetttings, postprocessSettings);
	}
}
