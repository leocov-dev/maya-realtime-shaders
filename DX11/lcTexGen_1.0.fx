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

Texture2D LitSphereTexture
<
	string UIGroup = "Textures";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Lit Sphere Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 101;
	int UVEditorOrder = 1;
>;

Texture2D NormalTexture
<
	string UIGroup = "Textures";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Normal Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 102;
	int UVEditorOrder = 2;
>;

TextureCube maskCube : environment
<
	string UIGroup = "Textures";
	string ResourceName = "texture/maskCube.dds";
	string UIWidget = "FilePicker";
	string UIName = "Cube Mask Map";	// Note: do not rename to 'Reflection Cube Map'. This is named this way for backward compatibilty (resave after compat_maya_2013ff10.mel)
	string ResourceType = "Cube";
	int mipmaplevels = 0; // Use (or load) max number of mip map levels so we can use blurring
	int UIOrder = 105;
	int UVEditorOrder = 5;
>;

//------------------------------------
// Per Object parameters
//------------------------------------
cbuffer UpdatePerObject : register(b1)
{
	bool OutputUvSpace
	<
		string UIGroup = "Global Properties";
		string UIName = "Output in UV space";
		int UIOrder = 200;
	> = false;

	bool OutputLuminanceOnly
	<
		string UIGroup = "Global Properties";
		string UIName = "Render as Luminance";
		int UIOrder = 201;
	> = false;

	bool UseNormalTexture
	<
		string UIGroup = "Global Properties";
		string UIName = "Normal Map";
		int UIOrder = 202;
	> = false;



	bool useLitSphereLighten
	<
		string UIGroup = "LitSphere Properties";
		string UIName = "Use Lighten Blend";
		int UIOrder = 301;
	> = false;

	bool useLitSphereCube
	<
		string UIGroup = "LitSphere Properties";
		string UIName = "Use Cube Projection";
		int UIOrder = 302;
	> = false;

	bool LitSphereFlipX
	<
		string UIGroup = "LitSphere Properties";
		string UIName = "Flip Lit Sphere X";
		int UIOrder = 303;
	> = false;

	bool LitSphereFlipY
	<
		string UIGroup = "LitSphere Properties";
		string UIName = "Flip Lit Sphere Y";
		int UIOrder = 304;
	> = false;


	float rotateYaw
	<
		string UIGroup = "LitSphere Properties";
		string UIWidget = "Slider";
		float UIMin = -360.0;
		float UIMax = 360.0;
		float UIStep = 0.001;
		string UIName = "Rotate Projection";
		int UIOrder = 305;
	> = 0.0;


	float cubeMipLvl
	<
		string UIGroup = "LitSphere Properties";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 8.0;
		float UIStep = 0.001;
		string UIName = "Cube Projection Blur";
		int UIOrder = 306;
	> = 0.0;


	bool useAoGradient
	<
		string UIGroup = "Fast AO Properties";
		string UIName = "Fast AO";
		int UIOrder = 400;
	> = true;

	bool useAoSmoothstep
	<
		string UIGroup = "Fast AO Properties";
		string UIName = "Fast AO use Smoothstep";
		int UIOrder = 401;
	> = false;

	float aoAdjustAmount
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		float UIMin = 0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Fast AO Amount";
		int UIOrder = 402;
	> = 1.0;

	float aoAdjustGamma
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 5.0;
		float UIStep = 0.001;
		string UIName = "Fast AO Contrast";
		int UIOrder = 403;
	> = 1.0;

	float aoAdjustExp
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		float UIMin = -5.0;
		float UIMax = 5.0;
		float UIStep = 0.001;
		string UIName = "Fast AO Slide";
		int UIOrder = 404;
	> = 0.0;

	bool useRampGradient
	<
		string UIGroup = "Fast AO Properties";
		string UIName = "Gradient Ramp";
		int UIOrder = 500;
	> = false;

	bool useRampSmoothstep
	<
		string UIGroup = "Fast AO Properties";
		string UIName = "Gradient Ramp use Smoothstep";
		int UIOrder = 501;
	> = false;

	float rampAdjustAmount
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		float UIMin = 0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Gradient Ramp Amount";
		int UIOrder = 502;
	> = 1.0;

	// float rampAdjustGamma
	// <
	// 	string UIGroup = "Fast AO Properties";
	// 	string UIWidget = "Slider";
	// 	float UIMin = 0.0;
	// 	float UIMax = 5.0;
	// 	float UIStep = 0.001;
	// 	string UIName = "Gradient Ramp Contrast";
	// 	int UIOrder = 502;
	// > = 1.0;

	float rampAdjustExp
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		float UIMin = -5.0;
		float UIMax = 5.0;
		float UIStep = 0.001;
		string UIName = "Gradient Ramp Slide";
		int UIOrder = 503;
	> = 0.0;

	float rampTop
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		//float UIMin = 0.0;
		//float UIMax = 1000.0;
		//float UIStep = 0.001;
		string UIName = "Gradient Ramp Top";
		int UIOrder = 504;
	> = 10.0;

	float rampBottom
	<
		string UIGroup = "Fast AO Properties";
		string UIWidget = "Slider";
		//float UIMin = 0.0;
		//float UIMax = 1000.0;
		//float UIStep = 0.001;
		string UIName = "Gradient Ramp Bottom";
		int UIOrder = 505;
	> = 0.0;

	bool rampHelper
	<
		string UIGroup = "Fast AO Properties";
		string UIName = "Show Ramp Positioning Helper";
		int UIOrder = 506;
	> = false;

} //end UpdatePerObject cbuffer


