#version 430 compatibility

#include "/lib/voxel.glsl"

out vec2 TexCoords;
out vec3 modelPos;
out vec3 viewPos;
out vec3 eyePlayerPos;
out vec3 worldPos;
out vec2 pos;
out float id;
out vec4 Color;
out vec3 Normal;
in vec3 mc_Entity;

uniform mat4 gbufferProjection;
uniform sampler2D texture;
uniform float frameTimeCounter;
out vec3 midblock;
in vec2 mc_midTexCoord;
in vec3 at_midBlock;

#include "/lib/water.glsl"

void main() {
    TexCoords = gl_MultiTexCoord0.st;
    Normal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    id = mc_Entity.x;
    Color = gl_Color;
    int bid = int(id + 0.1);
    modelPos = gl_Vertex.xyz;
    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    worldPos = eyePlayerPos + eyeCameraPosition;
    pos = worldPos.xz;

    midblock = at_midBlock;
    ivec3 voxelloc = ivec3(worldPos + midblock/64.0 - floor(cameraPosition) + vec3(128.0, 64.0, 128.0));
    const int vid = index(voxelloc);
    vec4 col = vec4(0.0);
    if (bid == 42) col.rgb += 0.1;

    col.a = bid/64.0;
    if (abs(voxelloc.x - 128.0) < 127.0 && abs(voxelloc.y - 64.0) < 63.0 && abs(voxelloc.z - 128.0) < 127.0) {
        voxel.stuff[vid].test = col;
        if (bid == 31) {
            voxel.stuff[vid].water = pow(vec4(texture2D(texture, mc_midTexCoord).rgb, 0.5) * Color, vec4(vec3(GAMMA), 1.0));
        } else if (bid == 42) {
            voxel.stuff[vid].water = vec4(0.0);
        } else {
            voxel.stuff[vid].water = pow(vec4(texture2D(texture, mc_midTexCoord).rgb, 1.0), vec4(vec3(GAMMA), 1.0));
        }
        voxel.stuff[vid].coord[faceid(Normal)] = mc_midTexCoord;
    }

    gl_Position = ftransform();
}