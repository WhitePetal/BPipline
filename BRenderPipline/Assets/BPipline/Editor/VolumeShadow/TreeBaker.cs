using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEditor.SceneManagement;

namespace VolumeShadow
{
    public class TreeBaker : EditorWindow
    {
        private static TreeBaker window;

        private Node root;
        private GameObject previewDrawer;

        private Light mainLight;
        private Camera cam_baker;
        private float sceneSize = 102.4f;
        private int gridNum = 256;
        private float gridSize;
        private bool drawGizmos;

        [MenuItem("工具/烘焙八叉树体素阴影")]
        public static void ShowWindow()
        {
            window = GetWindow<TreeBaker>();
        }

        private void OnGUI()
        {
            mainLight = EditorGUILayout.ObjectField("主光源: ", mainLight, typeof(Light), true) as Light;
            string scenetSizeStr = sceneSize + "m";
            sceneSize = EditorGUILayout.FloatField("场景总大小: " + scenetSizeStr + " * " + scenetSizeStr + " * " + scenetSizeStr, sceneSize);
            gridNum = EditorGUILayout.IntField("格子数量: " + gridNum + " * " + gridNum + " * " + gridNum, gridNum);
            gridSize = sceneSize / gridNum;
            GUILayout.Label("一个末端节点格子 = " + gridSize + "m");

            if (GUILayout.Button("烘焙"))
            {
                if(mainLight == null)
                {
                    EditorUtility.DisplayDialog("警告", "请先添加主光源", "确定");
                    return;
                }
                // 添加碰撞体
                var staticRenders = GetAllStaticRender();
                if(staticRenders.Count == 0)
                {
                    EditorUtility.DisplayDialog("警告", "场景中不存在静态渲染物", "确定");
                    return;
                }
                List<GameObject> noColliderRenders = new List<GameObject>();
                for(int i = 0; i < staticRenders.Count; ++i)
                {
                    var r = staticRenders[i];
                    Collider collider;
                    r.TryGetComponent<Collider>(out collider);
                    // 只有当原本没有碰撞体时才添加MeshCollider
                    // 因此烘焙需要在添加物理碰撞体之前进行，否则简单的物理碰撞体可能得到错误的阴影结果
                    if(collider == null)
                    {
                        r.AddComponent<MeshCollider>();
                        noColliderRenders.Add(r);
                    }
                }

                BakeShadow();

                // 移除添加的碰撞体
                for(int i = 0; i < noColliderRenders.Count; ++i)
                {
                    var c = noColliderRenders[i].GetComponent<MeshCollider>();
                    DestroyImmediate(c);
                }
            }
            drawGizmos = EditorGUILayout.Toggle("CPU端预览绘制", drawGizmos);
            if (drawGizmos)
            {
                if (previewDrawer == null)
                {
                    previewDrawer = new GameObject();
                    previewDrawer.name = "VolumedShadowPreviewDrawer";
                    var drawer = previewDrawer.AddComponent<TreePreviewDrawer>();
                    drawer.Init(gridSize, root);
                }
            }
            else
            {
                if (previewDrawer != null) DestroyImmediate(previewDrawer);
            }
        }

        private void OnDestroy()
        {
            if (previewDrawer != null) DestroyImmediate(previewDrawer);
        }

