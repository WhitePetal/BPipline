using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class RadiuBlur : PostEffectBase
{
    [Range(0, 8)]
    public int downSample = 1;
    [Range(0.0f, 1.0f)]
    public float centerX = 0.5f;
    [Range(0.0f, 1.0f)]
    public float centerY = 0.5f;
    [Range(0.001f, 1.0f)]
    public float clearX = 0.001f;
    [Range(0.001f, 1.0f)]
    public float clearY = 0.001f;
    [Range(0.0f, 2.0f)]
    public float blurRadius = 0.5f;
    [Range(0, 50)]
    public int iteration = 10;

    private int rt0 = Shader.PropertyToID("_RadialBlurRT0");

    public override void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width, int height)
    {
        width = width >> downSample;
        height = height >> downSample;

        commandBuffer.GetTemporaryRT(rt0, width, height, 0, postProcess.filterMode, postProcess.renderTextureFormat);

        commandBuffer.SetGlobalVector("_RadialBlurCenter_ClearRange", new Vector4(centerX, centerY, clearX, clearY));
        commandBuffer.SetGlobalVector("_RadialBlurRadius_Iteration", new Vector4(blurRadius / width, blurRadius / height, iteration));

        Draw(commandBuffer, source, rt0, PostProcessProfiler.Pass.RadialBlur);
        Draw(commandBuffer, rt0, destination, PostProcessProfiler.Pass.Copy);

        commandBuffer.ReleaseTemporaryRT(rt0);
    }
}
