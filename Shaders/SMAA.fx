/**
 *                  _______  ___  ___       ___           ___
 *                 /       ||   \/   |     /   \         /   \
 *                |   (---- |  \  /  |    /  ^  \       /  ^  \
 *                 \   \    |  |\/|  |   /  /_\  \     /  /_\  \
 *              ----)   |   |  |  |  |  /  _____  \   /  _____  \
 *             |_______/    |__|  |__| /__/     \__\ /__/     \__\
 *
 *                               E N H A N C E D
 *       S U B P I X E L   M O R P H O L O G I C A L   A N T I A L I A S I N G
 *
 *                               for ReShade 3.0+
 *
 *                      Optimized for Performance & Image Quality..
 *          10%~ GPU & 25%~ CPU time saved (varies by game, shaders in use and specs.)
 *              Optimized defaults & param ranges for better customization.
 *            Depth pass is disabled, optionally re-enabled through preprocessor.
 *              (Barely useful but immense performance hit, more in description.)
 *                  Swapped descriptions with more practical counterparts.
 */

//------------------- Preprocessor Settings -------------------

#if !defined(SMAA_PRESET_LOW) && !defined(SMAA_PRESET_MEDIUM) && !defined(SMAA_PRESET_HIGH) && !defined(SMAA_PRESET_ULTRA)
#define SMAA_PRESET_CUSTOM // Do not use a quality preset by default
#endif

/*Mostly unnecessary pass that eats away performance even when not using Predication.
With this, Performance cost is roughly only 2x Max quality FXAA (Preset 39) which prides itself on being fast. 
Almost industinguishable Image Quality, edge cases being very low contrast environments.
Can be enabled by setting it to 1 in Pre-processor settings.
*/
#ifndef SMAA_ENABLE_DEPTH_BUFFER
	#define SMAA_ENABLE_DEPTH_BUFFER 0 
#endif
//----------------------- UI Variables ------------------------

#include "ReShadeUI.fxh"

#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	uniform int EdgeDetectionType < __UNIFORM_COMBO_INT1
		ui_items = "Luminance edge detection\0Color edge detection\0Depth edge detection (Use it to preview Predication contribution in debug output.)\0";
		ui_label = "Avoid Depth use either 2 with Predication";
	> = 1;
#else
	uniform int EdgeDetectionType < __UNIFORM_COMBO_INT1
		ui_items = "Luminance edge detection\0Color edge detection\0";
		ui_label = "Edge Detection Type Color is recommended";
	> = 1;
#endif


#ifdef SMAA_PRESET_CUSTOM
uniform float EdgeDetectionThreshold < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.04; ui_max = 0.20; ui_step = 0.001;
	ui_tooltip = "0.04 - 0.10 recommended, higher misses more edges.";
	ui_label = "Edge Detection Threshold";
> = 0.05;

	#if (SMAA_ENABLE_DEPTH_BUFFER==1)
		uniform float DepthEdgeDetectionThreshold < __UNIFORM_DRAG_FLOAT1
			ui_min = 0.002; ui_max = 0.10; ui_step = 0.001;
			ui_tooltip = "Minimum is recommended, check in debug mode for any artifacts.";
			ui_label = "Depth Edge Detection Threshold";
		> = 0.002;
	#endif

uniform int MaxSearchSteps < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 112;
	ui_label = "Max Search Steps";
	ui_tooltip = "The radius SMAA will search for aliased edges, 32 is Ultra preset, 16 very similar.";
> = 32;

uniform int MaxSearchStepsDiagonal < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 20;
	ui_label = "Max Search Steps Diagonal";
	ui_tooltip = "The radius SMAA will search for diagonal aliased edges, 16 is Ultra preset, 8 perceivably the same.";
> = 8;

uniform int CornerRounding < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 100;
	ui_label = "Corner Rounding";
	ui_tooltip = "The percent of anti-aliasing to apply to corners. 25 is best across SMAA presets. Detrimental to text.";
> = 25;

	#if (SMAA_ENABLE_DEPTH_BUFFER==1)
		uniform bool PredicationEnabled < __UNIFORM_INPUT_BOOL1
			ui_label = "Enable Predicated Thresholding";
			ui_tooltip = "Combine Color/Luma edge detection with Depth edge detection. When enabling, stick to optimized defaults.\n"
						 "        If you untick this, Set SMAA_ENABLE_DEPTH_BUFFER to 0 in Preprocessor for free performance.       ";
		> = true;

		uniform float PredicationThreshold < __UNIFORM_DRAG_FLOAT1
			ui_min = 0.005; ui_max = 1.00; ui_step = 0.01;
			ui_tooltip = "Higher values give less weight to depth edges. Keep at minimum to have best of both worlds.";
			ui_label = "Predication Threshold";
		> = 0.005;

		uniform float PredicationScale < __UNIFORM_SLIDER_FLOAT1
			ui_min = 1; ui_max = 8;
			ui_tooltip = "Multiply luma/color edge detection threshold by this value when using predication.";
			ui_label = "Predication Scale";
		> = 1.2;

		uniform float PredicationStrength < __UNIFORM_SLIDER_FLOAT1
			ui_min = 0; ui_max = 4;
			ui_tooltip = "How much to locally decrease the threshold.";
			ui_label = "Predication Strength";
		> = 4.0;
	#endif
#endif

uniform int DebugOutput < __UNIFORM_COMBO_INT1
	ui_items = "None\0View edges\0View weights\0";
	ui_label = "Debug Output";
> = false;

