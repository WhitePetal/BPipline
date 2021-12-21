using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PixelRhombus : PostEffectBase
{
    public Vector2 rhombusSize = new Vector2(10, 10);
    [Range(0.0f, 1.0f)]
    public float edageSize = 0.2f;

    public override void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width, int height)
    {
        commandBuffer.SetGlobalVector("_RhombusSize_EdageSize", new Vector4(rhombusSize.x, rhombusSize.y, edageSize));
        Draw(commandBuffer, source, destination, PostProcessProfiler.Pass.PixelRhombus);
    }
}
