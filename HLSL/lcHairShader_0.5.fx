///////////////////////////////////////////////////////////////////////////////////////
//  lcHairShader.fx
//
//  Version: 0.5
//
//  Author: Leonardo Covarrubias
//  Date: 11/02/2009
//  Contact: leo.covarrubias@live.com
//  Website: blog.leocov.com - www.leocov.com
//
//  Basic Shader with support for specific file structures
//  3 lights integrated - deactivate unused lights by turning their colors to black
//  1 Directional light, 2 Point lights
//
//  
///////////////////////////////////////////////////////////////////////////////////////

/************* TWEAKABLES **************/
//Ambeint
half3 ambientColor : Ambient
<
        string UIName = "Ambient Color";
> = {0.0f, 0.0f, 0.0f};

//Diffuse
half3 diffuseColor : Diffuse
<
    string UIName = "Diffuse Color";
> = {0.5f, 0.5f, 0.5f};

//Dye Map
half3 dyeColor
<
    string UIName = "Dye Color";
> = {1.0f, 0.0f, 0.0f};

//Specularity
half3 specularColor : Specular
<
    string UIName = "Specular Color";
> = {0.5f, 0.5f, 0.5f};

half glossiness
<
    string UIWidget = "slider";
    half UIMin = 1.0;
    half UIMax = 512.0;
    half UIStep = 0.1;
    string UIName = "glossiness";
> = 33.0;

half anisoAngle
<
    string UIWidget = "slider";
    string UIName = "anisotropic angle";
> = 1.0;

//Diffuse Textures
bool useDiffuseTexture
<
    string UIName = "Use A Diffuse Texture?";
> = false;

bool transparencyInDiffuse
<
    string UIName = "Use Diffuse Alpha for Transparency";
> = false;

bool specularInDiffuse
<
    string UIName = "Specual Map is in the Diffuse's Alpha";
> = false;

bool dyemapInDiffuse
<
    string UIName = "Dye Map is in the Diffuse's Alpha";
> = false;

texture diffuseMap
<
    string name = "default_color.dds";
    string UIName = "Diffuse Texture";
    string TextureType = "2D";
>;

//Specular Texture
bool useSpecularTexture
<
    string UIName = "Use A Specular Texture?";
> = false;

texture specularMap
<
    string name = "default_specular.dds";
    string UIName = "Specular Texture";
    string TextureType = "2D";
>;

//Normal Textures
bool useNormalTexture
<
    string UIName = "Use A Normal Texture?";
> = false;

bool specularInNormal
<
    string UIName = "Specual Map is in the Normal's Alpha";
> = false;

half normalPower
<
    string UIWidget = "slider";
    half UIMin = 0.0;
    half UIMax = 10.0;
    half UIStep = 0.1;
    string UIName = "Normal Map Intensity";
> = 1.0;

bool flipGreen
<
    string UIName = "Invert Normal Map Green Channel?";
> = true;

texture normalMap
<
    string name = "default_bump_normal.dds";
    string UIName = "Normal Map";
    string TextureType = "2D";
>;

//Light Vars
bool useLightFalloff
<
    string UIName = "Use Linear Light Falloff?";
> = false;

half decayScale
<
    string UIWidget = "slider";
    half UIMin = 1.0;
    half UIMax = 512.0;
    half UIStep = 0.1;
    string UIName = "Light Decay Scale";
> = 20.0;

/************** light info **************/

half4 light1Dir : Direction   // Light 1 is a directional light
<
    string UIName = "Light 1 Directional Light";
    string Object = "DirectionalLight";
    string Space = "World";
    int refID = 0;
> = {100.0f, 100.0f, 100.0f, 0.0f};


half3 light1Color
<
    int LightRef = 0;
> = { 1.0f, 1.0f, 1.0f};

half4 light2Pos : POSITION
<
    string UIName = "Light 2 Position";
    string Object = "PointLight";
    string Space = "World";
    int refID = 1;
> = {-100.0f, -100.0f, -100.0f, 0.0f};


half3 light2Color
<
    int LightRef = 1;
> = { 0.00f, 0.00f, 0.00f};

half4 light3Pos : POSITION
<
    string UIName = "Light 3 Position";
    string Object = "PointLight";
    string Space = "World";
    int refID = 2;
> = {100.0f, 0.0f, -100.0f, 0.0f};


half3 light3Color
<
    int LightRef = 2;
