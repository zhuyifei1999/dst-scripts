   anim_haunted      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         AMBIENT                            LIGHTMAP_WORLD_EXTENTS                                TINT_ADD                             	   TINT_MULT                                PARAMS                        HAUNTPARAMS                                CAMERARIGHT                            anim.vs�  #define HAUNT
uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;

#if defined( FADE_OUT )
    uniform mat4 STATIC_WORLD_MATRIX;
    varying vec2 FADE_UV;
#endif

void main()
{
	mat4 mtxPVW = MatrixP * MatrixV * MatrixW;
	gl_Position = mtxPVW * vec4( POSITION.xyz, 1.0 );

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );

	PS_TEXCOORD = TEXCOORD0;
	PS_POS = world_pos.xyz;

#if defined( FADE_OUT )
	vec4 static_world_pos = STATIC_WORLD_MATRIX * vec4( POSITION.xyz, 1.0 );
    vec3 forward = normalize( vec3( MatrixV[2][0], 0.0, MatrixV[2][2] ) );
    float d = dot( static_world_pos.xyz, forward );
    vec3 pos = static_world_pos.xyz + ( forward * -d );
    vec3 left = cross( forward, vec3( 0.0, 1.0, 0.0 ) );

    FADE_UV = vec2( dot( pos, left ) / 4.0, static_world_pos.y / 8.0 );
#endif
}

    anim.ps�  #define HAUNT
#if defined( GL_ES )
precision mediump float;
#endif

uniform mat4 MatrixW;


uniform sampler2D SAMPLER[4];

#ifndef LIGHTING_H
#define LIGHTING_H

// Lighting
varying vec3 PS_POS;
uniform vec3 AMBIENT;

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;

	vec3 colour = texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb + AMBIENT.rgb;

	return clamp( colour.rgb, vec3( 0, 0, 0 ), vec3( 1, 1, 1 ) );
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}

#endif //LIGHTING.h


varying vec3 PS_TEXCOORD;

uniform vec4 TINT_ADD;
uniform vec4 TINT_MULT;
uniform vec2 PARAMS;
uniform vec4 HAUNTPARAMS;
uniform vec3 CAMERARIGHT;

#define ALPHA_TEST PARAMS.x
#define LIGHT_OVERRIDE PARAMS.y

#if defined( FADE_OUT )
    uniform vec3 EROSION_PARAMS; 
    varying vec2 FADE_UV;

    #define ERODE_SAMPLER SAMPLER[2]
    #define EROSION_MIN EROSION_PARAMS.x
    #define EROSION_RANGE EROSION_PARAMS.y
    #define EROSION_LERP EROSION_PARAMS.z
#endif

void main()
{
    vec4 colour;
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }

    if( colour.a >= ALPHA_TEST )
    {

        gl_FragColor.rgba = colour.rgba;
        gl_FragColor.rgba *= TINT_MULT.rgba;
        gl_FragColor.rgb += vec3( TINT_ADD.rgb * colour.a );

#if defined( FADE_OUT )
        float height = texture2D( ERODE_SAMPLER, FADE_UV.xy ).a;
        float erode_val = clamp( ( height - EROSION_MIN ) / EROSION_RANGE, 0.0, 1.0 );
        gl_FragColor.rgba = mix( gl_FragColor.rgba, gl_FragColor.rgba * erode_val, EROSION_LERP );
#endif

        vec3 light = CalculateLightingContribution();

        gl_FragColor.rgb *= max( light.rgb, vec3( LIGHT_OVERRIDE, LIGHT_OVERRIDE, LIGHT_OVERRIDE ) );
#if defined( HAUNT )
		// first part should move to the vertex shader
  	  	float xp = PS_POS.x;
  	  	float yp = PS_POS.y;
  	  	float zp = PS_POS.z;

#if 1	// do it in local space (so moving objects don't expose a world space pattern)
		float objx = MatrixW[3][0];
		xp -= objx;
		float objz = MatrixW[3][2];
		zp -= objz;
		// Add in a random base to desynchronise identical objects
		xp += HAUNTPARAMS.y;
		zp += HAUNTPARAMS.y;
		yp += HAUNTPARAMS.y;
#endif

		const float PI = 3.1415;
		const float TWO_PI = 2.0 * PI;

		xp *= 5.;
		yp *= 5.;
		zp *= 5.;

		float time = HAUNTPARAMS.x * 3.0;

		float cx = CAMERARIGHT.x;
		float cz = CAMERARIGHT.z;

		float resx = cx * xp;
		float resz = cz * zp;

		float x = resx+resz;
		float y = yp;

		// scale the effect
		x *= 5.0 * HAUNTPARAMS.w;	
		y *= 5.0 * HAUNTPARAMS.w;

		float strength = HAUNTPARAMS.z;
		float rnd = sin(HAUNTPARAMS.y);
#if defined(BLOOM)
		// Hmmm, still unsure if it looks better with bloom at a different rate. It adds some obfuscation to the pattern
		time *= -2.0;
#else
		time *= 3.0;
#endif
		float pix = 
        (
              (sin((x + time * 7.0) / (12.0+rnd)))
            + (cos((y + time * 1.5)  / (7.0-rnd)))
            + (sin((x + y + 3.0 * time ) / (16.0 + 0.3 * sin(time / 100.0))))
            + (sin(sqrt((x * x + y * y)) / (8.0+rnd)))
        ) / 4.0;

		// either this:
		pix = 0.5 + 0.5 * sin(pix * PI);
		// or this
		//pix = 0.5 + 0.5 * pix;
		//pix = 0.5 + 0.5 * sin(pix * TWO_PI);

		float orig_a = gl_FragColor.a;
		// pix is the new alpha
		// Take the alpha out of the source pixel
		gl_FragColor.rgb /= orig_a;	

		// approx saturation
		float avg = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;
		float sat = avg;

//if (pix > 0.8) pix = 0.8;
//if (pix < 0.95) pix = 0.0;

		float r = gl_FragColor.r;
		float g = gl_FragColor.g;
		float b = gl_FragColor.b;
		float r2 = r * 3.0;
		float g2 = g * 3.0;
		float b2 = b * 3.0;
		vec3 rgb2 = vec3(r2,g2,b2);

		//gl_FragColor.rgb = 0.01 * gl_FragColor.rgb + vec3(sat,sat,sat);
		pix = pix * strength;
		gl_FragColor.rgb = (1.0-pix) * gl_FragColor.rgb + pix * rgb2;

		// Multiply in the original alpha
		gl_FragColor.r *= orig_a;
		gl_FragColor.g *= orig_a;
		gl_FragColor.b *= orig_a;

#if defined(BLOOM)
		// This condition isn't needed but if I take it out opengl errs out because sampler accesses are optimized out
//		if ((HAUNTPARAMS.y > 0.5))	// 1 in the bloompass. Could also multiply instead
		{
			float v = pix;
			v *= 0.5;
			v *= orig_a;
			v *= strength;
			// To stop OpenGL on crapping out on unused samplers.....
			gl_FragColor = gl_FragColor * 0.0001 + vec4(v,v,v,orig_a) * 0.9999;
		}
#endif
		// To see the plasma

#endif  
    }
    else
    {
        discard;
    }
}

              	                        	   
   