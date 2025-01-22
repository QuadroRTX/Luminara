uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D noisetex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float worldTime;
uniform ivec2 atlasSize;
uniform int isEyeInWater; 
uniform vec3 skyColor;

#define AMBIENT 0.0 //bruh please dont turn this up [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]
#define BOUNCES 10 //Amount of path tracing bounces [0 1 2 3 4 5 6 7 8 9 10 20 50 100 1000]
#define REPROJECT 1
#define NORMAL 2
#define NONE 3
#define ACCUM REPROJECT //Type of accumulation [REPROJECT NORMAL NONE]
#define REPROJECTFRAMES 10 //Amount of frames to accumulate with reprojection [2 3 4 5 6 7 8 9 10 15 20 30 60]
#define CHEATS //Glowing ores
#define DEPTHREJECT 1.0 //Maximum value of depth change before rejecting reproject sample [0.1 0.2 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 6.0 7.0 8.0 9.0 10.0]
#define SUNR 0.95 //Sun red value [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define SUNG 0.90 //Sun red value [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define SUNB 0.60 //Sun red value [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define MOONR 0.30 //Sun red value [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define MOONG 0.50 //Sun red value [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define MOONB 1.0 //Sun red value [0.0 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define SUNROT -20.0 //Sun's rotation [-45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0]
#define GAMMA 3.0 //Gamma value for color correction [1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0]
#define CAUSTICS //chill no its not water caustics just sun bounce off mirrors
#define BOUNCELENGTH 50 //how far a ray can travel [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100]
#define EXPOSURE 0.8 //manual exposure multiplier [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 5.0 10.0 25.0 50.0 75.0 100.0 250.0 500.0 750.0 1000.0]
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 previousCameraPosition; 
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float near;
uniform float far;
vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;

const float pi = 3.14159265358979323;

vec4 QuaternionMultiply(vec4 a, vec4 b) {
    return vec4(
        a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x,
        -a.x * b.z + a.y * b.w + a.z * b.x + a.w * b.y,
        a.x * b.y - a.y * b.x + a.z * b.w + a.w * b.z,
        -a.x * b.x - a.y * b.y - a.z * b.z + a.w * b.w
    );
}

vec3 Rotate(vec3 vec, vec3 from, vec3 to) {
    vec3 halfway = normalize(from + to);
    vec4 quat = vec4(cross(from, halfway), dot(from, halfway));
    vec4 qInv = vec4(-quat.xyz, quat.w);
    return QuaternionMultiply(QuaternionMultiply(quat, vec4(vec, 0)), qInv).xyz;
}

float linearizeDepthFast(float depth) {
    return (near * far) / (depth * (near - far) + far);
}

vec3 proj(mat4 projectionMatrix, vec3 pos) {
    vec4 homoPos = projectionMatrix * vec4(pos, 1.0);
    return homoPos.xyz / homoPos.w;
}

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

vec3 screen(vec3 world) {
    vec3 player = world - cameraPosition;
    vec3 view = (gbufferModelView * vec4(player, 1.0)).xyz;
    vec3 ndc = proj(gbufferPreviousProjection, view);
    return ndc * 0.5 + 0.5;
}