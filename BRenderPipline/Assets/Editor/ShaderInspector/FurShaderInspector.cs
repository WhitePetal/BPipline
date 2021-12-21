/***************************
	文件：FurShaderInspector
	创建者：白翱翔
	电话：15617780691
	功能：自定义 fur Shader 的 inspector 面板
***************************/
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class FurShaderInspector : ShaderGUI
{
    MaterialEditor editor;
    Material target;
    MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.editor = materialEditor;
        this.target = (Material)this.editor.target;
        this.properties = properties;

        EditorGUI.indentLevel += 2;
        DrawFur();
        
        DrawRenderSetting();
        
        DrawNature();

        var bloomCol = FindProperty("_BloomColor");
        var bloom = FindProperty("_BloomIntensity");
        editor.ShaderProperty(bloomCol, MakeLable("辉光颜色"));
        editor.ShaderProperty(bloom, MakeLable("Bloom"));

        EditorGUI.indentLevel -= 2;
        editor.RenderQueueField();
    }

    private static GUIContent staticLable = new GUIContent();
    private static GUIContent MakeLable(string text, string toolTip = "")
    {
        staticLable.tooltip = toolTip;
        staticLable.text = text;
        return staticLable;
    }
    private static GUIContent MakeLable(MaterialProperty property, string toolTip = "")
    {
        staticLable.text = property.displayName;
        staticLable.tooltip = toolTip;
        return staticLable;
    }
    private MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }
    private void SetKeyword(string name, bool state)
    {
        if (state) target.EnableKeyword(name);
        else target.DisableKeyword(name);
    }

    private void DrawFur()
    {
        GUILayout.Label("Fur");
        var layerMap = FindProperty("_LayerMap");
        var furBaseOffset_furOffset_furLength = FindProperty("_FurBaseOffset_FurOffset_FurLength");
        var layerMap2 = FindProperty("_LayerMap2");
        editor.ShaderProperty(furBaseOffset_furOffset_furLength, "_FurBaseOffset_FurOffset_FurLength");
        editor.TexturePropertySingleLine(MakeLable("毛发形状"), layerMap2);
        editor.TexturePropertySingleLine(MakeLable("毛发分布"), layerMap);
        editor.TextureScaleOffsetProperty(layerMap);
    }

    enum LightColor
    {
        UNITY,
        CUSTOME
    }
    private void DrawRenderSetting()
    {
        GUILayout.Label("Render");
        var mainTex = FindProperty("_MainTex");
        var baseCol = FindProperty("_DiffuseColor");
        GUIContent mainTexLable = MakeLable("Diffuse", "漫反射贴图");
        editor.TexturePropertySingleLine(mainTexLable, mainTex, baseCol);
        editor.TextureScaleOffsetProperty(mainTex);

        DrawAO();
        DrawLight();
        DrawAmbient();
        DrawSpecular();
    }
    private void DrawAO()
    {
        EditorGUILayout.Space();
        var ao = FindProperty("_AO");
        var aoLable = MakeLable("AO", "自环境光遮蔽强度");
        editor.ShaderProperty(ao, aoLable);

        var aoOffset = FindProperty("_AoOffset");
        var aoOffsetLable = MakeLable("AO Offset", "自环境光遮蔽强度偏移");
        editor.ShaderProperty(aoOffset, aoOffsetLable);
    }
    private Light useLight;
    private void DrawLight()
    {
        EditorGUILayout.Space();
        LightColor lightColor = target.IsKeywordEnabled("CUSTOME_LIGHT_COLOR") ? LightColor.CUSTOME : LightColor.UNITY;
        EditorGUI.BeginChangeCheck();
        lightColor = (LightColor)EditorGUILayout.EnumPopup(MakeLable("Light Color Source", "光颜色源"), lightColor);
        if (EditorGUI.EndChangeCheck()) SetKeyword("CUSTOME_LIGHT_COLOR", lightColor == LightColor.CUSTOME);
        if(lightColor == LightColor.CUSTOME)
        {
            var lightCol = FindProperty("_LightCol");
            var lcLable = MakeLable("Light Color", "自定义光颜色");
            editor.ShaderProperty(lightCol, lcLable);
        }
        var lightFilter = FindProperty("_LightFilter");
        var lfLable = MakeLable("暗部亮度", "背光强度偏移");
        editor.ShaderProperty(lightFilter, lfLable);

        var lightExposure = FindProperty("_LightExposure");
        var leLable = MakeLable("受光强度", "光强");
        editor.ShaderProperty(lightExposure, leLable);
    }
    private void DrawAmbient()
    {
        EditorGUILayout.Space();
        var ambient = FindProperty("_Ambient");
        var abLable = MakeLable("环境光", "环境光颜色");
        editor.ShaderProperty(ambient, abLable);

        var abStrength = FindProperty("_AmbientStrength");
        var absLable = MakeLable("环境光强度", "环境光强");
        editor.ShaderProperty(abStrength, absLable);

        var rimColor = FindProperty("_RimColor");
        var fresnel = FindProperty("_FresnelStrength_FresnelRange");
        var fLable = MakeLable("Fresnel Strength", "菲涅尔/边缘光强度");
        editor.ShaderProperty(rimColor, MakeLable("边缘光颜色"));
        editor.ShaderProperty(fresnel, fLable);
    }
    private void DrawSpecular()
    {
        EditorGUILayout.Space();
        var spec1 = FindProperty("_SpecCol1"); ;
        var spec1Lable = MakeLable("1号高光颜色", "第一层高光颜色");
        editor.ShaderProperty(spec1, spec1Lable);

        var spec2 = FindProperty("_SpecCol2");
        var spec2Lable = MakeLable("2号高光颜色", "第二层高光颜色");
        editor.ShaderProperty(spec2, spec2Lable);

        var exp = FindProperty("_SpecExp");
        var expLable = MakeLable("Specular Exp", "高光系数(shift shift exponent exponent)");
        editor.ShaderProperty(exp, expLable);

        var strength = FindProperty("_SpecStrength");
        var strengthLable = MakeLable("高光强度", "高光强度");
        editor.ShaderProperty(strength, strengthLable);
    }

    enum GravityUse
    {
        ON,
        OFF
    }
    enum WindUse
    {
        ON,
        OFF
    }
    private void DrawNature()
    {
        GUILayout.Label("Nature");
        DrawGravity();

        DrawWind();
    }
    private void DrawGravity()
    {
        GravityUse gravityUse = target.IsKeywordEnabled("GRAVITY_ON") ? GravityUse.ON : GravityUse.OFF;
        EditorGUI.BeginChangeCheck();
        gravityUse = (GravityUse)EditorGUILayout.EnumPopup(MakeLable("Gravity Use", "是否应用重力"), gravityUse);
        if (EditorGUI.EndChangeCheck()) SetKeyword("GRAVITY_ON", gravityUse == GravityUse.ON);
        if (gravityUse == GravityUse.OFF) return;
        var gravityScale = FindProperty("_GravityScale");
        var gsLable = MakeLable("重力大小", "重力大小");
        editor.ShaderProperty(gravityScale, gsLable);

        var gravityDir = FindProperty("_GravityDir");
        var gdLable = MakeLable("重力方向", "重力方向");
        editor.ShaderProperty(gravityDir, gdLable);
    }
    private void DrawWind()
    {
        EditorGUILayout.Space();
        WindUse windUse = target.IsKeywordEnabled("WIND_ON") ? WindUse.ON : WindUse.OFF;
        EditorGUI.BeginChangeCheck();
        windUse = (WindUse)EditorGUILayout.EnumPopup(MakeLable("Wind Use", "是否应用风力"), windUse);
        if(EditorGUI.EndChangeCheck()) SetKeyword("WIND_ON", windUse == WindUse.ON);
        if (windUse == WindUse.OFF) return;
        var windScale = FindProperty("_WindScale");
        var wsLable = MakeLable("风力大小", "风强度");
        editor.ShaderProperty(windScale, wsLable);
        var windFrequency = FindProperty("_WindFresquency");
        var wfLabel = MakeLable("风频率", "风频");
        editor.ShaderProperty(windFrequency, wfLabel);
        var windPhaseScale = FindProperty("_WindPhaseScale");
        var wpLabel = MakeLable("风相位缩放", "风相位缩放");
        editor.ShaderProperty(windPhaseScale, wpLabel);

        var windDir = FindProperty("_WindDir");
        var wdLable = MakeLable("风方向", "风向");
        editor.ShaderProperty(windDir, wdLable);
    }
}
