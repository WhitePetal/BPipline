using System.Collections;
using System.Collections.Generic;
using Unity.Jobs;
using UnityEngine;

public class CullMgr
{
    private static CullTreeNode cullTreeRoot;

    public class CullTreeNode
    {
        public CullTreeNode[] childrens;
    }

    public void Setup()
    {
        if(cullTreeRoot == null)
        {
            LoadBakeCullTreeData();
        }
    }

    private void LoadBakeCullTreeData()
    {

    }

    public void BakeCullTree()
    {

    }

    public void Cull()
    {
        
    }
}
