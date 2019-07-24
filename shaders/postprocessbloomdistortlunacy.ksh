   postprocessbloomdistortlunacy      POST_PARAMS                            SAMPLER    +         DISTORTION_PARAMS                            postprocess.vs�  #define ENABLE_BLOOM
#define ENABLE_DISTORTION
#define ENABLE_LUNACY
attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;
varying vec2 PS_TEXCOORD1;

uniform vec3 POST_PARAMS;
#if defined( ENABLE_DISTORTION )
	#define TIME POST_PARAMS.x
#endif 

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
	 
#if defined( ENABLE_DISTORTION )
	float range = 0.00625;
	float time_scale = 50.0;
	vec2 offset_vec = vec2( cos( TIME * time_scale + 0.25 ), sin( TIME * time_scale ) );
	vec2 small_uv = TEXCOORD0.xy * ( 1.0 - 2.0 * range ) + range;
	PS_TEXCOORD1.xy = small_uv + offset_vec * range;
#endif

}

    postprocess.ps�  #define ENABLE_BLOOM
#define ENABLE_DISTORTION
#define ENABLE_LUNACY
#if defined( GL_ES )
precision highp float;
#endif

#define SAMPLER_COUNT 2

#if defined( ENABLE_BLOOM )
	#define BLOOM_SAMPLER_COUNT 1
#else
	#define BLOOM_SAMPLER_COUNT 0
#endif

#if defined(ENABLE_LUNACY) 
	#define OVERLAY_SAMPLER_COUNT 2
#else
	#define OVERLAY_SAMPLER_COUNT 0
#endif

uniform sampler2D SAMPLER[SAMPLER_COUNT + OVERLAY_SAMPLER_COUNT + BLOOM_SAMPLER_COUNT];

#define SRC_IMAGE        SAMPLER[0]
#define COLOUR_CUBE      SAMPLER[1]
#define OVERLAY_IMAGE    SAMPLER[SAMPLER_COUNT + 0]
#define OVERLAY_BUFFER   SAMPLER[SAMPLER_COUNT + 1]
#define BLOOM_BUFFER     SAMPLER[SAMPLER_COUNT + OVERLAY_SAMPLER_COUNT + 0]

uniform vec3 POST_PARAMS;
uniform vec4 SCREEN_PARAMS;

#define TIME                POST_PARAMS.x
#define OVERLAY_BLEND		POST_PARAMS.z

varying vec2 PS_TEXCOORD0;
#if defined( ENABLE_DISTORTION )
varying vec2 PS_TEXCOORD1;
#endif

const float CUBE_DIMENSION = 32.0;
const float CUBE_WIDTH = ( CUBE_DIMENSION * CUBE_DIMENSION );
const float CUBE_HEIGHT =( CUBE_DIMENSION );
const float ONE_OVER_CUBE_WIDTH =  1.0 / CUBE_WIDTH;
const float ONE_OVER_CUBE_HEIGHT =  1.0 / CUBE_HEIGHT;

const float TEXEL_WIDTH =   ( 1.0 / CUBE_WIDTH );
const float TEXEL_HEIGHT =  ( 1.0 / CUBE_HEIGHT);
const float HALF_TEXEL_WIDTH =  ( TEXEL_WIDTH  * 0.5 );
const float HALF_TEXEL_HEIGHT = ( TEXEL_HEIGHT * 0.5 );

#if defined( ENABLE_DISTORTION )
	uniform vec3 DISTORTION_PARAMS;

	#define DISTORTION_FACTOR			DISTORTION_PARAMS.x
	#define DISTORTION_INNER_RADIUS		DISTORTION_PARAMS.y
	#define DISTORTION_OUTER_RADIUS		DISTORTION_PARAMS.z
#endif

vec3 Overlay (vec3 a, vec3 b) {
    vec3 r = vec3(0.0,0.0,0.0);

    if(a.g > 0.5)
    {
    	r = 1.0-(1.0-2.0*(a-0.5))*(1.0-b);
    }
    else
    {
    	r = (2.0*a)*b;
    }

    return r;
}

vec3 ApplyColourCube(vec3 colour)
{
	vec3 intermediate = colour.rgb * vec3( CUBE_DIMENSION - 1.0, CUBE_DIMENSION - 1.0, CUBE_DIMENSION - 1.0 );

	vec2 floor_uv = vec2( ( min( intermediate.r + 0.5, 31.0 ) + floor( intermediate.b ) * CUBE_DIMENSION ) * ONE_OVER_CUBE_WIDTH,1.0 - ( min( intermediate.g + 0.5, 31.0 ) * ONE_OVER_CUBE_HEIGHT ) );
	vec2 ceil_uv = vec2( ( min( intermediate.r + 0.5, 31.0 ) + ceil( intermediate.b ) * CUBE_DIMENSION ) * ONE_OVER_CUBE_WIDTH,1.0 - ( min( intermediate.g + 0.5, 31.0 ) * ONE_OVER_CUBE_HEIGHT ) );
	vec3 floor_col = texture2D( COLOUR_CUBE, floor_uv.xy ).rgb;
	vec3 ceil_col = texture2D( COLOUR_CUBE, ceil_uv.xy ).rgb;
	return mix(floor_col, ceil_col, intermediate.b - floor(intermediate.b) );	
}

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb; // rgb all 0:1 - colour space

#if defined( ENABLE_BLOOM )
	vec3 bloom = texture2D( BLOOM_BUFFER, PS_TEXCOORD0.xy ).rgb;
	base_colour.rgb += bloom.rgb;
#endif

#if defined( ENABLE_DISTORTION )

	// Offset comes from vert shader
	vec2 offset_uv = PS_TEXCOORD1.xy;
	
	// rotation amount
	vec3 distorted_colour = texture2D( SRC_IMAGE, offset_uv ).xyz;

	#if defined( ENABLE_BLOOM ) 
		distorted_colour.rgb += texture2D( BLOOM_BUFFER, offset_uv ).rgb;
	#endif

	float distortion_mask = clamp( ( 1.0 - distance( PS_TEXCOORD0.xy, vec2( 0.5, 0.5 ) ) - DISTORTION_INNER_RADIUS ) / ( DISTORTION_OUTER_RADIUS - DISTORTION_INNER_RADIUS ), 0.0, 1.0 );
	distorted_colour.rgb = mix( distorted_colour, base_colour, DISTORTION_FACTOR );
	base_colour.rgb = mix( distorted_colour, base_colour, distortion_mask );
#endif
 	
	vec3 cc = ApplyColourCube(base_colour.rgb);

#if defined( ENABLE_LUNACY )
	vec3 overlay = texture2D( OVERLAY_IMAGE, PS_TEXCOORD0.xy ).rgb;
	vec4 overlay_buffer = texture2D(OVERLAY_BUFFER, PS_TEXCOORD0.xy);

	overlay_buffer.rgb += vec3(0.5, 0.5, 0.5);
	overlay = overlay.rgb + overlay_buffer.rgb;
	vec3 overlay_applied = Overlay(cc.rgb, overlay.rgb);
	
	float alpha = overlay_buffer.g * OVERLAY_BLEND;
	cc.rgb = mix(cc.rgb, overlay_applied.rgb, alpha);
#endif

    gl_FragColor = vec4( cc.rgb, 1.0 );
}

                     