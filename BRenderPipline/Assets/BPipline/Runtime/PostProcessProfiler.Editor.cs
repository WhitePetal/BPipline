using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public partial class PostProcessProfiler
{
#if UNITY_EDITOR
    private void ApplySceneViewState()
    {
        if(camera.cameraType == CameraType.SceneView && !SceneView.currentDrawingSceneView.sceneViewState.showImageEffects)
        {
            postprocessSettings = null;
        }
    }
#endif
}
