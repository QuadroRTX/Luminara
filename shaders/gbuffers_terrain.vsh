#version 460 compatibility

#include "lib/utils.glsl"
#include "/lib/importantStuff.glsl"

uniform sampler2D gtexture;

in vec2 mc_midTexCoord;
in vec3 at_midBlock;
in vec4 mc_Entity;

void main() {
	int bid = int(round(mc_Entity.x));
	bid = max(bid, 0);

    vec2 texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    ivec2 atlasSize = textureSize(gtexture, 0);

	vec3 norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));

	int face = faceid(norm);

	uint id = 0u;
	id = packUnorm4x8(vec4(gl_Color.rgb, 0.0));
	id = bitfieldInsert(id, bid, 24, 8);

	if (bid != 1 || (bid == 1 && norm.y > 0.9)) {
		addVoxel(
			ivec3(floor((gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz + cameraPosition + at_midBlock / 64.0)),
			ivec2(mc_midTexCoord * atlasSize), id, face, int(abs(texcoord - mc_midTexCoord).x * atlasSize.x * 2.0)
		);
	}
	gl_Position = vec4(10.0);
}