> = { 0.00f, 0.00f, 0.00f};



/****************************************************/
/********** SAMPLERS ********************************/
/****************************************************/

sampler2D diffuseMapSampler = sampler_state
{
    Texture       = <diffuseMap>;
    MinFilter     = Anisotropic;
    MaxAnisotropy = 8;
    MagFilter     = Linear;
    MipFilter     = Linear;
    AddressU      = Wrap;
    AddressV      = Wrap;
};

sampler2D specularMapSampler = sampler_state
{
    Texture       = <specularMap>;
    MinFilter     = Anisotropic;
    MaxAnisotropy = 8;
    MagFilter     = Linear;
    MipFilter     = Linear;
    AddressU      = Wrap;
    AddressV      = Wrap;
};

sampler2D normalMapSampler = sampler_state
{
    Texture       = <normalMap>;
    MinFilter     = Anisotropic;
    MaxAnisotropy = 8;
    MagFilter     = Linear;
    MipFilter     = Linear;
    AddressU      = Wrap;
    AddressV      = Wrap;
};

/***********************************************/
/*** automatically-tracked "tweakables" ********/
/***********************************************/

half4x4 WorldViewProjection     : WorldViewProjection   < string UIWidget = "None"; >;
half4x4 WorldInverseTranspose   : WorldInverseTranspose < string UIWidget = "None"; >;
half4x4 ViewInverse             : ViewInverse           < string UIWidget = "None"; >;
half4x4 World                   : World                 < string UIWidget = "None"; >;

/****************************************************/
/********** CG SHADER FUNCTIONS *********************/
/****************************************************/

// input from application
    struct a2v {
    half4 position  : POSITION;
    half2 texCoord  : TEXCOORD0;
    half3 normal    : NORMAL;
    half3 binormal  : BINORMAL;
    half3 tangent   : TANGENT;
};


// output to fragment program
struct v2f {
        half4 position        : POSITION;
        half2 texCoord        : TEXCOORD0;
        half3 light1Vec       : TEXCOORD1;
        half3 light2Vec       : TEXCOORD2;
        half3 light3Vec       : TEXCOORD3;
        half3 worldNormal     : TEXCOORD4;
        half3 worldBinormal   : TEXCOORD5;
        half3 worldTangent    : TEXCOORD6;
        half3 eyeVec          : TEXCOORD7;

};



/**************************************/
/***** VERTEX SHADER ******************/
/**************************************/

v2f v(a2v In, uniform half4 light1Dir, uniform half4 light2Pos, uniform half4 light3Pos)
{
    v2f Out;
    Out.worldNormal = (mul(In.normal, WorldInverseTranspose).xyz);
    Out.worldBinormal = (mul(In.binormal, WorldInverseTranspose).xyz);
    Out.worldTangent = (mul(In.tangent, WorldInverseTranspose).xyz);
    half3 worldSpacePos = mul(In.position, World);
    Out.light1Vec = -light1Dir;
    Out.light2Vec = light2Pos - worldSpacePos;
    Out.light3Vec = light3Pos - worldSpacePos;
    Out.eyeVec = ViewInverse[3] - worldSpacePos;
    Out.texCoord.xy = In.texCoord;
    Out.position = mul(In.position, WorldViewProjection);
    return Out;
}




/**************************************/
/***** FRAGMENT PROGRAM ***************/
/**************************************/

half3 blinn(half3 L, half3 V, half3 N, half gloss, half3 lightCol, half atten)
{
    half3 H = normalize(L + V);
    half NdH = saturate(dot(N,H));
    return pow(NdH, gloss)*lightCol*atten;
}

half3 phong(half3 L, half3 V, half3 N, half gloss, half3 lightCol, half atten)
{
    half3 R = -reflect(L,N);
    half RdV = saturate(dot(R,V));  
    return pow(RdV, gloss)*lightCol*atten;
}

half3 anisotropic (half3 L, half3 V, half3 N, half3 Bn, half3 Tn, half gloss, half angle, half3 lightCol, half atten)
{
	half cosA, sinA;
    sincos(angle, sinA, cosA);
    half3 Ta = sinA * Tn + cosA * Bn;
    half cs = -dot(V, Ta);
    half sn = sqrt(1 - cs * cs);
    half cl = dot(L, Ta);
    half sl = sqrt(1 - cl * cl);
    return pow(saturate(cs*cl + sn*sl), glossiness)*lightCol*atten;
}

