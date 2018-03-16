//------------------------------------
// Defines
// how many mip map levels should Maya generate or load per texture. 
// 0 means all possible levels
// some textures may override this value, but most textures will follow whatever we have defined here
// If you wish to optimize performance (at the cost of reduced quality), you can set NumberOfMipMaps below to 1

#define NumberOfMipMaps 0
#define PI 3.1415926
#define GammaCorrection 2.2

//------------------------------------
// Per Frame parameters
//------------------------------------
cbuffer UpdatePerFrame : register(b0)
{
	float4x4 worldInvXpose 	: WorldInverseTranspose < string UIWidget = "None"; >;
	float4x4 viewInv 		: ViewInverse 			< string UIWidget = "None"; >;   
	float4x4 view			: View					< string UIWidget = "None"; >;
	float4x4 prj			: Projection			< string UIWidget = "None"; >;
	float4x4 viewPrj		: ViewProjection		< string UIWidget = "None"; >;
	float4x4 worldViewPrj	: WorldViewProjection	< string UIWidget = "None"; >;
	float4x4 worldView		: WorldView				< string UIWidget = "None"; >;
	float4x4 world 			: World 				< string UIWidget = "None"; >;

	// A shader may wish to do different actions when Maya is rendering the preview swatch (e.g. disable displacement)
	// This value will be true if Maya is rendering the swatch
	bool IsSwatchRender     : MayaSwatchRender      < string UIWidget = "None"; > = false;

	// If the user enables viewport gamma correction in Maya's global viewport rendering settings, the shader should not do gamma again
	bool MayaFullScreenGamma : MayaGammaCorrection < string UIWidget = "None"; > = false;
}

//------------------------------------
// Samplers
//------------------------------------
SamplerState CubeMapSampler
{
	Filter = ANISOTROPIC;
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;    
};

SamplerState SamplerAnisoWrap
{
	Filter = ANISOTROPIC;
	AddressU = Wrap;
	AddressV = Wrap;
};

SamplerState SamplerShadowDepth
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
};

//------------------------------------
// Textures
//------------------------------------

Texture2D DiffuseTexture
<
	string UIGroup = "Textures";
	string ResourceName = "texture/replaceMe.tga";
	string UIWidget = "FilePicker";
	string UIName = "Diffuse Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 101;
	int UVEditorOrder = 1;
>;

Texture2D NormalTexture
<
	string UIGroup = "Textures";
	string ResourceName = "texture/replaceMe_normalmap.tga";
	string UIWidget = "FilePicker";
	string UIName = "Normal Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 102;
	int UVEditorOrder = 2;
>;

Texture2D SpecularTexture
<
	string UIGroup = "Textures";
	string ResourceName = "texture/replaceMe_specmap.tga";
	string UIWidget = "FilePicker";
	string UIName = "Specular Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 103;
	int UVEditorOrder = 3;
>;

Texture2D GlossTexture
<
	string UIGroup = "Textures";
	string ResourceName = "texture/replaceMe_glossmap.tga";
	string UIWidget = "FilePicker";
	string UIName = "Gloss Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 103;
	int UVEditorOrder = 3;
>;

// Texture2D GlowTexture
// <
// 	string UIGroup = "Textures";
// 	string ResourceName = "";
// 	string UIWidget = "FilePicker";
// 	string UIName = "Glow Map";
// 	string ResourceType = "2D";	
// 	int mipmaplevels = NumberOfMipMaps;
// 	int UIOrder = 104;
// 	int UVEditorOrder = 4;
// >;

TextureCube ReflectionCubeTexture : environment
<
	string UIGroup = "Textures";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Reflection Cube Map";
	string ResourceType = "Cube";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 105;
	int UVEditorOrder = 5;
>;

