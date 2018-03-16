////////////////////////////////////////////////////////////////////////
// litSphere.fx
// Matballz.fx
//
//	Shader by Charles Hollemeersch http://charles.hollemeersch.net/
//	Public domain.
//
//	Parameters:
//
//		Bumpmap Strength: Scales the bumps to be flatter/steeper
//                        (i.e. more/less towards 0,0,1).
//		Normal Map      : Provides a bumpmap if no map is provided the
//                        geometry normal is used.
//		Lit Sphere Map  : The prelighted sphere to apply as a light. Check
//                        http://www.cs.utah.edu/npr/papers/LitSphere_HTML/
//                        to get some inspiration.
//
//  Edited: 12/13/2009 - Leonardo Covarrubias - For use in Maya
//
////////////////////////////////////////////////////////////////////////



////////////////////////
// User interface
////////////////////////

float normalPower <
	string UIName = "Bumpmap Strength";
	string UIWidget = "slider";
	float UIMin = 0.0;
	float UIMax = 2.0;
	float UIStep = 0.1;
> = 1.0;

bool flipGreen
<
    string UIName = "Invert Normal Map Green Channel?";
> = false;

texture normalMap : Normal <
	string UIName = "Normal Map";
	string ResourceName = "";
	string ResourceType = "2D";
>;

texture litSphereMap : LitSphere <
	string UIName = "Lit Sphere Map";
	string ResourceName = "";
	string ResourceType = "2D";
>;

////////////////////////
// Samplers
////////////////////////

sampler NormalSampler = sampler_state {
	Texture = <normalMap>;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    AddressU  = WRAP;		
    AddressV  = WRAP;	
};

sampler LightSampler = sampler_state {
	Texture = <litSphereMap>;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    AddressU  = CLAMP;		
    AddressV  = CLAMP;
};

////////////////////////
// Matrices
////////////////////////

float4x4 WorldView            : WORLDVIEW;
float4x4 WorldViewProjection  : WORLDVIEWPROJECTION;

////////////////////////
// Exchange structs
////////////////////////

struct a2v 
{
	float4 Position : POSITION; 
	float2 TexCoord : TEXCOORD0;
	float3 Tangent  : TANGENT;
	float3 Binormal : BINORMAL;
	float3 Normal   : NORMAL;
};

struct v2f 
{
	float4 Position     : POSITION;
	float2 TexCoord     : TEXCOORD0;
	float3 viewTangent  : TEXCOORD1;
	float3 viewBinormal : TEXCOORD2;
	float3 viewNormal   : TEXCOORD3;
};

////////////////////////
// Vertex shader
////////////////////////

v2f BumpReflectVS(a2v IN)
{
	v2f OUT;

	// Pos to NDC
	OUT.Position = mul(IN.Position, WorldViewProjection);
	// Texcoords (for normal map)
	OUT.TexCoord.xy = IN.TexCoord;
	
	// Tangent space vectors
	OUT.viewTangent.xyz = mul(IN.Tangent,WorldView);
	OUT.viewBinormal.xyz = mul(IN.Binormal,WorldView);
	OUT.viewNormal.xyz = mul(IN.Normal,WorldView);
	
	return OUT;
}

////////////////////////
// Pixel shader
////////////////////////

float3 viewNormalTangent (float3 Tv, float3 Bv, float3 Nv, float3 normalTexture, float normalPower)
{
	normalTexture.rgb = normalTexture.rgb*2.0-1.0;
	normalTexture.xy *= normalPower;
	
	// Fixes normals if no normal map texture is supplied
	if ( dot(normalTexture,normalTexture) > 2.0 ) {
		normalTexture = float3(0,0,1);
	}
    
    float3 N = normalize(Nv + normalTexture.y * Bv + normalTexture.x * Tv);

	N.y = - N.y;
	return N;
}

float4 BumpReflectPS(v2f IN) : COLOR {

	float3 normalTexture = tex2D(NormalSampler, IN.TexCoord.xy).xyz;
	if(flipGreen)normalTexture.g = 1-normalTexture.g;
	
	  float3 Tv = normalize(IN.viewTangent.xyz);
    float3 Bv = normalize(IN.viewBinormal.xyz);
    float3 Nv = normalize(IN.viewNormal.xyz);
	
	float3 N = viewNormalTangent(Tv, Bv, Nv, normalTexture, normalPower);

	// Look up in the litsphere!
	float3 C = tex2D(LightSampler, N.xy * 0.5 + 0.5).xyz;
	return float4( C, 1.0 );
}

////////////////////////
// Pixel shader
////////////////////////

technique litSphere
{
	pass P0
    {
    ZEnable = true;
    ZWriteEnable = true;
    ZFunc = LessEqual;
    CullMode = none;
    VertexShader = compile vs_2_0 BumpReflectVS();
    PixelShader = compile ps_2_0 BumpReflectPS();
    }
}

