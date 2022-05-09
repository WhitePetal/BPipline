using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VolumeShadow
{
    [CreateAssetMenu(menuName = "Assets/VolumedShadowData")]
    public class VolumedShadowData : ScriptableObject
    {
        public int gridNum = 512;
        public float gridSize = 0.2f;
    }
}
