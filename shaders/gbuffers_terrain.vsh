#version 430 compatibility

in vec4 mc_Entity;

#include "/lib/voxel.glsl"

uniform sampler2D texture;
in vec2 mc_midTexCoord;
uniform float frameTimeCounter;

out vec2 lmcoord;
out vec2 midTexCoord;
out vec2 texcoord;
out vec4 glcolor;
out vec4 shadowPos;
out vec3 midblock;
out vec3 modelPos;
out vec3 viewPos;
out vec3 eyePlayerPos;
out vec3 worldPos;
out flat ivec3 voxelloc;
in vec3 at_midBlock;
in vec4 at_tangent;
out mat3 TBN;
out vec3 Normal;
out int bid;
out vec4 tangent;

void main() {
	bid = int(round(mc_Entity.x));
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	modelPos = gl_Vertex.xyz;
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
	worldPos = eyePlayerPos + eyeCameraPosition;
	Normal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
	vec3 B = normalize(cross(at_tangent.xyz, Normal) * at_tangent.w);
	tangent = at_tangent;

	midblock = at_midBlock;
	ivec3 voxelloc = ivec3(worldPos + midblock/64.0 - floor(cameraPosition) + vec3(128.0, 64.0, 128.0));
	int id = index(voxelloc);
	vec4 col = vec4(vec3(0.5), 1.0);
	midTexCoord = mc_midTexCoord + 0.5 / atlasSize;
	col.a = bid/64.0;
    
	if (abs(voxelloc.x - 128.0) < 127.0 && abs(voxelloc.y - 64.0) < 63.0 && abs(voxelloc.z - 128.0) < 127.0 && bid != 35) {
		voxel.stuff[id].test = col;
		voxel.stuff[id].coord[faceid(Normal)] = mc_midTexCoord;
		voxel.stuff[id].tint = glcolor;
	}

	gl_Position = ftransform();
}