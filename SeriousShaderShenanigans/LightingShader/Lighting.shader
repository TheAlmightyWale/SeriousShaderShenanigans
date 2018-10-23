Shader "Unlit/Lighting"
{
	Properties{
		[NoScaleOffset] _MainTex("Texture", 2D) = "white"{}
	}

	SubShader{
		Pass{
			//Indicate that our pass is the "base" pass in forward rendering pipeline.
			//It gets ambient and main directional light data set up;
			// light direction in _WorldSpaceLightPos0
			//color in _LightColor0
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			//Compile shader into multiple variants, with and without shadows
			#pragma multi_compile_fwdbase no_light_map no_dir_light_map no_dyn_light_map no_vertex_light
			// shadow helper functions and macros
			#include "AutoLight.cginc"
			
			struct v2f {
				float2 uv: TEXCOORD0;
				SHADOW_COORDS(1) // put shadow data into TEXCOORD1
				fixed3 diff : COLOR0; //Diffuse lighting color
				fixed3 ambient : COLOR1;
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				//get vertex normal in world space
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				//dot product between normal and light direction for standard diffuse (lambert) lighting
				half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				//factor in light color
				o.diff = nl * _LightColor0.rgb;
				//Add illumination from ambient or light probes
				//ShadesSH9 function from UnityCG evaluates it using world space normal
				o.ambient = ShadeSH9(half4(worldNormal, 1));
				
				//compute shadows data
				TRANSFER_SHADOW(o)

				return o;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f i) : SV_TARGET{
				//Sample texture
				fixed4 col = tex2D(_MainTex, i.uv);
				//compute shadow attenuation (1 = fully lit 0 = fully shadowed)
				fixed shadow = SHADOW_ATTENUATION(i);

				//Darken lights illumination with shadow, keep ambient intact
				fixed3 lighting = i.diff * shadow + i.ambient;
				//multiply by lighting
				col.rgb *= lighting;
				return col;
			}
			ENDCG
		}

		//Shadow caster pass
		Pass{
			Tags{"LightMode"="ShadowCaster"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
				return o;
			}

			float4 frag(v2f i): SV_Target{
				SHADOW_CASTER_FRAGMENT(i);
			}
			ENDCG
		}
	}
}
