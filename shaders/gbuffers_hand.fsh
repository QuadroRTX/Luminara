#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D specular;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 Normal;

#include "/lib/utils.glsl"

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

	/* DRAWBUFFERS:0259 */
	gl_FragData[0] = pow(color, vec4(vec3(GAMMA), 1.0));
	gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1.0);
	gl_FragData[2] = color;
	gl_FragData[3] = texture2D(specular, texcoord);
}