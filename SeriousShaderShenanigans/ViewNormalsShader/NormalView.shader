Shader "Unlit/NormalView"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// include file that contains UnityObjectToWorldNormal helper function
			#include "UnityCG.cginc"

			struct v2f {
				//Output world space normal as one of regular ("texcoord") interpolators
				half3 worldNormal : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			v2f vert(float4 vertex: POSITION, float3 normal : NORMAL) {
				v2f o;
				o.pos = UnityObjectToClipPos(vertex);
				o.worldNormal = UnityObjectToWorldNormal(normal);
				return o;
			}

			fixed4 frag (v2f input) : SV_TARGET
			{
				fixed4 c = 0;
				//normals have a range of -1 - 1
				//Need to bring that range in 0 - 1
				c.rgb = input.worldNormal * 0.5 + 0.5;
				return c;
			}

			ENDCG
		}
	}
}
