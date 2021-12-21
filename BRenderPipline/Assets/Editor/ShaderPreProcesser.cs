using System.Collections;
using System.Collections.Generic;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

public class ShaderPreProcesser : IPreprocessShaders
{
    public int callbackOrder => 0;

    private static ShaderKeyword receiveShadows_keyword = new ShaderKeyword("_RECEIVE_SHADOWS");
    private static ShaderKeyword lightmapon_keyword = new ShaderKeyword("LIGHTMAP_ON");

    public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data)
    {
        RenderPipelineAsset renderPipelineAsset = GraphicsSettings.renderPipelineAsset;
        for (int i = data.Count - 1; i >= 0; --i)
        {
            var compile = data[i];
            ShaderKeyword[] keywords = compile.shaderKeywordSet.GetShaderKeywords();
            foreach(var keyword in keywords)
            {
                string keywordName = ShaderKeyword.GetGlobalKeywordName(keyword);

                if (keywordName == "_SHADOW_MASK_ALWAYS" && QualitySettings.shadowmaskMode == ShadowmaskMode.DistanceShadowmask)
                {
                    data.RemoveAt(i);
                    break;
                }
                if (keywordName == "_SHADOW_MASK_DISTANCE" && QualitySettings.shadowmaskMode == ShadowmaskMode.Shadowmask)
                {
                    data.RemoveAt(i);
                    break;
                }

                if (!compile.shaderKeywordSet.IsEnabled(receiveShadows_keyword) && (
                    keywordName == "_DIRECTIONAL_PCF3" || keywordName == "_DIRECTIONAL_PCF5" || keywordName == "_DIRECTIONAL_PCF7" ||
                    keywordName == "_CASCADE_BLEND_SOFT" || keywordName == "_CASCADE_BLEND_DITHER" ||
                    keywordName == "_SHADOW_MASK_ALWAYS" || keywordName == "_SHADOW_MASK_DISTANCE"
                    ))
                {
                    data.RemoveAt(i);
                    break;
                }


                if (keywordName == "DIRLIGHTMAP_COMBINED" && !compile.shaderKeywordSet.IsEnabled(lightmapon_keyword))
				{
                    data.RemoveAt(i);
                    break;
				}

                if (keywordName == "_LIGHTS_PER_OBJECT")
                {
                    if (renderPipelineAsset == null)
                    {
                        data.RemoveAt(i);
                        break;
                    }
                    BPiplineAsset bPiplineAsset = (BPiplineAsset)renderPipelineAsset;
                    if (bPiplineAsset != null && !bPiplineAsset.useLightsPerObject)
                    {
                        data.RemoveAt(i);
                        break;
                    }
                }
            }
        }
    }
}
