#version 450

layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(131072, 1, 1);

struct stuff {
    vec4 test;
    vec4 water;
    vec2 coord[6];
    vec4 tint;
};

layout(std430, binding = 0) buffer voxelBuffer {
    stuff stuff[];
} voxel;

void main() {
	voxel.stuff[gl_GlobalInvocationID.x].test = vec4(0.0);
    voxel.stuff[gl_GlobalInvocationID.x].water = vec4(0.0);
    voxel.stuff[gl_GlobalInvocationID.x].tint = vec4(0.0);
    for(int i = 0; i < 6; i++)
    voxel.stuff[gl_GlobalInvocationID.x].coord[i] = vec2(0.0);
}