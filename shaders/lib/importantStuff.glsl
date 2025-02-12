const uint VOXEL_ARRAY_SIZE = 4096 * 4096;
//normally these would be divided by 64, not 32,
//since each tree level stores 1/64'th as many blocks as the previous one.
//however, in my testing, complicated scenes could increase
//the chance that any given tree bin will be occupied.
//so, I double each level to compensate for that.
const uint LOD_4_SIZE = VOXEL_ARRAY_SIZE / 32;
const uint LOD_16_SIZE = LOD_4_SIZE / 32;
const int PROBE_ATTEMPTS = 64;

struct Voxel {
	uint packedPosition; //11 bits for x and z, 10 bits for y
	uint coords; //first 4 bits are face priority, other 28 are texcoords
	uint ids; //last 8 are block id, first 24 is gl_Color.rgb
    uint flags; //first 3 are face priority, next 5 are texture size
};

struct trace {
	Voxel voxel;
	vec3 pos;
	vec3 norm;
};

layout(std430, binding = 0) restrict buffer voxelBuffer {
	Voxel voxelArray[];
};
layout(std430, binding = 1) restrict buffer lodBuffer {
	uint lodArray[];
};

ivec3 size = ivec3(1024, 512, 1024);

uint pack (ivec2 coords, uint face) {
	uint x = 0u;
	x = bitfieldInsert(x, coords.x, 0, 14);
	x = bitfieldInsert(x, coords.y, 14, 14);
	x = bitfieldInsert(x, face, 28, 4);

	return x;
}

uint packflags (int size, uint face) {
	uint x = 0u;
    size = int(round(log2(size)));
	x = bitfieldInsert(x, size, 24, 5);
	x = bitfieldInsert(x, face, 29, 3);

	return x;
}

ivec2 unpackcoord (uint coord) {
	uint x = bitfieldExtract(coord, 0, 14);
	uint y = bitfieldExtract(coord, 14, 14);

	return ivec2(x, y);
}

vec3 unpacktint (uint id) {
	return unpackUnorm4x8(id).rgb;
}

int unpackid (uint id) {
	return int(bitfieldExtract(id, 24, 8));
}

