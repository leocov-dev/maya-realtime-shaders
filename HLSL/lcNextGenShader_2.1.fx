///////////////////////////////////////////////////////////////////////////////////////
//  lcNextGenShader.fx
//
//  Author: Leonardo Covarrubias
//  Date: 11/02/2009
//  Contact: leo.covarrubias@live.com
//  Website: blog.leocov.com - www.leocov.com
//
//  Special thanks for inspiration and learing:
//
//  Ben Cloward - http://www.bencloward.com
//  Brice Vandemoortele - http://www.mentalwarp.com
//  Joel Styles - Fake Subsurface Scattering - www.jistyles.com
//  'The Renderman Sading Language Guide' - Rudy Cortes - www.rslprogramming.com - many basic and shading functions
//  RenderMonkey by ATI - http://developer.amd.com/gpu/rendermonkey/Pages/default.aspx
//  Charles Hollemeersch - litsphere shader - http://charles.hollemeersch.net/
//  'Advanced Game Development with Programmable Graphics Hardware' - Alan Watt, Fabio Policarpo - 1D texture mapping
//
//
//  This work is licensed under a  Creative Commons Attribution-Share Alike 3.0 Unported License
//  http://creativecommons.org/licenses/by-sa/3.0/
//
//  Change List:
//
//
//  1.1   - 11/16/2009 - initial release
//  1.3   - 01/29/2010 - fixed some minor issues with ambient color and order of operations
//  1.4   - 07/07/2010 - complete re-write to create parity with my lcUberShader_1.4.cgfx - no longer uses point lights, only 3 directional lights
//  1.4.5 - 07/08/2010 - took out the toon ramp, lit sphere and skin shader parts originaly from the lcUberShader_1.4.cgfx, they where not working in HLSL and I decided they are only marginaly useful
//
//  1.6   - 07/12/2010 - added switch to remove normal maps effect on specular (clearcoat) - added glow only preview technique - added depth preview technique
//  2.0   - 09/05/2010 - parity with lcUberShader_2.0 - linearLight light, tonemapping and illuminance loop amongst other changes - slight differences between CGFX and HLSL versions due to language differences
//  2.1   - 10/26/2010 - some bugs squashed - took things out of the light loop that should not have been inside
//
///////////////////////////////////////////////////////////////////////////////////////

#define MAX_LIGHTS 3

string description = "Leo Covarrubias - blog.leocov.com";
string URL = "http://blog.leocov.com/search/label/hlsl";

////////////////////////////////////////
//     User Tweakables                //
////////////////////////////////////////
float globalTonemap
<
  float UIMin     = 0.0;
  float UIMax     = 1.0;
  float UIStep    = 0.1;
  string UIName   = "Basic Global Tonemapping";
> = 0.0;

float exposure
<
  float UIMin     = -10.0;
  float UIMax     = 10.0;
  float UIStep    = 0.1;
  string UIName   = "Global Exposure";
> = 0.0;

bool linearLight
<
  string UIName   = "Linear Color Math?";
> = true;

//Backface Lighting - default(false) => backface lighting same as frontface
bool backFaceLighting
<
  string UIName   = "Back Face Lighting?";
> = false;

//Toggle diffuse map's alpha channel
bool alphaToggle
<
  string UIName   = "Alpha Toggle (diffuse.a)";
> = true;

//Ambeint
float3 ambientColor
<
  string UIName   = "Ambient Color";
  string Type     = "Color";
> = {0.0, 0.0, 0.0};

//Diffuse
float3 diffuseColor
<
  string UIName   = "Diffuse Color";
  string Type     = "Color";
> = {0.5, 0.5, 0.5};

float3 specularColor
<
  string UIName   = "Specular Color";
  string Type     = "Color";
> = {0.5, 0.5, 0.5};

float specularPower
<
  float UIMin     = 1.0;
  float UIMax     = 256.0;
  float UIStep    = 0.1;
  string UIName   = "Specular Power";
> = 30.0;

float tileTextures
<
  float UIMin     = 1.0;
  float UIMax     = 20.0;
  float UIStep    = 0.1;
  string UIName   = "UV Texture Tiling";
> = 1.0;

bool ________________________ <string UIName   = "spacerDiffuse";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Diffuse Textures
bool useDiffuseMap
<
  string UIName   = "Use A Diffuse Texture?";
> = false;

bool useHalfLambert
<
  string UIName   = "Use Half Lambert Diffuse?";