//------------------------------------
// Functions
//------------------------------------

float invert(float input)
{
	return (1.0-clamp(input,-1,1));
}

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

float remap(float value, float low1, float high1, float low2, float high2)
{
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

float contrast(float value, float contrast)
{
	const float AvgLum = 0.5;
	return lerp(AvgLum, value, contrast);
}

float4 desaturate(float3 color, float Desaturation)
{
	float3 grayXfer = float3(0.3, 0.59, 0.11);
	float grayf = dot(grayXfer, color);
	float3 gray = float3(grayf, grayf, grayf);
	return float4(lerp(color, gray, Desaturation), 1.0);
}

float fresnel (float3 N, float3 V) //this is the most basic approximation of the fresnel function
{
    //return max(0.f,pow(abs(1.0-dot(N,V)),fresnelExp));
    return abs(dot(N,V));
}

#define BlendOverlayf(base, blend) 	(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)))

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
	float4 hPosition		: SV_POSITION;
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

	return OUT;
}

//------------------------------------
// pixel shader
//------------------------------------

float4 f_default(SHADERDATA IN, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );
	float3 N = normalize(IN.worldNormal.xyz);
		   N = lerp (N, -N, FrontFace);
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = normalize(IN.worldBinormal.xyz);//cross(N, T); 
	
	if (UseNormalTexture)
	{
		float3 normalTextureSample = NormalTexture.Sample(SamplerAnisoWrap, IN.UV).rgb;
		N  = normalsTangent(normalTextureSample, N, Bn, T, false);
	}

	float3 result = pow(0.5 * N + 0.5, GammaCorrection);

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/GammaCorrection);

	return float4(result, 1.0);
}

float4 f_fastAo(SHADERDATA IN, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );
	float3 N = normalize(IN.worldNormal.xyz);
		   N = lerp (N, -N, FrontFace);
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = normalize(IN.worldBinormal.xyz);//cross(N, T); 
	
	if (UseNormalTexture)
	{
		float3 normalTextureSample = NormalTexture.Sample(SamplerAnisoWrap, IN.UV).rgb;
		N  = normalsTangent(normalTextureSample, N, Bn, T, false);
	}


	float aoGradient = 0.5 * N.y + 0.5;
	float posGradient = IN.worldPosition.y;

	float3 gradient = 1.0;

	if (useAoGradient)
	{	
		float aoGradBase = saturate(aoGradient);

		if (aoAdjustExp> 0.0) aoAdjustExp = remap(aoAdjustExp, 0, 5, 1, 5);
		if (aoAdjustExp< 0.0) aoAdjustExp = remap(aoAdjustExp, -5, 0, -5, -1);
		if (aoAdjustExp > 0.0)
		{
			aoGradBase = pow(saturate(aoGradBase), aoAdjustExp);
		}
		if (aoAdjustExp < 0.0)
		{
			aoGradBase = invert(pow(invert(saturate(aoGradBase)), -1*aoAdjustExp));
		}

		

		if (aoAdjustGamma < 1.0)
		{
			aoGradBase = pow(aoGradBase, aoAdjustGamma);
		}
		else
		{
			aoGradBase = contrast(saturate(aoGradBase), max(1.0, aoAdjustGamma));
		}



		if (useAoSmoothstep)
		{
			aoGradBase = smoothstep(0.0,1.0,aoGradBase);
		}
		

		gradient *= lerp(1.0,saturate(aoGradBase), aoAdjustAmount);
	}

	if (useRampGradient)
	{
		float rampGradBase = saturate(remap(posGradient, rampBottom, rampTop, 0, 1));

		if (rampAdjustExp> 0.0) rampAdjustExp = remap(rampAdjustExp, 0, 5, 1, 5);
		if (rampAdjustExp< 0.0) rampAdjustExp = remap(rampAdjustExp, -5, 0, -5, -1);
		if (rampAdjustExp > 0.0)
		{
			rampGradBase = pow(saturate(rampGradBase), rampAdjustExp);
		}
		if (rampAdjustExp < 0.0)
		{
			rampGradBase = invert(pow(invert(saturate(rampGradBase)), -1*rampAdjustExp));
		}

		if (useRampSmoothstep)
		{
			rampGradBase = smoothstep(0.0,1.0,rampGradBase);
		}

		gradient *= lerp(1.0, saturate(rampGradBase), rampAdjustAmount);

		if (rampHelper){
			if (posGradient > rampTop || posGradient < rampBottom) gradient = float3(1.0,0.4,0.4);
		}
	}

	float3 result = pow(saturate(gradient), GammaCorrection);

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/GammaCorrection);

	return float4(result, 1.0);
}

