using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

public partial class MainCameraRenderer
{
#if UNITY_EDITOR
	private static Material material_error = new Material(Shader.Find("Hidden/InternalErrorShader"));

	private string SampleName { get; set; }

	private void PrepareForSceneWindow()
	{
		if(camera.cameraType == CameraType.SceneView)
		{
			ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
		}
	}

	private void PreparBuffer()
	{
		Profiler.BeginSample("Editor Only");
		commandBuffer.name = SampleName = camera.name;
		Profiler.EndSample();
	}

	private void DrawUnsupportShader()
	{
		DrawingSettings drawingSettings = new DrawingSettings(BPipline.legacyShaderTagIds[0], new SortingSettings(camera))
		{
			overrideMaterial = material_error
		};
		FilteringSettings filteringSettings = FilteringSettings.defaultValue;
		for(int i = 1; i < BPipline.legacyShaderTagIds.Length; ++i)
		{
			drawingSettings.SetShaderPassName(i, BPipline.legacyShaderTagIds[i]);
		}
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
	}

	private void DrawGizmosBeforePostProcess()
	{
		if (Handles.ShouldRenderGizmos())
		{
			context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
		}
	}

	private void DrawGizmosAfterPostProcess()
    {
        if (Handles.ShouldRenderGizmos())
        {
			context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
		}
    }
#else
	private const string SampleName = commandBufferName;
#endif
}
