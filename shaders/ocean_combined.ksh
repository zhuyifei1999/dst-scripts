   ocean_combined   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         OCEAN_WORLD_EXTENTS                                OCEAN_UV0_PARAMS                                OCEAN_UV1_PARAMS                                OCEAN_UV2_PARAMS                                LIGHTMAP_WORLD_EXTENTS                                ocean_combined.vs  uniform mat4 MatrixPVW;
uniform mat4 MatrixW;

attribute vec3 POSITION;

varying vec3 PS_POS;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;
}

    ocean_combined.ps�	  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4];

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]
#define OCEAN_TEXTURE SAMPLER[2]

uniform vec4 OCEAN_WORLD_EXTENTS;
uniform vec4 OCEAN_UV0_PARAMS;
uniform vec4 OCEAN_UV1_PARAMS;
uniform vec4 OCEAN_UV2_PARAMS;
uniform vec4 OCEAN_PARAMS;

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


float SampleNoise(vec2 noise_uv, float noise_scale, vec2 uv_offset, float frequency)
{
	float noise = texture2D( NOISE_TEXTURE, (noise_uv * noise_scale + uv_offset )).g;
	noise = noise * noise * frequency;
	return noise;
}

void main()
{
	vec4 base_colour = vec4(0.0, 0.0, 0.0, 0.0);	
		
	vec2 ocean_uv = ( PS_POS.xz - OCEAN_WORLD_EXTENTS.xy ) * OCEAN_WORLD_EXTENTS.zw;
	base_colour = texture2D( BASE_TEXTURE, ocean_uv );

	vec4 base_ocean_colour = texture2D( OCEAN_TEXTURE, ocean_uv );

	vec2 noise_uv = ocean_uv;
	float noise0 = SampleNoise(noise_uv, OCEAN_UV0_PARAMS.z, OCEAN_UV0_PARAMS.xy, OCEAN_UV0_PARAMS.w);
	float noise1 = SampleNoise(noise_uv, OCEAN_UV1_PARAMS.z, OCEAN_UV1_PARAMS.xy, OCEAN_UV1_PARAMS.w);
	float noise2 = SampleNoise(noise_uv, OCEAN_UV2_PARAMS.z, OCEAN_UV2_PARAMS.xy, OCEAN_UV2_PARAMS.w);
	float noise = sin(noise0 + noise1 + noise2) * 0.5 + 0.5;	

	float noise_opacity = base_ocean_colour.a;
	base_colour.rgb = mix(base_colour.rgb, base_ocean_colour.rgb, noise * noise_opacity);
	base_colour.a = base_colour.a;

	vec3 colour = base_colour.rgb;

	colour.rgb *= CalculateLightingContribution();

	float encoding_factor = 2.0;
	colour.rgb = colour.rgb * encoding_factor;

	float alpha = base_colour.a + noise_opacity * noise;

	gl_FragColor = vec4( colour.rgb, alpha );
}

                                