half3 lambert (half3 L, half3 N, half3 lightCol, half atten)
{
    return saturate(dot(N,L)) * lightCol * atten;
}

half attenuation (half3 L, half scale)
{
    half d = length(L);
    return (1/d)*scale;
}

half3 normalMapTangent (half3 Tn, half3 Bn, half3 Nn, half normPow, half4 normalTexture)
{
    normalTexture.rgb = normalTexture.rgb * 2 - 1;
    normalTexture.xy *= normPow;
    half3 N = normalize((normalTexture.x*Tn)+(normalTexture.y*-Bn)+(normalTexture.z*Nn));
    if (normPow == 0) N = Nn;

    return N;
}

half3 ambient (half3 ambCol, half3 ambEnv)
{
    return ambCol*ambEnv;
}

half3 dyemap (half3 dyeCol, half mask)
{
    return clamp((dyeCol+mask),0,1);
}

//////////////////////
// Shader Body
//////////////////////

half4 hair (v2f In, uniform half3 light1Color, uniform half3 light2Color, uniform half3 light3Color) : COLOR
{
    half4 normalTexture   = tex2D(normalMapSampler, In.texCoord.xy);
    half4 diffuseTexture  = tex2D(diffuseMapSampler, In.texCoord.xy);
    half4 specularTexture     = tex2D(specularMapSampler, In.texCoord.xy);
    if(flipGreen)normalTexture.g = 1-normalTexture.g;

    half3 Nn = normalize(In.worldNormal);
    half3 Tn = normalize(In.worldTangent);
    half3 Bn = normalize(In.worldBinormal);
    half3 V  = normalize(In.eyeVec.xyz);
    half3 L1 = normalize(In.light1Vec.xyz);
    half3 L2 = normalize(In.light2Vec.xyz);
    half3 L3 = normalize(In.light3Vec.xyz);
	
    half3 N = Nn;

    //Normal Maps
    if(useNormalTexture) N = normalMapTangent(Tn, Bn, Nn, normalPower, normalTexture);

    //Ambient + Amb Env
    half3 Am = ambient(ambientColor,1);
    if(useDiffuseTexture) Am*=diffuseTexture;

    //lightAttenuation
    half3 atten = {1.0f,1.0f,1.0f};
    if(useLightFalloff){
        atten.x = 1.0;//attenuation (In.light1Vec.xyz, decayScale);
        atten.y = attenuation (In.light2Vec.xyz, decayScale);
        atten.z = attenuation (In.light3Vec.xyz, decayScale);
    }

    //Diffuse
    half3 D = (lambert (L1, N, light1Color, atten.x)
              + lambert (L2, N, light2Color, atten.y)
              + lambert (L3, N, light3Color, atten.z));
    if(!useDiffuseTexture) D *= diffuseColor;
    if(useDiffuseTexture) D *= diffuseTexture;
    if(dyemapInDiffuse) D *= dyemap(dyeColor,diffuseTexture.a);

    //Specular
    half3 S = (anisotropic(L1, V, N, Bn, Tn, glossiness, anisoAngle, light1Color, atten.x)+
               anisotropic(L2, V, N, Bn, Tn, glossiness, anisoAngle, light2Color, atten.y)+
               anisotropic(L3, V, N, Bn, Tn, glossiness, anisoAngle, light3Color, atten.z));
    if(useSpecularTexture) S *= saturate(specularTexture);
    if(specularInNormal) S *= saturate(normalTexture.a);
    if(specularInDiffuse) S *= saturate(diffuseTexture.a);
    
    if(glossiness<=1) specularColor *= glossiness;
    S *= specularColor;

    //Alpha
    half A = 1;
    if(transparencyInDiffuse && useDiffuseTexture) A = diffuseTexture.a;
    if(specularInDiffuse || dyemapInDiffuse || !useDiffuseTexture) A = 1;

    //return all
    half3 C = Am + D + S;
    return half4 (C.rgb,A);
}

/****************************************************/
/********** TECHNIQUES ******************************/
/****************************************************/

technique Hair_SM3
{
    pass one
    {
    VertexShader = compile vs_3_0 v(light1Dir,light2Pos,light3Pos);
    ZEnable = true;
    ZWriteEnable = true;
    ZFunc = LessEqual;
    CullMode = none;
    AlphaBlendEnable = true;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;
    PixelShader = compile ps_3_0 hair(light1Color,light2Color,light3Color);
    }
}