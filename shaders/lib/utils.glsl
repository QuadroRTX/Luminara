const float pi = 3.14159265358979323;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform int frameCounter;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;

#define SUNROT -40.0 //Sun's rotation [-45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0]
#define GAMMA 2.2 //Gamma value for color correction [1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0]
#define EXPOSURE 0.8 //manual exposure multiplier [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 250.0 500.0 750.0 1000.0]
#define GLOWING_ORES //Glowing ores
#define BOUNCES 5 //Amount of path tracing bounces [0 1 2 3 4 5 6 7 8 9 10 20 50 100 1000]
#define SUN_NEE
#define RUSSIAN_ROULETTE
#define HARDCODED_EMISSIVE 0 //hardcoded emissive [0 1]
#define GOLDEN_WORLD 0 //golden world [0 1]
#define ALBEDO_METALS 0 //albedo metals [0 1]
#define GLASS_BORDER 0 //borders around glass [0 1]
//#define MANUALFOV
#define FOV 90.0 //Fov [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0 41.0 42.0 43.0 44.0 45.0 46.0 47.0 48.0 49.0 50.0 51.0 52.0 53.0 54.0 55.0 56.0 57.0 58.0 59.0 60.0 61.0 62.0 63.0 64.0 65.0 66.0 67.0 68.0 69.0 70.0 71.0 72.0 73.0 74.0 75.0 76.0 77.0 78.0 79.0 80.0 81.0 82.0 83.0 84.0 85.0 86.0 87.0 88.0 89.0 90.0 91.0 92.0 93.0 94.0 95.0 96.0 97.0 98.0 99.0 100.0 101.0 102.0 103.0 104.0 105.0 106.0 107.0 108.0 109.0 110.0 111.0 112.0 113.0 114.0 115.0 116.0 117.0 118.0 119.0 120.0 121.0 122.0 123.0 124.0 125.0 126.0 127.0 128.0 129.0 130.0 131.0 132.0 133.0 134.0 135.0 136.0 137.0 138.0 139.0 140.0 141.0 142.0 143.0 144.0 145.0 146.0 147.0 148.0 149.0 150.0 151.0 152.0 153.0 154.0 155.0 156.0 157.0 158.0 159.0 160.0 161.0 162.0 163.0 164.0 165.0 166.0 167.0 168.0 169.0 170.0 171.0 172.0 173.0 174.0 175.0 176.0 177.0 178.0 179.0 180.0]

vec3 tone(vec3 color){	
	mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
	);
	mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
	);
	vec3 v = m1 * color;    
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / GAMMA));	
}

vec4 quaternionMultiply (vec4 a, vec4 b) {
    return vec4(
        a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x,
        -a.x * b.z + a.y * b.w + a.z * b.x + a.w * b.y,
        a.x * b.y - a.y * b.x + a.z * b.w + a.w * b.z,
        -a.x * b.x - a.y * b.y - a.z * b.z + a.w * b.w
    );
}

vec3 quaternionRotate (vec3 pos, vec4 q) {
    vec4 qInv = vec4(-q.xyz, q.w);
    return quaternionMultiply(quaternionMultiply(q, vec4(pos, 0)), qInv).xyz;
}

vec4 getRotationToZAxis (vec3 vec) {
	if (vec.z < -0.99999) return vec4(1.0, 0.0, 0.0, 0.0);

	return normalize(vec4(vec.y, -vec.x, 0.0, 1.0 + vec.z));
}

vec3 rotate(vec3 vec, vec3 from, vec3 to) {
    vec3 halfway = normalize(from + to);
    vec4 quat = vec4(cross(from, halfway), dot(from, halfway));
    vec4 qInv = vec4(-quat.xyz, quat.w);
    return quaternionMultiply(quaternionMultiply(quat, vec4(vec, 0)), qInv).xyz;
}

