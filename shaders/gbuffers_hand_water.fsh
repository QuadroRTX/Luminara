#version 430 compatibility

#include "/lib/voxel.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 Normal;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

	/* DRAWBUFFERS:025 */
	gl_FragData[0] = pow(color, vec4(vec3(GAMMA), 1.0));
	gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1.0);
	gl_FragData[2] = color;
}