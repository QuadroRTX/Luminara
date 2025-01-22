#version 430 compatibility

#include "/lib/voxel.glsl"

in vec2 TexCoords;
in vec3 viewPos;

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

/*
const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGBA32F;
const int colortex6Format = RGBA32F;
const int colortex10Format = RGBA32F;
*/

/* RENDERTARGETS: 0,3,4,6 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 prevOutput;
layout(location = 2) out vec4 prevDepthOut;
layout(location = 3) out vec4 albout;

uniform float frameTimeCounter;
uniform bool notMoving;
uniform float sunAngle;
uniform ivec2 eyeBrightnessSmooth;

#include "/lib/water.glsl"
#include "/lib/sky.glsl"

const bool colortex3Clear = false;
const bool colortex4Clear = false;
const float eyeBrightnessHalflife = 2.0;

const bool colortex3MipmapEnabled = true;

vec3 cosineWeightedDirection(vec3 normal, vec2 rand) {
    float angle = 2.0 * pi * rand.x;
    float phi = 2.0 * rand.y - 1.0;

    vec3 dir = vec3(sqrt(1.0 - phi * phi) * vec2(cos(angle), sin(angle)), phi);
    return normalize(normal + dir);
}

vec3 randDir(vec2 rand) {
    float angle = 2.0 * pi * rand.x;
    float phi = 2.0 * rand.y - 1.0;

    vec3 dir = vec3(sqrt(1.0 - phi * phi) * vec2(cos(angle), sin(angle)), phi);
    return normalize(dir);
}

void pcg(inout uint seed) {
    uint state = seed * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    seed = (word >> 22u) ^ word;
}

uint rngState = uint(viewWidth * viewHeight) * uint(frameCounter) + uint(gl_FragCoord.x + gl_FragCoord.y * viewWidth);

float randF()  { pcg(rngState); return float(rngState) / float(0xffffffffu); }

vec2  rand2F() { return vec2(randF(), randF());}

#include "/lib/brdf.glsl"

vec3 coneDir(vec3 vector, float angle) {
    vec2 xy = rand2F();
    xy.x *= radians(360.0);
    float cosAngle = cos(angle);
    xy.y = xy.y * (1.0 - cosAngle) + cosAngle;
    vec3 sphereCap = vec3(vec2(cos(xy.x), sin(xy.x)) * sqrt(1.0 - xy.y * xy.y), xy.y);
    return Rotate(sphereCap, vec3(0, 0, 1), vector);
}

const float sunPathRotation = SUNROT;

vec3 emissivecol (int id) {
    vec3 emissive;
    if (id == 33) emissive = vec3(0.95, 0.6, 0.25);
    if (id == 34) emissive = vec3(0.7, 0.9, 1.0);
    if (id == 37) emissive = vec3(1.0, 0.6, 0.2);
    if (id == 38) emissive = vec3(1.0, 0.6, 0.2);
    if (id == 42) emissive = vec3(0.7, 0.2, 1.0);
    if (id == 48) emissive = vec3(1.0, 0.8, 0.3);
    if (id == 49) emissive = vec3(0.9, 0.8, 1.0);
    #ifdef CHEATS
    if (id == 39) emissive = vec3(0.2, 0.7, 1.0);
    if (id == 40) emissive = vec3(1.0, 0.7, 0.4);
    if (id == 41) emissive = vec3(0.3, 1.0, 0.3);
    if (id == 43) emissive = vec3(1.0, 0.0, 0.0);
    if (id == 44) emissive = vec3(1.0);
    if (id == 45) emissive = vec3(1.0, 0.8, 0.1);
    if (id == 46) emissive = vec3(0.2, 0.4, 1.0);
    if (id == 47) emissive = vec3(1.0, 0.6, 0.2);
    #endif
    return pow(emissive, vec3(GAMMA));
}

float emissivebright (int id) {
    float emissive;
    if (id == 33) emissive = 250.0;
    if (id == 34) emissive = 250.0;
    if (id == 37) emissive = 250.0;
    if (id == 38) emissive = 250.0;
    if (id == 42) emissive = 250.0;
    if (id == 48) emissive = 250.0;
    if (id == 49) emissive = 250.0;
    #ifdef CHEATS
    if (id == 39) emissive = 1000.0;
    if (id == 40) emissive = 1000.0;
    if (id == 41) emissive = 1000.0;
    if (id == 43) emissive = 1000.0;
    if (id == 44) emissive = 50.0;
    if (id == 45) emissive = 1000.0;
    if (id == 46) emissive = 1000.0;
    if (id == 47) emissive = 1000.0;
    #endif
    return emissive;
}

vec3 emissiveget (int id) {
    return emissivecol(id) * emissivebright(id);
}

vec3 ggx (vec2 Xi, vec3 N, float roughness) {
    float a = roughness*roughness;
	
    float phi = 2.0 * pi * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
	
    // from spherical coordinates to cartesian coordinates
    vec3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;
	
    // from tangent-space vector to world-space sample vector
    vec3 up        = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent   = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);
	
    vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(sampleVec);
}

float fresnel(float n1, float n2, vec3 normal, vec3 incident, float f0, float f90) {
        float r0 = (n1-n2) / (n1+n2);
        r0 *= r0;
        float cosX = -dot(normal, incident);
        if (n1 > n2)
        {
            float n = n1/n2;
            float sinT2 = n*n*(1.0-cosX*cosX);

            if (sinT2 > 1.0)
                return f90;
            cosX = sqrt(1.0-sinT2);
        }
        float x = 1.0-cosX;
        float ret = r0+(1.0-r0)*x*x*x*x*x;
 
        return mix(f0, f90, ret);
}

vec3 reproject(vec3 worldPos) {
    vec3 prevPlayerPos = worldPos - previousCameraPosition;
    vec3 prevViewPos = (gbufferPreviousModelView * vec4(prevPlayerPos, 1.0)).xyz;
    vec4 prevClipPos = gbufferPreviousProjection * vec4(prevViewPos, 1.0);
    return prevClipPos.xyz / prevClipPos.w * 0.5 + 0.5;
}

vec3 path(in vec3 ro, in vec3 rd, inout uint rngState, in vec3 col, in vec3 alb, in vec3 ord, in vec3 norm, in vec3 oro, in bool underWater, in vec4 albw, in int id, float F0, float rough) {
    vec3 pro = ro;
    ivec3 test = voxelpos(ro + ord * 0.05 - norm * 0.05);
    vec3 ret; 
    if(emissiveget(id) != vec3(0.0)) ret = col * 10.0;
    vec3 through = col;
    if (isEyeInWater == 1) through *= exp(-clamp(distance(oro, eyeCameraPosition) * 0.25, 0.0, 20.0) * (1.0 - pow(vec3(0.15, 0.5, 0.8), vec3(1.0 / GAMMA))));
    else if (albw.rgb != vec3(0.0) && albw.a == 31) through *= exp(-clamp(distance(oro, ro) * 0.25, 0.0, 20.0) * (1.0 - pow(vec3(0.15, 0.5, 0.8), vec3(1.0 / GAMMA))));
    ret += skyColor * AMBIENT * through;
    vec3 currPos;
    vec3 misc;
    vec4 misc4;
    vec3 emissive;
    vec3 sunrd = coneDir(mat3(gbufferModelViewInverse) * normalize(shadowLightPosition), radians(sundeg));
    vec3 rsunrd = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
    vec4 water;
    vec3 waterPos;
    vec4 sundirect = trace(ro, sunrd, misc, misc, water, waterPos);

    vec3 sunintens = vec3(plancks(680.0, 5800.0), plancks(550.0, 5800.0), plancks(440.0, 5800.0));
    vec3 suncol = sunintens * lighttrans(vec3(0.0, planetrad, 0.0), sunrd);

    if (sundirect == vec4(0.0) && rough >= 0.25) {
        if (water.rgb != vec3(0.0)) {
            if (water.a < 0.75 && underWater) {
                ret += suncol * 2.0 * pi * (1.0 - cos(radians(sundeg))) * brdf(alb, rough, 0.0, vec3(F0), norm, -ord, sunrd) * exp(-clamp(distance(ro, waterPos) * 0.25, 1.0, 20.0) * (1.0 - water.rgb));
            } else if (water.a < 0.75 && !underWater) {
                ret += suncol * 2.0 * pi * (1.0 - cos(radians(sundeg))) * brdf(alb, rough, 0.0, vec3(F0), norm, -ord, sunrd);
            }
            else {
                ret += suncol * 2.0 * pi * (1.0 - cos(radians(sundeg))) * brdf(alb, rough, 0.0, vec3(F0), norm, -ord, sunrd) * water.rgb;
            }
        }
        else ret += suncol * 2.0 * pi * (1.0 - cos(radians(sundeg))) * max(brdf(alb, rough, 0.0, vec3(F0), norm, -ord, sunrd), 0.0);
    }

    float rough2 = 1.0;

    for (int bounce = 0; bounce < BOUNCES; bounce++) {
        vec4 test = trace(ro, rd, currPos, norm, water, misc);

        vec3 prd = rd;

        if (water.rgb != vec3(0.0) && water.a < 0.75) underWater = !underWater;
        emissive = vec3(0.0);
        if(test.rgb == vec3(0.0)) {
            if ((bounce == 0 && rough < 0.25) || rough2 < 0.25) ret += through * sky(rd, vec3(0.0));
            else ret += through * sky2(rd, vec3(0.0));
            break;
        }

        if (underWater) through *= exp(-max(distance(ro, currPos), 2.0) * (1.0 - vec3(0.15, 0.5, 0.8)) * 0.25);

        ro = currPos + norm * 0.001;

        vec3 spec = color(ro, norm, colortex8, voxelpos(currPos - norm * 0.001)).rgb;
        rough2 = pow(1.0 - spec.r, 2.0);
        vec3 alb = pow(color(ro, norm, colortex7, voxelpos(currPos - norm * 0.001)).rgb, vec3(2.2));

        vec3 waterPos;
        vec4 testsun = trace(ro, sunrd, misc, misc, water, waterPos);
        
        if (testsun.rgb == vec3(0.0)) {
            if (water.rgb != vec3(0.0)) {
                if (water.a < 0.75) ret += through * suncol * 2.0 * pi * (1.0 - cos(radians(sundeg))) * brdf(alb, rough, 0.0, vec3(F0), norm, -prd, sunrd) * exp(-max(distance(ro, waterPos), 2.0) * (1.0 - water.rgb) * 0.25);
                else ret += through * brdf(alb, rough, 0.0, vec3(F0), norm, -prd, sunrd) * water.rgb * suncol * 2.0 * pi * (1.0 - cos(radians(sundeg)));
            } else {
                ret += through * suncol * 2.0 * pi * (1.0 - cos(radians(sundeg))) * brdf(alb, rough, 0.0, vec3(F0), norm, -prd, sunrd);
            }
        }

        emissive = emissiveget(int(round(test.a * 64.0)));
        //dospec = 0.0;
        vec3 brdfv = vec3(0.0);
        rd = sampleSpecular(alb, rough, 0.0, vec3(spec.g), norm, -rd, brdfv);
        //vec3 facetnorm = ggx(rand2F(), norm, pow(1.0 - spec.r, 2.0));
        //if (spec.g != 0.0) dospec = fresnel(1.0, 1.0, prd, facetnorm, spec.g, 1.0);
        //dospec = (randF() < dospec) ? 1.0 : 0.0;
        //rd = reflect(rd, facetnorm);
        //if (dospec == 0.0 || bounce >= BOUNCES - 2) rd = cosineWeightedDirection(norm, rand2F());

        if (water.rgb != vec3(0.0)) {
            ret += emissive * through * exp(-water.a) * water.rgb;
        }
        else ret += emissive * through;

        through *= brdfv * 2.0 * pi;

        {
        	float p = max(through.r, max(through.g, through.b));
        	if (randF() > p)
            	break;

        	through *= 1.0 / p;            
        }

        pro = ro;
    }
	
    return ret;
}

void main(){
    vec3 screenPos = vec3(TexCoords, texture2D(depthtex0, TexCoords));
    vec3 screenPos2 = vec3(TexCoords, texture2D(depthtex1, TexCoords));
    vec3 viewPos = view(TexCoords, depthtex0);
    vec3 viewPos2 = view(TexCoords, depthtex1);
    vec3 eyePlayerPos = eyePlayer(TexCoords, depthtex0);
    vec3 eyePlayerPos2 = eyePlayer(TexCoords, depthtex1);
    vec3 worldPos = eyePlayerPos + eyeCameraPosition;
    vec3 worldPos2 = eyePlayerPos2 + eyeCameraPosition;
    vec3 rd = mat3(gbufferModelViewInverse) * normalize(viewPos);
    vec3 Normal = normalize(texture2D(colortex2, TexCoords).rgb * 2.0 - 1.0);
    vec3 Normal2 = normalize(texture2D(colortex10, TexCoords).rgb * 2.0 - 1.0);
    vec3 midblock = texture2D(colortex1, TexCoords).rgb;
    vec3 misc;

    vec3 ro = worldPos;

    vec3 col;
    float shadow = 1.0;
    vec4 newCol;
    vec4 newfog;
    vec3 sunrd = normalize(mat3(gbufferModelViewInverse) * normalize(shadowLightPosition));
    ivec3 voxelloc = ivec3(worldPos2 + midblock/64.0 - floor(cameraPosition) + vec3(128.0, 64.0, 128.0));
    int bid = int(round(voxel.stuff[index(voxelloc)].test.a * 64.0));
    vec4 alb = texture2D(colortex0, TexCoords);
    vec4 oalb = alb;
    vec4 albw = texture(colortex6, TexCoords);
    
    if (abs(voxelloc.x - 128.0) < 127.0 && abs(voxelloc.y - 64.0) < 63.0 && abs(voxelloc.z - 128.0) < 127.0 && texture(depthtex0, TexCoords).r != 1.0) {
        vec3 spec = texture(colortex9, TexCoords).rgb;
        float rough = pow(1.0 - spec.r, 2.0);
        vec3 brdf = vec3(0.0);
        vec3 finalrd = sampleSpecular(alb.rgb, rough, 0.0, spec.ggg, Normal, -rd, brdf);
        if (albw.rgb != vec3(0.0)) {
            vec3 rfrd = refract(rd, Normal, (isEyeInWater != 1) ? 3.0 / 4.0 : 4.0 / 3.0);
            float fresnel = fresnel(1.0, (isEyeInWater != 1) ? 4.0 / 3.0 : 3.0 / 4.0, rd, Normal, 0.0, 1.0);
            float doSpec = (randF() < fresnel) ? 1.0 : 0.0;
            vec3 waterrd = mix(rfrd, reflect(rd, Normal), doSpec);
            vec3 currPos;
            vec3 misc;
            vec4 misc4;
            vec3 norm2;
            vec4 water;
            vec4 trace = trace(worldPos, waterrd, currPos, norm2, water, misc);
            if (trace.rgb != vec3(0.0)) {
                alb.rgb = pow(color(currPos, norm2, colortex7, voxelpos(currPos - norm2 * 0.001)).rgb, vec3(GAMMA)) * ((bid == 31) ? vec3(1.0) : pow(albw.rgb, vec3(1.0 / GAMMA)));
				//if (emissiveget(int(round(trace.a * 64.0))) != vec3(0.0)) alb.rgb *= 10.0;
                ro = currPos;
                Normal = norm2;
            }
        }
        vec3 skycol = sky(worldPos, finalrd, vec3(0.0)) * ((albw.rgb != vec3(0.0)) ? vec3(1.0) : alb.rgb);
        ro += Normal * 0.01 * clamp(length(eyePlayerPos2) / far * 3.0, 1.0, 10000.0);
        ro -= rd * 0.05;
        col += path(ro, finalrd, rngState, brdf, alb.rgb, rd, Normal, worldPos + Normal * 0.01 - rd * 0.05, (albw.rgb != vec3(0.0) || isEyeInWater == 1), vec4(albw.rgb, bid), bid, spec.g, pow(1.0 - spec.r, 2.0));
    }
    else {
        vec3 sunrgb = vec3(SUNR, SUNG, SUNB) * 20.0 / pi;
        if(sunAngle > 0.5) sunrgb = vec3(MOONR, MOONG, MOONB) * 0.5;
        sunrgb *= pow(dot(mat3(gbufferModelViewInverse) * normalize(shadowLightPosition), vec3(0.0, 1.0, 0.0)), 1.0/2.0);
        vec3 sun = alb.rgb * alb.w * sunrgb * max(dot(sunrd, Normal), 0.0);
        sun += skyColor * alb.rgb;
        col = alb.rgb * vec3(max(dot(Normal, sunrd), 0.0)) * vec3(SUNR, SUNG, SUNB) * 20.0 / pi + vec3(0.3, 0.5, 0.7) * 0.5;
        col = sun;
    }
    
    vec3 currPos;
    vec4 misc4;
    vec3 norm;

    vec4 trace = trace(eyeCameraPosition, rd, currPos, norm, misc4, misc);
    //col = color(currPos, norm, colortex7, voxelpos(currPos - norm * 0.001)).rgb;

    #if ACCUM == NORMAL
        vec4 lastcol = texture2D(colortex3, TexCoords);
        float weight = lastcol.a + 1.0;

        if(!notMoving || cameraPosition != previousCameraPosition) {lastcol.rgb = col; weight = 0.0;}

        newCol.rgb = mix(lastcol.rgb, col, 1.0 / (weight + 1.0));
        newCol.a = weight;
    #endif

    #if ACCUM == REPROJECT
        vec3 prevScreenPos = reproject(worldPos);
        float prevDepth = texture2D(colortex4, TexCoords).r;

        if (abs(linearizeDepthFast(prevScreenPos.z) - linearizeDepthFast(prevDepth)) > DEPTHREJECT || clamp(prevScreenPos.xy, 0.0, 1.0) != prevScreenPos.xy) {
            newCol.rgb = col;
            newCol.a = 1.0;
        } else if (texture2D(colortex5, prevScreenPos.xy).a == 0.0 && texture2D(colortex5, TexCoords).a != 0.0) {
            newCol.rgb = col;
            newCol.a = 1.0;
        } else if (texture2D(colortex5, prevScreenPos.xy).a != 0.0 && texture2D(colortex5, TexCoords).a == 0.0) {
            newCol.rgb = col;
            newCol.a = 1.0;
        } else {
            vec4 prevCol = texture2D(colortex3, prevScreenPos.xy);
            float water = 1.0;
            if (bid == 31) water = 0.5;
            float weight = min(prevCol.a + 1.0, float(REPROJECTFRAMES * water));
            newCol = mix(prevCol, vec4(col, 1.0), 1.0 / weight);
            newCol.a = weight;
        }
    #endif

    #if ACCUM == NONE
        newCol.rgb = col;
    #endif

    if (any(isnan(newCol.rgb))) newCol = vec4(vec3(0.0), 1.0);

    if(texture2D(depthtex0, TexCoords).r == 1.0) newCol.rgb = sky(eyeCameraPosition, rd, alb.rgb);

    fragColor = newCol;

    prevOutput = newCol;
    prevDepthOut = vec4(screenPos.z);
    albout = alb;
}