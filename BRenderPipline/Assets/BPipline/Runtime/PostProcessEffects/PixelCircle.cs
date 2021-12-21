using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PixelCircle : PostEffectBase
{
    public Vector2 circleSize = new Vector2(10, 10);
    [Range(0.0f, 1.0f)]
    public float edageSize = 0.1f;

    public override void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width, int height)
    {
        commandBuffer.SetGlobalVector("_CircleSize_EdageSize", new Vector4(circleSize.x, circleSize.y, edageSize));
        Draw(commandBuffer, source, destination, PostProcessProfiler.Pass.PixelCircle);
    }
}