//------------------------------------
// Per Object parameters
//------------------------------------
cbuffer UpdatePerObject : register(b1)
{
	// int MipLevel
	// <
	// 	string UIGroup = "Textures";
	// 	string UIWidget = "Slider";
	// 	int UIMin = 0;
	// 	int UIMax = 4;
	// 	string UIName = "MipLevel";
	// 	int UIOrder = 106;
	// > = 0;

	bool OutputUvSpace
	<
		string UIGroup = "Properties";
		string UIName = "Output in UV space";
		int UIOrder = 200;
	> = false;
	
	bool UseDiffuseTextureAlpha
	<
		string UIGroup = "Properties";
		string UIName = "Alpha Clip in Diffuse?";
		int UIOrder = 201;
	> = false;

	// float3 SpecularColor
	// <
	// 	string UIGroup = "Properties";
	// 	string UIName = "Specular Color";
	// 	string UIWidget = "ColorPicker";
	// 	int UIOrder = 301;
	// > = {1.0f, 1.0f, 1.0f };

	// bool UseGlowTexture
	// <
	// 	string UIGroup = "Properties";
	// 	string UIName = "Glow Map";
	// 	int UIOrder = 400;
	// > = false;

	// float3 GlowColor
	// <
	// 	string UIGroup = "Properties";
	// 	string UIName = "Glow Color";
	// 	string UIWidget = "ColorPicker";
	// 	int UIOrder = 401;
	// > = {1.0f, 1.0f, 1.0f };

	bool UseReflectionTexture
	<
		string UIGroup = "Properties";
		string UIName = "Environment Cube Map";
		int UIOrder = 500;
	> = false;

	// bool UseNormalTexture
	// <
	// 	string UIGroup = "Properties";
	// 	string UIName = "Normal Map";
	// 	int UIOrder = 600;
	// > = true;

	float3 ShadowColor
	<
		string UIGroup = "Misc";
		string UIName = "Shadow Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 1001;
	> = {0.0f, 0.0f, 0.0f };

	float LightIntensity
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		float UIMin = 1.0;
		float UIMax = 3.0;
		float UIStep = 0.001;
		string UIName = "Light Intensity";
		int UIOrder = 1002;
	> = 1.0;

	// at what value do we clip away pixels
	float AlphaClip
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Alpha Clip";
		int UIOrder = 1002;
	> = 0.5;


	float RotateX
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 360.0;
		float UIStep = 0.001;
		string UIName = "Light RotateX";
		int UIOrder = 1002;
	> = 40.0;


	float RotateY
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 360.0;
		float UIStep = 0.001;
		string UIName = "Light RotateY";
		int UIOrder = 1002;
	> = 340.0;


	float RotateZ
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 360.0;
		float UIStep = 0.001;
		string UIName = "Light RotateZ";
		int UIOrder = 1002;
	> = 0.0;

	bool UseGridOverlay
	<
		string UIGroup = "Misc";
		string UIName = "Checker Overlay";
		int UIOrder = 1002;
	> = false;

	int CheckerSize
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		int UIMin = 1;
		int UIMax = 200;
		string UIName = "Checker Size";
		int UIOrder = 1002;
	> = 10;

	float CheckerOpacity
	<
		string UIGroup = "Misc";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "CheckerOpacity";
		int UIOrder = 1002;
	> = 0.5;

	// bool DoubleSided
	// <
	// 	string UIGroup = "Diffuse";
	// 	string UIName = "Double Sided";
	// 	int UIOrder = 202;
	// > = false;

} //end UpdatePerObject cbuffer

//------------------------------------
// Functions
//------------------------------------

float invert(float input)
{
	return (1.0-clamp(input,-1,1));
}

//---------------------------------------------------------------------------
// component mult method
float3 RotateVectorYaw(float3 vec, float degreeOfRotation)
{
	float3 rotatedVec = vec;
	float angle = radians(degreeOfRotation);

	rotatedVec.x = ( cos(angle) * vec.x ) - ( sin(angle) * vec.z );
	rotatedVec.z = ( sin(angle) * vec.x ) + ( cos(angle) * vec.z );	

	return rotatedVec;
}

float3 RotateVectorRoll(float3 vec, float degreeOfRotation)
{
	float3 rotatedVec = vec;
	float angle = radians(degreeOfRotation);
	
	rotatedVec.y = ( cos(angle) * vec.y ) - ( sin(angle) * vec.z );
	rotatedVec.z = ( sin(angle) * vec.y ) + ( cos(angle) * vec.z );	

	return rotatedVec;
}

float3 RotateVectorPitch(float3 vec, float degreeOfRotation)
{
	float3 rotatedVec = vec;
	float angle = radians(degreeOfRotation);

	rotatedVec.x = ( cos(angle) * vec.x ) - ( sin(angle) * vec.y );
	rotatedVec.y = ( sin(angle) * vec.x ) + ( cos(angle) * vec.y );	

	return rotatedVec;
}

//---------------------------------------------------------------------------
// matrix multiplication method
float3 RotateVectorX(float3 vec, float degreeOfRotation)
{
	float angle = radians(degreeOfRotation);
	float4x4 xMatrix = {1,0,0,0,
						0,cos(angle),-sin(angle),0,
						0,sin(angle), cos(angle),0,
						0,0,0,1};
	float4 rvec = mul(float4(vec.x,vec.y,vec.z,1),xMatrix);
	return float3(rvec.x, rvec.y, rvec.z);
}