> = false;

texture diffuseMap
<
  string TextureType = "2D";
  string UIName       = "Diffuse Map";
>;

sampler2D diffuseMapSampler = sampler_state
{
  Texture       = <diffuseMap>;
  MinFilter     = Linear; //Anisotropic; //some people may need to change this to Linear
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  //MaxAnisotropy = 8;           //some people may need to comment this out
  MipMapLodBias = -0.5;
};

bool __________________________ <string UIName   = "spacerSpec";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Specular Additional Attributes
bool useSpecularMap
<
  string UIName = "Use A Specular Map?";
> = false;

bool useGlossAlpha
<
  string UIName = "Use a Gloss Map? (specular.a)";
> = false;

bool useAnisoSpec
<
  string UIName   = "Use Anisotropic Specular?";
> = false;

float anisoAngle
<
  float UIMin     = 0.0;
  float UIMax     = 3.15;
  float UIStep    = 0.1;
  string UIName   = "Anisotropic Angle";
> = 1.0;

bool useGlossySpec
<
  string UIName   = "Use Glossy (Toon) Specular?";
> = false;

float glossySharpness
<
  float UIMin     = -3;
  float UIMax     = 1;
  float UIStep    = 0.1;
  string UIName   = "Glossy Spec Edge Sharpness";
> = 0.85;

float specFresnelExp
<
    float UIMin = 0.0;
    float UIMax = 5.0;
    float UIStep = 0.1;
    string UIName = "Specular Fresnel Exponent";
> = 0.0;

float specFresnelScale
<
    float UIMin = 1.0;
    float UIMax = 15.0;
    float UIStep = 0.1;
    string UIName = "Specular Fresnel Multiplier";
> = 1.0;

texture specularMap
<
  string TextureType  = "2D";
  string UIName       = "Specular Map";
>;

sampler2D specularMapSampler = sampler_state
{
  Texture       = <specularMap>;
  MinFilter     = Linear;
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  MipMapLodBias = -0.5;
};

bool ___________________________ <string UIName   = "spacerN";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Normal Map Textures
bool useNormalMap
<
  string UIName   = "Use A Normal Map?";
> = false;

float normalIntensity
<
  float UIMin     = 0.0;
  float UIMax     = 3.0;
  float UIStep    = 0.1;
  string UIName   = "Normal Map Intensity";
> = 1.0;

bool flipGreen
<
  string UIName   = "Invert Normal Map Green Channel?";
> = false;

bool noSpecNormal
<
  string UIName   = "Exclude Specular from Normal Map";
> = false;

//Normalmap Sampler
texture normalMap
<
  string TextureType  = "2D";
  string UIName       = "Normal Map";
>;

sampler2D normalMapSampler = sampler_state
{
  Texture       = <normalMap>;
  MinFilter     = Linear; //Anisotropic; //some people may need to change this to Linear
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  //MaxAnisotropy = 8;           //some people may need to comment this out
  MipMapLodBias = -0.5;
};

bool ____________________________ <string UIName   = "spacerGlow";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Glow Map
bool useGlowMap
<
  string UIName = "Use A Glow Texture?";
> = false;

float glowIntensity
<
  float UIMin     = 0.0;
  float UIMax     = 10.0;
  float UIStep    = 0.1;
  string UIName   = "Glow Map Intensity";
> = 1.0;

texture glowMap
<
  string TextureType = "2D";
  string UIName       = "Glow Map";
>;

sampler2D glowMapSampler = sampler_state
{
  Texture   = <glowMap>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};

bool _____________________________ <string UIName   = "spacerRim";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Rim Light
bool useRimLight
<
  string UIName   = "Use Rim Light?";
> = false;

bool useRimLightSec
<
  string UIName   = "Use Secondary Rim Light?";
> = false;

float rimExponent
<
  float UIMin     = 0.0;
  float UIMax     = 5.0;
  float UIStep    = 0.1;
  string UIName   = "Rim Light Exponent";
> = 2.2;

float3 rimColor
<
  string UIName   = "Rim Light Color";
  string Type     = "Color";
> = {0.75, 0.9, 1.0};

float3 rimColorSec
<
  string UIName   = "Rim Light B Color";
  string Type     = "Color";
> = {0.75, 0.9, 1.1};

bool ______________________________ <string UIName   = "spacerHemi";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Hemispherical Ambient Shading
bool useAmbientHemi
<
  string UIName = "Use Hemispherical Ambient?";
