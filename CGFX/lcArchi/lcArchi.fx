//lcShader.fx

string description = "Leo Covarrubias - blog.leocov.com";
string URL = "http://blog.leocov.com/search/label/hlsl";
string name = "lcArchi.fx";

#include "../_basic.cgh" // basic helper functions
#include "../_shading.cgh" // shading functions
#include "lcArchiAttr.cgh" // user tweakables, auto matricies and structs

bool TEXTURES____________________ = false;

sampler2D diffuseTextureSampler = sampler_state
{
  Texture       = <diffuseTexture>;
  MinFilter     = Linear;
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  MipMapLodBias = -0.5;
};

sampler2D specularTextureSampler = sampler_state
{
  Texture       = <specularTexture>;
  MinFilter     = Linear;
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  MipMapLodBias = -0.5;
};

sampler2D normalTextureSampler = sampler_state
{
  Texture       = <normalTexture>;
  MinFilter     = Linear;
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  MipMapLodBias = -0.5;
};

sampler2D occlusionTextureSampler = sampler_state
{
  Texture       = <occlusionTexture>;
  MinFilter     = Linear;
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  MipMapLodBias = -0.5;
};

sampler2D glowTextureSampler = sampler_state
{
  Texture       = <glowTexture>;
  MinFilter     = Linear;
  MagFilter     = Linear;
  MipFilter     = Linear;
  AddressU      = Wrap;
  AddressV      = Wrap;
  MipMapLodBias = -0.5;
};

samplerCUBE envCubeTextureSampler = sampler_state
{
  Texture   = <envCubeTexture>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Clamp;
  AddressV  = Clamp;
  AddressW  = Clamp;
};

sampler2D rimMaskTextureSampler = sampler_state
{
  Texture   = <rimMaskTexture>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};

sampler2D reflectivityMaskTextureSampler = sampler_state
{
  Texture   = <reflectivityMaskTexture>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};

sampler2D shadow0TextureSampler = sampler_state
{
  Texture   = <shadow0Texture>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};
sampler2D shadow1TextureSampler = sampler_state
{
  Texture   = <shadow1Texture>;
  MinFilter = None;
  MagFilter = None;
  MipFilter = None;
  AddressU  = Wrap;
  AddressV  = Wrap;
};
sampler2D shadow2TextureSampler = sampler_state
{
  Texture   = <shadow2Texture>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};
sampler2D shadow3TextureSampler = sampler_state
{
  Texture   = <shadow3Texture>;
  MinFilter = Linear;
  MagFilter = Linear;
  MipFilter = Linear;
  AddressU  = Wrap;
  AddressV  = Wrap;
};

//================================================
//     VERTEX SHADER
//================================================
vert2pixel VS(app2vert IN, uniform bool backface)
{
  vert2pixel OUT;

  OUT.hpos = mul(IN.Position, WorldViewProjection);
  
  if(outputInUvSpace)
  {
  	float2 uvBake = (outputToUvBake) ? IN.TexCoordBake : IN.TexCoord;
		float2 uvPos = uvBake * float2(2,-2*FIXCOORD) + float2(-1,1*FIXCOORD);
		OUT.hpos = float4(uvPos,0,1);
	}
  
  OUT.UV.xy = IN.TexCoord.xy;
  OUT.UV.zw = IN.TexCoordShadow.xy;

  OUT.worldNormal   = (backface) ? -1*mul(IN.Normal, WorldInverseTranspose).xyz : mul(IN.Normal, WorldInverseTranspose).xyz;
  OUT.worldTangent  = mul(IN.Tangent, WorldInverseTranspose).xyz;
  OUT.worldBinormal = mul(IN.Binormal, WorldInverseTranspose).xyz;

  OUT.WSPos = mul(IN.Position, World).xyz;
  OUT.eyeVec.xyz = ViewInverse[3].xyz - OUT.WSPos.xyz;

  return OUT;
}
//================================================
//     Pixel Shaders
//================================================

#include "lcArchiLists.cgh" //light and shadow lists
#include "lcArchiPSFull.cgh" //full shading

//================================================
//     Techniques
//================================================
technique ps_3_0 //onebit alpha testing
{
  pass front
  {
    CullMode = CCW;

    AlphaBlendEnable = true;
    AlphaFunc = Greater;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;

    VertexShader = compile vs_3_0 VS(false);
    PixelShader  = compile ps_3_0 PSFull();
  }
  pass back
  {
    CullMode = CW;

    AlphaBlendEnable = true;
    AlphaFunc = Greater;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;

    VertexShader = compile vs_3_0 VS(true);
    PixelShader  = compile ps_3_0 PSFull();
  }
}

technique _ //empty technique for Maya 2011
{
  pass P0
  {
    //empty
  }
}