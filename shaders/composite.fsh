#version 460 compatibility

#extension GL_ARB_gpu_shader_int64 : enable

#include "lib/utils.glsl"
#include "/lib/importantStuff.glsl"
#include "/lib/random.glsl"
#include "/lib/brdf.glsl"
#include "/lib/phase.glsl"
#include "/lib/sky.glsl"
#include "/lib/cie.glsl"

uniform bool notMoving;
in vec2 texcoords;

/*
const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
*/

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 prevColor;

const bool colortex1Clear = false;

mat3 calculateTBN(vec3 hitNormal) {
    vec3 tangent = mix(vec3(hitNormal.z, 0.0, -hitNormal.x), vec3(1.0, 0.0, 0.0), step(0.5, abs(hitNormal.y)));
    return mat3(tangent, -cross(hitNormal, tangent), hitNormal);
}

#define VOLUMETRICS 0 //Volumetrics [0 1]
#define SCATTERS 2 //Scatters for volumetrics [1 2 3 4 5]
#define DENSITY 200 //Density for volumetrics [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200 225 250 275 300 325 350 375 400 425 450 475 500 550 600 650 700 750 800 850 900 950 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2100 2200 2300 2400 2500]

/*vec3 ptfog (vec3 ro, vec3 rd, float t, inout vec3 col) {
    vec3 through = vec3(1.0);
    vec3 scattering = vec3(0.0);

    vec3 sundir = coneDir(sunrd, sunrad);
    vec3 suncol = vec3(plancks(680.0, 5800.0), plancks(550.0, 5800.0), plancks(440.0, 5800.0)) * lighttrans(ro + vec3(0.0, planetrad, 0.0), sundir);
    
    vec3 p = ro + rd * t * randF();

    vec3 scatter = scatterm;
    float dens = DENSITY;

    vec3 currPos;
    vec3 misc;
    vec4 misc4;
    
    vec3 trans = exp(-t * scatter * dens);
    col *= trans;

    rd = randV();
    
    for (int i = 0; i < SCATTERS; i++) {
        trace hit = rayTrace(p, rd);
        //trace sun = rayTrace(p, sundir);

        int bid = unpackid(hit.voxel.ids);

        float t = distance(p, hit.pos);
        if (hit.pos == vec3(0.0)) t = 100.0;

        float dist = t * randF();
        
        vec3 od = exp(-dist * scatter * dens);
        
        p = p + rd * dist;
        
        float mass = dens;
        if (mass > 1e35) break;
        if (isnan(mass)) mass = 0.0;
        
        vec3 newDir = randV();
        
        float mu = dot(rd, newDir);

        float miephase = mphase(mu) * 4.0 * pi;

        float mu2 = dot(rd, sunrd);

        float miephase2 = mphase(mu2) * 4.0 * pi;
        
        scattering += through * (scatter * mass * miephase) * exp(-t * scatter * dens) * t * emissiveget(bid);
        //scattering += through * (scatter * mass * miephase2) * od * suncol * t * 2.0 * pi * (1.0 - cos(sunrad)) * (sun.pos == vec3(0.0) ? 1.0 : 0.0);

        through *= (scatter * mass * miephase) * od * t;

        #ifdef RUSSIAN_ROULETTE
            float p = max(through.r, max(through.g, through.b));
            if (randF() > p) break;

            through /= p;
        #endif
        
        rd = newDir;
    }
    
    return scattering;
}*/

float metal = 0.0;

float fresnel(float n1, float n2, vec3 normal, vec3 incident) {
    float r0 = (n1 - n2) / (n1 + n2);
    r0 *= r0;
    float cosX = -dot(normal, incident);

    if (n1 > n2) {
        float n = n1 / n2;
        float sinT2 = n * n * (1.0 - cosX * cosX);
        if (sinT2 > 1.0) return 1.0;
        cosX = sqrt(1.0 - sinT2);
    }

    float x = 1.0-cosX;
    return r0 + (1.0 - r0) * x * x * x * x * x;
}

