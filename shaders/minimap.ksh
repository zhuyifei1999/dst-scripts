   minimap   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         NOISE_REPEAT_SIZE                     PosUV_WorldPos.vs_  uniform mat4 MatrixPVW;
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

 
   minimap.psA  #if defined( GL_ES )
precision mediump float;
#endif

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]

uniform sampler2D SAMPLER[2];

uniform float NOISE_REPEAT_SIZE;
varying vec2 PS_TEXCOORD;

#if defined ENABLE_OCEAN
uniform vec4 OCEAN_WORLD_EXTENTS;
uniform vec4 OCEAN_UV_PARAMS;
#endif

varying vec3 PS_POS;

void main()
{
	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );


#if defined ENABLE_OCEAN
	vec2 ocean_uv = ( PS_POS.xz - OCEAN_WORLD_EXTENTS.xy + vec2(2.0, 2.0) ) * OCEAN_WORLD_EXTENTS.zw;
	vec4 ocean_colour = texture2D( BASE_TEXTURE, ocean_uv );
	gl_FragColor = vec4(ocean_colour.rgb + noise.rgb * 0.00001, 1);
#else
	gl_FragColor = texture2D( BASE_TEXTURE, PS_TEXCOORD );
	gl_FragColor.rgb *= noise.rgb;
#endif
}

                    