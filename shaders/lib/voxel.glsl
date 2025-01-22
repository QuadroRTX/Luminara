#include "/lib/utils.glsl"

struct stuff {
    vec4 test;
    vec4 water;
    vec2 coord[6];
    vec4 tint;
};

layout(std430, binding = 0) buffer voxelBuffer {
    stuff stuff[];
} voxel;


int index(ivec3 c) {
	return (c.z * 256 * 128) + (c.y * 256) + c.x;
}

ivec3 voxelpos(vec3 pos) { 
    return ivec3(floor(pos) - floor(cameraPosition) + vec3(128.0, 64.0, 128.0));
}

int faceid(vec3 norm) {
    if (abs(norm.y) > abs(norm.x) && abs(norm.y) > abs(norm.z)) {
        return (1 + int(sign(norm.y))) / 2;
    }
    if (abs(norm.x) > abs(norm.y) && abs(norm.x) > abs(norm.z)) {
        return (5 + int(sign(norm.x))) / 2;
    }
    if (abs(norm.z) > abs(norm.x) && abs(norm.z) > abs(norm.y)) {
        return (9 + int(sign(norm.z))) / 2;
    }
}

vec2 coord(vec3 pos, vec3 Normal, ivec2 size) {
    if (abs(Normal.y) > abs(Normal.x) && abs(Normal.y) > abs(Normal.z)) {
        return (fract(pos.xz) - 0.5) * 16.0 / size;
    } else {
        return vec2((fract(pos.x * sign(Normal.z) - pos.z * sign(Normal.x)) - 0.5) * 16.0 / size.x, (fract(-pos.y) - 0.5) * 16.0 / size.y);
    }
}

vec4 color(vec3 pos, vec3 norm, sampler2D atlas, ivec3 voxelloc) {
    ivec2 size = textureSize(atlas, 0);
    int id = faceid(norm);
    return texelFetch(atlas, ivec2(voxel.stuff[index(voxelloc)].coord[id] * size + coord(pos, norm, size) * vec2(size)), 0) * voxel.stuff[index(voxelloc)].tint;
}

mat3 tbn(vec3 norm) {
    if (abs(norm.y) > abs(norm.x) && abs(norm.y) > abs(norm.z)) {
        return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, sign(norm.y)), norm);
    } else {
        return mat3(vec3(sign(norm.z), 0.0, -sign(norm.x)), vec3(0.0, -1.0, 0.0), norm);
    }
}

vec4 trace(in vec3 ro, in vec3 rd, out vec3 currPos, out vec3 normal, out vec4 water, out vec3 waterPos) {
    vec3 stepSizes = 1.0 / abs(rd);
    vec3 stepDir = sign(rd);
    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(ro)) / rd;
    water = vec4(vec3(0.0), 0.0);
    waterPos = vec3(0.0);

    vec3 voxelPos = ro;
    currPos = ro;
    for (int i = 0; i < BOUNCELENGTH; i++) {
        vec4 block = voxel.stuff[index(voxelpos(voxelPos))].test;
        vec4 watertest = voxel.stuff[index(voxelpos(voxelPos))].water;
        vec3 lastPos = currPos;
        vec3 lastWater;

        if (block.rgb != vec3(0.0)) {
			float alpha = color(currPos, normal, colortex7, voxelpos(currPos - normal * 0.001)).a;
			if (alpha > 0.99) return block;
        }
		
        if (watertest.rgb != vec3(0.0)) waterPos = currPos + rd * min(min(nextDist.x, nextDist.y),min(nextDist.y, nextDist.z));
        if (watertest.rgb != vec3(0.0) && water == vec4(0.0)) {water = watertest; lastWater = watertest.rgb;}
        if (watertest.rgb != vec3(0.0) && water != vec4(0.0)) {
            if (watertest.rgb != lastWater) {water = pow(water, vec4(vec3(1.0 / GAMMA), 1.0)) * pow(watertest, vec4(vec3(1.0 / GAMMA), 1.0)); lastWater = watertest.rgb; }
        }

        float closestDist = min(min(nextDist.x, nextDist.y),min(nextDist.y, nextDist.z));
        currPos += rd * closestDist;
        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));
        voxelPos += stepAxis * stepDir;
        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;
        normal = -stepAxis * stepDir;
    }
    return vec4(0.0);
}