using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMove : MonoBehaviour
{
    private float xMove;
    private bool right = true;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (xMove < 2.0f && right)
        {
            transform.localPosition += Vector3.right * Time.deltaTime;
            xMove += Time.deltaTime;
            right = true;
        }
        if(xMove > -2.0f && !right)
        {
            transform.localPosition -= Vector3.right * Time.deltaTime;
            xMove -= Time.deltaTime;
            right = false;
        }
        if(xMove <= -2.0f && !right)
        {
            right = true;
        }
        if(xMove >= 2.0f && right)
        {
            right = false;
        }
    }
}
