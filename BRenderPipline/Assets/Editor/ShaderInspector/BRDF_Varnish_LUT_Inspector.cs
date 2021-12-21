using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BRDF_LUT_Varnish_Inspector : MShaderGUI
{
	protected enum Level
    {
		High,
		Low,
		VeryLow
    }
	protected enum EmissionPointLevel
	{
		Off,
		Low,
		Mid,
		Height
	}

	protected Level level = Level.High;

	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
	{
		base.OnGUI(materialEditor, properties);

		var albedo = FindProperty("_MainTex");
		materialEditor.TexturePropertySingleLine(MakeLable("LUT"), FindProperty("_LUT"));
		GUILayout.Label(MakeLable("MainTex"));
		EditorGUI.indentLevel += 2;
		materialEditor.TexturePropertySingleLine(MakeLable("Albedo"), albedo, FindProperty("_DiffuseColor"));
		materialEditor.ColorProperty(FindProperty("_SpecularColor"), "高光颜色");

		if (level == Level.High) materialEditor.TexturePropertySingleLine(MakeLable("NormalMap"), FindProperty("_NormalTex"));
		else materialEditor.TexturePropertySingleLine(MakeLable("NormalMap"), FindProperty("_NormalTex"), FindProperty("_NormalScale"));

		materialEditor.ShaderProperty(FindProperty("_KdKsExpoureParalxScale"), MakeLable("KdKsExpoureParalxScale"));

		if(level == Level.High)
        {
			bool heightMapOn = target.IsKeywordEnabled("_HeightMap");
			heightMapOn = GUILayout.Toggle(heightMapOn, MakeLable("Height Map On"));
			if (heightMapOn)
			{
				materialEditor.TexturePropertySingleLine(MakeLable("HeightMap"), FindProperty("_ParallxTex", properties));
				target.EnableKeyword("_HeightMap");
			}
			else
			{
				target.DisableKeyword("_HeightMap");
			}
		}

		materialEditor.TexturePropertySingleLine(MakeLable("金属度(R) 粗糙度(G) AO(B)"), FindProperty("_MRATex"));
		bool emissionOn = target.IsKeywordEnabled("_Emission");
		emissionOn = GUILayout.Toggle(emissionOn, MakeLable("Emission On"));
		if (emissionOn)
		{
			materialEditor.TexturePropertySingleLine(MakeLable("EmissionMap RGB:Color A:Mask"), FindProperty("_EmissionMap"), FindProperty("_EmissionStrength"));
			target.EnableKeyword("_Emission");
		}
		else
		{
			target.DisableKeyword("_Emission");
		}
		GUILayout.Space(20);
		materialEditor.ColorProperty(FindProperty("_Fresnel"), "Fresnel0");
		materialEditor.ShaderProperty(FindProperty("_MetallicRoughnessAO"), "_MetallicRoughnessAO");
		materialEditor.TextureScaleOffsetProperty(albedo);
		EditorGUI.indentLevel -= 2;

		GUILayout.Space(20);
		EditorGUI.indentLevel += 2;
		materialEditor.ShaderProperty(FindProperty("_Varnish_Color"), "清漆颜色");
		materialEditor.ShaderProperty(FindProperty("_Varnish_Transmission_Roughness"), "清漆");
		EditorGUI.indentLevel -= 2;

		if(level == Level.High)
        {
			GUILayout.Space(20);
			GUILayout.Label(MakeLable("DetilTex"));
			EditorGUI.indentLevel += 2;
			var detil = FindProperty("_DetilTex");
			materialEditor.TexturePropertySingleLine(MakeLable("Detil"), detil, FindProperty("_DetilColor"));
			materialEditor.TexturePropertySingleLine(MakeLable("DetilNormal"), FindProperty("_DetilNormalTex"));
			materialEditor.TextureScaleOffsetProperty(detil);
			EditorGUI.indentLevel -= 2;
		}

		if(level == Level.High)
        {
			GUILayout.Space(20);
			GUILayout.Label(MakeLable("NormalScales"));
			EditorGUI.indentLevel += 2;
			materialEditor.ShaderProperty(FindProperty("_NormalScales"), "_NormalScales");
			EditorGUI.indentLevel -= 2;
		}

		if(level == Level.High)
        {
			GUILayout.Space(20);
			GUILayout.Label(MakeLable("Custome Point Light"));
			EditorGUI.indentLevel += 2;
			bool pointLightOn = target.IsKeywordEnabled("_PointLight");
			pointLightOn = GUILayout.Toggle(pointLightOn, MakeLable("Point Light On"));
			if (pointLightOn)
			{
				materialEditor.ShaderProperty(FindProperty("_PointLightColor"), MakeLable("Point Light Color"));
				materialEditor.ShaderProperty(FindProperty("_PointLightPos"), MakeLable("Point Light Position"));
				target.EnableKeyword("_PointLight");
			}
			else
			{
				target.DisableKeyword("_PointLight");
			}
			EditorGUI.indentLevel -= 2;
		}

		GUILayout.Space(20);
		GUILayout.Label(MakeLable("AmbientTex"));
		EditorGUI.indentLevel += 2;
		if (level != Level.VeryLow) materialEditor.TexturePropertySingleLine(MakeLable("环境光"), FindProperty("_AmbientTex"), FindProperty("_AmbientColor"));
		else materialEditor.ShaderProperty(FindProperty("_AmbientColor"), MakeLable("环境光"));
		materialEditor.ShaderProperty(FindProperty("_AmbientSpecStrength_SHStrength"), MakeLable("_AmbientSpecStrength_SHStrength"));
		EditorGUI.indentLevel -= 2;

		GUILayout.Space(20);
		GUILayout.Label(MakeLable("PostProcess"));
		EditorGUI.indentLevel += 2;
		materialEditor.ShaderProperty(FindProperty("_PostProcessFactors"), MakeLable("_PostProcessFactors"));
		EditorGUI.indentLevel -= 2;

		GUILayout.Space(20);
		materialEditor.RenderQueueField();
	}
}
