using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ObjDirectionVectorDrawer : MaterialPropertyDrawer
{
	private MaterialProperty m_prop;
	private bool drawSceneGUI = false;
	private bool startDraw = true;
	private Vector3 pos;


	public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
	{
		EditorGUI.BeginChangeCheck();
		drawSceneGUI = GUILayout.Toggle(drawSceneGUI, new GUIContent("Draw Direction Handle"));
		if (drawSceneGUI)
		{
			if (startDraw)
			{
				m_prop = prop;
				pos = Selection.activeGameObject.transform.position;
				RegisterSceneGUI();
			}
		}
		else
		{
			if (!startDraw) RemoveSceneGUI();
		}
		Vector4 direction = prop.vectorValue;
		direction = EditorGUI.Vector3Field(position, label, direction);
		if (EditorGUI.EndChangeCheck())
		{
			prop.vectorValue = direction;
		}
	}

	private void RegisterSceneGUI()
	{
		SceneView.duringSceneGui += OnSceneGUI;
		startDraw = false;
	}

	private void RemoveSceneGUI()
	{
		SceneView.duringSceneGui -= OnSceneGUI;
		startDraw = true;
		m_prop = null;
	}

	private void OnSceneGUI(SceneView sceneView)
	{
		GameObject selectObj = Selection.activeGameObject;
		if (selectObj == null)
		{
			RemoveSceneGUI();
			return;
		}
		Transform curObj = selectObj.transform;
		while (curObj.parent != null) curObj = curObj.parent;
		Vector4 vecValue = m_prop.vectorValue;
		vecValue.w = 0.0f;
		Quaternion rot = Quaternion.FromToRotation(Vector3.forward, vecValue);
		pos = Handles.PositionHandle(pos, Quaternion.identity);
		rot = Handles.RotationHandle(rot, pos);
		m_prop.vectorValue = rot * Vector3.forward;
		Handles.color = Color.red;
		Vector3 point_target = pos + new Vector3(m_prop.vectorValue.x, m_prop.vectorValue.y, m_prop.vectorValue.z).normalized * 100;
		Handles.DrawLine(pos, point_target);
		//Handles.ArrowHandleCap(0, pos, rot, 2.0f, EventType.Ignore);
	}
}
