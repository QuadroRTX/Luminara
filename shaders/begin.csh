#version 460 compatibility

layout(local_size_x = 32, local_size_y = 1, local_size_z = 1) in;

//workGroups = VOXEL_ARRAY_SIZE / local_size_x.
const ivec3 workGroups = ivec3(524288, 1, 1);

#include "lib/utils.glsl"
#include "lib/importantStuff.glsl"

void main() {
	voxelArray[gl_GlobalInvocationID.x] = Voxel(0u, 0u, 0u, 0u);
	if (gl_GlobalInvocationID.x < LOD_4_SIZE + LOD_16_SIZE) {
		lodArray[gl_GlobalInvocationID.x] = ~0u;
	}
}