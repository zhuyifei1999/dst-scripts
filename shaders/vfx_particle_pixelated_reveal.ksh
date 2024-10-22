   vfx_particle_pixelated_reveal   	   MatrixPVW                                                                                SAMPLER    +         vfx_particle_reveal.vs>  uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0_LIFE;
attribute vec4 DIFFUSE;

varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );

	PS_TEXCOORD_LIFE.xyz = TEXCOORD0_LIFE.xyz;
	PS_COLOUR = DIFFUSE;
}

     vfx_particle_pixelated_reveal.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];

varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;

void main()
{
	const float uv_steps = 12.0;
	
	vec2 uv = floor(PS_TEXCOORD_LIFE.xy * uv_steps)/uv_steps;
	vec4 colour = texture2D( SAMPLER[0], uv );
	
	float a = (colour.g - PS_TEXCOORD_LIFE.z) * 10000.0;
	a = clamp( a, 0.0, 1.0 );
	
	gl_FragColor = vec4( PS_COLOUR.rgb, PS_COLOUR.a * a );
}

              