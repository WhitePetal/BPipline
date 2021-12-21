using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Bloom : PostEffectBase
{
    [Range(0, 8)]
    public int downSample = 1;
    [Range(0, 8)]
    public int iteration = 2;
    [Range(0.0f, 8.0f)]
    public float blurRadius = 1.0f;
    [Range(0.0f, 4.0f)]
    public float bloomStrength = 1.0f;
    [Range(0.0f, 1024.0f)]
    public float bloomThreshold = 0.0f;
    public Color bloomColor = Color.white;

    private int rt0 = Shader.PropertyToID("_BloomRt0");
    private int rt1 = Shader.PropertyToID("_BloomRt1");

    public override void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width_screen, int height_screen)
    {
        int width = width_screen >> downSample;
        int height = height_screen >> downSample;

        commandBuffer.GetTemporaryRT(rt0, width, height, 0, postProcess.filterMode, postProcess.renderTextureFormat);
        commandBuffer.GetTemporaryRT(rt1, width, height, 0, postProcess.filterMode, postProcess.renderTextureFormat);

        commandBuffer.SetGlobalVector("_BloomFactor", new Vector4(bloomColor.r, bloomColor.g, bloomColor.b, bloomStrength));
        commandBuffer.SetGlobalFloat("_GlobalBloomThreshold", bloomThreshold);

        Draw(commandBuffer, source, rt0, PostProcessProfiler.Pass.BloomExtract);
        for (int i = 0; i < iteration; i++)
        {
            float blurR = (1 + i) * blurRadius;
            commandBuffer.SetGlobalVector("_BlurOffset", new Vector4(blurR / width, 0.0f));
            Draw(commandBuffer, rt0, rt1, PostProcessProfiler.Pass.GaussianBlur);
            commandBuffer.SetGlobalVector("_BlurOffset", new Vector4(0.0f, blurR / height));
            Draw(commandBuffer, rt1, rt0, PostProcessProfiler.Pass.GaussianBlur);
        }
        commandBuffer.SetGlobalTexture("_PostProcessBlend", rt0);
        Draw(commandBuffer, source, destination, PostProcessProfiler.Pass.BlendAdd);

        commandBuffer.ReleaseTemporaryRT(rt0);
        commandBuffer.ReleaseTemporaryRT(rt1);
    }
}
