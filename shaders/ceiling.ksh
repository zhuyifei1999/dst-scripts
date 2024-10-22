   ceiling      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         NOISE_REPEAT_SIZE                     BLEND_FACTOR                            LIGHTMAP_WORLD_EXTENTS                             
   ceiling.vs�  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;
attribute vec4 DIFFUSE;

varying vec2 PS_TEXCOORD;
varying vec3 PS_POS;
varying vec4 PS_COLOUR;

void main()
{
	mat4 mtxPVW = MatrixP * MatrixV * MatrixW;
	gl_Position = mtxPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0;

	PS_COLOUR = DIFFUSE;

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;
}

 
   ceiling.psH  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]
#define MULTILAYER_TEXTURE SAMPLER[2]

uniform float NOISE_REPEAT_SIZE;
uniform vec3 BLEND_FACTOR;

#define SRC_BLEND_FACTOR BLEND_FACTOR.x
#define DEST_BLEND_FACTOR BLEND_FACTOR.y

varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

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
	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	vec4 base_colour = texture2D( NOISE_TEXTURE,  noise_uv);
	if( base_colour.a > 0.0 )
	{
		vec4 noise = texture2D( BASE_TEXTURE, PS_TEXCOORD );

		base_colour.rgb *= noise.rgb;
		base_colour.rgba *= PS_COLOUR;

		vec3 layers = texture2D( MULTILAYER_TEXTURE, noise_uv ).rgb;
		layers *= BLEND_FACTOR;

		// Snow
		vec3 colour = base_colour.rgb;
		colour.rgb = layers.r + ( 1.0 - layers.r ) * base_colour.rgb;
		colour.rgb = layers.g + ( 1.0 - layers.g ) * colour.rgb;
		colour.rgb = layers.b + ( 1.0 - layers.b ) * colour.rgb;
		colour.rgb *= base_colour.a;
		colour.rgb *= CalculateLightingContribution();


		gl_FragColor = vec4( colour.rgb, base_colour.a );
	}
	else
	{
		discard;
	}
}

                             