float4 f_litSphere(SHADERDATA IN, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );
	float3 N = normalize(IN.worldNormal.xyz);
		   N = lerp (N, -N, FrontFace);
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = normalize(IN.worldBinormal.xyz);//cross(N, T); 

	if (useLitSphereLighten||useLitSphereCube)
	{
		N = RotateVectorYaw(N, rotateYaw);
		T = RotateVectorYaw(T, rotateYaw);
		Bn = RotateVectorYaw(Bn, rotateYaw);
	}

	float4x4 viewX = {float4(0.0,0.0,1.0,0.0),
					  float4(0.0,1.0,0.0,0.0),
					  float4(0.0,0.0,0.0,0.0),
					  float4(0.0,0.0,0.0,0.0)};

	float4x4 viewY = {float4(-1.0,0.0,0.0,0.0),
					  float4(0.0,0.0,1.0,0.0),
					  float4(0.0,0.0,0.0,0.0),
					  float4(0.0,0.0,0.0,0.0)};

	float4x4 viewZ = {float4(1.0,0.0,0.0,0.0),
					  float4(0.0,1.0,0.0,0.0),
					  float4(0.0,0.0,0.0,0.0),
					  float4(0.0,0.0,0.0,0.0)};
	
	if (UseNormalTexture)
	{
		float3 normalTextureSample = NormalTexture.Sample(SamplerAnisoWrap, IN.UV).rgb;
		N  = normalsTangent(normalTextureSample, N, Bn, T, false);
	}
	
	float3 Nc = mul(viewInv, float4(N,1)).xyz;
	float3 Nx = mul(viewX, float4(N,1)).xyz;
	float3 Ny = mul(viewY, float4(N,1)).xyz;
	float3 Nz = mul(viewZ, float4(N,1)).xyz;

	float iX = 1;
	float iY = 1;
	if (LitSphereFlipX) iX = -1;
	if (LitSphereFlipY) iY = -1;

	float3 litSphereTextureSample  = LitSphereTexture.Sample(SamplerAnisoWrap, float2(0.49*iX,-0.49*iY) * Nc.xy + 0.5).rgb;
	float3 litSphereTextureSampleX = LitSphereTexture.Sample(SamplerAnisoWrap, float2(0.49*iX,-0.49*iY) * Nx.xy + 0.5).rgb;
	float3 litSphereTextureSampleY = LitSphereTexture.Sample(SamplerAnisoWrap, float2(0.49*iX,-0.49*iY) * Ny.xy + 0.5).rgb;
	float3 litSphereTextureSampleZ = LitSphereTexture.Sample(SamplerAnisoWrap, float2(0.49*iX,-0.49*iY) * Nz.xy + 0.5).rgb;

	float3 litSphereComponent  = pow(litSphereTextureSample,  GammaCorrection);
	float3 litSphereComponentX = pow(litSphereTextureSampleX, GammaCorrection);
	float3 litSphereComponentY = pow(litSphereTextureSampleY, GammaCorrection);
	float3 litSphereComponentZ = pow(litSphereTextureSampleZ, GammaCorrection);

	float3 cameraProject = litSphereComponent;

	float3 lightenBlend = max(litSphereComponentY, max(litSphereComponentX, litSphereComponentZ));

	
	float3 rgbCubeMask = maskCube.SampleLevel(CubeMapSampler, N, cubeMipLvl).rgb;

	float xMask = rgbCubeMask.b;
	float yMask = rgbCubeMask.g;
	float zMask = rgbCubeMask.r;

	float3 cubeProject = 0.0;

	cubeProject += lerp(0.0, litSphereComponentX, xMask);

	cubeProject += lerp(0.0, litSphereComponentY, yMask);

	cubeProject += lerp(0.0, litSphereComponentZ, zMask);
	
	// //----------------------------------------
	// //angle based
	// cubeProject = 0.0;
	// float blurVal = cubeMipLvl;
	// float midVal = radians(40.5);
	// float posX = remap(N.x, midVal-blurVal, midVal+blurVal, 0, 1);
	// if (N.x > midVal || N.x < -midVal) cubeProject = 1.0;



	// //cubeProject = posX;
	// cubeProject = abs(dot(dot(N.x,N.y),N.z));
	// cubeProject = dot(N.x, N.y);

	// //----------------------------------------

	float3 result = cameraProject;
	if (useLitSphereLighten) result  = lightenBlend;
	if (useLitSphereCube) result = cubeProject;

	if (OutputLuminanceOnly) result = desaturate(result,1.0);

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
technique11 CHOOSE_A_TECHNIQUE
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
		SetRasterizerState(Backface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f_default()));

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
		SetPixelShader(CompileShader(ps_5_0, f_default()));

	}
}

technique11 Fast_AO
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
		SetRasterizerState(Backface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f_fastAo()));

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
		SetPixelShader(CompileShader(ps_5_0, f_fastAo()));

	}
}

technique11 LitSphere
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
		SetRasterizerState(Backface);
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f_litSphere()));

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
		SetPixelShader(CompileShader(ps_5_0, f_litSphere()));

	}
}

/////////////////////////////////////// eof //