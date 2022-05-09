using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/PostProcessSettings")]
public class PostProcessSettings : ScriptableObject
{
    public CommandBuffer commandBuffer;
    [SerializeField]
    private Shader postprocessStackShader;
    [System.NonSerialized]
    private Material material;
    public Material Material
    {
        get
        {
            if(material == null && postprocessStackShader != null)
            {
                material = new Material(postprocessStackShader);
                material.hideFlags = HideFlags.HideAndDontSave;
            }
            return material;
        }
    }

    public ComputeShader computeShaderStack;

    [System.Serializable]
    public struct HDR_Settings
	{
        public bool enable;
        [Range(0.0f, 10.0f)]
        public float aces_tonemapping;
	}

    [System.Serializable]
    public struct SSAO_Settings
	{
        public bool enable;
        [Range(0, 8)]
        public int downSample;
        [Range(0.0f, 64.0f)]
        public float sampleScale;
        [Range(0.0f, 10.0f)]
        public float blurScale;
        [Range(0.0f, 4.0f)]
        public float aoStrength;
	}

    public SSAO_Settings ssao = new SSAO_Settings
    {
        enable = false,
        downSample = 1,
        sampleScale = 7.0f,
        blurScale = 1.0f,
        aoStrength = 1.0f
    };
    public HDR_Settings hdr = new HDR_Settings
    {
        enable = false,
        aces_tonemapping = 1.2f
	};
    
    public bool fxaa = false;
    public FilterMode filterMode = FilterMode.Bilinear;
    //[HideInInspector]
    public RenderTextureFormat renderTextureFormat = RenderTextureFormat.Default;

    [HideInInspector]
    public List<PostEffectBase> postProcessEffects = new List<PostEffectBase>();

    public void AddPostEffect(PostEffectBase effect)
    {
        postProcessEffects.Add(effect);
        postProcessEffects.Sort(PostEffectBase.compare);
    }

    public void RemovePostEffect(PostEffectBase effect)
    {
        postProcessEffects.Remove(effect);
    }
}
