
Shader "URP/Custom/SurfaceWithBakedSkinnedAnimation_URP_Final"
{
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _Specular("Specular Map", 2D) = "black" {}
        _Smoothness("Smoothness", Range(0,1)) = 0.5

        _AnimationPos("Baked Position Texture", 2D) = "black" {}
        _AnimationNm("Baked Normal Texture", 2D) = "black" {}
        _Speed("Animation Speed", float) = 60
        _Length("Animation Length", float) = 300
        _ManualFrame("Manual Frame", float) = 0
        [Toggle(MANUAL)] _UseManual("Use Manual Frame", Float) = 0

        _NoiseTiling("Frame Noise Tiling", Vector) = (1,1,1,1)
        _SpeedNoiseTiling("Speed Noise Tiling", Vector) = (1,1,1,1)
        _SpeedMinMax("Speed Min Max", Vector) = (1,1,1,1)
        _ScaleNoiseTiling("Scale Noise Tiling", Vector) = (1,1,1,1)
        _ScaleMinMax("Scale Min Max", Vector) = (1,1,1,1)

        [HideInInspector]_LocalPosition("Instance Position", Vector) = (0,0,0,0)
        [HideInInspector]_InstancedColor("Instance Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 300

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ MANUAL

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 tangentWS : TEXCOORD1;
                float3 bitangentWS : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float2 uv : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_Specular); SAMPLER(sampler_Specular);
            TEXTURE2D(_AnimationPos); SAMPLER(sampler_AnimationPos);
            TEXTURE2D(_AnimationNm); SAMPLER(sampler_AnimationNm);

            float4 _Color;
            float _Smoothness;
            float4 _AnimationPos_TexelSize;
            float _Speed, _Length, _ManualFrame, _UseManual;
            float4 _NoiseTiling, _SpeedNoiseTiling, _SpeedMinMax, _ScaleNoiseTiling, _ScaleMinMax;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LocalPosition)
                UNITY_DEFINE_INSTANCED_PROP(float4, _InstancedColor)
            UNITY_INSTANCING_BUFFER_END(Props)

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                float framesCount = _AnimationPos_TexelSize.z;
                float verticesCount = _AnimationPos_TexelSize.w;

                float3 randomOffset = abs(UNITY_ACCESS_INSTANCED_PROP(Props, _LocalPosition).xyz);

                float frame;
                if (_UseManual > 0.5)
                {
                    frame = _ManualFrame;
                }
                else
                {
                    float3 speedOffset = randomOffset * _SpeedNoiseTiling.xyz;
                    float speedRandom = fmod(speedOffset.x + speedOffset.y + speedOffset.z, _SpeedMinMax.y - _SpeedMinMax.x) + _SpeedMinMax.x;
                    frame = _Speed * speedRandom * _Time.y;

                    float3 frameOffset = randomOffset * _NoiseTiling.xyz;
                    frame += frameOffset.x + frameOffset.y + frameOffset.z;
                    frame = fmod(frame, _Length);
                }

                float3 scaleOffset = randomOffset * _ScaleNoiseTiling.xyz;
                float scaleRandom = fmod(scaleOffset.x + scaleOffset.y + scaleOffset.z, _ScaleMinMax.y - _ScaleMinMax.x) + _ScaleMinMax.x;

                float vertexId = IN.vertexID;
                float2 animUV = float2(frame / framesCount, (vertexId + 0.5) / verticesCount);
                float3 animatedPos = SAMPLE_TEXTURE2D_LOD(_AnimationPos, sampler_AnimationPos, animUV, 0).xyz * scaleRandom;
                float3 animatedNormal = SAMPLE_TEXTURE2D_LOD(_AnimationNm, sampler_AnimationNm, animUV, 0).xyz;

                float4 worldPos = mul(GetObjectToWorldMatrix(), float4(animatedPos, 1.0));
                float3 worldNormal = normalize(mul((float3x3)GetObjectToWorldMatrix(), animatedNormal));
                float3 worldTangent = normalize(mul((float3x3)GetObjectToWorldMatrix(), IN.tangentOS.xyz));
                float3 worldBitangent = normalize(cross(worldNormal, worldTangent) * IN.tangentOS.w);

                OUT.positionHCS = TransformWorldToHClip(worldPos.xyz);
                OUT.worldPos = worldPos.xyz;
                OUT.normalWS = worldNormal;
                OUT.tangentWS = worldTangent;
                OUT.bitangentWS = worldBitangent;
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                float3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
                float3 specular = SAMPLE_TEXTURE2D(_Specular, sampler_Specular, IN.uv).rgb;
                float3 normalWS = TransformTangentToWorld(normalTS, float3x3(IN.tangentWS, IN.bitangentWS, IN.normalWS));

                float3 finalColor = baseColor * _Color.rgb * UNITY_ACCESS_INSTANCED_PROP(Props, _InstancedColor).rgb;

                InputData inputData = (InputData)0;
                inputData.positionWS = IN.worldPos;
                inputData.normalWS = normalize(normalWS);
                inputData.viewDirectionWS = SafeNormalize(_WorldSpaceCameraPos - IN.worldPos);

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = finalColor;
                surfaceData.normalTS = float3(0,0,1); // already in WS
                surfaceData.metallic = 0.0;
                surfaceData.specular = specular;
                surfaceData.smoothness = _Smoothness;
                surfaceData.occlusion = 1.0;
                surfaceData.emission = 0;
                surfaceData.alpha = 1.0;

                return UniversalFragmentPBR(inputData, surfaceData);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Forward"
}
