using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public partial class PostProcessProfiler
{
    private const string bufferName = "PostProcess";
    private CommandBuffer commandBuffer = new CommandBuffer
    {
        name = bufferName
    };
    private ScriptableRenderContext context;
    private Camera camera;
    private PostProcessSettings postprocessSettings;

    public static int sourceId = Shader.PropertyToID("_PostProcessSource");
    public static int destinationId = Shader.PropertyToID("_PostProcessDestination");
    //private int ssaoRTIn = Shader.PropertyToID("_SSAO_RTIN");
    private int ssaoRt0 = Shader.PropertyToID("_SSAO_RT0");
    private int ssaoRt1 = Shader.PropertyToID("_SSAO_RT1");

    public bool isActive => postprocessSettings != null;

    public enum Pass
    {
        Copy,
        BlendAdd,
        BlendMul,
        BlendMulR,
        GaussianBlur,
        BoxBlur,
        BloomExtract,
        ACES_TomeMapping,
        FXAA,
        //GetScreenSpaceNormal,
        SSAO,
        PixelCircle,
        PixelHexagon,
        PixelRhombus,
        RadialRGBSplit,
        RadialBlur
    }

    public void Setup(ScriptableRenderContext context, Camera camera, PostProcessSettings postprocessSettings)
    {
        this.context = context;
        this.camera = camera;
        this.postprocessSettings = camera.cameraType <= CameraType.SceneView ? postprocessSettings : null;
#if UNITY_EDITOR
        ApplySceneViewState();
#endif
    }

    public void Render(int sourceId)
    {
        int width = camera.pixelWidth;
        int height = camera.pixelHeight;
        commandBuffer.SetGlobalVector("_Width_Height_Factors", new Vector4(width, height, 1.0f / width, 1.0f / height));
        commandBuffer.GetTemporaryRT(destinationId, width, height, 0, postprocessSettings.filterMode, postprocessSettings.renderTextureFormat, RenderTextureReadWrite.Default);
        int sourceTarget = sourceId;
        int destTarget = destinationId;
        for(int i = 0; i < postprocessSettings.postProcessEffects.Count; i++)
        {
            PostEffectBase effect = postprocessSettings.postProcessEffects[i];
            if (effect.effected)
            {
                effect.Render(commandBuffer, sourceTarget, destTarget, width, height);
                int temp = sourceTarget;
                sourceTarget = destTarget;
                destTarget = temp;
            }
        }

        if (postprocessSettings.hdr.enable)
		{
            commandBuffer.SetGlobalFloat("_ACES_Tonemapping_Factor", postprocessSettings.hdr.aces_tonemapping);
			Draw(sourceTarget, destTarget, Pass.ACES_TomeMapping);
            int temp = sourceTarget;
            sourceTarget = destTarget;
            destTarget = temp;
        }

		if (postprocessSettings.fxaa)
		{
            Draw(sourceTarget, destTarget, Pass.FXAA);
            int temp = sourceTarget;
            sourceTarget = destTarget;
            destTarget = temp;
        }

        if(sourceTarget != sourceId)
        {
            Draw(sourceTarget, sourceId, Pass.Copy);
        }
        commandBuffer.ReleaseTemporaryRT(destinationId);
        Execute();
    }

    #region
    // 使用 ComputeShader 并不能解决 RenderTarget 切换问题，并且在移动端有问题
    //public void RenderSSAO(int sourceId)
    //{
    //    PostProcessSettings.SSAO_Settings ssao = postprocessSettings.ssao;
    //    if (ssao.enable)
    //    {
    //        int width = camera.pixelWidth;
    //        int height = camera.pixelHeight;

    //        int sourceTarget = sourceId;
    //        int destTarget = destinationId;
    //        commandBuffer.GetTemporaryRT(destinationId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.Default, RenderTextureReadWrite.Default, 1, true);

    //        commandBuffer.BeginSample("SSAO");
    //        ComputeShader cs = postprocessSettings.computeShaderStack;
    //        Vector2Int rtSize = new Vector2Int(width >> ssao.downSample, height >> ssao.downSample);
    //        Vector2Int csThreadGroup = new Vector2Int(Mathf.CeilToInt(width / 8.0f), Mathf.CeilToInt(height / 8.0f));
    //        Vector2Int csThreadGroup_rt = new Vector2Int(Mathf.CeilToInt(rtSize.x / 8.0f), Mathf.CeilToInt(rtSize.y / 8.0f));
    //        commandBuffer.GetTemporaryRT(ssaoRt0, rtSize.x, rtSize.y, 0, FilterMode.Bilinear, RenderTextureFormat.Default, RenderTextureReadWrite.Default, 1, true);
    //        commandBuffer.GetTemporaryRT(ssaoRt1, rtSize.x, rtSize.y, 0, FilterMode.Bilinear, RenderTextureFormat.Default, RenderTextureReadWrite.Default, 1, true);
    //        commandBuffer.SetComputeVectorParam(cs, "_SourceWidthHeight", new Vector4(rtSize.x, rtSize.y));

    //        commandBuffer.SetComputeTextureParam(cs, 1, "_StackSource", sourceTarget);
    //        commandBuffer.SetComputeTextureParam(cs, 1, "_StackOutput", ssaoRt0);
    //        commandBuffer.SetComputeTextureParam(cs, 1, "_DepthBuffer", MainCameraRenderer.depthBufferId);
    //        commandBuffer.SetComputeVectorParam(cs, "_AO_Scales", new Vector4(ssao.aoStrength, ssao.sampleScale / rtSize.x, ssao.sampleScale / rtSize.y));
    //        commandBuffer.DispatchCompute(cs, 1, csThreadGroup_rt.x, csThreadGroup_rt.y, 1);

    //        for (int i = 0; i < 2; i++)
    //        {
    //            commandBuffer.SetComputeTextureParam(cs, 0, "_StackSource", ssaoRt0);
    //            commandBuffer.SetComputeTextureParam(cs, 0, "_StackOutput", ssaoRt1);
    //            commandBuffer.SetComputeVectorParam(cs, "_BlurOffset", new Vector4(ssao.blurScale / rtSize.x, 0.0f));
    //            commandBuffer.DispatchCompute(cs, 0, csThreadGroup_rt.x, csThreadGroup_rt.y, 1);

    //            commandBuffer.SetComputeTextureParam(cs, 0, "_StackSource", ssaoRt1);
    //            commandBuffer.SetComputeTextureParam(cs, 0, "_StackOutput", ssaoRt0);
    //            commandBuffer.SetComputeVectorParam(cs, "_BlurOffset", new Vector4(0.0f, ssao.blurScale / rtSize.y));
    //            commandBuffer.DispatchCompute(cs, 0, csThreadGroup_rt.x, csThreadGroup_rt.y, 1);
    //        }

    //        commandBuffer.SetComputeVectorParam(cs, "_SourceWidthHeight", new Vector4(width, height));
    //        commandBuffer.SetComputeTextureParam(cs, 2, "_StackSource", sourceTarget);
    //        commandBuffer.SetComputeTextureParam(cs, 2, "_StackOutput", destTarget);
    //        commandBuffer.SetComputeTextureParam(cs, 2, "_BlendMulRTex", ssaoRt0);
    //        commandBuffer.DispatchCompute(cs, 2, csThreadGroup.x, csThreadGroup.y, 1);

    //        commandBuffer.SetComputeTextureParam(cs, 3, "_StackSource", destTarget);
    //        commandBuffer.SetComputeTextureParam(cs, 3, "_StackOutput", sourceTarget);
    //        commandBuffer.DispatchCompute(cs, 3, csThreadGroup.x, csThreadGroup.y, 1);

    //        commandBuffer.ReleaseTemporaryRT(ssaoRt0);
    //        commandBuffer.ReleaseTemporaryRT(ssaoRt1);
    //        commandBuffer.ReleaseTemporaryRT(destTarget);

    //        commandBuffer.EndSample("SSAO");
    //        Execute();
    //    }
    //}
    #endregion

    public void RenderSSAO(int colorBuffer, int depthBuffer)
    {
		PostProcessSettings.SSAO_Settings ssao = postprocessSettings.ssao;
		int width = camera.pixelWidth;
		int height = camera.pixelHeight;

		int sourceTarget = colorBuffer;
		int destTarget = destinationId;
        commandBuffer.GetTemporaryRT(destinationId, width, height, 0, postprocessSettings.filterMode, postprocessSettings.renderTextureFormat);
		Draw(sourceTarget, destTarget, Pass.Copy);

		Vector2Int rtSize = new Vector2Int(width >> ssao.downSample, height >> ssao.downSample);
        commandBuffer.GetTemporaryRT(ssaoRt0, rtSize.x, rtSize.y, 0, FilterMode.Bilinear, GraphicsFormat.R8_UNorm);
        commandBuffer.GetTemporaryRT(ssaoRt1, rtSize.x, rtSize.y, 0, FilterMode.Bilinear, GraphicsFormat.R8_UNorm);

        commandBuffer.SetGlobalVector("_AO_Scales", new Vector4(ssao.aoStrength, ssao.sampleScale / rtSize.x, ssao.sampleScale / rtSize.y, 0.5f));
		Draw(destTarget, ssaoRt0, Pass.SSAO);

		for (int i = 0; i < 3; i++)
		{
            commandBuffer.SetGlobalVector("_BlurOffset", new Vector4(ssao.blurScale / rtSize.x, 0.0f));
			Draw(ssaoRt0, ssaoRt1, Pass.GaussianBlur);

            commandBuffer.SetGlobalVector("_BlurOffset", new Vector4(0.0f, ssao.blurScale / rtSize.y));
			Draw(ssaoRt1, ssaoRt0, Pass.GaussianBlur);
		}

        commandBuffer.SetGlobalTexture("_PostProcessBlend", ssaoRt0);
		Draw(destTarget, sourceTarget, Pass.BlendMulR);
        commandBuffer.ReleaseTemporaryRT(ssaoRt0);
        commandBuffer.ReleaseTemporaryRT(ssaoRt1);
        commandBuffer.ReleaseTemporaryRT(destinationId);

		Execute();
	}

    private void Draw(RenderTargetIdentifier source, RenderTargetIdentifier destination, Pass pass, bool clear = false)
    {
        commandBuffer.SetGlobalTexture(sourceId, source);
        commandBuffer.SetRenderTarget(destination, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        if (clear)
        {
            commandBuffer.ClearRenderTarget(true, true, Color.clear);
        }
        commandBuffer.DrawProcedural(Matrix4x4.identity, postprocessSettings.Material, (int)pass, MeshTopology.Triangles, 3);
    }

    private void Execute()
    {
        context.ExecuteCommandBuffer(commandBuffer);
        commandBuffer.Clear();
    }
}
