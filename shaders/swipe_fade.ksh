
   swipe_fade   	   MatrixPVW                                                                                IMAGE_PARAMS                                PosUVColour.vsg  uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;
attribute vec4 DIFFUSE;

varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
	PS_COLOUR.rgba = vec4( DIFFUSE.rgb * DIFFUSE.a, DIFFUSE.a ); // premultiply the alpha
}

    swipe_fade.ps#  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];
varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

uniform vec2 ALPHA_RANGE;
uniform vec4 IMAGE_PARAMS;

#define ALPHA_MIN   ALPHA_RANGE.x
#define ALPHA_MAX   ALPHA_RANGE.y

#define PROGRESS		IMAGE_PARAMS.x
#define PHASE_SCALE		IMAGE_PARAMS.y 
 

void main()
{
	float slope = 2.0;
	
    float phase_1 = mix( 0.0, 4.0*slope, PROGRESS);
    phase_1 -= slope; //ensure we start at 0
    phase_1 -= PS_TEXCOORD.x*slope;
	phase_1 += PS_TEXCOORD.y*slope;
    phase_1 = max(0.0, phase_1);
    
	//phase_1 += texture2D( SAMPLER[0], PS_TEXCOORD ).x * 0.1;
	
	float phase_2 = mix( 0.0, 4.0*slope, PROGRESS-0.5);
    phase_2 -= slope; //ensure we start at 0
    phase_2 -= PS_TEXCOORD.x*slope;
	phase_2 += PS_TEXCOORD.y*slope;
	
	//phase_2 += texture2D( SAMPLER[0], PS_TEXCOORD ).x * 0.1;
	
    phase_2 = 1.0 - phase_2;
    phase_2 = max(0.0, phase_2);
	
	float t = mix( phase_1, phase_2, PHASE_SCALE );
	
	gl_FragColor = vec4(0,0,0,t);
}

              