vec3 pt (vec3 ro, vec3 rd) {
    vec3 sundir = coneDir(sunrd, sunrad);

    float wl = 390.0 + 440.0 * randF();

    float scatterray = BetaR(wl);
    float scattermie = BetaM(wl, aerosol);
    float absorbo = ozonefunc(wl);
    float scattermist = mistfunc(wl).r;
    vec4 coeff = vec4(scatterray, scattermie, absorbo, scattermist);

    vec3 suncol = coltorgb(plancks(wl, 5800.0) * ratioTrackingEstimator(ro + vec3(0.0, planetrad, 0.0), sundir, coeff), wl);

    vec3 ret = vec3(0.0);
    vec3 through = vec3(1.0);

    vec3 alb = vec3(0.0);
    vec4 spec = vec4(0.0);
    float rough = 0.0;
    bool doSpec = false;

    bool inside = false;
    vec3 absorb = vec3(0.0);

    for (int bounce = 0; bounce < BOUNCES; bounce++) {
        trace hit = rayTrace(ro, rd);

        #if VOLUMETRICS == 1
        //if (bounce == 0) ret += ptfog(ro, rd, (hit.pos != vec3(0.0) ? distance(ro, hit.pos) : 100.0), through);
        #endif

        if (hit.pos == vec3(0.0)) {
            #ifdef SUN_NEE
                if ((doSpec && rough == 0.0) || bounce == 0) ret += through * coltorgb(sky(ro, rd, 0.0, wl), wl);
                else ret += through * coltorgb(sky2(ro, rd, 0.0, wl), wl);
            #else
                ret += through * coltorgb(sky(ro, rd, 0.0, wl), wl);
            #endif
            break;
        }

        alb = pow(getcolor(hit, colortex2).rgb, vec3(GAMMA));
        spec = getcolor(hit, colortex3);
        rough = pow(1.0 - spec.r, 2.0);

        vec3 truenorm = hit.norm.xyz;
        vec3 map = getcolor(hit, colortex4).rgb * 2.0 - 1.0;
        map.z = sqrt(1.0 - dot(map.xy, map.xy));
        vec3 norm = normalize(calculateTBN(truenorm) * map);
        if (any(isnan(norm))) norm = truenorm;

        int bid = unpackid(hit.voxel.ids);

        float t = distance(ro, hit.pos);
        through *= inside ? exp(-t * absorb) : vec3(1.0);

        float emissive = emissivebright(bid);
        #if HARDCODED_EMISSIVE == 0
            emissive = (spec.a != 1.0 ? spec.a : 0.0) * 50.0;
        #endif

        ret += alb * emissive * through;
        //else ret += emissivecol(bid) * through;

        bool secondcheck = false;

        #if GLASS_BORDER == 0
        secondcheck = bid != 21;
        #else
        secondcheck = getcolor(hit, colortex2).a > 0.2;
        #endif

        if (bid != 20 && hit.voxel.coords != 0u && secondcheck) {
            ro = hit.pos + truenorm * 0.01;

            #ifdef SUN_NEE
                trace sun = trace(Voxel(0u, 0u, 0u, 0u), vec3(1.0), vec3(0.0));
                if (dot(sunrd, truenorm) > 0.0) sun = rayTrace(ro, sundir);

                if (sun.pos == vec3(0.0) && (!doSpec || rough > 0.0)) {
                    vec3 tempnorm = norm;
                    ret += suncol * (1.0 - cos(sunrad)) * 2.0 * pi * through * max(brdf(alb, rough, metal, vec3(spec.g), tempnorm, -rd, sundir) * 2.0 * pi, 0.0);
                }
            #endif

            rd = sampleSpecular(alb, rough, metal, spec.ggg, norm, truenorm, -rd, through, doSpec);
        } else {
            //norm = truenorm;
            if (!inside) {
                float f = fresnel(1.0, 1.45, norm, rd);
                float rng = randF();
                if (f >= rng) {
                    ro = hit.pos + norm * 0.001;
                    rd = reflect(rd, norm);
                    inside = false;
                    through /= f;
                } else {
                    ro = hit.pos - norm * 0.001;
                    rd = refract(rd, norm, 1.0 / 1.45);
                    inside = true;
                    absorb = (1.0 - alb);
                    if (bid == 21) absorb = 1.0 * vec3(0.3, 0.1, 0.2);
                    through /= 1.0 - f;
                }
            } else {
                float f = fresnel(1.45, 1.0, norm, rd);
                float rng = randF();
                if (f >= rng) {
                    ro = hit.pos + norm * 0.001;
                    rd = reflect(rd, norm);
                    inside = true;
                    through /= f;
                } else {
                    ro = hit.pos - norm * 0.001;
                    rd = refract(rd, norm, 1.45);
                    inside = false;
                    through /= 1.0 - f;
                }
            }
            doSpec = true;
            rough = 0.0;
        }

        #ifdef RUSSIAN_ROULETTE
            float p = max(through.r, max(through.g, through.b));
            if (p < 1.0) {
                float rng = randF();
                if (rng > p) break;

                through /= p;
            }
        #endif
    }

    return ret;
}

