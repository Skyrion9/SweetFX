## SMAA modification

Inspired by the [FSMAA](https://github.com/lordbean-git/reshade-shaders/tree/main) modification by lordbean, disabling the rarely-needed depth pass by default. This depth pass incurs a noticable performance penalty (25%~ CPU & 10%~ GPU time on Reshade 6.3, R5 1600 and RX 6700) even when it's not in use. It can be re-enabled through Preprocessor settings if desired.

* Depth costs performance regardless of it actually being used before this modification. Now user has the ability to enable or disable it through Preprocessor settings to their taste.
* Comes with optimized defaults for best balance of image quality (IQ) and performance. 
* Carefully tweaked predication settings to use best of both color/luma and depth edge detections for those seeking maximum IQ regardless of performance cost.
* Edited descriptions with easier to understand, more practical counterparts.
* SMAA is often the preferred solution to bad AA implementations, usually that of badly optimized games, so every bit of performance counts.
* Note that this might be slower than the stock SMAA shader due to tweaked parameters, change `Edge Detection Threshold` to `0.1` for apples to apples comparison.
* Optional preset included for a very decent AA+CAS combo.

Note that your mileage may vary depending on your specs, game in question, resolution, shader stack etc., check Statistics tab in Reshade to compare performance difference between settings. You generally won't see a difference in FPS directly if you're already hitting your max. Less work on SMAA means more resources for other things, so it'll benefit your minimum FPS in the very least. It can be a few FPS difference in GPU limited/struggling systems.

## Short guide

You should use `Debug Output` in `View Weights` mode to see which areas have AA applied to them. Using this, tweak `Edge Detection Threshold` to your taste. It has a direct impact on IQ as well as performance.

See "When to enable depth pass" below for predication settings and whether you need them at all.

Use provided preset if you're lazy. More on this at Extras below.

## When to enable depth pass

Depth edge detection by itself is largely useless as it misses vast majority of edges in the scene, generally only highlighting outer edges of large objects, ignoring any fine aliasing in the details.

Its main function is to be used in Predication, which allows you to blend either Color or Luma edge detection techniques together with Depth edge detection.

This is useful for low contrast & visibility scenes with excessive amounts of transparency/postFX on the screen. Examples include : Desert with sandstorm, swamp with fog, heavy rain with fog, scene with washed-out or bleached colors with very little contrast. In these cases, normal edge detection methods might fail so it's feasible to enable Depth pass and use predication along with Color or Luminance based edge detection to have best of both worlds.

Changing `SMAA_ENABLE_DEPTH_BUFFER` to `1` in Preprocessor definitions enables depth pass and predication that depends on it. You'll notice Predication is already enabled with already tweaked parameters. It is recommended to keep it as-is. Set `SMAA_ENABLE_DEPTH_BUFFER` back to `0` if you deem predication unnecessary to save performance. Among predication settings, you're encouraged to only change `Predication Scale` slightly. Use `View Weights` same as before to check if it does anything for your scene in particular.

## Extras

An optional preset is included (Drop it in reshade-presets folder) to make use of the following shaders with tweaked parameters: 
CMAA from [Insane-Shaders](https://github.com/LordOfLunacy/Insane-Shaders/tree/master) > SMAA > FXAA > CAS

I've found CMAA to be exceptionally good at smoothing stair-stepped edges (follow above link to download.) SMAA covers up what CMAA misses and a light amount of FXAA helps with shimmering during motion. Finally CAS is applied to selectively sharpen the image. This combination yields very good IQ, you may want to tweak FXAA subpixel to your taste (more or less blur to counteract shimmering.)

It's recommended to use any color/contrast shaders before the AA shaders.


## The original readme below

          .-.                   .  .---..   .
         (   )                 _|_ |     \ / 
          `-..  .    ._.-.  .-. |  |---   /  
         (   )\  \  / (.-' (.-' |  |     / \ 
          `-'  `' `'   `--' `--'`-''    '   '
                    Shader Suite
                    by CeeJay.dk                    
     

## Introduction

SweetFX is a suite of effects for universal image improvement and tweaking.

This is the Reshade based version.

Previous SweetFX 1.x versions came bundled with InjectSMAA and used that to apply the shaders to the games.
However SweetFX have been a part of Reshade ever since the first version of Reshade (and even before that when Crosire was working on EFX)

Starting with Reshade 4.6 most shaders move out of the reshade-shader package and into their own, managed directly by the shader developers that created them. This means shaders can be released faster to the public because Crosire no longer needs to approve them and it frees up Crosires time to work on Reshade itself, rather than also having to manage the effect shaders it can run.

I'm also hoping it will help people to realize that SweetFX never went away when we released Reshade but it became part of the included effects, as this is a common misunderstanding.

Effects included:

* SMAA Anti-aliasing : Anti-aliases the image using the SMAA technique - see http://www.iryoku.com/smaa/
* FXAA Anti-aliasing : Anti-aliases the image using the FXAA technique
* Cartoon : Creates an outline-effect that makes the image look more cartoonish.
* Advanced CRT : Mimics the look of an old arcade CRT display.
* LumaSharpen : Sharpens the image, making details easier to see
* HDR : Mimics an HDR tonemapped look
* Levels : Sets a new black and white point. A fast and easy way to increase contrast but it causes clipping. The Curves effect does this in a more subtle way without causing clipping.
* Technicolor : Makes the image look like it was processed using a three-strip Technicolor process - see http://en.wikipedia.org/wiki/Technicolor
* DPX : Makes the image look like it was converted from film to Cineon DPX. Can be used to create a "sunny" look.
* Monochrome : Removes colors from the image so it appears as if shot on black and white film.
* Lift Gamma Gain : Adjust brightness and color of shadows, midtones and highlights (and typically does it better then the Tonemap effect)
* Tonemap : Adjust gamma, exposure, saturation, bleach and defog. (may cause clipping)
* Vibrance : Intelligently saturates (or desaturates if you use negative values) the pixels depending on their original saturation.
* Curves : Contrast adjustments using S-curves - without causing clipping.
* Sepia : Sepia tones the image - see http://en.wikipedia.org/wiki/Sepia_tone#Sepia_toning
* Vignette : Darkens the edges of the image to make it look more like it was shot with a camera lens. - see http://en.wikipedia.org/wiki/Vignetting )
* Border : Makes the screenedge black as a workaround for the bright edge that forcing some AA modes sometimes causes or use it to create your own letterbox.
* Layer : Allows you to overlay an image onto the game.
* Nostalgia : Tries to mimic the look of very old computers or console systems.
* AMD FidelityFX Contrast Adaptive Sharpening : Sharpens the image, making details easier to see. I've taken over the job of maintaining this Reshade port of AMDs sharpening effect, as it's popular with users and it's therefore best included in one of the popular shader suites.

The following two effects are also created by me, but are found in the Reshade-shaders package as they are too crucial to Reshade not to include there.
* DisplayDepth : A utility shader created to help you set up the depth buffer correctly in Reshade.
* Splitscreen : Enables an before-and-after splitscreen comparison mode.

## Installation

Either :
A) Allow the Reshade installer to download SweetFX and install it for you.
or
B) Download SweetFX manually from https://github.com/CeeJayDK/SweetFX/archive/master.zip and extract it to the reshade-shaders folder that Reshade creates when you install it to a game directory.

## Usage
  
Enable the SweetFX effects you want to use on the Home tab of Reshade.
Then adjust the settings in the settings dialog that appears at the bottom of the Home tab.

## Presets

Presets are files contain settings for the effects.
People create their favorite looks for a particular game and then share these with others.

You can find a lot of them in the SweetFX Settings Database (created and run by Terrasque)
http://sfx.thelazy.net/games/

To work with Reshade they need to be made for Reshade and for a similar enough version of Reshade.

But you can still make presets made for older versions or presets made for the SweetFX 1.x series work in recent Reshade versions, by manually copying the settings over.

To do this:
1) Download the preset you want.
2) Look in the top section for effects with their ´USE_´ define set to 1 - These are the effect that have been enabled.
3) Enable these same effects in Reshade.
4) Scroll down to the settings of these effect in the preset and see what values they are set to.
5) Try to find the exact or similar setting in the effect settings in Reshade and give it the same value.

Most settings still have the same name because I try not to modify the settings if I can avoid it - so they stay more compatible with older presets.

## Problems?

Post issues with Reshade on the Reshade forum :
https://reshade.me/forum

Post suggestions and ideas for the (sweet) effects in SweetFX on the Reshade discord:
https://discordapp.com/invite/GEb23bD as I'm often there.

If I'm not there you can try the subreddit at :
https://www.reddit.com/r/ReShade

## Uninstallation

1) Delete all the files you copied during the installation.  

## Credits

Runs on Reshade by Crosire

 Uses SMAA. Copyright (C) 2011 by Jorge Jimenez, Jose I. Echevarria,
 Belen Masia, Fernando Navarro and Diego Gutierrez.
  - More info on: http://www.iryoku.com/smaa/
 
 Uses FXAA by Timothy Lottes (Nvidia) 
  - His blog: http://timothylottes.blogspot.com
 
 Uses the HDR, Tonemap, Technicolor, Sepia and Vignette shaders from FXAATool by Violator, [some dude], fpedace, BeetleatWar1977 and [DKT70]
  - https://www.assembla.com/wiki/show/fxaa-pp-inject/
  - All of these shaders have been modified by me (CeeJay.dk) .. some of them extensively.
  
 AMD FidelityFX Contrast Adaptive Sharpening by AMD
  - https://gpuopen.com/fidelityfx-cas/ 
  
 DPX shader by Loadus
 
 Border shader by Oomek - rewritten, optimized and improved by CeeJay.dk
 
 Advanced CRT shader by cgwg, Themaister and DOLLS - ported to SweetFX by Boulotaur2024.
 
 Lift Gamma Gain shader by 3an and CeeJay.dk
 
 Cartoon by CeeJay.dk, but based on the Auto Toon cg shader found in the Dolphin emulator.
  - http://dolphin-emu.org/
  
 SweetFX, LumaSharpen, Dither, Curves, Vibrance, Monochrome, Splitscreen, Explosion, Border, and Levels by Christian Cann Schuldt Jensen ( CeeJay.dk )
 
## Contact

Post comments, suggestions, support questions, screenshots, videos and presets on the Reshade forum at 
https://reshade.me/forum

Or join the Reshade discord :
https://discordapp.com/invite/GEb23bD

Also check out the Reshade subreddit :
https://www.reddit.com/r/ReShade/

Submit your presets to the SweetFX Settings Database at:
http://sfx.thelazy.net/games/
