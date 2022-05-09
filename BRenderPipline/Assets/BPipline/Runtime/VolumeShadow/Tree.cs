using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VolumeShadow
{
    public class Tree : MonoBehaviour
    {
        public Texture2D tex;
        public VolumedShadowData data;
        public Shader SSVolShadow;
        private Material drawMaterial;
        private RenderTexture rt_mask;
        public Transform testPoint;


        private void Start()
        {
            InitShadowData();
        }

        private void InitShadowData()
        {

            drawMaterial = new Material(SSVolShadow);

            rt_mask = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.R8);
            drawMaterial.SetInt("_GridNum", data.gridNum);
            drawMaterial.SetFloat("_GridSize_Inv", 1.0f / data.gridSize);
            Shader.SetGlobalTexture("_TestQTreeMaskTex", rt_mask);

            Shader.SetGlobalTexture("_TestQTreeTex", tex);
            Shader.SetGlobalInt("_TestQTreeWidth", tex.width);
        }

        private void OnPreRender()
        {
            GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            Camera cam = GetComponent<Camera>();
            float aspect = cam.aspect;
            float near = cam.nearClipPlane;
            float far = cam.farClipPlane;

            float halfFovTan = Mathf.Tan(cam.fieldOfView * 0.5f * Mathf.Deg2Rad);
            Vector3 up = cam.transform.up;
            Vector3 right = cam.transform.right;
            Vector3 forward = cam.transform.forward;

            Vector3 forwardVector = forward * far;
            Vector3 upVector = up * far * halfFovTan;
            Vector3 rightVector = right * far * halfFovTan * aspect;

            Vector3 topLeft = forwardVector - rightVector + upVector;
            Vector3 topRight = forwardVector + rightVector + upVector;
            Vector3 bottomLeft = forwardVector - rightVector - upVector;
            Vector3 bottomRight = forwardVector + rightVector - upVector;

            Matrix4x4 viewPortRay = Matrix4x4.identity;
            viewPortRay.SetRow(0, topLeft);
            viewPortRay.SetRow(1, topRight);
            viewPortRay.SetRow(2, bottomLeft);
            viewPortRay.SetRow(3, bottomRight);

            Shader.SetGlobalMatrix("_FrustumCornerRay", viewPortRay);
            Graphics.Blit(source, rt_mask, drawMaterial, 0);
            Graphics.Blit(source, destination, drawMaterial, 1);
        }

        private void OnDestroy()
        {
            RenderTexture.ReleaseTemporary(rt_mask);
        }
    }
}
