#version 120

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 Normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

void main() {
	vec3 modelPos = gl_Vertex.xyz;
	vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + vec3(0.0, 0.0, 0.0);
	vec3 view = mat3(gbufferModelView) * worldPos;
	vec4 clip = gl_ProjectionMatrix * vec4(view, 1.0);
	gl_Position = clip;
	Normal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}