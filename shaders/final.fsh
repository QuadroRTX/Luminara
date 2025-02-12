#version 430 compatibility

#include "/lib/utils.glsl"

varying vec2 TexCoords;

/*
const int colortex0Format = RGBA32F;
*/

void main() {
	vec4 col = max(texture(colortex0, TexCoords), 0.0);

    col.rgb = tone(col.rgb * EXPOSURE);
    
	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(col.rgb, 1.0);
}