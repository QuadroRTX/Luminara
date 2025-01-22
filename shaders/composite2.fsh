#version 430 compatibility

#include "/lib/voxel.glsl"

varying vec2 TexCoords;

const bool colortex0MipmapEnabled = true;

/*
const int colortex0Format = RGBA32F;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGBA32F;
const int colortex6Format = RGBA32F;
*/

#define GAUSSIAN
#define SELECTIVEEBLUR 1 //Reject blur if conditions aren't met [0 1]
#define BLUR 0 //Blur toggle [0 1]
#define BLURSIZE 1.0 //Blur size [0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0]

vec3 dither (vec2 uv, float depth) {
    vec3 dither = vec3(dot(vec2(171.0, 231.0), uv + frameCounter));
    dither = fract(dither / vec3(103.0, 71.0, 97.0));
    return dither / depth;
}

layout(std430, binding = 1) buffer exposBuf {
    float exposure;
} expos;

void main() {
	float tau = 6.28318530718;
	
	float dirs = 10.0;
	float qual = 8.0;
	float size = BLURSIZE;
	
	vec2 rad = size / vec2(viewWidth,viewHeight);
	
	vec4 col = texture(colortex0, TexCoords);
	float tick = 1.0;
	#if BLUR == 1
	#ifdef GAUSSIAN
	for(float d = 0.0; d < tau; d += tau / dirs) {
		for(float i = 1.0 / qual; i <= 1.0; i += 1.0 / qual) {
			#if SELECTIVEEBLUR == 1
			if (abs(linearizeDepthFast(texture(depthtex0, TexCoords + vec2(cos(d), sin(d)) * rad * i).r) - linearizeDepthFast(texture(depthtex0, TexCoords).r)) < 0.25 && texture(colortex2, TexCoords + vec2(cos(d), sin(d)) * rad * i) == texture(colortex2, TexCoords)) {
				col += texture(colortex0, TexCoords + vec2(cos(d), sin(d)) * rad * i);
				tick = tick + 1.0;
			}
			#else
			col += texture(colortex0, TexCoords + vec2(cos(d), sin(d)) * rad * i);
			tick = tick + 1.0;
			#endif
		}
	}
	col /= tick;
	#else
	for(float i = -size; i <= size; i++) {
		for(float d = -size; d <= size; d++) {
			#if SELECTIVEEBLUR == 1
			if (abs(linearizeDepthFast(texture(depthtex0, TexCoords + vec2(i, d) / vec2(viewWidth,viewHeight)).r) - linearizeDepthFast(texture(depthtex0, TexCoords).r)) < 0.25 && texture(colortex2, TexCoords + vec2(i, d) / vec2(viewWidth,viewHeight)) == texture(colortex2, TexCoords)) {
				col += texture(colortex0, TexCoords + vec2(i, d) / vec2(viewWidth,viewHeight));
				tick = tick + 1.0;
			}
			#else
			col += texture(colortex0, TexCoords + vec2(i, d) / vec2(viewWidth,viewHeight));
			tick = tick + 1.0;
			#endif
		}
	}
	col /= tick;
	#endif
	#else
	col = texture(colortex0, TexCoords);
	#endif

    col.rgb = tone(col.rgb * EXPOSURE);

    col.rgb = floor((col.rgb + dither(gl_FragCoord.xy, 512.0)) * 512.0) / 512.0;
    
	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(col.rgb, 1.0);
}