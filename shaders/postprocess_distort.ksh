   postprocess_distort      DISTORTION_PARAMS                                FISHEYE_PARAMS                        SAMPLER    +         postprocess_distort.vs�  attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;
varying vec2 PS_TEXCOORD1;

uniform vec4 DISTORTION_PARAMS;

#define TIME DISTORTION_PARAMS.x

uniform vec2 FISHEYE_PARAMS;

#define FISHEYE_INTENSITY FISHEYE_PARAMS.x
#define FISHEYE_TIME FISHEYE_PARAMS.y

const float RANGE = 0.00625;
const float TIME_SCALE = 50.0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;

	vec2 offset_vec = vec2( cos( TIME * TIME_SCALE + 0.25 ), sin( TIME * TIME_SCALE ) );
	vec2 small_uv = TEXCOORD0.xy * ( 1.0 - 2.0 * RANGE ) + RANGE;
	vec2 lens_vec = POSITION.xy * FISHEYE_INTENSITY * 0.5 * (1.0 + sin( FISHEYE_TIME ));
	PS_TEXCOORD1.xy = small_uv + offset_vec * RANGE + lens_vec;
}

    postprocess_distort.ps�  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];

#define SRC_IMAGE        SAMPLER[0]

varying vec2 PS_TEXCOORD0;
varying vec2 PS_TEXCOORD1;

uniform vec4 DISTORTION_PARAMS;

#define DISTORTION_FACTOR			DISTORTION_PARAMS.y
#define DISTORTION_INNER_RADIUS		DISTORTION_PARAMS.z
#define DISTORTION_OUTER_RADIUS		DISTORTION_PARAMS.q

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb; // rgb all 0:1 - colour space
	
	// rotation amount
	vec3 distorted_colour = texture2D( SRC_IMAGE, PS_TEXCOORD1.xy ).xyz;

	float distortion_mask = clamp( ( 1.0 - distance( PS_TEXCOORD0.xy, vec2( 0.5, 0.5 ) ) - DISTORTION_INNER_RADIUS ) / ( DISTORTION_OUTER_RADIUS - DISTORTION_INNER_RADIUS ), 0.0, 1.0 );
	distorted_colour.rgb = mix( distorted_colour, base_colour, DISTORTION_FACTOR );

    gl_FragColor = vec4( mix( distorted_colour, base_colour, distortion_mask ), 1.0 );
}

                     