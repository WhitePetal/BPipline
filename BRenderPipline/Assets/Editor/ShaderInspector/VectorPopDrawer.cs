using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class VectorPopDrawer : MaterialPropertyDrawer
{
	public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
	{
		Vector4 value = prop.vectorValue;
		string[] names = prop.displayName.Split('_');
		EditorGUI.BeginChangeCheck();
		for (int i = 0; i < names.Length; ++i)
        {
			string name = names[i];
			//int len = name.Length * 20;
			value[i] = EditorGUILayout.FloatField(name, value[i]);
			//EditorGUI.LabelField(position, name);
			//value[i] = EditorGUI.FloatField(new Rect(position.x + len, position.y, position.width - len, position.height), value[i]);
			//position.y += position.height + 5;
		}
		if (EditorGUI.EndChangeCheck())
		{
			prop.vectorValue = value;
		}
		GUILayout.Space(20);
	}
}
