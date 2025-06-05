Shader "URP/Custom/SurfaceWithBakedSkinnedAnimation_URP"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _NormalMap("Normal", 2D) = "bump" {}
        _Specular("Specular", 2D) = "black" {}
        _Smoothness("Smoothness", Range(0,1)) = 0.5

        _AnimationPos("Baked Position Animation Texture", 2D) = "black" {}
        _AnimationNm("Baked Normal Animation Texture", 2D) = "black" {}
        _Speed("Animation Speed", float) = 60
        _Length("Animation Length", float) = 300
        _ManualFrame("Animation Frame", float) = 300
        [Toggle(MANUAL)] _UseManual("Manual", Float) = 0

        _NoiseTiling("Offset noise tiling", Vector) = (1,1,1,1)
        _SpeedNoiseTiling("Speed noise tiling", Vector) = (1,1,1,1)
        _SpeedMinMax("Speed min max", Vector) = (1,1,1,1)
        _ScaleNoiseTiling("Scale noise tiling", Vector) = (1,1,1,1)
        _ScaleMinMax("Scale min max", Vector) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 200

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _MANUAL
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
                uint vertexID       : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 worldPos     : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
            TEXTURE2D(_Specular);       SAMPLER(sampler_Specular);
            TEXTURE2D(_AnimationPos);   SAMPLER(sampler_AnimationPos);
            TEXTURE2D(_AnimationNm);    SAMPLER(sampler_AnimationNm);

            float4 _MainTex_ST;
            float4 _AnimationPos_TexelSize;
            float4 _Color;
            float _Smoothness;
            float _Speed;
            float _Length;
            float _ManualFrame;
            float _UseManual;

            float4 _NoiseTiling;
            float4 _SpeedNoiseTiling;
            float4 _SpeedMinMax;
            float4 _ScaleNoiseTiling;
            float4 _ScaleMinMax;

            float remap(float s, float a1, float a2, float b1, float b2)
            {
                return b1 + (s - a1) * (b2 - b1) / (a2 - a1);
            }

            Varyings vert(Attributes v)
            {
                Varyings o;

                float framesCount = _AnimationPos_TexelSize.z;
                float verticesCount = _AnimationPos_TexelSize.w;

                float3 randomOffset = abs(v.positionOS.xyz);

                float frame;
                if (_UseManual > 0.5)
                {
                    frame = _ManualFrame;
                }
                else
                {
                    float3 speedOffset = randomOffset * _SpeedNoiseTiling.xyz;
                    float speedRandom = fmod(speedOffset.x + speedOffset.y + speedOffset.z, _SpeedMinMax.y - _SpeedMinMax.x) + _SpeedMinMax.x;
                    frame = (_Speed * speedRandom) * _Time.y;

                    float3 frameOffset = randomOffset * _NoiseTiling.xyz;
                    frame += frameOffset.x + frameOffset.y + frameOffset.z;
                    frame = fmod(frame, _Length);
                }

                float3 scaleOffset = randomOffset * _ScaleNoiseTiling.xyz;
                float scaleRandom = fmod(scaleOffset.x + scaleOffset.y + scaleOffset.z, _ScaleMinMax.y - _ScaleMinMax.x) + _ScaleMinMax.x;

                float vertexId = (float)v.vertexID;

                float2 animUV = float2(frame / framesCount, (vertexId + 0.5) / verticesCount);
                float3 offset = SAMPLE_TEXTURE2D_LOD(_AnimationPos, sampler_AnimationPos, animUV, 0).xyz;
                float3 normal = SAMPLE_TEXTURE2D_LOD(_AnimationNm, sampler_AnimationNm, animUV, 0).xyz;

                float3 animatedPosition = offset * scaleRandom;
                float4 worldPos = mul(GetObjectToWorldMatrix(), float4(animatedPosition, 1.0));
                o.positionHCS = TransformWorldToHClip(worldPos.xyz);
                o.worldPos = worldPos.xyz;

                o.normalWS = normalize(mul((float3x3)GetObjectToWorldMatrix(), normal));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _Color.rgb;
                float3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv));
                float3 specular = SAMPLE_TEXTURE2D(_Specular, sampler_Specular, i.uv).rgb;
                float smoothness = _Smoothness;

                // simplified lighting model: use URP's fragment lighting
                InputData inputData;
                inputData.positionWS = i.worldPos;
                inputData.normalWS = normalize(i.normalWS);
                inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - i.worldPos);
                inputData.shadowCoord = 0;
                inputData.fogCoord = 0;

                SurfaceData surfaceData;
                surfaceData.albedo = albedo;
                surfaceData.normalTS = normalTex;
                surfaceData.emission = 0;
                surfaceData.specular = specular;
                surfaceData.smoothness = smoothness;
                surfaceData.occlusion = 1;
                surfaceData.alpha = 1;

                return UniversalFragmentPBR(inputData, surfaceData);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Forward"
}
