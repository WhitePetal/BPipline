using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSetttings
{
	public enum ShadowMapSize
	{
		_256 = 256,
		_512 = 512,
		_1024 = 1024,
		_2048 = 2048,
		_4096 = 4096,
		_8192 = 8192
	}

	public enum FilterMode
	{
		PCF2x2,
		PCF3x3,
		PCF5x5,
		PCF7x7
	}

	public enum CascadeBlendMode
	{
		Hard, Soft, Dither
	}

	[Min(0.001f)]
	public float maxDistance = 100f;
	[Range(0.001f, 1.0f)]
	public float distanceFade = 0.1f;
	public Color shadowColor = Color.black;


	[System.Serializable]
	public struct Directional
	{
		public ShadowMapSize shadowMapSize;
		public FilterMode filterMode;
		[Range(1, 4)]
		public int cascadeCount;
		[Range(0.001f, 1.0f)]
		public float cascadeFade;
		[Range(0.0f, 1.0f)]
		public float cascadeRatio1, cascadeRatio2, cascadeRatio3; // cascadeRatio0 = 1.0f
		public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);
		public CascadeBlendMode cascadeBlend;
	}

	[System.Serializable]
	public struct Other
    {
		public ShadowMapSize ShadowMapSize;
		public FilterMode filterMode;
    }

	public Directional directional = new Directional()
	{
		shadowMapSize = ShadowMapSize._1024,
		filterMode = FilterMode.PCF2x2,
		cascadeCount = 4,
		cascadeFade = 0.1f,
		cascadeRatio1 = 0.12f,
		cascadeRatio2 = 0.25f,
		cascadeRatio3 = 0.5f,
		cascadeBlend = CascadeBlendMode.Hard
	};

	public Other other = new Other()
	{
		ShadowMapSize = ShadowMapSize._1024,
		filterMode = FilterMode.PCF2x2
	};
}