float3 RotateVectorY(float3 vec, float degreeOfRotation)
{
	float angle = radians(degreeOfRotation);
	float4x4 xMatrix = { cos(angle),0,sin(angle),0,
						0,1,0,0,
						-sin(angle),0,cos(angle),0,
						0,0,0,1};
	float4 rvec = mul(float4(vec.x,vec.y,vec.z,1),xMatrix);
	return float3(rvec.x, rvec.y, rvec.z);
}

float3 RotateVectorZ(float3 vec, float degreeOfRotation)
{
	float angle = radians(degreeOfRotation);
	float4x4 xMatrix = {cos(angle),-sin(angle),0,0,
						sin(angle), cos(angle),0,0,
						0,0,1,0,
						0,0,0,1};
	float4 rvec = mul(float4(vec.x,vec.y,vec.z,1),xMatrix);
	return float3(rvec.x, rvec.y, rvec.z);
}

//---------------------------------------------------------------------------
float3 normalsTangent(float3 normalTexture,
                      float3 Nn,
                      float3 Bn,
                      float3 Tn,
                      bool   invertGreen)
{
  	if(invertGreen) invert(normalTexture.g);
  	float3 normalValues = normalTexture * 2.0 - 1.0;
  	Nn = normalize((normalValues.x*Tn )+(normalValues.y*Bn )+(normalValues.z*Nn ) );

  	return Nn;
}

float3 lambert(float3 L, float3 N)
{
  	return saturate(dot(N,L) );
}

float3 blinn(float3 L, float3 V, float3 N, float power)
{
	//power = max(power, 1.0);
	power = -10.0 / log2( power*0.968 + 0.03 );
	power *= power;

  	float3 H = normalize(L + V);
  	float NdH = saturate(dot(N,H) );
  	//float specularScale = ComputeSpecularConservationScale(power);
  	return smoothstep(-0.1,0.1,dot(N,L)) * pow(NdH, power);
}

float3 fresnel_schlick(	float cosTheta,
				float3 reflectivity,
				float3 fresnelStrength	)
{
	//schlick's fresnel approximation
	float f = saturate( 1.0 - cosTheta );
	float f2 = f*f; f *= f2 * f2;
	return lerp( reflectivity, float3(1.0,1.0,1.0), f*fresnelStrength );
}

bool checker (float2 UV, int frequency)
{	
	//using odd frequency numbers results in half squares at edges that look like artifacts when tiled
	if (frequency&1 == 1) frequency -=1;

	bool x = int(UV.x*frequency)&2;
	bool y = int(UV.y*frequency)&2;
	return (x!=y);
}

//------------------------------------
// Structs
//------------------------------------
struct APPDATA
{ 
	float3 position		: POSITION;
	float3 normal		: NORMAL;
	float3 binormal		: BINORMAL;
	float3 tangent		: TANGENT; 
	float2 UV			: TEXCOORD0;
};

struct SHADERDATA
{
	float4 hPosition		: POSITION;
	float3 worldNormal   	: NORMAL;
	float4 worldTangent 	: TANGENT; 
	float4 worldBinormal 	: BINORMAL; 
	float2 UV	  			: TEXCOORD0;
	float3 worldPosition	: TEXCOORD1;
  	float3 cameraLightVec	: TEXCOORD2;

	//float clipped : CLIPPED;
};

//------------------------------------
// vertex shader
//------------------------------------
// take inputs from 3d-app
// vertex animation/skinning would happen here
SHADERDATA v(APPDATA IN) 
{
	SHADERDATA OUT = (SHADERDATA)0;

	// we pass vertices in world space
	OUT.worldPosition = mul(float4(IN.position, 1), world).xyz;
	OUT.hPosition = mul( float4(IN.position.xyz, 1), worldViewPrj );
  
	if(OutputUvSpace)
	{
		float2 uvPos = IN.UV * float2(2,-2) + float2(-1,1);
		uvPos = float2(uvPos.x,(uvPos.y*-1.0));
		OUT.hPosition = float4(uvPos,0,1);
	}

	// Pass through texture coordinates
	// flip Y for Maya
	OUT.UV = float2(IN.UV.x,(1.0-IN.UV.y));

	// output normals in world space:
	OUT.worldNormal = normalize(mul(IN.normal, (float3x3)worldInvXpose));
	// output tangent in world space:
	OUT.worldTangent.xyz = normalize( mul(IN.tangent, (float3x3)worldInvXpose) );
	// store direction for normal map:
	OUT.worldTangent.w = 1;
	if (dot(cross(IN.normal.xyz, IN.tangent.xyz), IN.binormal.xyz) < 0.0) OUT.worldTangent.w = -1;
	// output binormal in world space:
	OUT.worldBinormal.xyz = normalize( mul(IN.binormal, (float3x3)worldInvXpose) );

	OUT.cameraLightVec = viewInv[3].xyz - OUT.worldPosition.xyz;
	//OUT.cameraLightVec = mul(float4(OUT.cameraLightVec.x,OUT.cameraLightVec.y,OUT.cameraLightVec.z,1), world).xyz;

	return OUT;
}