> = false;

float3 skyColor
<
  string UIName   = "Hemispherical Sky Color";
  string Type     = "Color";
> = {0.7, 0.95, 1.0};

float3 groundColor
<
  string UIName   = "Hemispherical Ground Color";
  string Type     = "Color";
> = {0.23, 0.27, 0.12};

bool _______________________________ <string UIName   = "spacerCube";> = false;
////////////////////////////////////////////////////////////////////////////////////
//Cubemap for Reflections and Ambient Shading
bool useAmbCube
<
  string UIName = "Use Cubemap for Ambient?";
> = false;

float ambCubeScale
<
  float UIMin     = 0.0;
  float UIMax     = 50.0;
  float UIStep    = 0.1;
  string UIName   = "Ambient Cubemap Intensity";
> = 1;

bool useReflCube
<
  string UIName = "Use Cubemap for Reflection?";
> = false;

float reflCubeScale
<
  float UIMin     = 0.0;
  float UIMax     = 20.0;
  float UIStep    = 0.1;
  string UIName   = "Reflection Cubemap Intensity";
> = 1;

float reflFresnelExp
<
    float UIMin = 0.0;
    float UIMax = 5;
    float UIStep = 0.1;
    string UIName = "Reflection Fresnel Exponent";
> = 1.0;

float reflCubeGain
<
  float UIMin     = 0.1;
  float UIMax     = 0.9;
  float UIStep    = 0.1;
  string UIName   = "Reflection Cubemap Contrast";
> = 0.5;

float glossBlurWeight
<
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName = "Gloss Blurring Amount";
> = 0.0;

texture envCubeMap
<
    string UIName = "Reflection Env Map";
    string TextureType = "Cube";
>;

samplerCUBE envCubeMapSampler = sampler_state
{
  Texture   = <envCubeMap>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Clamp;
  AddressV  = Clamp;
};

bool _________________________________ <string UIName   = "spacerShadowMap";> = false;
//////////////////////////////////
////// Shadow Map Attributes /////
//////////////////////////////////

bool useShadowMap
<
  string UIName   = "Use a Shadow Map?";
> = false;

bool useAO
<
  string UIName = "AO in shadowMap.a?";
> = false;

bool useSecondaryUVAO
<
  string UIName = "AO uses secondary UV's?";
> = false;

bool vertAO
<
  string UIName = "AO in vertex color?";
> = false;

float aoDiffuseBlend
<
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName = "Weight of AO on Diffuse";
> = 0.5;

texture shadowMap
<
  string TextureType = "2D";
  string UIName       = "Shadow Map";
>;

sampler2D shadowMapSampler = sampler_state
{
  Texture   = <shadowMap>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};

bool __________________________________ <string UIName   = "spacerLights";> = false;
////////////////////////////////////////
////// Lights - position and color /////
////////////////////////////////////////

float4 light1Dir : DIRECTION
<
  string UIName = "Light 1 - Directional Light";
  string Space  = "World";
> = {0.0, -1.0, -1.0, 0.0};

float3 light1Color
<
  string UIName   = "Light1Color";
  string Type     = "Color";
> = {1.0, 1.0, 1.0};

float4 light2Dir : DIRECTION
<
  string UIName = "Light 2 - Directional Light";
  string Space  = "World";
> = {-1.0, 1.0, 1.0, 0.0};


float3 light2Color
<
  string UIName   = "Light2Color";
  string Type     = "Color";
> = {0.00, 0.00, 0.00};

float4 light3Dir : DIRECTION
<
  string UIName = "Light 3 - Directional Light";
  string Space  = "World";
> = {1.0, 1.0, 1.0, 0.0};


float3 light3Color
<
  string UIName   = "Light3Color";
  string Type     = "Color";
> = { 0.00, 0.00, 0.00};

////////////////////////////////////////
//     Auto Maxtricies                //
////////////////////////////////////////

float4x4 WorldViewProjection   : WorldViewProjection       < string UIWidget = "None"; >;
float4x4 WorldInverseTranspose : WorldInverseTranspose     < string UIWidget = "None"; >;
float4x4 ViewInverse           : ViewInverse               < string UIWidget = "None"; >;
float4x4 World                 : World                     < string UIWidget = "None"; >;

//====================================//
////// Structs /////////////////////////
//====================================//

