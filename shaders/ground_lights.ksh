   ground_lights      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         NOISE_REPEAT_SIZE                     ground_lights.vs�  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD;
varying vec3 PS_POS;

void main()
{
	mat4 mtxPVW = MatrixP * MatrixV * MatrixW;

	gl_Position = mtxPVW * vec4( POSITION.xyz, 1.0 );

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;

	PS_TEXCOORD.xy = TEXCOORD0;
}

    ground_lights.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D 			SAMPLER[2]; // NO LIGHTING

#define BASE_TEXTURE 		SAMPLER[0]
#define NOISE_TEXTURE		SAMPLER[1]
#define MULTILAYER_TEXTURE	SAMPLER[2]

uniform float 	NOISE_REPEAT_SIZE;
uniform vec3 	BLEND_FACTOR;

#define SRC_BLEND_FACTOR	BLEND_FACTOR.x
#define DEST_BLEND_FACTOR	BLEND_FACTOR.y

varying vec2 PS_TEXCOORD;
varying vec3 PS_POS;

void main()
{
	vec4 base_colour = texture2D( BASE_TEXTURE, PS_TEXCOORD );
	if( base_colour.a > 0.0 )
	{
		vec2 noise_uv = PS_POS.xz * NOISE_REPEAT_SIZE;
		vec4 noise = texture2D( NOISE_TEXTURE, noise_uv );
		if( noise.a < 1.0 )
		{

			// base_colour.rgb *= noise.rgb;

			// vec3 layers = texture2D( MULTILAYER_TEXTURE, noise_uv ).rgb;
			// layers *= BLEND_FACTOR;

			// vec3 colour = vec3(0.0,0.0, base_colour.b);//rgb;
			// colour.rgb = layers.r + ( 1.0 - layers.r ) * base_colour.rgb;
			// colour.rgb = layers.g + ( 1.0 - layers.g ) * colour.rgb;
			// colour.rgb = layers.b + ( 1.0 - layers.b ) * colour.rgb;

			// colour.rgb *= base_colour.a;

			gl_FragColor = vec4( 0.0, 0.0, 1.0, noise.a );
		}
		 else
		 {
		 	discard;
		 }
	}
	else
	{
		discard;
	}
}

                       