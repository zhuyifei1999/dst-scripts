
   anim_bloom      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         anim_bloom.vs#  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec4 POS2D_UV;                   // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;

void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
	// Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

	mat4 mtxPVW = MatrixP * MatrixV * MatrixW;
	gl_Position = mtxPVW * vec4( POSITION.xyz, 1.0 );

	PS_TEXCOORD = TEXCOORD0;
}

    anim_bloom.psT  #if defined( GL_ES )
precision mediump float;
#endif

#if defined( TRIPLE_ATLAS )
    uniform sampler2D SAMPLER[6];
#else
    uniform sampler2D SAMPLER[2];
#endif	

varying vec3 PS_TEXCOORD;

void main()
{
    vec4 colour;

#if defined( TRIPLE_ATLAS )
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else if( PS_TEXCOORD.z < 1.5 )
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[5], PS_TEXCOORD.xy );
    }
#else
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
#endif

    gl_FragColor.rgba = vec4( 0, 0, 0, colour.a );
}

                    