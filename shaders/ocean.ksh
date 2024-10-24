   ocean   	   MatrixPVW                                                                                SAMPLER    +         ocean.vs7  uniform mat4 MatrixPVW;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;
varying vec3 PS_TEXCOORD1;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );

	PS_TEXCOORD0.xy = TEXCOORD0;
	PS_TEXCOORD1.xyz = gl_Position.xyw;
}

    ocean.ps  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];

#define BASE_TEXTURE SAMPLER[0]

varying vec2 PS_TEXCOORD0;
varying vec3 PS_TEXCOORD1;

void main()
{
	vec2 ss_uv = (PS_TEXCOORD1.xy / PS_TEXCOORD1.z) * 0.5 + 0.5;
	vec4 base_colour = texture2D( BASE_TEXTURE, ss_uv + PS_TEXCOORD0.xy * 0.000001);	

	float decoding_factor = 0.5;
	base_colour.rgb = base_colour.rgb * decoding_factor;

	float alpha = base_colour.a;

	gl_FragColor = vec4(base_colour.rgb * alpha, alpha);
}

              