   ground_underground   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         NOISE_REPEAT_SIZE                     GROUND_PARAMS                                LIGHTMAP_WORLD_EXTENTS                                PosUV_WorldPos.vs�  #define ENABLE_UNDERGROUND_FADE
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

 	   ground.psy  #define ENABLE_UNDERGROUND_FADE
#if defined( GL_ES )
precision mediump float;
#endif

#if defined(ENABLE_OCEAN)
uniform sampler2D SAMPLER[5]; // SAMPLER[3] used in lighting.h
#else
uniform sampler2D SAMPLER[4]; // SAMPLER[3] used in lighting.h
#endif


#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]
#define MULTILAYER_TEXTURE SAMPLER[2]
#define OCEAN_TEXTURE SAMPLER[4]

uniform float NOISE_REPEAT_SIZE;
uniform vec3 BLEND_FACTOR;

#if defined(ENABLE_UNDERGROUND_FADE)
uniform vec4 GROUND_PARAMS;
#endif

#if defined(ENABLE_OCEAN)
uniform vec4 OCEAN_WORLD_EXTENTS;
uniform vec4 OCEAN_UV0_PARAMS;
uniform vec4 OCEAN_UV1_PARAMS;
uniform vec4 OCEAN_UV2_PARAMS;
uniform vec4 OCEAN_PARAMS;
#endif

#   if defined(ENABLE_OVERLAY)
uniform vec4 GROUND_COL0;
uniform vec4 GROUND_COL1;
uniform vec4 GROUND_COL2;
# 	endif

#define SRC_BLEND_FACTOR BLEND_FACTOR.x
#define DEST_BLEND_FACTOR BLEND_FACTOR.y

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


float SampleNoise(vec2 noise_uv, float noise_scale, vec2 uv_offset, float frequency)
{
	float noise = texture2D( NOISE_TEXTURE, (noise_uv * noise_scale + uv_offset )).g;
	noise = noise * noise * frequency;
	return noise;
}

void main()
{
	vec4 base_colour = vec4(0.0, 0.0, 0.0, 0.0);	

#	if defined(ENABLE_OCEAN)		
	vec2 ocean_uv = ( PS_POS.xz - OCEAN_WORLD_EXTENTS.xy + vec2(2.0, 2.0) ) * OCEAN_WORLD_EXTENTS.zw;
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

#	else
	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	base_colour = texture2D( BASE_TEXTURE, PS_TEXCOORD );
	vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );
	base_colour.rgb *= noise.rgb;
#	endif	

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
#	elif defined(ENABLE_OCEAN)
		alpha = base_colour.a + noise_opacity * noise;
#	else
	
#	endif

	colour.rgb = colour.rgb * alpha;

	gl_FragColor = vec4( colour.rgb, alpha );
}

                          