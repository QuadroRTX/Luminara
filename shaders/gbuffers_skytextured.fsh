#version 150
#extension GL_ARB_explicit_attrib_location : enable

uniform sampler2D gtexture;
uniform float viewWidth;
uniform float viewHeight;  

in vec2 texcoord;
in vec4 tint;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	vec4 col = texture(gtexture, texcoord) * tint;
    col.rgb *= 0.0;
    
	colortex0Out = col;
}