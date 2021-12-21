using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PixelHexagon : PostEffectBase
{
    public Vector2 hexagonSize = new Vector2(10, 10);
    [Range(0.0f, 1.0f)]
    public float edageSize = 0.6f;

    public override void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width, int height)
    {
        commandBuffer.SetGlobalVector("_Hexagon_EdageSize", new Vector4(hexagonSize.x, hexagonSize.y, edageSize));
        Draw(commandBuffer, source, destination, PostProcessProfiler.Pass.PixelHexagon);
    }
}
