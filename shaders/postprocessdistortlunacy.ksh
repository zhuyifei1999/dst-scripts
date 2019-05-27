   postprocessdistortlunacy      POST_PARAMS                            SAMPLER    +         DISTORTION_PARAMS                            postprocess.vs�  #define ENABLE_DISTORTION
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

    postprocess.psD  #define ENABLE_DISTORTION
#define ENABLE_LUNACY
#if defined( GL_ES )
precision highp float;
#endif

#if defined( ENABLE_BLOOM )
// Angle is REALLY anal about this. You can't enable a sampler
// that you aren't going to use or it very quietly asserts in the
// dll with a spectacularly less than informative assert.
uniform sampler2D SAMPLER[5];
#else
uniform sampler2D SAMPLER[4];
#endif

uniform vec3 POST_PARAMS;
uniform vec4 OVERLAY_PARAMS;

#define TIME                POST_PARAMS.x
#define INTENSITY_MODIFIER  POST_PARAMS.y
#define OVERLAY_BLEND		POST_PARAMS.z

#define SRC_IMAGE        SAMPLER[0]
#define COLOUR_CUBE      SAMPLER[1]
#define OVERLAY_IMAGE    SAMPLER[2]
#define OVERLAY_BUFFER   SAMPLER[3]
#define BLOOM_BUFFER     SAMPLER[4]


varying vec2 PS_TEXCOORD0;
#if defined( ENABLE_DISTORTION )
varying vec2 PS_TEXCOORD1;
#endif

#define CUBE_DIMENSION 32.0
#define CUBE_WIDTH  ( CUBE_DIMENSION * CUBE_DIMENSION )
#define CUBE_HEIGHT ( CUBE_DIMENSION )
#define ONE_OVER_CUBE_WIDTH  1.0 / CUBE_WIDTH
#define ONE_OVER_CUBE_HEIGHT  1.0 / CUBE_HEIGHT

#define TEXEL_WIDTH   ( 1.0 / CUBE_WIDTH )
#define TEXEL_HEIGHT  ( 1.0 / CUBE_HEIGHT)
#define HALF_TEXEL_WIDTH  ( TEXEL_WIDTH  * 0.5 )
#define HALF_TEXEL_HEIGHT ( TEXEL_HEIGHT * 0.5 )

#if defined( ENABLE_DISTORTION )
	uniform vec3 DISTORTION_PARAMS;

	#define DISTORTION_FACTOR			DISTORTION_PARAMS.x
	#define DISTORTION_INNER_RADIUS		DISTORTION_PARAMS.y
	#define DISTORTION_OUTER_RADIUS		DISTORTION_PARAMS.z
#endif

#define BlendOverlayf(base, blend) 	(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)))
#define Blend(base, blend, funcf) 		vec3(funcf(base.r, blend.r), funcf(base.g, blend.g), funcf(base.b, blend.b))
#define BlendOverlay(base, blend) 		Blend(base, blend, BlendOverlayf)

vec3 Overlay (vec3 a, vec3 b) {
    vec3 r = vec3(0.0,0.0,0.0);
    if (a.r > 0.5) { r.r = 1.0-(1.0-2.0*(a.r-0.5))*(1.0-b.r); }
    else { r.r = (2.0*a.r)*b.r; }
    if (a.g > 0.5) { r.g = 1.0-(1.0-2.0*(a.g-0.5))*(1.0-b.g); }
    else { r.g = (2.0*a.g)*b.g; }
    if (a.b > 0.5) { r.b = 1.0-(1.0-2.0*(a.b-0.5))*(1.0-b.b); }
    else { r.b = (2.0*a.b)*b.b; }
    return r;
}


//Manually apply bilinear filtering to the colour cube, to prevent anistropic "red outline" filtering bug
vec3 texture2DBilinear( sampler2D textureSampler, vec2 uv )
{
    // in vertex shaders you should use texture2DLod instead of texture2D
    vec3 tl = texture2D(textureSampler, uv).rgb;
    vec3 tr = texture2D(textureSampler, uv + vec2(TEXEL_WIDTH,	0			)).rgb;
    vec3 bl = texture2D(textureSampler, uv + vec2(0,			TEXEL_HEIGHT)).rgb;
    vec3 br = texture2D(textureSampler, uv + vec2(TEXEL_WIDTH , TEXEL_HEIGHT)).rgb;
    vec2 f = fract( uv.xy * vec2(CUBE_WIDTH,CUBE_HEIGHT) ); // get the decimal part
    vec3 tA = mix( tl, tr, f.x ); // will interpolate the red dot in the image
    vec3 tB = mix( bl, br, f.x ); // will interpolate the blue dot in the image
    return mix( tA, tB, f.y ); // will interpolate the green dot in the image
}

