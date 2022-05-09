using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VolumeShadow
{
    public class TreePreviewDrawer : MonoBehaviour
    {
        public float drawScale;
        public Node root;

        public void Init(float drawScale, Node root)
        {
            this.drawScale = drawScale;
            this.root = root;
        }

        private void OnDrawGizmos()
        {
            if (root == null) return;
            root.Draw(drawScale);
        }
    }
}