int faceid (vec3 norm) {
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

vec2 getcoord (vec3 pos, vec3 norm, int size) {
    if (abs(norm.y) > abs(norm.x) && abs(norm.y) > abs(norm.z)) {
        return vec2((fract(pos.xz) - 0.5) * size);
    } else {
        return vec2((fract(pos.x * sign(norm.z) - pos.z * sign(norm.x)) - 0.5) * size, (fract(-pos.y) - 0.5) * size);
    }
}

vec4 getcolor (trace hit, sampler2D atlas) {
	vec3 pos = hit.pos;
	vec3 norm = hit.norm;
	Voxel voxel = hit.voxel;
    ivec2 coord = unpackcoord(voxel.coords);

    int size = int(exp2(bitfieldExtract(hit.voxel.flags, 24, 5)));

    return texelFetch(atlas, ivec2(coord + getcoord(pos, norm, size)), 0) * vec4(unpacktint(voxel.ids), 1.0);
}

vec4 getcolor (Voxel voxel, sampler2D atlas, vec3 pos, vec3 norm) {
    ivec2 coord = unpackcoord(voxel.coords);

    int size = int(exp2(bitfieldExtract(voxel.flags, 24, 5)));

    return texelFetch(atlas, ivec2(coord + getcoord(pos, norm, size)), 0) * vec4(unpacktint(voxel.ids), 1.0);
}

uint packPosition (ivec3 pos) {
	pos -= ivec3(floor(cameraPosition));
	pos &= (size - 1);

	return pos.x | (pos.z << 11) | (pos.y << 22);
}

uint packLodPos4 (ivec3 lodPos) {
	lodPos -= ivec3(floor(cameraPosition)) & ~3;
	lodPos &= (size - 1);

	return lodPos.x | (lodPos.z << 11) | (lodPos.y << 22);
}

uint packLodPos16 (ivec3 lodPos) {
	lodPos -= ivec3(floor(cameraPosition)) & ~15;
	lodPos &= (size - 1);

	return lodPos.x | (lodPos.z << 11) | (lodPos.y << 22);
}

const uint PHI = 0x9E3779B9u;

uint fastMix (uint value) {
	value *= PHI;

	return value ^ (value >> 16);
}

uint hashPosition (ivec3 pos) {
	uint hash = fastMix(uint(pos.x));
	hash = fastMix(hash + uint(pos.y));
	hash = fastMix(hash + uint(pos.z));

	return hash;
}

bool isInVoxelArea (ivec3 pos) {
	pos -= ivec3(floor(cameraPosition));

	return pos == clamp(pos, -size / 2, size / 2 - 1);
}

void addVoxel (ivec3 pos, ivec2 coord, uint id, uint face, int size) {
	if (isInVoxelArea(pos)) {
		uint hashedPosition = hashPosition(pos) & (VOXEL_ARRAY_SIZE - 1);
		uint packedPosition = packPosition(pos);
		
		uint packedCoords = pack(coord, id);
        uint flags = packflags(size, face);

		for (int attempt = 0; attempt < PROBE_ATTEMPTS; attempt++) {
			uint oldPackedPosition = atomicCompSwap(voxelArray[hashedPosition].packedPosition, 0u, packedPosition);
			if (oldPackedPosition == 0u || oldPackedPosition == packedPosition) {
				atomicMax(voxelArray[hashedPosition].coords, packedCoords);
				atomicMax(voxelArray[hashedPosition].ids, id);
                atomicMax(voxelArray[hashedPosition].flags, flags);
				break;
			}
			else {
				hashedPosition = (hashedPosition + 1u) & (VOXEL_ARRAY_SIZE - 1);
			}
		}

		ivec3 lodPos4 = pos & ~3;
		uint hashedLodPos4 = hashPosition(lodPos4) & (LOD_4_SIZE - 1);
		uint packedLodPos4 = packLodPos4(lodPos4);
		for (int attempt = 0; attempt < PROBE_ATTEMPTS; attempt++) {
			uint old = atomicCompSwap(lodArray[hashedLodPos4], ~0u, packedLodPos4);
			if (old == ~0u || old == packedLodPos4) {
				break;
			}
			else {
				hashedLodPos4 = (hashedLodPos4 + 1u) & (LOD_4_SIZE - 1);
			}
		}

		ivec3 lodPos16 = pos & ~15;
		uint hashedLodPos16 = hashPosition(lodPos16) & (LOD_16_SIZE - 1);
		uint packedLodPos16 = packLodPos16(lodPos16);
		for (int attempt = 0; attempt < PROBE_ATTEMPTS; attempt++) {
			uint old = atomicCompSwap(lodArray[hashedLodPos16 + LOD_4_SIZE], ~0u, packedLodPos16);
			if (old == ~0u || old == packedLodPos16) {
				break;
			}
			else {
				hashedLodPos16 = (hashedLodPos16 + 1u) & (LOD_16_SIZE - 1);
			}
		}
	}
}

Voxel getVoxel (ivec3 pos) {
	if (isInVoxelArea(pos)) {
		uint hashedPosition = hashPosition(pos) & (VOXEL_ARRAY_SIZE - 1);
		uint packedPosition = packPosition(pos);
		for (int attempt = 0; attempt < PROBE_ATTEMPTS; attempt++) {
			Voxel voxel = voxelArray[hashedPosition];
			if (voxel.coords == 0u) {
				break;
			}
			else if (voxel.packedPosition == packedPosition) {
				return voxel;
			}
			else {
				hashedPosition = (hashedPosition + 1u) & (VOXEL_ARRAY_SIZE - 1);
			}
		}
	}

	return Voxel(0u, 0u, 0u, 0u);
}

bool hasLod4 (ivec3 pos) {
	if (isInVoxelArea(pos)) {
		ivec3 lodPos4 = pos & ~3;
		uint hashedLodPos4 = hashPosition(lodPos4) & (LOD_4_SIZE - 1);
		uint packedLodPos4 = packLodPos4(lodPos4);
		for (int attempt = 0; attempt < PROBE_ATTEMPTS; attempt++) {
			uint old = lodArray[hashedLodPos4];
			if (old == ~0u) {
				break;
			}
			else if (old == packedLodPos4) {
				return true;
			}
			else {
				hashedLodPos4 = (hashedLodPos4 + 1u) & (LOD_4_SIZE - 1);
			}
		}
	}

	return false;
}

bool hasLod16 (ivec3 pos) {
	if (isInVoxelArea(pos)) {
		ivec3 lodPos16 = pos & ~15;
		uint hashedLodPos16 = hashPosition(lodPos16) & (LOD_16_SIZE - 1);
		uint packedLodPos16 = packLodPos16(lodPos16);
		for (int attempt = 0; attempt < PROBE_ATTEMPTS; attempt++) {
			uint old = lodArray[hashedLodPos16 + LOD_4_SIZE];
			if (old == ~0u) {
				break;
			}
			else if (old == packedLodPos16) {
				return true;
			}
			else {
				hashedLodPos16 = (hashedLodPos16 + 1u) & (LOD_16_SIZE - 1);
			}
		}
	}

	return false;
}

trace rayTrace1 (ivec3 section, vec3 ro, vec3 rd, vec3 norm) {
	ivec3 voxelPos = clamp(ivec3(floor(ro)), section, section | 3);
	for (int stepIndex = 0; stepIndex < 16 && (voxelPos & ~3) == section; stepIndex++) {
		Voxel voxel = getVoxel(voxelPos);
        int bid = unpackid(voxel.ids);
		if (voxel.coords != 0u && getcolor(voxel, colortex2, ro, norm).a > 0.2 || bid == 20 || bid == 21) return trace(voxel, ro, norm);

		vec3 relative = ro - vec3(voxelPos);
		vec3 distancesToFace = (step(vec3(0.0), rd) - relative) / rd;
		int index = 0;
		if (distancesToFace[1] < distancesToFace[0]) index = 1;
		if (distancesToFace[2] < distancesToFace[index]) index = 2;
		voxelPos[index] += int(sign(rd[index]));
		ro += rd * distancesToFace[index];
		norm = vec3(0.0);
		norm[index] = -sign(rd[index]);
	}

	return trace(Voxel(0u, 0u, 0u, 0u), vec3(0.0), vec3(0.0));
}

trace rayTraceTranslucent (vec3 ro, vec3 rd) {
	ivec3 voxelPos = ivec3(floor(ro));
    vec3 norm = vec3(0.0);
	for (int stepIndex = 0; stepIndex < 32; stepIndex++) {
		Voxel voxel = getVoxel(voxelPos);
        int bid = unpackid(voxel.ids);
		if (bid != 20 && bid != 21) return trace(voxel, ro, norm);

		vec3 relative = ro - vec3(voxelPos);
		vec3 distancesToFace = (step(vec3(0.0), rd) - relative) / rd;
		int index = 0;
		if (distancesToFace[1] < distancesToFace[0]) index = 1;
		if (distancesToFace[2] < distancesToFace[index]) index = 2;
		voxelPos[index] += int(sign(rd[index]));
		ro += rd * distancesToFace[index];
		norm = vec3(0.0);
		norm[index] = -sign(rd[index]);
	}

	return trace(Voxel(0u, 0u, 0u, 0u), vec3(0.0), vec3(0.0));
}

trace rayTrace4(ivec3 section, vec3 ro, vec3 rd, vec3 norm) {
	ivec3 voxelPos = clamp(ivec3(floor(ro)), section, section | 15) & ~3;
	for (int stepIndex = 0; stepIndex < 16 && (voxelPos & ~15) == section; stepIndex++) {
		if (hasLod4(voxelPos)) {
			trace result = rayTrace1(voxelPos, ro, rd, norm);
			if (result.voxel.coords != 0u) return result;
		}
		vec3 relative = ro - vec3(voxelPos & ~3);
		vec3 distancesToFace = (step(vec3(0.0), rd) * 4.0 - relative) / rd;
		int index = 0;
		if (distancesToFace[1] < distancesToFace[0]) index = 1;
		if (distancesToFace[2] < distancesToFace[index]) index = 2;
		voxelPos[index] += int(sign(rd[index])) << 2;
		ro += rd * distancesToFace[index];
		norm = vec3(0.0);
		norm[index] = -sign(rd[index]);
	}

	return trace(Voxel(0u, 0u, 0u, 0u), vec3(0.0), vec3(0.0));
}

trace rayTrace16 (vec3 ro, vec3 rd) {
	ivec3 voxelPos = ivec3(floor(ro)) & ~15;
    vec3 norm = vec3(0.0, 1.0, 0.0);
	for (int stepIndex = 0; stepIndex < 64 && isInVoxelArea(voxelPos); stepIndex++) {
		if (hasLod16(voxelPos)) {
			trace result = rayTrace4(voxelPos, ro, rd, norm);
			if (result.voxel.coords != 0u) return result;
		}
		vec3 relative = ro - vec3(voxelPos & ~15);
		vec3 distancesToFace = (step(vec3(0.0), rd) * 16.0 - relative) / rd;
		int index = 0;
		if (distancesToFace[1] < distancesToFace[0]) index = 1;
		if (distancesToFace[2] < distancesToFace[index]) index = 2;
		voxelPos[index] += int(sign(rd[index])) << 4;
		ro += rd * distancesToFace[index];
		norm = vec3(0.0);
		norm[index] = -sign(rd[index]);
	}

	return trace(Voxel(0u, 0u, 0u, 0u), vec3(0.0), vec3(0.0));
}

trace rayTrace (vec3 ro, vec3 rd) {
    if (any(isnan(rd)) || any(isinf(rd))) return trace(Voxel(0u, 0u, 0u, 0u), vec3(0.0), vec3(0.0));
    Voxel voxel = getVoxel(ivec3(floor(ro)));
    if (unpackid(voxel.ids) == 20 || unpackid(voxel.ids) == 21) {
        return rayTraceTranslucent(ro, rd);
    }
	return rayTrace16(ro, rd);
}