   sprite      SCREEN_PARAMS                                SPRITE_PARAMS                                SAMPLER    +      	   sprite.vs�  attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;
varying vec2 PS_TEXCOORD1;

uniform vec4 SCREEN_PARAMS;
uniform vec4 SPRITE_PARAMS;

void main()
{
	vec3 screen_pos = POSITION.xyz;
	screen_pos.x = screen_pos.x * SCREEN_PARAMS.z * SCREEN_PARAMS.y;
	screen_pos.xy = screen_pos.xy * SPRITE_PARAMS.xy;	
	screen_pos.xy = screen_pos.xy + SPRITE_PARAMS.zw;
	gl_Position = vec4( screen_pos.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}

 	   sprite.ps  #if defined( GL_ES )
precision highp float;
#endif

varying vec2 PS_TEXCOORD0;

uniform sampler2D SAMPLER[1];

#define SPRITE_IMAGE SAMPLER[0]

void main()
{
	vec4 sprite = texture2D( SPRITE_IMAGE, PS_TEXCOORD0.xy ).rgba;
    gl_FragColor = vec4(sprite.rgb, 1.0);
}

                 