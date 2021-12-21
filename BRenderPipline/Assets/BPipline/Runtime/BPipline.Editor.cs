using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using UnityEngine.Rendering;
using LightType = UnityEngine.LightType;

public partial class BPipline
{
#if UNITY_EDITOR
	public static ShaderTagId[] legacyShaderTagIds = new ShaderTagId[]
	{
		new ShaderTagId("Always"),
		new ShaderTagId("ForwardBase"),
		new ShaderTagId("PrepassBase"),
		new ShaderTagId("Vertex"),
		new ShaderTagId("VertexLMRGBM"),
		new ShaderTagId("VertexLM")
	};

	private static Lightmapping.RequestLightsDelegate lightsDelegate = (Light[] lights, NativeArray<LightDataGI> output) =>
	{
		var lightData = new LightDataGI();
		for(int i = 0; i < lights.Length; i++)
        {
			Light light = lights[i];
            switch (light.type)
            {
				case LightType.Directional:
					var dirLight = new DirectionalLight();
					LightmapperUtils.Extract(light, ref dirLight);
					lightData.Init(ref dirLight);
					break;
				case LightType.Point:
					var pointLight = new PointLight();
					LightmapperUtils.Extract(light, ref pointLight);
					lightData.Init(ref pointLight);
					break;
				case LightType.Spot:
					var spotLight = new SpotLight();
					LightmapperUtils.Extract(light, ref spotLight);

					// 从 2019.3 开始，烘焙才支持 innerAngle。对于之前的版本，这里可以设置，但是烘焙时会被忽略
					spotLight.innerConeAngle = light.innerSpotAngle * Mathf.Deg2Rad;
					spotLight.angularFalloff = AngularFalloffType.AnalyticAndInnerAngle;
					// 从 2019.3 开始，烘焙才支持 innerAngle 对于之前的版本，这里可以设置，但是烘焙时会被忽略

					lightData.Init(ref spotLight);
					break;
				case LightType.Area:
					var rectLight = new RectangleLight();
					LightmapperUtils.Extract(light, ref rectLight);
					rectLight.mode = LightMode.Baked;
					lightData.Init(ref rectLight);
					break;
				default:
					lightData.InitNoBake(light.GetInstanceID());
					break;
            }
			lightData.falloff = FalloffType.InverseSquared;
			output[i] = lightData;
        }
	};

    private void InitializeForEditor()
    {
        Lightmapping.SetDelegate(lightsDelegate);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
		Lightmapping.ResetDelegate();
    }
#endif
}