// input from application
struct app2vert {
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord2: TEXCOORD1;
    float4 Normal   : NORMAL;
    float4 Binormal : BINORMAL;
    float4 Tangent  : TANGENT;
    float4 VertColor: COLOR0;
};

// output to fragment program
struct vert2pixel {
    float4 hpos          : POSITION;
    float2 UV            : TEXCOORD0;
    float2 UVsh          : TEXCOORD1;
    float3 worldNormal   : TEXCOORD2;
    float3 worldBinormal : TEXCOORD3;
    float3 worldTangent  : TEXCOORD4;
    float3 eyeVec        : TEXCOORD5;
    float3 vertColor     : TEXCOORD6;

};

//====================================//
//==== VERTEX SHADER =================//
//====================================//

vert2pixel VS(app2vert IN)
{
    vert2pixel OUT;

  OUT.vertColor = IN.VertColor;

  OUT.hpos = mul(IN.Position, WorldViewProjection);
  OUT.UV = IN.TexCoord.xy;
  OUT.UVsh = IN.TexCoord2.xy;

  OUT.worldNormal     = (mul(IN.Normal, WorldInverseTranspose).xyz);
  OUT.worldBinormal   = (mul(IN.Binormal, WorldInverseTranspose).xyz);
  OUT.worldTangent    = (mul(IN.Tangent, WorldInverseTranspose).xyz);

  float3 worldSpacePos  = mul(IN.Position, World).xyz;
  float3 worldCameraPos = ViewInverse[3].xyz;
  OUT.eyeVec = worldCameraPos - worldSpacePos;

  return OUT;
}

////////////////////////////////////////
////// Fragment Program Functions //////
////////////////////////////////////////

float3 ungamma22 (float3 input)
{
  if (any(input)&&linearLight) return pow(input,2.2); //seems pow() returns 1 if it evaluates to zero ??? - use any() to see if any component of float3 is non-zero
  return input;
}

float3 gamma22 (float3 input)
{
  if (any(input)&&linearLight) return pow(input,1/2.2); //seems pow() returns 1 if it evaluates to zero ??? - use any() to see if any component of float3 is non-zero
  return input;
}

float gamma (float val, float g)
{
  return pow(val,g);
}

float bias (float val, float b) //Rudy Cortes - The Renderman Shading Language Guide
{
  return (b>0) ? pow(abs(val),log(b) / log(0.5)) : 0;
}

float bias2 (float t, float a) //Rudy Cortes - The Renderman Shading Language Guide - for use with fresnelSchlick
{
    return pow(t,-(log(a)/log(2.0)));
}

float gain (float val, float g) //Rudy Cortes - The Renderman Shading Language Guide
{
  return 0.5 * ((val<0.5) ? bias(2.0*val, 1.0-g) : (2.0 - bias(2.0-2.0*val, 1.0-g)));
}

float3 filmicTonemap(float3 input)  //John Hable's filmic tonemap function with fixed values
{
  float A = 0.22;
  float B = 0.3;
  float C = 0.1;
  float D = 0.2;
  float E = 0.01;
  float F = 0.3;
  float linearLightWhite = 11.2;
  float3 Fcolor = ((input*(A*input+C*B)+D*E)/(input*(A*input+B)+D*F)) - E/F;
  float  Fwhite = ((linearLightWhite*(A*linearLightWhite+C*B)+D*E)/(linearLightWhite*(A*linearLightWhite+B)+D*F)) - E/F;
  return Fcolor/Fwhite;
}

float fresnel (float3 N, float3 V, float fresnelExp) //this is the most basic approximation of the fresnel function
{
    return max(0,pow(abs(1.0-dot(N,V)),fresnelExp));
}

float3 lambert (float3 L, float3 N)
{
  return max(0,dot(N,L));
}

float3 halfLambert (float3 L, float3 N) //Valve's Wrapped Diffuse Function
{
    return max(0,pow(dot(N,L)*0.5+.5,2));
}

float3 blinn (float3 L, float3 V, float3 N, float roughness)
{
  float3 H = normalize(L + V);
  float NdH = max(0,dot(N,H));
  return smoothstep(-0.1,0.1,dot(N,L)) * pow(NdH, roughness);
}

