#version 430 compatibility

uniform float alphaTestRef;
uniform sampler2D texture;
uniform sampler2D lightmap;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 tint;
in vec3 Normal;

void main() {
	vec4 col = texture2D(texture, texcoord);
	//if (col.a < alphaTestRef) discard;

	/* DRAWBUFFERS:025 */
	gl_FragData[0] = col; //gcolor
	gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1.0);
	gl_FragData[2] = col;
}