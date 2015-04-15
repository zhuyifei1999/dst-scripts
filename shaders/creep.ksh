   creep   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         NOISE_REPEAT_SIZE                     AMBIENT                            LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs_  uniform mat4 MatrixPVW;
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

    creep.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]
#define MULTILAYER_TEXTURE SAMPLER[2]

uniform float NOISE_REPEAT_SIZE;

varying vec2 PS_TEXCOORD;

// Already defined by lighting.h
// varying vec3 PS_POS

#ifndef LIGHTING_H
#define LIGHTING_H

// Lighting
varying vec3 PS_POS;
uniform vec3 AMBIENT;

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;

	vec3 colour = texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb + AMBIENT.rgb;

	return clamp( colour.rgb, vec3( 0, 0, 0 ), vec3( 1, 1, 1 ) );
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}

#endif //LIGHTING.h


void main()
{
	vec2 noise_uv = PS_POS.xz / NOISE_REPEAT_SIZE;
	vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );

	float alpha = texture2D( BASE_TEXTURE, PS_TEXCOORD ).a;
	if( alpha > 0.0 )
	{
		float saturated_alpha = clamp( alpha * 16.0, 0.0, 1.0 );

		noise.rgb *= saturated_alpha;
		noise.rgb *= CalculateLightingContribution();

		gl_FragColor.rgba = vec4( noise.rgb, alpha );
	}
	else
	{
		discard;
	}
}

                          