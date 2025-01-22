#version 430 compatibility

#include "/lib/voxel.glsl"

uniform sampler2D specular;
uniform sampler2D normals;
uniform sampler2D texture;
layout(rgba8) uniform image3D cimage1;

const float ambientOcclusionLevel = 0.0f;

in vec2 lmcoord;
in flat ivec3 voxelloc;
in vec2 midTexCoord;
in vec2 texcoord;
in vec4 glcolor;
in vec4 shadowPos;
in vec3 modelPos;
in vec3 viewPos;
in vec3 worldPos;
in vec3 eyePlayerPos;
in vec3 midblock;
in vec3 tangent;
in vec3 Normal;

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    // For DirectX normal mapping you want to switch the order of these 
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

void main() {

	vec4 col = texture2D(texture, texcoord) * pow(glcolor, vec4(1.0));
	col.rgb = pow(col.rgb, vec3(GAMMA));
	col.rgb *= glcolor.a;

	vec3 map = texture2D(normals, texcoord).rgb * 2.0 - 1.0;
	map.z = sqrt(1.0 - dot(map.xy, map.xy));
	vec3 Normal2 = normalize(tbnNormalTangent(Normal, tangent) * map);

	/* DRAWBUFFERS:0129 */
	gl_FragData[0] = col; //gcolor
	gl_FragData[1] = vec4(midblock, 1.0);
	gl_FragData[2] = vec4(Normal2 * 0.5 + 0.5, 1.0);
	gl_FragData[3] = texture2D(specular, texcoord);
} 