#ifdef SMAA_PRESET_CUSTOM
	#define SMAA_THRESHOLD EdgeDetectionThreshold
	#define SMAA_MAX_SEARCH_STEPS MaxSearchSteps
	#define SMAA_MAX_SEARCH_STEPS_DIAG MaxSearchStepsDiagonal
	#define SMAA_CORNER_ROUNDING CornerRounding
		#if (SMAA_ENABLE_DEPTH_BUFFER==1)
			#define SMAA_DEPTH_THRESHOLD DepthEdgeDetectionThreshold
			#define SMAA_PREDICATION PredicationEnabled
			#define SMAA_PREDICATION_THRESHOLD PredicationThreshold
			#define SMAA_PREDICATION_SCALE PredicationScale
			#define SMAA_PREDICATION_STRENGTH PredicationStrength
			#define SMAA_DISABLE_DEPTH_BUFFER2 DisableDepthBuffer2
		#else
			#define SMAA_PREDICATION false
		#endif
#endif

#define SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define SMAA_CUSTOM_SL 1

#define SMAATexture2D(tex) sampler tex
#define SMAATexturePass2D(tex) tex
#define SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define SMAASampleLevelZeroPoint(tex, coord) SMAASampleLevelZero(tex, coord)
#define SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define SMAASample(tex, coord) tex2D(tex, coord)
#define SMAASamplePoint(tex, coord) SMAASample(tex, coord)
#define SMAASampleOffset(tex, coord, offset) tex2Doffset(tex, coord, offset)
#define SMAA_BRANCH [branch]
#define SMAA_FLATTEN [flatten]

#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
#endif

#include "SMAA.fxh"
#include "ReShade.fxh"

// Textures

#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	texture depthTex < pooled = true; >
	{ 
		Width = BUFFER_WIDTH;   
		Height = BUFFER_HEIGHT;   
		Format = R16F;  
	};
#endif

texture edgesTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RG8;
};
texture blendTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture areaTex < source = "AreaTex.png"; >
{
	Width = 160;
	Height = 560;
	Format = RG8;
};
texture searchTex < source = "SearchTex.png"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};

// Samplers

#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	sampler depthLinearSampler
	{
		Texture = depthTex;
	};
#endif

sampler colorGammaSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler colorLinearSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = true;
};
sampler edgesSampler
{
	Texture = edgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler blendSampler
{
	Texture = blendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler areaSampler
{
	Texture = areaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler searchSampler
{
	Texture = searchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};

// Vertex shaders

void SMAAEdgeDetectionWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}

void SMAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}

void SMAANeighborhoodBlendingWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

// Pixel shaders

#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	float SMAADepthLinearizationPS(
		float4 position : SV_Position,
		float2 texcoord : TEXCOORD) : SV_Target
	{
		return ReShade::GetLinearizedDepth(texcoord);
	}
#endif

float2 SMAAEdgeDetectionWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	if (EdgeDetectionType == 0 && SMAA_PREDICATION == true)
		return SMAALumaEdgePredicationDetectionPS(texcoord, offset, colorGammaSampler, depthLinearSampler);
	else
#endif
	if (EdgeDetectionType == 0)
		return SMAALumaEdgeDetectionPS(texcoord, offset, colorGammaSampler);
#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	if (EdgeDetectionType == 2)
		return SMAADepthEdgeDetectionPS(texcoord, offset, depthLinearSampler);

	if (SMAA_PREDICATION)
		return SMAAColorEdgePredicationDetectionPS(texcoord, offset, colorGammaSampler, depthLinearSampler);
	else
#endif
		return SMAAColorEdgeDetectionPS(texcoord, offset, colorGammaSampler);
}
float4 SMAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaSampler, searchSampler, 0.0);
}

float3 SMAANeighborhoodBlendingWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
	if (DebugOutput == 1)
		return tex2D(edgesSampler, texcoord).rgb;
	if (DebugOutput == 2)
		return tex2D(blendSampler, texcoord).rgb;

	return SMAANeighborhoodBlendingPS(texcoord, offset, colorLinearSampler, blendSampler).rgb;
}

// Rendering passes

technique SMAA
< ui_tooltip =        
	"                    Tuned defaults for best performance & image quality, relaxed parameter ranges.                        \n"
	"  Skips Depth Pass (from 4 to 3 passes) for -|10%~ GPU & 25%~ CPU|- time saved YMMV by game, other shaders in use and specs. \n"
	"                      Set SMAA_ENABLE_DEPTH_BUFFER to 1 in preprocessor settings to re-enable.                               \n"
	"                 Should only be enabled for Predication (used in tandem with Color/Luma edge detection)                      \n"
	"        Predication isn't worth the performance loss but can detect a few low contrast edges normal detection can miss.      \n"
	"Only useful in low contrast, washed out scenes such as heavy fog/rainy weather, where you can barely make out edges visually.\n"
	"              SMAA is best used in combination with (in Load order): CMAA (Lunacy port) > SMAA > FXAA > CAS                  \n";
>

{
#if (SMAA_ENABLE_DEPTH_BUFFER==1)
	pass LinearizeDepthPass
	{
		VertexShader = PostProcessVS;
		PixelShader = SMAADepthLinearizationPS;
		RenderTarget = depthTex;
	}
#endif
	pass EdgeDetectionPass
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = SMAAEdgeDetectionWrapPS;
		RenderTarget = edgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass BlendWeightCalculationPass
	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = blendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass NeighborhoodBlendingPass
	{
		VertexShader = SMAANeighborhoodBlendingWrapVS;
		PixelShader = SMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
		SRGBWriteEnable = true;
	}
}
