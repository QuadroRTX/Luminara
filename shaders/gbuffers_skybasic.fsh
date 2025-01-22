#version 430

in vec4 starData;

/*
const int colortex0Format = RGBA16F;
*/

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;

void main() {
	vec3 col;
    
	if (starData.a != 0.0) {
		col = starData.rgb * 5.0;
	}

	colortex0Out = vec4(col, 1.0);
}