float3 glossy (float3 L, float3 V, float3 N, float roughness, float sharpness)
//glossy ceramic like specular highlight - not physically accurate - sourced from The Renderman Shading Language Guide
//values 0.18, 0.72 are arrived at empirically - roughness/3.333 brings the size into an equivalent range as blinn()
{
  float w = 0.18 * (1-sharpness);
  float3 H = normalize(L + V);
  float NdH = dot(N,H);
  return smoothstep(-0.1,0.1,dot(N,L)) * smoothstep(0.72-w,0.72+w,pow(max(0,NdH),roughness/3.333));
}

//adapted from anisotropic.fx from ati rendermonkey example file - based on Steve Westin Brushed Metal work
float3 anisotropic (float3 normalTexture, float3 L, float3 V, float3 N, float3 Bn, float3 Tn, float roughness, float angle)
{
  if(flipGreen)normalTexture.g = 1.0 - normalTexture.g;
  float cosA, sinA;
  sincos(angle, sinA, cosA); //gives back the sin of angle and cos of angle into sinA and cosA variables - faster than doing each seperatly
  float3 Ta = sinA*Tn + cosA*Bn;
  if(useNormalMap) Ta = sinA*(Tn*normalTexture.r) + cosA*(Bn*normalTexture.g); //vary the world normal and binormal by the texture normalmap x and y - but dont remap the normalmap to -1,1  keep as 0,1 - dont normalize it will negate the effect of multiply by scalar
  float cs = -dot(V, Ta);
  float sn = sqrt(1 - cs * cs);
  float cl = dot(L, Ta);
  float sl = sqrt(1 - cl * cl);
  
  if (useHalfLambert) return smoothstep(0,0.5,pow(dot(N,L)*0.5+.5,2) ) * (pow(max(0,cs*cl + sn*sl), roughness));
  
  return smoothstep(0,0.1,dot(N,L)) * (pow(max(0,cs*cl + sn*sl), roughness));
}

//this returns a float for mipmap level selection
float glossBlur (float specPow, float glossTex, float weight)
{
    float mipMax = 7;
    specPow = (specPow>=1) ? 1 : specPow;
    float G = (specPow*glossTex);
    return mipMax*G*weight;
}

//////////////////////////////////////////////////
//     Compartmentalized Shading Components     //
//////////////////////////////////////////////////

////////////////////////////////////////
// Tangent Space Normal Mapping
float3 normalsTangent (float4 normalTexture,
                       float3 Nn,
                       float3 Bn,
                       float3 Tn,
                       float3 V)
{
  if(flipGreen)normalTexture.g = 1.0 - normalTexture.g;

  if(backFaceLighting == true) Nn = faceforward(Nn,-V,Nn);
  if(useNormalMap)
  {
    normalTexture.rgb = normalTexture.rgb * 2.0 - 1.0;
    normalTexture.xy *= normalIntensity;
    if (normalIntensity > 0) Nn = normalize((normalTexture.x*Tn)+(normalTexture.y*Bn)+(normalTexture.z*Nn));
  }

  return Nn;
}

////////////////////////////////////////
// Ambient Shading - Uniform, Hemisphere, and Cubemap
float3 ambientEnv (float3 N)
{
  groundColor = ungamma22(groundColor);
  skyColor = ungamma22(skyColor);

  if(useAmbientHemi) return lerp(groundColor,skyColor,max(0,0.5*N.y+0.5));  //linearLightly interpolate between the two colors based on the World Normal's Y/up vector (shifted into 0-1 range)
  if(useAmbCube) return ungamma22(texCUBElod(envCubeMapSampler, float4(N,7.8)).rgb)*ambCubeScale;
  return 1;
}

////////////////////////////////////////
// Rim lighting effect
float3 rimLight (float3 N,
                 float3 V)
{
  rimColor = ungamma22(rimColor);
  //multiply a fresnel edge effect with 'N dot WorldUp'
  //creates a general rimlighting effect from a light upward and behind.
  float3 Fr = 0;
  if(useRimLight) Fr = fresnel(N,V,rimExponent)*rimColor*max(0,pow(dot(N,float3(0,1,0))*0.5+.5,2));//I use a half lambert style calculation on N.Y instead of standard lambert because it gives a softer blend across the surface
  return Fr;
}

float3 rimLightSec (float3 D,
                    float3 V,
                    float3 Nn)
{
  rimColorSec = ungamma22(rimColorSec);
  float3 Fr = 0;
  if (useRimLightSec) Fr = fresnel(Nn,V,rimExponent)*rimColorSec*(1.0-D);
  return Fr;
}

