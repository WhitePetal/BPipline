using UnityEngine;
using System.Collections;
using UnityEngine.Rendering;
using System.Collections.Generic;

public abstract class PostEffectBase : MonoBehaviour
{
    public struct PostEffectCompare : IComparer<PostEffectBase>
    {
        public int Compare(PostEffectBase x, PostEffectBase y)
        {
            if (x.renderQueue < y.renderQueue) return -1;
            else if (x.renderQueue > y.renderQueue) return 1;
            return 0;
        }
    }
    public static PostEffectCompare compare = new PostEffectCompare();

    protected PostProcessSettings postProcess;
    protected CommandBuffer commandBuffer;
    private bool postprocessActive => postProcess != null;

    public int renderQueue;
    public bool effected = true;

    protected virtual void OnEnable()
    {
        postProcess = ((BPiplineAsset)GraphicsSettings.currentRenderPipeline).postprocessSettings;
        if (postprocessActive)
        {
            postProcess.AddPostEffect(this);
        }
        
    }

    public abstract void Render(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, int width, int height);

    protected virtual void Draw(CommandBuffer commandBuffer, RenderTargetIdentifier source, RenderTargetIdentifier destination, PostProcessProfiler.Pass pass)
    {
        commandBuffer.SetGlobalTexture(PostProcessProfiler.sourceId, source);
        commandBuffer.SetRenderTarget(destination, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        commandBuffer.DrawProcedural(Matrix4x4.identity, postProcess.Material, (int)pass, MeshTopology.Triangles, 3);
    }

    private void OnDisable()
    {
        postProcess.RemovePostEffect(this);
    }
}