//------------------------------------
// pixel shader
//------------------------------------
float4 f_silhouette(SHADERDATA IN) : SV_Target
{
	if (true)
	{
		if (UseDiffuseTextureAlpha)
		{
			clip(pow(DiffuseTexture.Sample(SamplerAnisoWrap, IN.UV), GammaCorrection).a < AlphaClip ? -1:1);
		}
	}

	//Combine all shading components
	float3 result = 0.0;

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/GammaCorrection);

	return float4(result, 1.0);
}

float4 f_worldNormals(SHADERDATA IN) : SV_Target
{
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );
	float3 N = normalize(IN.worldNormal.xyz);
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = normalize(IN.worldBinormal.xyz);
	
	if (true)
	{
		float3 normalTextureSample = NormalTexture.Sample(SamplerAnisoWrap, IN.UV).rgb;
		N  = normalsTangent(normalTextureSample, N, Bn, T, false);
	}

	if (true)
	{
		if (UseDiffuseTextureAlpha)
		{
			clip(pow(DiffuseTexture.Sample(SamplerAnisoWrap, IN.UV), GammaCorrection).a < AlphaClip ? -1:1);
		}
	}

	//Combine all shading components
	float3 result = pow(0.5 * N + 0.5, GammaCorrection);

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/GammaCorrection);

	return float4(result, 1.0);
}

//Diffuse Only
float4 f_diffuseOnly(SHADERDATA IN) : SV_Target
{
	// GlowColor = pow(GlowColor, GammaCorrection);

	float4 diffuseTextureSample = float4(0.5,0.5,0.5,1.0);
	float3 glowTextureSample = 0.0;

	float3 diffuseComponent = 0.5;
	float3 glowComponent = 0.0;

	if (true)
	{
		diffuseTextureSample = pow(DiffuseTexture.Sample(SamplerAnisoWrap, IN.UV), GammaCorrection);
		diffuseComponent = diffuseTextureSample.rgb;

		if (UseDiffuseTextureAlpha)
		{
			clip(diffuseTextureSample.a < AlphaClip ? -1:1);
		}
	}

	// if (UseGlowTexture)
	// {
	// 	glowTextureSample = pow(GlowTexture.Sample(SamplerAnisoWrap, IN.UV).rgb, GammaCorrection);
	// 	glowComponent = glowTextureSample * GlowColor;
	// }

	float3 grid = 1.0;
	if (UseGridOverlay)
	{
		if (checker(IN.UV, CheckerSize)) grid = 0.0;
		grid = saturate(grid+CheckerOpacity);
	}


	//Combine all shading components
	float3 result = diffuseComponent+glowComponent;
	result *= grid;

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/GammaCorrection);

	return float4(result, 1.0);
}