////////////////////////////////////////
// CubeMap Reflection
float3 reflectionCube (float4 specularTexture,
                       float3 N,
                       float3 V)
{
  float3 REnv = 0;
  float3 R = reflect(-V,N); //reflection vector
  float roughness = (useGlossAlpha) ? specularTexture.a : 1;
  float Fr = fresnel(N,V,reflFresnelExp);
  float miplvl = glossBlur (specularPower, roughness, glossBlurWeight); //set a mipmap level to give the impression of blur
  if(useReflCube) REnv = ungamma22(texCUBElod(envCubeMapSampler, float4(R,miplvl)).rgb);  //lets you choose a mip level for the cube map to make it appear blurred

  //apply a contrast function to increase or decrease contrast - most useful as an increase
  REnv.r = gain(REnv.r,reflCubeGain);
  REnv.g = gain(REnv.g,reflCubeGain);
  REnv.b = gain(REnv.b,reflCubeGain);

  return REnv*reflCubeScale*Fr;
}

////////////////////////////////////////
// Glow Texture / Incandescence
float3 glow (float3 glowTexture)
{
  if(useGlowMap) return glowTexture*glowIntensity;
  return 0;
}

////////////////////////////////////////
// Alpha Texture
float alpha (float4 diffuseTexture)
{
  float A = 1;
  if(alphaToggle) A = diffuseTexture.a;

  return A;
}

////////////////////////////////////////
//     Pixel Shaders                  //
////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
//     Normals Only
//////////////////////////////////////////////////////////////////////////////////////////////
float4 PSNormals (vert2pixel IN) : COLOR //visualize the normals in worldspace
{
  float2 UV = IN.UV*tileTextures;
  //////////////////////
  // Normal Component //
  float3 N = normalsTangent(tex2D(normalMapSampler, UV),
                            normalize(IN.worldNormal),
                            normalize(IN.worldBinormal),
                            normalize(IN.worldTangent),
                            normalize(IN.eyeVec.xyz));
  N = 0.5 * N + 0.5;  //I need to shift the normals into the 0-1 range for viewing as color
                      //otherwise they are in the -1 to 1 range
  /////////////////////
  // Alpha Component //
  float Alpha = alpha(tex2D(diffuseMapSampler, IN.UV.xy));

  return float4(N,Alpha);
}

//////////////////////////////////////////////////////////////////////////////////////////////
//     Full Shading
//////////////////////////////////////////////////////////////////////////////////////////////

