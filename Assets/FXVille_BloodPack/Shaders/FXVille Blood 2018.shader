// Custom Inputs are X = Pan Offset, Y = UV Warp Strength, Z = Gravity
// Specular Alpha is used like a metalness control. High values are more like dielectrics, low are more like metals
// Subshader at the bottom is for Shader Model 2.0 and OpenGL ES 2.0 devices

Shader "Particles/FXVille Blood 2018"
{
	   Properties
    {
        [Header(Color Controls)]
        [HDR] _BaseColor ("Base Color Mult", Color) = (1,1,1,1)
        _LightStr ("Lighting Strength", float) = 1.0
        _AlphaMin ("Alpha Clip Min", Range(-0.01, 1.01)) = 0.1
        _AlphaSoft ("Alpha Clip Softness", Range(0,1)) = 0.1
        _EdgeDarken ("Edge Darkening", float) = 1.0
        _ProcMask ("Procedural Mask Strength", float) = 1.0

        [Header(Mask Controls)]
        _MainTex ("Mask Texture", 2D) = "white" {}
        _MaskStr ("Mask Strength", float) = 0.7
        _Columns ("Flipbook Columns", Int) = 1
        _Rows ("Flipbook Rows", Int) = 1
        _ChannelMask ("Channel Mask", Vector) = (1,1,1,0)
        [Toggle] _FlipU("Flip U Randomly", Float) = 0
        [Toggle] _FlipV("Flip V Randomly", Float) = 0

        [Header(Noise Controls)]
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseAlphaStr ("Noise Strength", float) = 1.0
        _NoiseColorStr ("Noise Color Distort", float) = 0.0
        _ChannelMask2 ("Channel Mask 2", Vector) = (1,1,1,0)
        _Randomize ("Randomize Noise", float) = 1.0

        [Header(UV Warp Controls)]
        _WarpTex ("Warp Texture", 2D) = "gray" {}
        _WarpStr ("Warp Strength", float) = 0.2

        [Header(Vertex Physics)]
        _FallOffset ("Gravity Offset", Range(-1,0)) = -0.5
        _FallRandomness ("Gravity Randomness", float) = 0.25

        [Header(Specular Reflection)]
        [HDR] _SpecularColor ("Reflection Color Mult", Color) = (1,1,1,0.5)
        _ReflectionTex ("Reflection Texture", 2D) = "black" {}
        _ReflectionSat ("Reflection Saturation", float) = 0.5
        [Normal] _Normal ("Reflection Normalmap", 2D) = "bump" {}
        _FlattenNormal ("Flatten Reflection Normal", float) = 2.0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 300
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "FXVilleBloodURP"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float4 _BaseColor, _SpecularColor;
            float _LightStr, _AlphaMin, _AlphaSoft, _EdgeDarken, _ProcMask;
            float _MaskStr, _FlipU, _FlipV, _Columns, _Rows;
            float _NoiseAlphaStr, _NoiseColorStr, _Randomize;
            float4 _ChannelMask, _ChannelMask2;
            float _WarpStr, _FallOffset, _FallRandomness;
            float _ReflectionSat, _FlattenNormal;

            
float4 _MainTex_ST;
float4 _NoiseTex_ST;
float4 _WarpTex_ST;
float4 _Normal_ST;
float4 _ReflectionTex_ST;
TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_WarpTex); SAMPLER(sampler_WarpTex);
            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_ReflectionTex); SAMPLER(sampler_ReflectionTex);

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color : COLOR;
                float4 texcoord0 : TEXCOORD0;
                float3 texcoord1 : TEXCOORD1;
            };

            struct v2f
            {
                float4 positionHCS : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 uvFlipbook : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float fogFactor : TEXCOORD4;
            };

            v2f vert(appdata IN)
            {
                v2f OUT;

                float lifetime = IN.texcoord0.w;
                float random = IN.texcoord0.z;
                float3 fall = (lifetime * lifetime + (_FallOffset + ((random - 0.5) * _FallRandomness)) * lifetime) * float3(0, IN.texcoord1.z, 0);
                float3 worldPos = TransformObjectToWorld(IN.vertex.xyz) + fall;
                OUT.positionHCS = TransformWorldToHClip(worldPos);
                OUT.worldPos = worldPos;
                OUT.color = IN.color;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);

                float2 flip = lerp(float2(1, 1), float2(1 - 2 * round(frac(random * 13)), 1 - 2 * round(frac(random * 8))), float2(_FlipU, _FlipV));
                float2 baseUV = IN.texcoord0.xy * flip;
                OUT.uv = TRANSFORM_TEX(baseUV, _MainTex);
                OUT.uvFlipbook = OUT.uv * float2(_Columns, _Rows) + random * float2(3, 8) * _Randomize;

                OUT.fogFactor = saturate(ComputeFogFactor(worldPos));
                return OUT;
            }

            half4 frag(v2f IN) : SV_Target
            {
                float2 warpUV = IN.uvFlipbook + SAMPLE_TEXTURE2D(_WarpTex, sampler_WarpTex, IN.uvFlipbook).xy * _WarpStr;
                half4 mask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + warpUV);
                mask = lerp(1.0, mask, _MaskStr);

                float2 uvFrac = frac(IN.uv * float2(_Columns, _Rows)) - 0.5;
                float edgeMask = 1.0 - saturate((uvFrac.x * uvFrac.x + uvFrac.y * uvFrac.y) * 4.0);
                edgeMask = lerp(1.0, edgeMask, _ProcMask);
                mask *= edgeMask;

                half alpha = saturate(dot(mask, _ChannelMask));
                half4 noiseSample = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, warpUV);
                float noise = saturate(lerp(1, dot(noiseSample, _ChannelMask2), _NoiseAlphaStr));
                alpha *= noise;
                float preClipAlpha = alpha;
                alpha = saturate((alpha * IN.color.a - _AlphaMin) / max(_AlphaSoft, 1e-5));

                float3 lighting = SampleSH(IN.normalWS);
                lighting = max(lighting, 0.15.xxx) * _LightStr;

                float edge = 1.0 - saturate(preClipAlpha * alpha);
                edge = 1.0 - edge * edge;
                edge = saturate(lerp(0.71, edge * edge, _EdgeDarken));

                float3 finalColor = _BaseColor.rgb * IN.color.rgb * lighting;
                finalColor *= edge;
                float finalAlpha = alpha * _BaseColor.a;

                float4 col = float4(finalColor, finalAlpha);
                col.rgb = MixFog(col.rgb, IN.fogFactor);
                return col;
            }

            ENDHLSL
        }
    }
}
