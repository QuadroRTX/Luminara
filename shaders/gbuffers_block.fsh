#version 430 compatibility

#include "/lib/voxel.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 Normal;

void main() {
	vec4 col = texture2D(texture, texcoord) * glcolor;

	/* DRAWBUFFERS:02 */
	gl_FragData[0] = pow(col, vec4(vec3(GAMMA), 1.0));
	gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1.0);
}