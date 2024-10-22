   river   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         GROUND_REPEAT_VEC                        BLEND_FACTOR                         	   UV_OFFSET                        LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs_  uniform mat4 MatrixPVW;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;
varying vec3 PS_POS;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0;

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;
}

    river.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]
#define MULTILAYER_TEXTURE SAMPLER[2]

uniform vec2 GROUND_REPEAT_VEC;
uniform vec3 BLEND_FACTOR;
uniform vec2 UV_OFFSET;

varying vec2 PS_TEXCOORD;

// Already defined by lighting.h
// varying vec3 PS_POS

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


void main()
{
	vec4 noise = texture2D( NOISE_TEXTURE, PS_TEXCOORD.xy + UV_OFFSET.xy );

	vec4 base_colour = texture2D( BASE_TEXTURE, PS_TEXCOORD.xy );
	base_colour.rgb /= base_colour.a;
	base_colour.rgb *= noise.rgb;

	vec2 world_noise_uv = ( PS_POS.xz / GROUND_REPEAT_VEC.y );
	vec3 layers = texture2D( MULTILAYER_TEXTURE, world_noise_uv ).rgb;
	layers *= BLEND_FACTOR;

	vec3 colour;
	colour = layers.r + ( 1.0 - layers.r ) * base_colour.rgb;
	colour = layers.g + ( 1.0 - layers.g ) * colour;
	colour = layers.b + ( 1.0 - layers.b ) * colour;

	gl_FragColor.rgb = colour.rgb * CalculateLightingContribution();
	gl_FragColor.a = noise.a * base_colour.a;
	gl_FragColor.rgb *= gl_FragColor.a;
}

                             