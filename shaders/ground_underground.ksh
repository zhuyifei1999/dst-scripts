   ground_underground   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         GROUND_PARAMS                                NOISE_REPEAT_SIZE                     LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs�  #define ENABLE_UNDERGROUND_FADE
uniform mat4 MatrixPVW;
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

 	   ground.ps�	  #define ENABLE_UNDERGROUND_FADE
#if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]
#define MULTILAYER_TEXTURE SAMPLER[2]
#define OCEAN_TEXTURE SAMPLER[2]

#if defined(ENABLE_UNDERGROUND_FADE)
uniform vec4 GROUND_PARAMS;
#endif

uniform float NOISE_REPEAT_SIZE;

#   if defined(ENABLE_OVERLAY)
uniform vec3 BLEND_FACTOR;
uniform vec4 GROUND_COL0;
uniform vec4 GROUND_COL1;
uniform vec4 GROUND_COL2;
# 	endif

varying vec2 PS_TEXCOORD;

// Already defined by lighting.h
// varying vec3 PS_POS

#ifndef LIGHTING_H
#define LIGHTING_H

// Lighting
varying vec3 PS_POS;

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;

	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}

#endif //LIGHTING.h


void main()
{
	vec4 base_colour = vec4(0.0, 0.0, 0.0, 0.0);	

	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	base_colour = texture2D( BASE_TEXTURE, PS_TEXCOORD );
	vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );
	base_colour.rgb *= noise.rgb;

	vec3 colour = base_colour.rgb;
#   if defined(ENABLE_OVERLAY)
	    vec3 layers = texture2D( MULTILAYER_TEXTURE, noise_uv ).rgb;
	    layers *= BLEND_FACTOR;
	    colour.rgb = layers.r * GROUND_COL0.a * ( GROUND_COL0.rgb ) + ( 1.0 - layers.r * GROUND_COL0.a ) * base_colour.rgb;
	    colour.rgb = layers.g * GROUND_COL1.a * ( GROUND_COL1.rgb ) + ( 1.0 - layers.g * GROUND_COL1.a ) * colour.rgb;
	    colour.rgb = layers.b * GROUND_COL2.a * ( GROUND_COL2.rgb ) + ( 1.0 - layers.b * GROUND_COL2.a ) * colour.rgb;
#   endif

	colour.rgb *= CalculateLightingContribution();

	float alpha = base_colour.a;

#   if defined(ENABLE_UNDERGROUND_FADE)
		float height_factor = 1.0 - max(min(abs(PS_POS.y) * GROUND_PARAMS.x, 1.0), 0.0);
		alpha *= height_factor;
		colour.rgb = colour.rgb * height_factor;	
#	endif

	if(alpha < 0.105)
	{
		discard;
	}

	colour.rgb = colour.rgb * alpha;


	gl_FragColor = vec4( colour.rgb, alpha );
}

                          