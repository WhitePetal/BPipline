using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class CustomeLightMapInspector : MShaderGUI
{
    private bool lightmap;
    private bool dirLightmap;
    private bool shadowmask;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        var mainTex = FindProperty("_MainTex");
        var normalTex = FindProperty("_NormalTex");
        materialEditor.ShaderProperty(FindProperty("_BaseColor"), MakeLable("BaseColor"));
        materialEditor.TexturePropertySingleLine(MakeLable("Albedo(RGB) A(AO)"), mainTex);
        materialEditor.TexturePropertySingleLine(MakeLable("Normal Map"), normalTex);
        materialEditor.TextureScaleOffsetProperty(mainTex);

        materialEditor.ShaderProperty(FindProperty("_NormalScale_AO_Brightness"), MakeLable("_NormalScale_AO_Brightness"));

        materialEditor.TexturePropertySingleLine(MakeLable("Light Map"), FindProperty("_LightMap"));

        dirLightmap = target.IsKeywordEnabled("UseDirLightMap");
        dirLightmap = EditorGUILayout.Toggle(MakeLable("DirLightMap"), dirLightmap);
        if (dirLightmap)
        {
            target.EnableKeyword("UseDirLightMap");
            materialEditor.TexturePropertySingleLine(MakeLable("Dir Light Map"), FindProperty("_DirLightMap"));
        }
        else
        {
            target.DisableKeyword("UseDirLightMap");
        }

        shadowmask = target.IsKeywordEnabled("UseShadowMaskMap");
        shadowmask = EditorGUILayout.Toggle(MakeLable("ShadowMask"), shadowmask);
        if (shadowmask)
        {
            target.EnableKeyword("UseShadowMaskMap");
            materialEditor.TexturePropertySingleLine(MakeLable("Shadow Mask"), FindProperty("_ShadowMaskMap"));
        }
        else
        {
            target.DisableKeyword("UseShadowMaskMap");
        }
    }
}
