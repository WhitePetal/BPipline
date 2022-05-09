using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VolumeShadow
{
    public class Node
    {
        public int level;
        public int x;
        public int y;
        public int z;
        public int size;
        public int flag; // 0 node 1 shadowdata
        public Node parent;
        public Node[] children;
        public int index;

        static Vector3Int[] OffsetNodeList =
        {
            new Vector3Int{x = 0, y = 0, z = 0}, new Vector3Int{x = 1, y = 0, z = 0}, new Vector3Int{x = 0, y = 1, z = 0}, new Vector3Int{x = 1, y = 1, z = 0},
            new Vector3Int{x = 0, y = 0, z = 1,}, new Vector3Int{x = 1, y = 0, z = 1}, new Vector3Int{x = 0, y = 0, z = 1,}, new Vector3Int{x = 1, y = 1, z = 1}
        };

        private void CalCount(ref int count)
        {
            count += 1;
            if(children != null)
            {
                foreach (var c in children) c.CalCount(ref count);
            }
        }

        public void Insert(int vx, int vy, int vz)
        {
            if(size <= 1)
            {
                flag = 1;
                return;
            }

            int nSize = size >> 1;
            int nLevel = level + 1;
            if(children == null)
            {
                children = new Node[8];
                for(int i = 0; i < 8; ++i)
                {
                    Vector3Int nSizeVec = OffsetNodeList[i] * nSize;
                    children[i] = new Node { level = nLevel, size = nSize, x = x + nSizeVec.x, y = y + nSizeVec.y, z = z + nSizeVec.z, parent = this };
                }
            }

            // 继续向下定位vx，vy, vz，直到创建出以 vx vy,vz为原点的grid
            // 或者 grid 无法继续向下细分
            int offset = 0;
            if (vx > x + nSize) ++offset;
            if (vy > y + nSize) offset += 2;
            if (vz > z + nSize) offset += 4;
            children[offset].Insert(vx, vy, vz);
        }

        public void ClipSameNode(bool recursion = true)
        {
            if (children == null) return;
            int shadowedChildCount = 0;
            foreach(var c in children)
            {
                if (c.flag == 1) ++shadowedChildCount;
            }
            if(shadowedChildCount == 8)
            {
                if(flag != 1)
                {
                    flag = 1;
                    children = null;
                    // 自身状态更新后 自下而上更新父节点状态
                    if (parent != null) parent.ClipSameNode(false);
                }
            }
            else if (recursion)
            {
                foreach(var c in children)
                {
                    c.ClipSameNode();
                }
            }
        }

        public List<Node> GetAllNodes()
        {
            List<Node> nodes = new List<Node>();
            nodes.Add(this);
            int startIndex = 0;
            int endIndex = nodes.Count;
            while(startIndex != endIndex)
            {
                for(int i = startIndex; i < endIndex; ++i)
                {
                    if (nodes[i].children != null) nodes.AddRange(nodes[i].children);
                }
                startIndex = endIndex;
                endIndex = nodes.Count;
            }
            return nodes;
        }

        public void PrintCount()
        {
            int count = 0;
            CalCount(ref count);
            Debug.Log(count);
        }

        public bool Find(int fx, int fy, int fz)
        {
            if (children == null) return flag == 1;
            int offset = 0;
            int cSize = size >> 1;
            if (fx > x + cSize) ++offset;
            if (fy > y + cSize) offset += 2;
            if (fz > z + cSize) offset +=4;

            return children[offset].Find(fx, fy, fz);
        }

        public void Draw(float drawScale = 1f)
        {
            if(children == null)
            {
                Gizmos.color = flag == 1 ? Color.red : Color.green;
                Gizmos.DrawCube(new Vector3(x, y, z) * drawScale + new Vector3(size, size, size) * 0.5f * drawScale,
                    new Vector3(size, size, size) * drawScale);
            }
            else
            {
                foreach(var c in children)
                {
                    c.Draw(drawScale);
                }
            }
        }
    }
}