#define APERTURE_BLADES 6 //blades [0 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
#define STAR_BOKEH 0 //star bokeh [0 1]

vec2 bokeh () {
	vec2 rand = rand2F();

    #if APERTURE_BLADES == 0
        vec2 p = vec2(cos(rand.x * 2.0 * pi), sin(rand.x * 2.0 * pi));
    #else
        float blade = rand.x * APERTURE_BLADES;
        float angle = 2.0 * pi / APERTURE_BLADES;

        vec2 rotated = vec2(cos(floor(blade) * angle), sin(floor(blade) * angle));
        mat2 rotation = mat2(rotated.y, -rotated.x, rotated.xy);

        #if STAR_BOKEH == 0
        angle *= 0.5;
        #endif

        vec2 p = rotation * vec2(cos(angle), sin(angle) * (fract(blade) * 2.0 - 1.0));
    #endif

    p *= 1.0 - pow(1.0 - sqrt(rand.y), 1.2);

	return p;
}

vec3 computeThinLensApproximation (out vec3 sensorPosition, inout vec3 brdf) {
    vec2 sensorSize = vec2(0.15) * vec2(viewWidth / viewHeight, 1.0);
    
    #ifndef MANUALFOV
	vec2 focalLength = sensorSize * vec2(gbufferProjection[0].x, gbufferProjection[1].y);
    #else
	vec2 focalLength = sensorSize / tan(radians(FOV * 0.5)) / vec2(viewWidth / viewHeight, 1.0);
    #endif
	vec2 fovCorrection  = sensorSize  / focalLength;
	vec2 apertureRad = focalLength / (F_STOPS * 2.0);

	vec2 aaoffset = (rand2F() * 2.0 - 1.0) / vec2(viewWidth, viewHeight);
	vec3 ro = vec3(((texcoords * 2.0 - 1.0) + aaoffset) * fovCorrection, -1.0);

    #if AUTOFOCUS == 1
    trace hit = rayTrace(eyeCameraPosition, -gbufferModelViewInverse[2].xyz);
    float focalDistance = distance(hit.pos, eyeCameraPosition);
    #else
    float focalDistance = FOCAL;
    #endif

    vec2 bokehPoint = bokeh();
    //brdf = (sin(bokehPoint.x * 20.0) + sin(bokehPoint.y * 20.0)) > 0.4 ? vec3(2.0) : vec3(0.0);

	vec3 aperturePoint = vec3(bokehPoint * apertureRad, 0.0);

	sensorPosition = (gbufferModelViewInverse * vec4(aperturePoint, 1.0)).xyz + eyeCameraPosition;
	return mat3(gbufferModelViewInverse) * normalize((ro * focalDistance) - aperturePoint);
}

void main() {
    uint seed = uint(gl_FragCoord.x * viewHeight + gl_FragCoord.y);
	     seed = seed * 720720u + uint(frameCounter);

    init_msws(seed);

	vec4 tmp = gbufferProjectionInverse * vec4((gl_FragCoord.xy + rand2F() - 0.5) / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
	vec3 rd = normalize(mat3(gbufferModelViewInverse) * tmp.xyz);

    //trace hit = rayTrace(eyeCameraPosition, rd);

    vec3 ro = vec3(0.0);
    vec3 brdf = vec3(1.0);

    rd = computeThinLensApproximation(ro, brdf);

    vec3 col = pt(ro, rd) * brdf;

    /*
    vec3 truenorm = hit.norm;
    vec3 map = getcolor(hit, colortex4).rgb * 2.0 - 1.0;
    map.z = sqrt(1.0 - dot(map.xy, map.xy));
    vec3 norm = normalize(calculateTBN(truenorm) * map);
    vec3 col = norm;
    col = getcolor(hit, colortex2).rgb;
    */
    
    if (any(isnan(col)) || any(isinf(col))) col = vec3(0.0);

	vec4 newCol;
	vec4 lastcol = texture2D(colortex1, texcoords);
	float weight = lastcol.a + 1.0;

	if(!notMoving || cameraPosition != previousCameraPosition) {
		lastcol.rgb = col;
		weight = 0.0;
	}

    //newCol.rgb = col;
	newCol.rgb = mix(lastcol.rgb, col, 1.0 / (weight + 1.0));
	newCol.a = weight;

	fragColor = newCol;
	prevColor = newCol;
}