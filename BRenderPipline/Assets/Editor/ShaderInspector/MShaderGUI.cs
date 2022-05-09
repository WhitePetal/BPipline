using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MShaderGUI : ShaderGUI
{
    protected MaterialEditor editor;
    protected Material target;
    protected MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.editor = materialEditor;
        this.target = (Material)this.editor.target;
        this.properties = properties;
        base.OnGUI(materialEditor, properties);
    }

    protected static GUIContent staticLable = new GUIContent();
    protected static GUIContent MakeLable(string text, string toolTip = "")
    {
        staticLable.tooltip = toolTip;
        staticLable.text = text;
        return staticLable;
    }
    protected static GUIContent MakeLable(MaterialProperty property, string toolTip = "")
    {
        staticLable.text = property.displayName;
        staticLable.tooltip = toolTip;
        return staticLable;
    }
    protected MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }
    protected void SetKeyword(string name, bool state)
    {
        if (state) target.EnableKeyword(name);
        else target.DisableKeyword(name);
    }
}
