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

//------------------------------------
// Per Object parameters
//------------------------------------
cbuffer UpdatePerObject : register(b1)
{
	bool OutputUvSpace
	<
		string UIGroup = "Properties";
		string UIName = "Output in UV space";
		int UIOrder = 200;
	> = false;

	bool LitSphereFlipX
	<
		string UIGroup = "Properties";
		string UIName = "Flip Lit Sphere X";
		int UIOrder = 201;
	> = false;

	bool LitSphereFlipY
	<
		string UIGroup = "Properties";
		string UIName = "Flip Lit Sphere Y";
		int UIOrder = 201;
	> = false;

	bool UseNormalTexture
	<
		string UIGroup = "Properties";
		string UIName = "Normal Map";
		int UIOrder = 600;
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

	return OUT;
}

//------------------------------------
// pixel shader
//------------------------------------

//Full Shading
float4 f(SHADERDATA IN, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );
	float3 N = normalize(IN.worldNormal.xyz);
		   N = lerp (N, -N, FrontFace);
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = normalize(IN.worldBinormal.xyz);//cross(N, T); 

	float3 Nc = mul(viewInv, float4(IN.worldNormal.xyz,1)).xyz; //transform to View/Camera
	float3 Tc = mul(viewInv, float4(IN.worldTangent.xyz,1)).xyz; //transform to View/Camera
	float3 Bc = mul(viewInv, float4(IN.worldBinormal.xyz,1)).xyz; //transform to View/Camera
	float3 Nsphere = Nc;
	
	if (UseNormalTexture)
	{
		float3 normalTextureSample = NormalTexture.Sample(SamplerAnisoWrap, IN.UV).rgb;
		N  = normalsTangent(normalTextureSample, N, Bn, T, false);
		Nsphere  = normalsTangent(normalTextureSample, Nc, Bc, Tc, false);
	}

	float iX = 1;
	float iY = 1;
	if (LitSphereFlipX) iX = -1;
	if (LitSphereFlipY) iY = -1;

	float3 litSphereTextureSample = LitSphereTexture.Sample(SamplerAnisoWrap, float2(0.49*iX,-0.49*iY) * Nsphere.xy + 0.5).rgb;

	float3 litSphereComponent = pow(litSphereTextureSample, GammaCorrection);

	float3 result = litSphereComponent;

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

/////////////////////////////////////// eof //