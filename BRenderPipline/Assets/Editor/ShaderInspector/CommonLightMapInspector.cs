using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class CommonLightMapInspector : MShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        var mainTex = FindProperty("_MainTex");
        var normalTex = FindProperty("_NormalTex");
        materialEditor.ShaderProperty(FindProperty("_BaseColor"), MakeLable("BaseColor"));
        materialEditor.TexturePropertySingleLine(MakeLable("Albedo(RGB) AO(A)"), mainTex);
        materialEditor.TexturePropertySingleLine(MakeLable("NormalMap"), normalTex);
        materialEditor.TextureScaleOffsetProperty(mainTex);
        materialEditor.ShaderProperty(FindProperty("_NormalScale_AO_Brightness"), MakeLable("_NormalScale_AO_Brightness"));
        materialEditor.ShaderProperty(FindProperty("_AmbientColor"), MakeLable("环境光颜色"));
        materialEditor.ShaderProperty(FindProperty("_PostProcessFactors"), MakeLable("辉光强度_辉光阈值"));
    }
}