vec3 ApplyColourCube(vec3 colour)
{
	vec3 intermediate = colour.rgb * vec3( CUBE_DIMENSION - 1.0, CUBE_DIMENSION, CUBE_DIMENSION - 1.0 );
	vec2 floor_uv = vec2( ( min( intermediate.r + 0.5, 31.0 ) + floor( intermediate.b ) * CUBE_DIMENSION ) * ONE_OVER_CUBE_WIDTH,1.0 - ( min( intermediate.g, 31.0 ) * ONE_OVER_CUBE_HEIGHT ) );
	vec2 ceil_uv = vec2( ( min( intermediate.r + 0.5, 31.0 ) + ceil( intermediate.b ) * CUBE_DIMENSION ) * ONE_OVER_CUBE_WIDTH,1.0 - ( min( intermediate.g, 31.0 ) * ONE_OVER_CUBE_HEIGHT ) );
	vec3 floor_col = texture2DBilinear( COLOUR_CUBE, floor_uv.xy ).rgb;
	vec3 ceil_col = texture2DBilinear( COLOUR_CUBE, ceil_uv.xy ).rgb;
	return mix(floor_col, ceil_col, intermediate.b - floor(intermediate.b) );	
}

float random(vec3 scale,float seed){return fract(sin(dot(gl_FragCoord.xyz+seed,scale))*43758.5453+seed);}

vec3 ZoomBlur(sampler2D src_image, vec3 colour, vec2 uv)
{
	vec2 ray_from_center = (PS_TEXCOORD0.xy - vec2(0.5, 0.5)) * 2.0;
	float dist_sq = min(ray_from_center.x * ray_from_center.x + ray_from_center.y * ray_from_center.y, 1.0);
	float radius = 0.02;
	float radius_sq = radius * radius;
	float dist_from_circle = sqrt(min(max(dist_sq - radius_sq, 0.0) / (1.0 - radius_sq), 1.0));

	vec2 resolution = vec2(1920.0, 1080.0);
	float strength = 0.015 * dist_from_circle;
	vec2 center = vec2(resolution.x * 0.5, resolution.y * 0.5);
	vec3 color=vec3(0.0, 0.0, 0.0);
	float total=0.0;
	vec2 toCenter=center-uv*resolution;
	float offset=random(vec3(12.9898,78.233,151.7182),0.0);
	for(float t=0.0;t<=8.0;t++){
		float percent=(t+offset)/8.0;
		float weight=4.0*(percent-percent*percent);
		vec3 sample=texture2D(src_image,uv+toCenter*percent*strength/resolution).rgb;
		color+=sample*weight;
		total+=weight;
	}
	return color.rgb / total;
}

void main()
{
	vec3 base_colour = texture2D( SRC_IMAGE, PS_TEXCOORD0.xy ).rgb; // rgb all 0:1 - colour space
	
#if defined( ENABLE_LUNACY )
	if(OVERLAY_BLEND > 0.0)
	{
		vec3 zoom_colour = ZoomBlur(SRC_IMAGE, base_colour.rgb, PS_TEXCOORD0.xy);
		base_colour.rgb = base_colour.rgb * (1.0 - OVERLAY_BLEND) + zoom_colour.rgb * OVERLAY_BLEND;
	}
#endif

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
    
    cc *= INTENSITY_MODIFIER;	

	float overlay_blend = OVERLAY_BLEND;

#if defined( ENABLE_LUNACY )
	if(overlay_blend > 0.0)
	{
		vec3 overlay = texture2D( OVERLAY_IMAGE, PS_TEXCOORD0.xy ).rgb;
		vec4 overlay_buffer = texture2D(OVERLAY_BUFFER, PS_TEXCOORD0.xy);

		overlay_buffer.rgb += vec3(0.5, 0.5, 0.5);
		overlay = overlay.rgb + overlay_buffer.rgb;
		vec3 overlay_applied = BlendOverlay(cc.rgb, overlay.rgb);
		
		float alpha = 0.299*overlay_buffer.r + 0.587*overlay_buffer.g + 0.114*overlay_buffer.b;
		// TODO(YOG): Why is there a little bit of alpha over the entire screen?
		const float alpha_bias = 0.3;
		alpha = alpha - alpha_bias;
		alpha = alpha / (1.0 - alpha_bias);
		alpha = (alpha + 0.5);
		alpha = min(alpha * overlay_blend, 1.0);
		cc.rgb = mix(cc.rgb, overlay_applied.rgb, alpha);
	}
	else
#endif	
	{
		vec3 overlay = texture2D( OVERLAY_IMAGE, PS_TEXCOORD0.xy ).rgb;
		vec4 overlay_buffer = texture2D(OVERLAY_BUFFER, PS_TEXCOORD0.xy);
		cc.rgb = cc.rgb + overlay.rgb * overlay_blend + overlay_buffer.rgb * overlay_blend;
	}
	

    gl_FragColor = vec4( cc.rgb, 1.0 );
}

                     