float4 PSFull (vert2pixel IN) : COLOR
{
  float3 lights [MAX_LIGHTS][2]= { { normalize(-light1Dir.xyz), light1Color },
                                   { normalize(-light2Dir.xyz), light2Color },
                                   { normalize(-light3Dir.xyz), light3Color } };

  float3 V   = normalize(IN.eyeVec);
  float3 Nw  = normalize(IN.worldNormal);
  float3 Bw  = normalize(IN.worldBinormal);
  float3 Tw  = normalize(IN.worldTangent);

  float2 UV   = IN.UV*tileTextures;
  float2 UVsh = IN.UVsh;

  // Texture Components
  float4 Nt   = tex2D(normalMapSampler, UV);
  float4 Dt   = tex2D(diffuseMapSampler, UV);
  Dt.rgb = ungamma22(Dt.rgb);
  float4 St   = tex2D(specularMapSampler, UV);
  St.rgb = ungamma22(St.rgb);
  float4 Gt   = tex2D(glowMapSampler, UV);
  Gt.rgb = ungamma22(Gt.rgb);
  float4 Shwt = tex2D(shadowMapSampler, UVsh);
  if(!useShadowMap) Shwt.rgb = float3(1,1,1);
  if(!useAO) Shwt.a = 1.0;

  ambientColor  = ungamma22(ambientColor);
  diffuseColor  = ungamma22(diffuseColor);
  specularColor = ungamma22(specularColor);

  // Normal Component
  float3 N = normalsTangent(Nt,
                            Nw,
                            Bw,
                            Tw,
                            V);

  // Light Loop
  // Diffuse and Specular
  float3 Ci = 0;  //Incident Color
  float3 Cd = 0;  //Diffuse of lights only, no textures

  float Fr = fresnel(N,V,specFresnelExp)*specFresnelScale;

  float ShwtAO = Shwt.a;
  if(!useSecondaryUVAO&&useAO) ShwtAO = tex2D(shadowMapSampler, UV).a;
  float3 AO = (vertAO) ? IN.vertColor : ShwtAO;
  float3 Shadow = 1;

  if(useGlossAlpha) specularPower*=pow((St.a+1),2);  //here i take the aproach of increasing the specularPower by the alpha instead of simply multiplying and reducing specPower - this avoids issues when specPower aproaches Zero - using pow() is arbitrary but creates a visualy pleasing distinction between sizes
  if(useSpecularMap) specularColor*=St.rgb;
  if(specularPower<1)specularColor=0; //avoids problems with small specularPower values

  for ( int i = 0; i < MAX_LIGHTS; i++  ) //Illuminance loop
  {
    if(i==0) Shadow = Shwt.r;
    if(i==1) Shadow = Shwt.g;
    if(i==2) Shadow = Shwt.b;

    float3 L = lights[i][0];
    float3 Lc = ungamma22(lights[i][1]); //light color is an interface color swatch and needs to be gamma corrected

    float3 Diffuse  = lambert(L, N);
    if (useHalfLambert) Diffuse = halfLambert(L, N);
 
    //new Normal and Normalmap variables allow seperating normalmaps on specular vs diffuse and other effects
    float3 specN = N;
    float3 specNt = Nt.rgb;
    if (noSpecNormal){
      specN = Nw;
      specNt = float3(0.5,0.5,1);
    }

    float3 Specular = blinn(L, V, specN, specularPower);
    if(useAnisoSpec)  Specular = anisotropic(specNt, L, V, specN, Bw, Tw, specularPower, anisoAngle);
    if(useGlossySpec) Specular = glossy (L, V, specN, specularPower, glossySharpness);

    Diffuse *= Lc;
    Cd += Diffuse; //store a variable of just the diffuse light intensity/colors
    Diffuse *= (useDiffuseMap) ? Dt.rgb : diffuseColor;

    Specular *= Lc* Fr * specularColor;

    Ci += (Diffuse+Specular)*Shadow*saturate(lerp(1.0,AO.x,aoDiffuseBlend));
    Shadow = 1;
  }

  // Rim Light Component
  Ci += rimLight(N,
                 V);
  Ci += rimLightSec (Cd,  //use Cd instead of Ci to mask the rim light by only the diffuse light intensity
                     V,
                     N);

  // Cubemap Reflection Component
  Ci += reflectionCube(St,
                       N,
                       V) * AO;

  //Ambient Component
  ambientColor *= ambientEnv(N)*AO;
  Ci += (useDiffuseMap) ? ambientColor*Dt.rgb : ambientColor*diffuseColor;

  //Glow Component
  Ci += glow(Gt.rgb);

  // Alpha Component
  float Oi = alpha(Dt);

  //Ci = gamma22(Ci);  //re-apply gamma, without tonemapping
  Ci = lerp(gamma22(Ci*pow(2,exposure)),gamma22(filmicTonemap(Ci*pow(2,exposure))),globalTonemap);

  return float4(Ci,Oi);  //Incident Color and Incident Opacity
}

////////////////////////////////////////
//     Techniques                     //
////////////////////////////////////////

technique Full_1_Bit_Alpha //onebit alpha testing
{
  pass one
  {
    ZEnable = true;
    ZWriteEnable = true;
    ZFunc = LessEqual;
    CullMode = none;
    AlphaTestEnable = true;
    AlphaFunc = Greater;
    AlphaRef = 127;
    VertexShader = compile vs_3_0 VS();
    PixelShader  = compile ps_3_0 PSFull();
  }
}

technique Full_8_Bit_Alpha //8bit alpha blending - has problems in maya viewport with sorting
{
  pass one
  {
    CullMode = none;
    ZEnable = true;
    ZWriteEnable = true;
    ZFunc = LessEqual;
    AlphaBlendEnable = true;
    AlphaTestEnable = true;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;
    VertexShader = compile vs_3_0 VS();
    PixelShader  = compile ps_3_0 PSFull();
  }
}

technique World_Normals
{
  pass one
  {
    CullMode = none;
    ZEnable = true;
    ZWriteEnable = true;
    ZFunc = LessEqual;
    VertexShader = compile vs_3_0 VS();
    PixelShader  = compile ps_3_0 PSNormals();
  }
}

technique _ //empty technique for Maya 2011
{
  pass one
  {
    //empty
  }
}