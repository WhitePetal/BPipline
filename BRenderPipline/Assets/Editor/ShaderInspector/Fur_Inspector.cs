using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class Fur_Inspector : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        Material t = materialEditor.target as Material;
        bool gravity = t.IsKeywordEnabled("GRAVITY_ON");
        gravity = EditorGUILayout.Toggle("Graivty_ON", gravity);
        if (gravity)
        {
            t.EnableKeyword("GRAVITY_ON");
        }
        else
        {
            t.DisableKeyword("GRAVITY_ON");
        }
        bool wind = t.IsKeywordEnabled("WIND_ON");
        wind = EditorGUILayout.Toggle("WIND_ON", wind);
        if (wind)
        {
            t.EnableKeyword("WIND_ON");
        }
        else
        {
            t.DisableKeyword("WIND_ON");
        }
    }
}
