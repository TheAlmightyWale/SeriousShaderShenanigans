// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SkyReflectionShader"
{
	properties
	{
		//Normal map texture on material
		// default to dummy "flat" surface normalmap
		_BumpMap("Normal Map", 2D) = "bump"{}
		_MainTex("Base texture", 2D) = "white"{}
		_OcclusionMap("Occlusion", 2D) = "white"{}
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2f {
				float3 worldPos :TEXCOORD0;
				//These threee vectors will hold a 3x3 rotation matrix
				//that transforms from tangent to world space
				half3 tspace0 : TEXCOORD1;  //tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD2; //tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD3; // same but .z
				//Texture coord for normal map
				float2 uv : TEXCOORD4;
				float4 pos : SV_POSITION;
			};

			// vertex shader now also needs a per-vertex tangent vector
			// in unity tangents are 4D, with .w component used to
			// indicate direction of the bitangent vector
			// we also need the texture coordinate.
			v2f vert(float4 vertex: POSITION, float3 normal : NORMAL, float4 tangent : TANGENT, float2 uv : TEXCOORD0)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(vertex);
				o.worldPos = mul(unity_ObjectToWorld, vertex).xyz;
				half3 wNormal = UnityObjectToWorldNormal(normal);
				half3 wTangent = UnityObjectToWorldDir(tangent.xyz);
				//compute bitangent from cross product of normal and tangent
				half tangentSign = tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
				// output the tangent space matrix
				o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
				o.uv = uv;

				return o;
			}
			
			//Textures from shader properties
			sampler2D _BumpMap;
			sampler2D _MainTex;
			sampler2D _OcclusionMap;

			fixed4 frag (v2f i) : SV_Target
			{
				// Sample the normal map, and decode from unity encoding
				half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				//Transform normal from tangent to world space
				half3 worldNormal;
				worldNormal.x = dot(i.tspace0, tnormal);
				worldNormal.y = dot(i.tspace1, tnormal);
				worldNormal.z = dot(i.tspace2, tnormal);
				
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half3 worldRefl = reflect(-worldViewDir, worldNormal);
				half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
				half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);
				fixed4 c = 0;
				c.rgb = skyColor;

				//Modulate the sky reflection color with the base texture, and the occlusion map
				fixed3 baseColor = tex2D(_MainTex, i.uv).rgb;
				fixed occlusion = tex2D(_OcclusionMap, i.uv).r;
				c.rgb *= baseColor;
				c.rgb *= occlusion;

				return c;
			}

			ENDCG
		}
	}
}
