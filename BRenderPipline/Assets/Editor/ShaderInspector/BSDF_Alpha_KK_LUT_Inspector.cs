﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BSDF_Alpha_KK_LUT_Inspector : MShaderGUI
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
		materialEditor.TexturePropertySingleLine(MakeLable("Alpha Mask"), FindProperty("_AlphaMask"));
		materialEditor.TexturePropertySingleLine(MakeLable("Albedo"), albedo, FindProperty("_DiffuseColor"));
		materialEditor.ColorProperty(FindProperty("_SpecularColor"), "高光颜色");

		if (level == Level.High) materialEditor.TexturePropertySingleLine(MakeLable("NormalMap"), FindProperty("_NormalTex"));
		else materialEditor.TexturePropertySingleLine(MakeLable("NormalMap"), FindProperty("_NormalTex"), FindProperty("_NormalScale"));

		materialEditor.ShaderProperty(FindProperty("_KdKsExpoureParalxScale"), MakeLable("KdKsExpoureParalxScale"));
		if(level == Level.High) materialEditor.ShaderProperty(FindProperty("_AddLightStrength"), MakeLable("附加光强度"));

		if(level == Level.High)
        {
			bool heightMapOn = target.IsKeywordEnabled("_HeightMap");
			heightMapOn = GUILayout.Toggle(heightMapOn, MakeLable("Height Map On"));
			if (heightMapOn)
			{
				materialEditor.TexturePropertySingleLine(MakeLable("HeightMap"), FindProperty("_ParallxTex"));
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
		materialEditor.ShaderProperty(FindProperty("_Fresnel"), MakeLable("Fresnel0"));
		materialEditor.ShaderProperty(FindProperty("_MetallicRoughnessAOClampValue"), MakeLable("_MetallicRoughnessAOClampValue"));
		materialEditor.TextureScaleOffsetProperty(albedo);
		EditorGUI.indentLevel -= 2;

		if(level == Level.High)
        {
			GUILayout.Space(20);
			GUILayout.Label(MakeLable("DetilTex"));
			EditorGUI.indentLevel += 2;
			var detil = FindProperty("_DetilTex", properties);
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
			materialEditor.ShaderProperty(FindProperty("_NormalScales"), MakeLable("_NormalScales"));
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
		GUILayout.Label(MakeLable("Aniso Specular"));
		EditorGUI.indentLevel += 2;
		var shiftTex = FindProperty("_AnisoDirectionTex");
		materialEditor.TexturePropertySingleLine(MakeLable("Shift Texture"), shiftTex);
		materialEditor.TextureScaleOffsetProperty(shiftTex);
		materialEditor.ShaderProperty(FindProperty("_ShiftStrength"), MakeLable("扰动强度"));
		materialEditor.ShaderProperty(FindProperty("_Shifts_SpecularWidths"), "Shifts_SpecularWidth");
		materialEditor.ShaderProperty(FindProperty("_Exponents_SpecStrengths"), "Exponents_SpecStrengths");
		materialEditor.ShaderProperty(FindProperty("_SpecColor1"), MakeLable("1号高光颜色"));
		materialEditor.ShaderProperty(FindProperty("_SpecColor2"), MakeLable("2号高光颜色"));
		EditorGUI.indentLevel -= 2;

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


		if(level != Level.VeryLow)
        {
			EmissionPointLevel emissionPointLevel = EmissionPointLevel.Off;
			if (target.IsKeywordEnabled("_EmissionPointOff")) emissionPointLevel = EmissionPointLevel.Off;
			else if (target.IsKeywordEnabled("_EmissionPointLow")) emissionPointLevel = EmissionPointLevel.Low;
			else if (target.IsKeywordEnabled("_EmissionPointMid")) emissionPointLevel = EmissionPointLevel.Mid;
			else if (target.IsKeywordEnabled("_EmissionPointHeight")) emissionPointLevel = EmissionPointLevel.Height;
			EditorGUI.BeginChangeCheck();
			emissionPointLevel = (EmissionPointLevel)EditorGUILayout.EnumPopup(MakeLable("Emission Point", "闪点"), emissionPointLevel);
			if (EditorGUI.EndChangeCheck())
			{
				switch (emissionPointLevel)
				{
					case EmissionPointLevel.Off:
						SetKeyword("_EmissionPointOff", true);
						SetKeyword("_EmissionPointLow", false);
						SetKeyword("_EmissionPointMid", false);
						SetKeyword("_EmissionPointHeight", false);
						break;
					case EmissionPointLevel.Low:
						SetKeyword("_EmissionPointOff", false);
						SetKeyword("_EmissionPointLow", true);
						SetKeyword("_EmissionPointMid", false);
						SetKeyword("_EmissionPointHeight", false);
						break;
					case EmissionPointLevel.Mid:
						SetKeyword("_EmissionPointOff", false);
						SetKeyword("_EmissionPointLow", false);
						SetKeyword("_EmissionPointMid", true);
						SetKeyword("_EmissionPointHeight", false);
						break;
					case EmissionPointLevel.Height:
						SetKeyword("_EmissionPointOff", false);
						SetKeyword("_EmissionPointLow", false);
						SetKeyword("_EmissionPointMid", false);
						SetKeyword("_EmissionPointHeight", true);
						break;
				}
			}
			if (!target.IsKeywordEnabled("_EmissionPointOff"))
			{
				GUILayout.Space(20);
				GUILayout.Label(MakeLable("闪点"));
				EditorGUI.indentLevel += 2;
				var epPulse = FindProperty("_EmissionPointPulse");

				editor.TexturePropertySingleLine(MakeLable("闪点遮罩"), FindProperty("_EmissionPointMask"), FindProperty("_EmissionPointColor"));
				//editor.ShaderProperty(epColor, MakeLable("闪点颜色"));
				editor.ShaderProperty(FindProperty("_EmissionGloss"), MakeLable("闪点高光Gloss", "X: 高亮范围，Y：高亮强度，Z：高亮基础强度"));
				editor.ShaderProperty(FindProperty("_EmissionPointDensity"), MakeLable("闪点密度"));
				editor.ShaderProperty(FindProperty("_EmissionPointNoiseOffset"), MakeLable("闪点偏移"));

				editor.ShaderProperty(FindProperty("_EmissionPointCutoff_EmissionPointFrequency"), MakeLable("_EmissionPointCutoff_EmissionPointFrequency"));

				float epPulsePhase = epPulse.vectorValue.x;
				float epPulseFrequency = epPulse.vectorValue.y;
				EditorGUI.BeginChangeCheck();
				epPulsePhase = EditorGUILayout.FloatField(MakeLable("闪点脉冲相位偏差", "越大闪点间的闪烁\n越不同步"), epPulsePhase);
				epPulseFrequency = EditorGUILayout.Slider(MakeLable("闪点脉冲频率", "越大闪烁越块"), epPulseFrequency, 0f, 2f);
				if (EditorGUI.EndChangeCheck())
				{
					target.SetVector("_EmissionPointPulse", new Vector4(epPulsePhase, epPulseFrequency, 0f, 0f));
				}
				EditorGUI.indentLevel -= 2;
			}
		}

		GUILayout.Space(20);
		GUILayout.Label(MakeLable("PostProcess"));
		EditorGUI.indentLevel += 2;
		materialEditor.ShaderProperty(FindProperty("_BloomColor"), MakeLable("辉光颜色"));
		materialEditor.ShaderProperty(FindProperty("_PostProcessFactors"), MakeLable("_PostProcessFactors"));
		EditorGUI.indentLevel -= 2;

		GUILayout.Space(20);
		materialEditor.RenderQueueField();
	}
}
