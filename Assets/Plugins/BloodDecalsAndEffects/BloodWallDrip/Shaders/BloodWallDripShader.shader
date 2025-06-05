// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Blood/BloodWallDripShader"
{
	Properties
	{
		_MainDriverTexture("MainDriverTexture", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "bump" {}
		_Color_Gloss("Color_Gloss", Color) = (0.5882353,0,0,0.872)
		_DryColor_Gloss("DryColor_Gloss", Color) = (0.5882353,0,0,0.872)
		_YOffset("YOffset", Range( -1 , 1)) = -0.1
		_BloodDrying("BloodDrying", Range( 0 , 1)) = 0
		_Adjust("Adjust", Range( 0 , 1)) = 0
		_Contrast("Contrast", Range( 0 , 60)) = 6
		_Noise("Noise", Float) = 20
		_Fade("Fade", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
		};

		uniform sampler2D _NormalMap;
		uniform float _YOffset;
		uniform sampler2D _MainDriverTexture;
		uniform float4 _MainDriverTexture_ST;
		uniform float _BloodDrying;
		uniform float _Adjust;
		uniform float _Contrast;
		uniform float4 _Color_Gloss;
		uniform float4 _DryColor_Gloss;
		uniform float _Fade;
		uniform float _Noise;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 appendResult10 = (float2(0.0 , _YOffset));
			float2 uv_MainDriverTexture = i.uv_texcoord * _MainDriverTexture_ST.xy + _MainDriverTexture_ST.zw;
			float2 uv_TexCoord7 = i.uv_texcoord + ( appendResult10 * tex2D( _MainDriverTexture, uv_MainDriverTexture ).b );
			float4 tex2DNode6 = tex2D( _MainDriverTexture, uv_TexCoord7 );
			float lerpResult42 = lerp( tex2DNode6.g , tex2DNode6.b , _Adjust);
			float temp_output_26_0 = pow( lerpResult42 , _Contrast );
			float clampResult41 = clamp( ( _BloodDrying + ( 1.0 - temp_output_26_0 ) ) , 0.0 , 0.7 );
			float3 lerpResult40 = lerp( UnpackNormal( tex2D( _NormalMap, uv_TexCoord7 ) ) , float3(0,0,1) , clampResult41);
			o.Normal = lerpResult40;
			float4 lerpResult33 = lerp( ( ( _Color_Gloss * ( tex2DNode6.r * tex2DNode6.g ) ) * tex2DNode6.g ) , ( _DryColor_Gloss * tex2DNode6.r ) , _BloodDrying);
			o.Albedo = lerpResult33.rgb;
			float lerpResult37 = lerp( ( _Color_Gloss.a * tex2DNode6.g ) , ( _DryColor_Gloss.a * lerpResult42 ) , _BloodDrying);
			o.Smoothness = lerpResult37;
			float2 temp_cast_1 = (_Noise).xx;
			float3 ase_worldPos = i.worldPos;
			float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
			float2 appendResult61 = (float2(( ase_worldPos.x * ase_objectScale.x ) , ( ase_worldPos.z * ase_objectScale.z )));
			float2 uv_TexCoord49 = i.uv_texcoord * temp_cast_1 + appendResult61;
			float simplePerlin2D46 = snoise( uv_TexCoord49 );
			float clampResult52 = clamp( pow( ( temp_output_26_0 + ( temp_output_26_0 * simplePerlin2D46 ) + temp_output_26_0 ) , _Contrast ) , 0.0 , 1.0 );
			o.Alpha = ( ( 1.0 - _Fade ) * clampResult52 );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard alpha:fade keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16200
298;582;1376;1014;-520.7736;286.9499;1.644288;True;False
Node;AmplifyShaderEditor.CommentaryNode;64;-1990.294,-386.2645;Float;False;1406.562;685.3397;Driver and vertical offset;5;4;10;9;5;11;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-1472.705,-192.9529;Float;False;Property;_YOffset;YOffset;4;0;Create;True;0;0;False;0;-0.1;-0.07;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;4;-1940.294,-336.2645;Float;True;Property;_MainDriverTexture;MainDriverTexture;0;0;Create;True;0;0;False;0;af5d2739aed3c6a4e80f71690e848c42;af5d2739aed3c6a4e80f71690e848c42;False;white;Auto;Texture2D;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.CommentaryNode;62;-502.9567,528.3883;Float;False;1282.832;507.8466;Noise;7;43;27;48;60;61;49;46;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;-1087.874,-83.43882;Float;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;5;-1329.64,69.07516;Float;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectScaleNode;66;-451.2263,1069.011;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;60;-452.9567,857.2355;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-752.7318,34.55494;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-237.0844,980.9243;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;68;-222.0181,1184.322;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;7;-553.9888,5.021941;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;61;-28.86237,851.4642;Float;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-153.8602,-168.7996;Float;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;48;-80.40799,751.3524;Float;False;Property;_Noise;Noise;8;0;Create;True;0;0;False;0;20;10.71;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-106.5974,578.3885;Float;False;Property;_Adjust;Adjust;6;0;Create;True;0;0;False;0;0;0.089;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;42;337.2693,30.22943;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;49;208.3759,800.1084;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;27;-115.0719,663.2522;Float;False;Property;_Contrast;Contrast;7;0;Create;True;0;0;False;0;6;12.3;0;60;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;26;561.1833,181.4879;Float;False;2;0;FLOAT;0;False;1;FLOAT;8;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;63;932.6929,239.253;Float;False;969.0858;338.6863;Opacity;5;50;51;59;52;69;;1,1,1,1;0;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;46;546.8746,822.6526;Float;False;Simplex2D;1;0;FLOAT2;1,1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;982.6929,415.0288;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;318.6704,-113.4979;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;51;1294.066,289.253;Float;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;111.9758,-467.9295;Float;False;Property;_BloodDrying;BloodDrying;5;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;45;793.4229,-12.55766;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;21;-462.1315,-344.4133;Float;False;Property;_Color_Gloss;Color_Gloss;2;0;Create;True;0;0;False;0;0.5882353,0,0,0.872;0.2426471,0,0,0.886;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;34;-459.1959,-525.5407;Float;False;Property;_DryColor_Gloss;DryColor_Gloss;3;0;Create;True;0;0;False;0;0.5882353,0,0,0.872;0.06617647,0.02555781,0.02286981,0.066;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;59;1501.028,444.9393;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;2;502.6513,-245.5955;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;968.6683,-214.2811;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;65;402.3172,-301.0589;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;1535.954,368.1606;Float;False;Property;_Fade;Fade;9;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;70;1931.572,135.632;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;39;1163.924,-59.12842;Float;False;Constant;_Vector0;Vector 0;7;0;Create;True;0;0;False;0;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ClampOpNode;52;1726.778,327.0917;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;41;1164.98,-210.9514;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.7;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;722.2,-244.3123;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;651.8641,-99.30173;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;997.2307,49.76886;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;515.2811,-546.4182;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;25;-146.3858,166.122;Float;True;Property;_NormalMap;NormalMap;1;0;Create;True;0;0;False;0;7962e27806f58f442bce0b4342e1d7e8;7962e27806f58f442bce0b4342e1d7e8;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;2119.021,124.122;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;37;1876.983,-23.9123;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;40;1597.083,-177.6994;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;33;1117.417,-550.1836;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2319.268,-160.8459;Float;False;True;2;Float;ASEMaterialInspector;0;0;Standard;Blood/BloodWallDripShader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;10;1;9;0
WireConnection;5;0;4;0
WireConnection;11;0;10;0
WireConnection;11;1;5;3
WireConnection;67;0;60;1
WireConnection;67;1;66;1
WireConnection;68;0;60;3
WireConnection;68;1;66;3
WireConnection;7;1;11;0
WireConnection;61;0;67;0
WireConnection;61;1;68;0
WireConnection;6;0;4;0
WireConnection;6;1;7;0
WireConnection;42;0;6;2
WireConnection;42;1;6;3
WireConnection;42;2;43;0
WireConnection;49;0;48;0
WireConnection;49;1;61;0
WireConnection;26;0;42;0
WireConnection;26;1;27;0
WireConnection;46;0;49;0
WireConnection;50;0;26;0
WireConnection;50;1;46;0
WireConnection;18;0;6;1
WireConnection;18;1;6;2
WireConnection;51;0;26;0
WireConnection;51;1;50;0
WireConnection;51;2;26;0
WireConnection;45;0;26;0
WireConnection;59;0;51;0
WireConnection;59;1;27;0
WireConnection;2;0;21;0
WireConnection;2;1;18;0
WireConnection;44;0;36;0
WireConnection;44;1;45;0
WireConnection;65;0;6;1
WireConnection;70;0;69;0
WireConnection;52;0;59;0
WireConnection;41;0;44;0
WireConnection;29;0;2;0
WireConnection;29;1;6;2
WireConnection;28;0;21;4
WireConnection;28;1;6;2
WireConnection;38;0;34;4
WireConnection;38;1;42;0
WireConnection;35;0;34;0
WireConnection;35;1;65;0
WireConnection;25;1;7;0
WireConnection;71;0;70;0
WireConnection;71;1;52;0
WireConnection;37;0;28;0
WireConnection;37;1;38;0
WireConnection;37;2;36;0
WireConnection;40;0;25;0
WireConnection;40;1;39;0
WireConnection;40;2;41;0
WireConnection;33;0;29;0
WireConnection;33;1;35;0
WireConnection;33;2;36;0
WireConnection;0;0;33;0
WireConnection;0;1;40;0
WireConnection;0;4;37;0
WireConnection;0;9;71;0
ASEEND*/
//CHKSM=A3F9992064C2936E29F18BB1956AF5264099B71C