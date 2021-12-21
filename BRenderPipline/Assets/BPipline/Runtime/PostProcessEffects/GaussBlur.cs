using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GaussBlur : PostEffectBase
{
    [Range(0, 8)]
    public int downSample = 2;
    [Range(0, 8)]
    public int iteration = 3;
    [Range(0.0f, 8.0f)]
    public float blurSpeard = 1.0f;

    private int rt0 = Shader.PropertyToID("_GaussianBlur_RT0");
    private int rt1 = Shader.PropertyToID("_GaussianBlur_RT1");

    public override void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width_screen, int height_screen)
    {
        int width = width_screen >> downSample;
        int height = height_screen >> downSample;

        commandBuffer.GetTemporaryRT(rt0, width, height, 0, postProcess.filterMode, postProcess.renderTextureFormat);
        commandBuffer.GetTemporaryRT(rt1, width, height, 0, postProcess.filterMode, postProcess.renderTextureFormat);

        Draw(commandBuffer, source, rt0, PostProcessProfiler.Pass.Copy);

        for(int i = 0; i < iteration; i++)
        {
            commandBuffer.SetGlobalVector("_BlurOffset", new Vector4(blurSpeard / width, 0.0f));
            Draw(commandBuffer, rt0, rt1, PostProcessProfiler.Pass.GaussianBlur);
            commandBuffer.SetGlobalVector("_BlurOffset", new Vector4(0.0f, blurSpeard / height));
            Draw(commandBuffer, rt1, rt0, PostProcessProfiler.Pass.GaussianBlur);
        }
        Draw(commandBuffer, rt0, destination, PostProcessProfiler.Pass.Copy);

        commandBuffer.ReleaseTemporaryRT(rt0);
        commandBuffer.ReleaseTemporaryRT(rt1);
    }
}
