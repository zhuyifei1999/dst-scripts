   waves      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                WavesUp                            WavesRepeat                            WavesOffset                  SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                waves.vs�  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec3 WavesUp;
uniform vec3 WavesRepeat;
uniform vec2 WavesOffset[32];

attribute vec4 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;
varying vec3 PS_POS;

void main()
{
	vec2 offset = WavesOffset[int(POSITION.w)];
	vec3 pos3 = vec3(POSITION.x + offset.x, 0.0, POSITION.z) + (WavesUp * (POSITION.y + offset.y));
	vec4 pos = vec4( pos3, 1.0 );

	vec4 world_pos = MatrixW * pos;

	gl_Position = world_pos - normalize(vec4(MatrixW[2].x, 0, MatrixW[2].z, 0.0)) * WavesRepeat.y;
	PS_POS.xyz = gl_Position.xyz;
	gl_Position = MatrixP * MatrixV * gl_Position;

	PS_TEXCOORD.x = TEXCOORD0.x + WavesRepeat.x;
	PS_TEXCOORD.y = TEXCOORD0.y;
}

 	   TexLit.psP  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4];
#ifndef LIGHTING_H
#define LIGHTING_H

#if !defined( UI_CC )
// Lighting
varying vec3 PS_POS;
#endif

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

#if defined( UI_CC )
vec3 CalculateLightingContribution(vec2 pos)
{
	vec2 uv = ( pos - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;
	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}
#else
vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;
	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}
#endif

#endif //LIGHTING.h


varying vec2 PS_TEXCOORD;

void main()
{
    gl_FragColor.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
	gl_FragColor.rgb *= CalculateLightingContribution();
}

                                