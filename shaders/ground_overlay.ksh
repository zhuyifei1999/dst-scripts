   ground_overlay
   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         NOISE_REPEAT_SIZE                     MINIMUM_OPACITY                     BLEND_FACTOR                            GROUND_COL0                                GROUND_COL1                                GROUND_COL2                                LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs_  uniform mat4 MatrixPVW;
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

    ground_overlay.ps   #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h

#define BASE_TEXTURE SAMPLER[0]
#define MULTILAYER_TEXTURE SAMPLER[1]

uniform float NOISE_REPEAT_SIZE;
uniform float MINIMUM_OPACITY;

uniform vec3 BLEND_FACTOR;
uniform vec4 GROUND_COL0;
uniform vec4 GROUND_COL1;
uniform vec4 GROUND_COL2;

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
	float alpha = texture2D( BASE_TEXTURE, PS_TEXCOORD ).a;
	if(alpha < MINIMUM_OPACITY || alpha < 0.105)
	{
		discard;
	}

	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	vec3 layers = texture2D( MULTILAYER_TEXTURE, noise_uv ).rgb * BLEND_FACTOR;

	float first_alpha = layers.b * GROUND_COL2.a;
	float secondary_alpha = (1.0 - first_alpha) * (layers.g * GROUND_COL1.a);
	float third_alpha = (1.0 - (first_alpha+secondary_alpha)) * (layers.r * GROUND_COL0.a);

	vec3 colour = (third_alpha * GROUND_COL0.rgb) + (secondary_alpha * GROUND_COL1.rgb) + (first_alpha * GROUND_COL2.rgb);

	colour *= CalculateLightingContribution();

	colour *= alpha;

	gl_FragColor = vec4(colour, (first_alpha + secondary_alpha + third_alpha) * alpha);
}

                                   	   