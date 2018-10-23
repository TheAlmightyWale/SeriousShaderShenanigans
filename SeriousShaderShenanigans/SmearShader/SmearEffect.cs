using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SmearEffect : MonoBehaviour {

    Queue<Vector3> _recentPositions = new Queue<Vector3>();

    [SerializeField]
    int _frameLag = 0;

    Material _smearMat = null;
    public Material smearMat
    {
        get
        {
            if (!_smearMat)
            {
                _smearMat = GetComponent<Renderer>().material;
            }

            if (!_smearMat.HasProperty("_PrevPosition"))
            {
                _smearMat.shader = Shader.Find("Custom/Smear");
            }

            return _smearMat;
        }
    }
	
	// Update is called once per frame
	void LateUpdate () {
		if(_recentPositions.Count > _frameLag)
        {
            smearMat.SetVector("_PrevPosition", _recentPositions.Dequeue());
        }

        smearMat.SetVector("_Position", transform.position);
        _recentPositions.Enqueue(transform.position);
	}
}
