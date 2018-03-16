string description = "Subsurface Scattering Hack";
//------------------------------------
// John Vidziunas
float4x4 worldViewProj : WorldViewProjection;
float4x4 world   : World;
float4x4 worldInverseTranspose : WorldInverseTranspose;
float4x4 viewInverse : ViewInverse;

float4 LightPosition1 : POSITION
<
	string Object = "PointLight";
	string UIName =  "Light 1";
	string Space = "World";
> 	= {1403.0f, 1441.0f, 1690.0f, 0.0f};

float3 specColor
<
	string UIWidget = "color";
	string UIName = "Specular Color";
> = {0.9f, 0.9f, 1.0f};

float3 lightColor
<
	string UIWidget = "color";
	string UIName = "Light Color";
> = {1.0f, 1.0f, 1.0f};

float materialThickness
<
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
	float UIStep = 0.01f;
	string UIName = "Material Thickness Factor";
> 	= 0.6f;

float rimScalar
<
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
	float UIStep = 0.01f;
	string UIName = "Rim Light Strength";
> 	= 1.0f;

float extinctionCoefficientRed
<
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
	float UIStep = 0.01f;
	string UIName = "Extinction Coefficient, Red";
> 	= 0.80f;

float extinctionCoefficientBlue
<
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
	float UIStep = 0.01f;
	string UIName = "Extinction Coefficient, Blue";
> 	= 0.12f;

float extinctionCoefficientGreen
<
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 1.0f;
	float UIStep = 0.01f;
	string UIName = "Extinction Coefficient, Green";
> 	= 0.20f;

float specularPower
<
	string UIWidget = "Slider";
	float UIMin = 0.0f;
	float UIMax = 100.0f;
	float UIStep = 0.50f;
	string UIName = "Blinn Specular Power";
> = 1.0f;

texture diffuseTex;
texture thicknessTex;
texture normalTex;

sampler normalSampler = sampler_state
{
	texture		= <normalTex>;
	MinFilter	=	point;
	MagFilter	=	point;
	MipFilter	=	point;
	AddressU	=	CLAMP;
	AddressV	=	CLAMP;
};

sampler2D diffuseSampler = sampler_state
{
	Texture		=	<diffuseTex>;
	MinFilter	=	Linear;
	MagFilter	=	Linear;
	MipFilter	=	Linear;
	AddressU	=	WRAP;
	AddressV	=	WRAP;
};

sampler2D thicknessSampler = sampler_state
{
	Texture		=	<diffuseTex>;
	MinFilter	=	Linear;
	MagFilter	=	Linear;
	MipFilter	=	Linear;
	AddressU	=	WRAP;
	AddressV	=	WRAP;
};

struct VSOut
{
	float4 position			:	POSITION;
	float2 texCoord			:	TEXCOORD0;
	float3 worldNormal		:	TEXCOORD1;
	float3 eyeVec     		:	TEXCOORD2;
	float3 lightVec			:	TEXCOORD3;
	float3 worldTangent		: 	TEXCOORD4;
	float3 worldBinormal		: 	TEXCOORD5;
	float3 vertPos			:	TEXCOORD6;
};

struct AppData {
   	float4 position	:	POSITION;
	float2 UV	:	TEXCOORD0;
	float3 normal	:	NORMAL;
	float3 tangent	: 	TANGENT;
	float3 binormal	: 	BINORMAL;
};

VSOut SkinVS(AppData IN, uniform float4 lightPosition)
{
	VSOut OUT;

	OUT.worldNormal = normalize(mul(IN.normal, worldInverseTranspose).xyz);
	OUT.worldTangent = normalize(mul(IN.tangent, worldInverseTranspose).xyz);
	OUT.worldBinormal = normalize(mul(IN.binormal, worldInverseTranspose).xyz);
	 
	float3 worldSpacePos = mul(IN.position, world);
	OUT.lightVec = lightPosition - worldSpacePos;
	OUT.texCoord = IN.UV;
	OUT.eyeVec = viewInverse[3].xyz - worldSpacePos;
	OUT.position = mul(IN.position, worldViewProj);
	OUT.vertPos = worldSpacePos;
	return OUT;

};

float halfLambert(float3 vec1, float3 vec2)
{
	float product = dot(vec1, vec2);
	product *= 0.5;
	product += 0.5;
	return product;
}

float blinnPhongSpecular(float3 normalVec, float3 lightVec, float specPower)
{
	float3 halfAngle = normalize(normalVec + lightVec);
	return pow(saturate(dot(normalVec, halfAngle)), specPower);
}

float4 SkinPS(VSOut IN) : COLOR0
{
	float attenuation = (1.0f/distance(LightPosition1, IN.vertPos));
	attenuation *= 10.0f;
	float3 eyeVec 	= normalize(IN.eyeVec);
	float3 lightVec = normalize(IN.lightVec.xyz);
	float3 worldNormal = normalize(IN.worldNormal);
	//float3 nMap = tex2D(normalSampler, IN.texCoord);
	//worldNormal.x = dot(nMap.x, IN.worldTangent);
	//worldNormal.y = dot(nMap.y, IN.worldBinormal);
	//worldNormal.z = dot(nMap.z, IN.worldNormal);
	float4 dotLN	= halfLambert(lightVec, worldNormal) * attenuation;
	float3 indirectLightComponent = (float3)(materialThickness * max(0, dot(-worldNormal, lightVec)));
	indirectLightComponent += materialThickness * halfLambert(-eyeVec, lightVec);
	indirectLightComponent *= attenuation;
	indirectLightComponent.r *= extinctionCoefficientRed;
	indirectLightComponent.g *= extinctionCoefficientGreen;
	indirectLightComponent.b *= extinctionCoefficientBlue;
	indirectLightComponent.rgb *= tex2D(thicknessSampler, IN.texCoord).r;
	float3 rim = (float3)(1.0f - max(0.0f, dot(worldNormal, eyeVec)));
	rim *= rim;
	dotLN *= tex2D(diffuseSampler, IN.texCoord);
	float4 finalCol = dotLN + float4(indirectLightComponent, 1.0f);
	rim *= max(0.0f, dot(worldNormal, lightVec)) * specColor;
	finalCol.rgb += (rim * rimScalar * attenuation * finalCol.a);
	finalCol.rgb += (blinnPhongSpecular(worldNormal, lightVec, specularPower) * attenuation * specColor * finalCol.a * 0.05f);
	finalCol.rgb *= lightColor;
	return float4(finalCol);
};

technique subSurfaceScattering
{
    pass p0 
    {		
		VertexShader		= compile vs_2_0 SkinVS(LightPosition1);
		PixelShader			= compile ps_2_0 SkinPS();
		ZEnable 			= true;
		ZWriteEnable 		= true;
		AlphaBlendEnable	= false;
		SrcBlend 			= SrcAlpha;
		DestBlend 			= InvSrcAlpha;
		CullMode 			= CW; //None, CW, or CCW
    }
}