using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Rendering;

[CanEditMultipleObjects]
[CustomEditorForRenderPipeline(typeof(MeshRenderer), typeof(BPiplineAsset))]
public class CustomeMeshRenderEditor : Editor
{
    private bool receiveShadow;

    public override void OnInspectorGUI()
    {
        MeshRenderer meshRenderer = target as MeshRenderer;

        base.OnInspectorGUI();

        if (receiveShadow != meshRenderer.receiveShadows)
        {
            receiveShadow = meshRenderer.receiveShadows;
            Material[] mats = meshRenderer.sharedMaterials;
            for (int i = 0; i < mats.Length; ++i)
            {
                if (receiveShadow) mats[i].EnableKeyword("_RECEIVE_SHADOWS");
                else mats[i].DisableKeyword("_RECEIVE_SHADOWS");
            }
        }
        EditorGUILayout.Space(10);

        meshRenderer.lightProbeUsage = (LightProbeUsage)EditorGUILayout.EnumPopup("Light Probes", meshRenderer.lightProbeUsage);
        meshRenderer.reflectionProbeUsage = (ReflectionProbeUsage)EditorGUILayout.EnumPopup("Reflect Probes", meshRenderer.reflectionProbeUsage);
        EditorGUILayout.Space(10);

        meshRenderer.sortingOrder = EditorGUILayout.IntField("SortingOrder", meshRenderer.sortingOrder);
        StaticEditorFlags staticFlags = GameObjectUtility.GetStaticEditorFlags(meshRenderer.gameObject);
        EditorGUILayout.Space(10);

        bool contributeGI = GameObjectUtility.AreStaticEditorFlagsSet(meshRenderer.gameObject, StaticEditorFlags.ContributeGI);
        contributeGI = EditorGUILayout.Toggle("Contribute GI", contributeGI);
        if (contributeGI)
        {
            GameObjectUtility.SetStaticEditorFlags(meshRenderer.gameObject, staticFlags | StaticEditorFlags.ContributeGI);
        }
        else
        {
            GameObjectUtility.SetStaticEditorFlags(meshRenderer.gameObject, staticFlags & (StaticEditorFlags)((int)StaticEditorFlags.ContributeGI ^ 0xFF));
        }

        EditorGUI.BeginDisabledGroup(!contributeGI);
        meshRenderer.receiveGI = (ReceiveGI)EditorGUILayout.EnumPopup("ReceiveGI", meshRenderer.receiveGI);
        EditorGUI.EndDisabledGroup();
        EditorGUILayout.Space(10);

        if (contributeGI && meshRenderer.receiveGI == ReceiveGI.Lightmaps)
        {
            meshRenderer.scaleInLightmap = EditorGUILayout.FloatField("ScaleInLightMap", meshRenderer.scaleInLightmap);
        }
        EditorGUILayout.Space(10);

        meshRenderer.motionVectorGenerationMode = (MotionVectorGenerationMode)EditorGUILayout.EnumPopup("Motion Vectors", meshRenderer.motionVectorGenerationMode);
        EditorGUILayout.Space(10);

        meshRenderer.sortingOrder = EditorGUILayout.IntField("Order In Layer", meshRenderer.sortingOrder);
    }
}
