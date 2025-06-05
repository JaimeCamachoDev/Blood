// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Blood/BloodSpurtAnimate"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_MainColorGloss("MainColor-Gloss", Color) = (0.6985294,0.0626268,0.020545,0.803)
		_Metalness("Metalness", Float) = 0
		_Anim4x4GreyScale("Anim(4x4)GreyScale", 2D) = "white" {}
		_Anim4x4Normal("Anim(4x4)Normal", 2D) = "bump" {}
		_StartFrame("StartFrame", Float) = 1
		_AnimSpeed("AnimSpeed", Float) = 1
		[Toggle(_USECUSTOMTIME_ON)] _UseCustomTime("UseCustomTime?", Float) = 0
		_TimeInput("TimeInput", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma shader_feature _USECUSTOMTIME_ON
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Anim4x4Normal;
		uniform float _AnimSpeed;
		uniform float _StartFrame;
		uniform float _TimeInput;
		uniform sampler2D _Anim4x4GreyScale;
		uniform float4 _MainColorGloss;
		uniform float _Metalness;
		uniform float _Cutoff = 0.5;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			#ifdef _USECUSTOMTIME_ON
				float staticSwitch24 = _TimeInput;
			#else
				float staticSwitch24 = _Time.y;
			#endif
			// *** BEGIN Flipbook UV Animation vars ***
			// Total tiles of Flipbook Texture
			float fbtotaltiles4 = 4.0 * 8.0;
			// Offsets for cols and rows of Flipbook Texture
			float fbcolsoffset4 = 1.0f / 4.0;
			float fbrowsoffset4 = 1.0f / 8.0;
			// Speed of animation
			float fbspeed4 = staticSwitch24 * _AnimSpeed;
			// UV Tiling (col and row offset)
			float2 fbtiling4 = float2(fbcolsoffset4, fbrowsoffset4);
			// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
			// Calculate current tile linear index
			float fbcurrenttileindex4 = round( fmod( fbspeed4 + _StartFrame, fbtotaltiles4) );
			fbcurrenttileindex4 += ( fbcurrenttileindex4 < 0) ? fbtotaltiles4 : 0;
			// Obtain Offset X coordinate from current tile linear index
			float fblinearindextox4 = round ( fmod ( fbcurrenttileindex4, 4.0 ) );
			// Reverse X animation if speed is negative
			fblinearindextox4 = (_AnimSpeed > 0 ? fblinearindextox4 : (int)4.0 - fblinearindextox4);
			// Multiply Offset X by coloffset
			float fboffsetx4 = fblinearindextox4 * fbcolsoffset4;
			// Obtain Offset Y coordinate from current tile linear index
			float fblinearindextoy4 = round( fmod( ( fbcurrenttileindex4 - fblinearindextox4 ) / 4.0, 8.0 ) );
			// Reverse Y to get tiles from Top to Bottom and Reverse Y animation if speed is negative
			fblinearindextoy4 = (_AnimSpeed <  0 ? fblinearindextoy4 : (int)8.0 - fblinearindextoy4);
			// Multiply Offset Y by rowoffset
			float fboffsety4 = fblinearindextoy4 * fbrowsoffset4;
			// UV Offset
			float2 fboffset4 = float2(fboffsetx4, fboffsety4);
			// Flipbook UV
			half2 fbuv4 = i.uv_texcoord * fbtiling4 + fboffset4;
			// *** END Flipbook UV Animation vars ***
			o.Normal = UnpackNormal( tex2D( _Anim4x4Normal, fbuv4 ) );
			float4 tex2DNode1 = tex2D( _Anim4x4GreyScale, fbuv4 );
			float4 temp_output_2_0 = ( tex2DNode1 * _MainColorGloss );
			o.Albedo = temp_output_2_0.rgb;
			o.Emission = ( temp_output_2_0 * 0.1 ).rgb;
			o.Metallic = _Metalness;
			o.Smoothness = _MainColorGloss.a;
			o.Alpha = 1;
			clip( tex2DNode1.r - _Cutoff );
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16200
19;345;1376;698;1911.12;827.6639;2.901447;True;False
Node;AmplifyShaderEditor.SimpleTimeNode;23;-1033.377,147.6875;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-1042.377,249.6875;Float;False;Property;_TimeInput;TimeInput;8;0;Create;True;0;0;False;0;0;22.55;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-911.7274,-36.85081;Float;False;Property;_StartFrame;StartFrame;5;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;12;-1064.798,-340.9211;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;24;-791.377,235.6875;Float;False;Property;_UseCustomTime;UseCustomTime?;7;0;Create;True;0;0;False;0;0;0;0;True;;Toggle;2;Key0;Key1;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-906.7272,-138.7592;Float;False;Property;_AnimSpeed;AnimSpeed;6;0;Create;True;0;0;False;0;1;30;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;4;-572.4996,-253.3174;Float;False;0;1;6;0;FLOAT2;0,0;False;1;FLOAT;4;False;2;FLOAT;8;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TexturePropertyNode;18;-622.9074,-624.0607;Float;True;Property;_Anim4x4GreyScale;Anim(4x4)GreyScale;3;0;Create;True;0;0;False;0;None;98cb61d2031caf34fa4d2d8724be8d5c;False;white;Auto;Texture2D;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.SamplerNode;1;-290.5,-269.5;Float;True;Property;_AnimTexture;AnimTexture;3;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;3;-228.5,-66.5;Float;False;Property;_MainColorGloss;MainColor-Gloss;1;0;Create;True;0;0;False;0;0.6985294,0.0626268,0.020545,0.803;0.3161765,0,0,0.897;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;2;47.5,-248.5;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;15;1.899004,-31.37299;Float;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;False;0;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;20;-321.3198,367.9198;Float;True;Property;_Anim4x4Normal;Anim(4x4)Normal;4;0;Create;True;0;0;False;0;None;3f573d0285b1a0a408b0001de33a4b4f;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;21;-1.723871,70.83549;Float;False;Property;_Metalness;Metalness;2;0;Create;True;0;0;False;0;0;0.37;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;184.8011,-153.275;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;455.285,-231.9549;Float;False;True;2;Float;ASEMaterialInspector;0;0;Standard;Blood/BloodSpurtAnimate;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;TransparentCutout;;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;24;1;23;0
WireConnection;24;0;22;0
WireConnection;4;0;12;0
WireConnection;4;3;6;0
WireConnection;4;4;13;0
WireConnection;4;5;24;0
WireConnection;1;0;18;0
WireConnection;1;1;4;0
WireConnection;2;0;1;0
WireConnection;2;1;3;0
WireConnection;20;1;4;0
WireConnection;14;0;2;0
WireConnection;14;1;15;0
WireConnection;0;0;2;0
WireConnection;0;1;20;0
WireConnection;0;2;14;0
WireConnection;0;3;21;0
WireConnection;0;4;3;4
WireConnection;0;10;1;0
ASEEND*/
//CHKSM=024A18AE0B62D0FC5E8420DFBB4D0668AB7428A2