vec3 emissivecol (int id) {
    vec3 emissive;
    if (id == 3) emissive = vec3(0.95, 0.6, 0.25);
    if (id == 4) emissive = vec3(0.7, 0.9, 1.0);
    if (id == 5) emissive = vec3(1.0, 0.6, 0.2);
    if (id == 6) emissive = vec3(1.0, 0.6, 0.2);
    if (id == 10) emissive = vec3(0.7, 0.2, 1.0);
    if (id == 16) emissive = vec3(1.0, 0.8, 0.3);
    if (id == 17) emissive = vec3(0.9, 0.8, 1.0);
    #ifdef GLOWING_ORES
    if (id == 8) emissive = vec3(0.2, 0.7, 1.0);
    if (id == 9) emissive = vec3(1.0, 0.7, 0.4);
    if (id == 11) emissive = vec3(0.3, 1.0, 0.3);
    if (id == 12) emissive = vec3(1.0, 0.0, 0.0);
    if (id == 13) emissive = vec3(1.0, 1.0, 1.0);
    if (id == 14) emissive = vec3(1.0, 0.8, 0.1);
    if (id == 15) emissive = vec3(0.2, 0.4, 1.0);
    if (id == 16) emissive = vec3(1.0, 0.6, 0.2);
    #endif
    return pow(emissive, vec3(GAMMA));
}

float emissivebright (int id) {
    float emissive;
    if (id == 3) emissive = 1.0;
    if (id == 4) emissive = 1.0;
    if (id == 5) emissive = 1.0;
    if (id == 6) emissive = 1.0;
    if (id == 10) emissive = 50.0;
    if (id == 16) emissive = 1.0;
    if (id == 17) emissive = 1.0;
    #ifdef GLOWING_ORES
    if (id == 8) emissive = 1000.0;
    if (id == 9) emissive = 1000.0;
    if (id == 11) emissive = 1000.0;
    if (id == 12) emissive = 50.0;
    if (id == 13) emissive = 1000.0;
    if (id == 14) emissive = 1000.0;
    if (id == 15) emissive = 1000.0;
    if (id == 16) emissive = 1000.0;
    #endif
    return emissive;
}

vec3 emissiveget (int id) {
    return emissivecol(id) * emissivebright(id);
}

#define FOCAL 25 //focus distance [1 2 3 4 5 6 7 8 9 10 15 20 25 30 35 40 45 50 60 70 80 90 100 125 150 175 200 225 250 275 300 325 350 375 400 425 450 475 500]
#define F_STOPS 2.0 //f-stops [0.001 0.01 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0 4.25 4.5 4.75 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 22.0 24.0 26.0 28.0 30.0 32.0 36.0 40.0 44.0 48.0 52.0 56.0 60.0 64.0]
#define AUTOFOCUS 1 //autofocus [0 1]

vec3 proj(mat4 projectionMatrix, vec3 pos) {
    vec4 homoPos = projectionMatrix * vec4(pos, 1.0);
    return homoPos.xyz / homoPos.w;
}

vec3 world(vec2 TexCoords, sampler2D depthtex) {
    vec3 screenPos = vec3(TexCoords, texture2D(depthtex, TexCoords));
    vec3 ndcPos = screenPos * 2.0 - 1.0;
    vec3 viewPos = proj(gbufferProjectionInverse, ndcPos);
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    return eyePlayerPos + eyeCameraPosition;
}

vec3 eyePlayer(vec2 TexCoords, sampler2D depthtex) {
    vec3 screenPos = vec3(TexCoords, texture2D(depthtex, TexCoords));
    vec3 ndcPos = screenPos * 2.0 - 1.0;
    vec3 viewPos = proj(gbufferProjectionInverse, ndcPos);
    return mat3(gbufferModelViewInverse) * viewPos;
}

vec3 view(vec2 TexCoords, sampler2D depthtex) {
    vec3 screenPos = vec3(TexCoords, texture2D(depthtex, TexCoords));
    vec3 ndcPos = screenPos * 2.0 - 1.0;
    return proj(gbufferProjectionInverse, ndcPos);
}

vec3 view2player (vec3 view) {
    return (gbufferModelViewInverse * vec4(view, 1.0)).xyz;
}

vec3 view2world (vec3 view) {
    return (gbufferModelViewInverse * vec4(view, 1.0)).xyz + cameraPosition;
}