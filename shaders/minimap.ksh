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
   minimap.ps�  #if defined( GL_ES )
precision mediump float;
#endif

#define BASE_TEXTURE SAMPLER[0]
#define NOISE_TEXTURE SAMPLER[1]

uniform sampler2D SAMPLER[2];

uniform float NOISE_REPEAT_SIZE;
varying vec2 PS_TEXCOORD;

varying vec3 PS_POS;

void main()
{
	vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
	vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );

	gl_FragColor = texture2D( BASE_TEXTURE, PS_TEXCOORD );
	gl_FragColor.rgb *= noise.rgb;
}

                    