uint64_t x, w1, s;  

uint msws() {
    x *= x; 
    x += (w1 += s); 
    return uint(x = (x >> 32u) | (x << 32u));
}

void init_msws(uint64_t seed) {
    x = 0u; w1 = 0u;
    s = (((uint64_t(1890726812u) << 32u) | seed) << 1u) | uint64_t(1u);

    msws(); msws();
}

#define rand() msws()
#define rand2() uvec2(msws(), msws())

#define randF() (float(rand() & 0x00ffffffu) / float(0x00ffffff))
#define rand2F() (vec2(rand2() & 0x00ffffffu) / float(0x00ffffff))

vec3 randV () {
    float z = randF() * 2.0 - 1.0;
    float a = randF() * pi * 2.0;
    float r = sqrt(1.0 - z * z);
    float x = r * cos(a);
    float y = r * sin(a);
    return vec3(x, y, z);
}

vec3 coneDir(vec3 vector, float angle) {
    //return vector;
    vec2 xy = rand2F();
    xy.x *= 2.0 * pi;
    float cosAngle = cos(angle);
    xy.y = xy.y * (1.0 - cosAngle) + cosAngle;
    vec3 sphereCap = vec3(vec2(cos(xy.x), sin(xy.x)) * sqrt(1.0 - xy.y * xy.y), xy.y);
    vec4 q = getRotationToZAxis(vector);
    return rotate(sphereCap, vec3(0.0, 0.0, 1.0), vector);
}