        private void BakeShadow()
        {
            var shadows = FindPosInShadow();
            if (shadows == null) return;
            root = new Node();
            root.x = 0;
            root.z = 0;
            root.size = gridNum;

            int progress = 0;
            int group = 0;
            float count = shadows.Count;
            foreach (var d in shadows)
            {
                if(++group >= gridNum)
                {
                    group = 0;
                    float p = ++progress * gridNum / count;
                    if(EditorUtility.DisplayCancelableProgressBar("八叉树构建", "以构建末端节点数量: " + progress * gridNum, p))
                    {
                        EditorUtility.ClearProgressBar();
                        root = null;
                        return;
                    }
                }
                root.Insert(d.x, d.y, d.z);
            }

            root.ClipSameNode();
            EditorUtility.ClearProgressBar();

            root.PrintCount();

            var nodes = root.GetAllNodes();
            Debug.Log(nodes.Count);
            int width = Mathf.CeilToInt(Mathf.Sqrt(nodes.Count));
            var tex = new Texture2D(width, width, TextureFormat.RGBAFloat, false);
            tex.filterMode = FilterMode.Point;
            tex.wrapMode = TextureWrapMode.Clamp;

            var colors = tex.GetPixels();
            progress = 0;
            group = 0;
            count = nodes.Count * 2f;
            for (int i = 0; i < nodes.Count; ++i)
            {
                if(++group >= gridNum)
                {
                    group = 0;
                    float p = ++progress * gridNum / count;
                    if(EditorUtility.DisplayCancelableProgressBar("八叉树编码", "已编码节点数: " + progress * gridNum, p))
                    {
                        EditorUtility.ClearProgressBar();
                        root = null;
                        return;
                    }
                }
                nodes[i].index = i;
            }
            group = 0;
            for (int i = 0; i < nodes.Count; ++i)
            {
                if (++group >= gridNum)
                {
                    group = 0;
                    float p = ++progress * gridNum / count;
                    if (EditorUtility.DisplayCancelableProgressBar("八叉树编码", "已编码节点数: " + progress * gridNum, p))
                    {
                        EditorUtility.ClearProgressBar();
                        root = null;
                        return;
                    }
                }
                colors[i].r = nodes[i].x;
                colors[i].g = nodes[i].y;
                colors[i].b = nodes[i].z;
                colors[i].a = nodes[i].children != null ? nodes[i].children[0].index : 0;
                colors[i].a = colors[i].a * 10 + nodes[i].flag;
            }
            tex.SetPixels(colors);
            tex.Apply();
            var curScene = EditorSceneManager.GetActiveScene();
            string scenePath = curScene.path;
            string texPath = scenePath.Replace(curScene.name + ".unity", "VolumedShadowMap.asset");
            AssetDatabase.CreateAsset(tex, texPath);
            string dataPath = scenePath.Replace(curScene.name + ".unity", "VolumedShadowData.asset");
            VolumedShadowData data = new VolumedShadowData() { gridNum = gridNum, gridSize = gridSize };
            AssetDatabase.CreateAsset(data, dataPath);
            EditorUtility.ClearProgressBar();
        }

        private List<GameObject> GetAllStaticRender()
        {
            List<GameObject> result = new List<GameObject>();
            var renders = FindObjectsOfType<Renderer>();
            for(int i = 0; i < renders.Length; ++i)
            {
                var r = renders[i];
                if (r.gameObject.isStatic) result.Add(r.gameObject);
            }
            return result;
        }

        private List<Vector3Int> FindPosInShadow()
        {
            Vector3 lightDir = -mainLight.transform.forward;
            List<Vector3Int> list = new List<Vector3Int>();
            int progress = 0;
            float count = gridNum * gridNum * gridNum;
            // 1024 => 102.4m & 1024 => rootSize grid
            // 1grid => 0.4m
            for (int x = 0; x < gridNum; ++x)
            {
                float p = (++progress) * gridNum * gridNum / count;
                if(EditorUtility.DisplayCancelableProgressBar("阴影检测", "以检测末端节点数量: " + progress * 256 * 256, p))
                {
                    EditorUtility.ClearProgressBar();
                    return null;
                }
                float gridSize_half = gridSize * 0.5f;
                for (int y = 0; y < gridNum; ++y)
                {
                    for (int z = 0; z < gridNum; ++z)
                    {
                        Vector3 pos = new Vector3(x * gridSize, y * gridSize, z * gridSize);
                        if ((Physics.Raycast(pos, lightDir, 100) ? 1 : 0)
                        + (Physics.Raycast(pos + new Vector3(-1, 0, 0) * gridSize_half, lightDir, 100) ? 1 : 0)
                        + (Physics.Raycast(pos + new Vector3(0, -1, 0) * gridSize_half, lightDir, 100) ? 1 : 0)
                        + (Physics.Raycast(pos + new Vector3(0, 0, -1) * gridSize_half, lightDir, 100) ? 1 : 0)
                        + (Physics.Raycast(pos + new Vector3(1, 0, 0) * gridSize_half, lightDir, 100) ? 1 : 0)
                        + (Physics.Raycast(pos + new Vector3(0, 1, 0) * gridSize_half, lightDir, 100) ? 1 : 0)
                        + (Physics.Raycast(pos + new Vector3(0, 0, 1) * gridSize_half, lightDir, 100) ? 1 : 0)
                            > 2)
                        {
                            list.Add(new Vector3Int(x, y, z));
                        }
                    }
                }
            }
            EditorUtility.ClearProgressBar();
            return list;
        }
    }
}
