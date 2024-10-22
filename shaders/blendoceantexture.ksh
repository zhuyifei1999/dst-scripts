   blendoceantexture      SAMPLER    +         OCEAN_TEXTURE_BLEND_PARAMS                                blendoceantexture.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}

    blendoceantexture.ps�  #if defined( GL_ES )
precision highp float;
#endif

varying vec2 PS_TEXCOORD0;

uniform sampler2D SAMPLER[2];

uniform vec4 OCEAN_TEXTURE_BLEND_PARAMS;

void main()
{
	vec4 source_tex = texture2D( SAMPLER[0], PS_TEXCOORD0.xy ).rgba;
	vec4 dest_tex = texture2D( SAMPLER[1], PS_TEXCOORD0.xy ).rgba;

	gl_FragColor = mix(source_tex, dest_tex, OCEAN_TEXTURE_BLEND_PARAMS.x);
}

               