//Full Shading
float4 f(SHADERDATA IN, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );
	float3 N = normalize(IN.worldNormal.xyz);
	N = lerp (N, -N, FrontFace);
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = normalize(IN.worldBinormal.xyz);//cross(N, T); 
	float3 L = normalize(IN.cameraLightVec.xyz);

	// transform vector to viewSpace for editing, then back for general use.
	L = mul(viewInv,float4(L.x,L.y,L.z,1)).xyz;
	L = RotateVectorX(L, RotateX);
	L = RotateVectorY(L, RotateY);
	L = RotateVectorZ(L, RotateZ);
	L = mul(view,float4(L.x,L.y,L.z,1)).xyz;
	
	if (true)
	{
		float3 normalTextureSample = NormalTexture.Sample(SamplerAnisoWrap, IN.UV).rgb;
		N  = normalsTangent(normalTextureSample, N, Bn, T, false);
	}

	float3 reflectionVector = reflect(-V, N);
	float ReflectionMipLevel = 0.0;
	float3 SpecularColor = float3(1.0,1.0,1.0);//pow(SpecularColor, GammaCorrection);
	// GlowColor = pow(GlowColor, GammaCorrection);

	float4 diffuseTextureSample = float4(0.5,0.5,0.5,1.0);
	float4 specularTextureSample = float4(0.5,0.5,0.0,0.0);
	float4 glossTextureSample = float4(0.5,0.5,0.0,0.0);
	// float3 glowTextureSample = 0.0;
	float3 reflectionTextureSample = 0.0;

	float3 ambientComponent = ShadowColor;
	float3 diffuseComponent = float3(0.7, 0.0, 0.2);
	float3 specularComponent = 0.0;
	float3 glowComponent = 0.0;
	float3 reflectionComponent = 0.0;





	//lambert diffuse lighting
	diffuseComponent = lambert(L, N)*LightIntensity;
	
	//blinn specular lighting
	specularComponent = blinn(L, V, N, 80.0);

	diffuseTextureSample = pow(DiffuseTexture.Sample(SamplerAnisoWrap, IN.UV), GammaCorrection);
	ambientComponent *= diffuseTextureSample.rgb;
	diffuseComponent *= diffuseTextureSample.rgb;

	if (UseDiffuseTextureAlpha)
	{
		clip(diffuseTextureSample.a < AlphaClip ? -1:1);
	}

	specularTextureSample = SpecularTexture.Sample(SamplerAnisoWrap, IN.UV);
	glossTextureSample = min(GlossTexture.Sample(SamplerAnisoWrap, IN.UV), 0.995);

	float fresnel = fresnel_schlick(dot(V,N), specularTextureSample, glossTextureSample.r*glossTextureSample.r);//pow(1-saturate(dot(N,V)), specularTextureSample.w*16.0);

	specularComponent = blinn(L, V, N, glossTextureSample.r);
	specularComponent *= specularTextureSample * SpecularColor;
	

	// if (UseGlowTexture)
	// {
	// 	glowTextureSample = pow(GlowTexture.Sample(SamplerAnisoWrap, IN.UV).rgb, GammaCorrection);
	// 	glowComponent = glowTextureSample * GlowColor;
	// }

	if (UseReflectionTexture)
	{

		reflectionTextureSample = ReflectionCubeTexture.SampleLevel(CubeMapSampler, reflectionVector, ReflectionMipLevel).rgb;//pow(ReflectionCubeTexture.SampleLevel(CubeMapSampler, reflectionVector, ReflectionMipLevel).rgb, GammaCorrection);
		if (true)
		{
			reflectionComponent = reflectionTextureSample * fresnel * (LightIntensity);
		}
	}

	float3 grid = 1.0;
	if (UseGridOverlay)
	{
		if (checker(IN.UV, CheckerSize)) grid = 0.0;
		grid = saturate(grid+CheckerOpacity);
	}

	//Combine all shading components
	float3 result = ambientComponent+diffuseComponent+specularComponent+glowComponent+reflectionComponent;
	result *= grid;

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/GammaCorrection);

	return float4(result, 1.0);
}



//-----------------------------------
// Objects without tessellation
//------------------------------------
RasterizerState FrontFace {
    //FrontCounterClockwise = true;
    CullMode = Front;
};
RasterizerState Backface {
    //FrontCounterClockwise = false;
    CullMode = Back;
};
RasterizerState Noneface {
    //FrontCounterClockwise = false;
    CullMode = None;
};

//------------------------
//Techniques
//------------------------
technique11 DoubleSided
<
	bool overridesDrawState = false;	// we do not supply our own render state settings
	int isTransparent = 0;
>
{ 
	pass p0
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		//SetBlendState(AlphaBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(Backface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f()));

	}
	pass p1
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		SetRasterizerState(FrontFace);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f()));

	}
}

technique11 SingleSided
<
	bool overridesDrawState = false;	// we do not supply our own render state settings
	int isTransparent = 0;
>
{ 
	pass p0
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		SetRasterizerState(FrontFace);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f()));

	}
}

technique11 WorldNormals
<
	bool overridesDrawState = false;	// we do not supply our own render state settings
	int isTransparent = 0;
>
{ 
	pass p0
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		//SetBlendState(AlphaBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(Noneface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f_worldNormals()));

	}
}

technique11 DiffuseOnly
<
	bool overridesDrawState = false;	// we do not supply our own render state settings
	int isTransparent = 0;
>
{ 
	pass p0
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		//SetBlendState(AlphaBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(Noneface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f_diffuseOnly()));

	}
}

technique11 Silhouette
<
	bool overridesDrawState = false;	// we do not supply our own render state settings
	int isTransparent = 0;
>
{ 
	pass p0
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		//SetBlendState(AlphaBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(Noneface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f_silhouette()));

	}
}

/////////////////////////////////////// eof //