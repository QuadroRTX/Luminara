vec3 n_min (vec3 r) {
    return (1.0 - r) / (1.0 + r);
}

vec3 n_max (vec3 r) {
    return (1.0 + sqrt(r)) / (1.0 - sqrt(r));
}

vec3 get_n (vec3 r, vec3 g) {
    return n_min(r) * g + (1.0 - g) * n_max(r);
}

vec3 get_k2 (vec3 r, vec3 n) {
    vec3 nr = (n + 1.0) * (n + 1.0) * r - (n - 1.0) * (n - 1.0);
    return nr / (1.0 - r);
}

vec3 get_r (vec3 n, vec3 k) {
    return ((n - 1.0) * (n - 1.0) + k * k) / ((n + 1.0) * (n + 1.0) + k * k);
}

vec3 get_g (vec3 n, vec3 k) {
    vec3 r = get_r(n, k);
    return (n_max(r) - n) / (n_max(r) - n_min(r));
}

float f0toior (float F0) {
    return (1.0 + sqrt(F0)) / (1.0 - sqrt(F0));
}

float iortof0 (float ior) {
    float a = (ior - 1.0) / (ior + 1.0);
    return a * a;
}

vec3 fresnelschlick (vec3 F0, float c) {
    return F0 + (1.0 - F0) * pow((1.0 - c), 5.0);
}

vec3 fresnel (vec3 r, vec3 g, float c) {
    if (r == vec3(1.0)) return vec3(1.0);
    vec3 r2 = clamp(r, 0.0, 0.999999);
    
    vec3 n = get_n(r2, g);
    vec3 k2 = get_k2(r2, n);
    //vec3 n = vec3(0.18299, 0.42108, 1.3734);
    //vec3 k2 = vec3(3.4242, 2.3459, 1.7704);
    
    vec3 rs_num = n * n + k2 - 2.0 * n * c + c * c;
    vec3 rs_den = n * n + k2 + 2.0 * n * c + c * c;
    vec3 rs = rs_num / rs_den;
    
    vec3 rp_num = (n * n + k2) * c * c - 2.0 * n * c + 1.0;
    vec3 rp_den = (n * n + k2) * c * c + 2.0 * n * c + 1.0;
    vec3 rp = rp_num / rp_den;
    
    return (rp + rs) / 2.0;
}

vec3 fresnelnk (vec3 n, vec3 k2, float c) {
    vec3 rs_num = n * n + k2 - 2.0 * n * c + c * c;
    vec3 rs_den = n * n + k2 + 2.0 * n * c + c * c;
    vec3 rs = rs_num / rs_den;
    
    vec3 rp_num = (n * n + k2) * c * c - 2.0 * n * c + 1.0;
    vec3 rp_den = (n * n + k2) * c * c + 2.0 * n * c + 1.0;
    vec3 rp = rp_num / rp_den;
    
    return (rp + rs) / 2.0;
}

vec3 fresnel (vec3 F0, float c) {
    return fresnel(F0, mix(F0, vec3(1.0), 82.0 / 90.0), c);
}

float distributionGGX(vec3 v, float alpha) {
    float alpha2 = alpha * alpha;
    return 1.0 / (pi * alpha2 * pow(v.x * v.x / alpha2 + v.y * v.y / alpha2 + v.z * v.z , 2.0));
}

float smithShadowing(vec3 v, float roughness) {
    float lambda = (-1.0 + sqrt(1.0 + (roughness * roughness * (v.x * v.x + v.y * v.y)) / v.z / v.z)) / 2.0;
    return 1.0 / (1.0 + lambda);
}

float smithUncorrelatedGeometry(vec3 V, vec3 L, float roughness) {
    return smithShadowing(V, roughness) * smithShadowing(L, roughness);
}

vec3 sampleGGXVNDF(vec3 viewDirection, vec2 alpha, vec2 xi) {
    viewDirection = normalize(vec3(alpha * viewDirection.xy, viewDirection.z));

    float phi       = 2.0 * pi * xi.x;
    float cosTheta  = (1.0 - xi.y) * (1.0 + viewDirection.z) - viewDirection.z;
    float sinTheta  = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
    vec3  reflected = vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);

    vec3 halfway = reflected + viewDirection;

    return normalize(vec3(alpha * halfway.xy, halfway.z));
}

vec3 brdf (vec3 alb, float rough, float metal, vec3 F0, vec3 normal, vec3 view, vec3 light) {
    vec4 q = getRotationToZAxis(normal);
    vec3 V = quaternionRotate(view, q);
    vec3 L = quaternionRotate(light, q);
    vec3 H = normalize(V + L);
    
    float HdotV = clamp(dot(H, V), 0.0, 1.0);
    float NdotH = clamp(H.z, 0.0, 1.0);

    vec3 n = vec3(0.0);
    vec3 k = vec3(0.0);

    int metalID = int(F0.r * 255.0 - 229.5);

    switch(metalID) {
        case 0: {
            n = vec3(2.9114, 2.9497, 2.5845);
            k = vec3(3.0893, 2.9318, 2.7670);
            metal = 1.0;
            break;
        }
        case 1: {
            n = vec3(0.18299, 0.42108, 1.3734);
            k = vec3(3.4242, 2.3459, 1.7704);
            metal = 1.0;
            break;
        }
        case 2: {
            n = vec3(1.3456, 0.96521, 0.61722);
            k = vec3(7.4746, 6.3995, 5.3031);
            metal = 1.0;
            break;
        }
        case 3: {
            n = vec3(3.1071, 3.1812, 2.3230);
            k = vec3(3.3314, 3.3291, 3.1350);
            metal = 1.0;
            break;
        }
        case 4: {
            n = vec3(0.27105, 0.67693, 1.3164);
            k = vec3(3.6092, 2.6248, 2.2921);
            metal = 1.0;
            break;
        }
        case 5: {
            n = vec3(1.9100, 1.8300, 1.4400);
            k = vec3(3.5100, 3.4000, 3.1800);
            metal = 1.0;
            break;
        }
        case 6: {
            n = vec3(2.3757, 2.0847, 1.8453);
            k = vec3(4.2655, 3.7153, 3.1365);
            metal = 1.0;
            break;
        }
        case 7: {
            n = vec3(0.15943, 0.14512, 0.13547);
            k = vec3(3.9291, 3.1900, 2.3808);
            metal = 1.0;
            break;
        }
    }

    vec3 F = metal == 1.0 ? fresnelnk(n, k, max(dot(H, V), 0.0)) : fresnel(F0, max(dot(H, V), 0.0));

    #if ALBEDO_METALS == 1
        if (metalID >= 0) {
            metal = 1.0;
            F = fresnelschlick(alb, max(dot(H, V), 0.0));
        }
    #endif

    #if GOLDEN_WORLD == 1
        F = fresnelnk(vec3(0.18299, 0.42108, 1.3734), vec3(3.4242, 2.3459, 1.7704), max(dot(H, V), 0.0));
        metal = 1.0;
    #endif
    
    float D = distributionGGX(H, rough);
    float G = smithUncorrelatedGeometry(V, L, rough);
    
    vec3 spec = F * D * G / max(4.0 * V.z * L.z, 0.001);

    if (rough == 0.0) return (1.0 - metal) * (1.0 - F) * alb / pi * max(L.z, 0.0);
    return ((1.0 - metal) * (1.0 - F) * alb / pi + spec) * max(L.z, 0.0);
}

float ggxh(float Xi, vec3 direction, float height, float alpha) {
    float direction_length = length(vec3(direction.xy * alpha, 1.0));
    float delta = -log(1.0f - Xi) * direction.z / max(0.5 * (direction_length - direction.z), 1e-6);

    return height + delta;
}

#define ALBEDO_METALS 0 //unbelievably cringe, do not turn this on [0 1]

vec3 sampleSpecularBasis (vec3 alb, float rough, float metal, vec3 F0, vec3 normal, vec3 view, inout vec3 through, out bool doSpec) {
    vec4 q = getRotationToZAxis(normal);
    vec3 V = view;
    vec3 H = sampleGGXVNDF(V, vec2(rough), rand2F());
    vec3 L = reflect(-V, H);

    vec3 n = vec3(0.0);
    vec3 k = vec3(0.0);

    int metalID = int(F0.r * 255.0 - 229.5);

    switch(metalID) {
        case 0: {
            n = vec3(2.9114, 2.9497, 2.5845);
            k = vec3(3.0893, 2.9318, 2.7670);
            metal = 1.0;
            break;
        }
        case 1: {
            n = vec3(0.18299, 0.42108, 1.3734);
            k = vec3(3.4242, 2.3459, 1.7704);
            metal = 1.0;
            break;
        }
        case 2: {
            n = vec3(1.3456, 0.96521, 0.61722);
            k = vec3(7.4746, 6.3995, 5.3031);
            metal = 1.0;
            break;
        }
        case 3: {
            n = vec3(3.1071, 3.1812, 2.3230);
            k = vec3(3.3314, 3.3291, 3.1350);
            metal = 1.0;
            break;
        }
        case 4: {
            n = vec3(0.27105, 0.67693, 1.3164);
            k = vec3(3.6092, 2.6248, 2.2921);
            metal = 1.0;
            break;
        }
        case 5: {
            n = vec3(1.9100, 1.8300, 1.4400);
            k = vec3(3.5100, 3.4000, 3.1800);
            metal = 1.0;
            break;
        }
        case 6: {
            n = vec3(2.3757, 2.0847, 1.8453);
            k = vec3(4.2655, 3.7153, 3.1365);
            metal = 1.0;
            break;
        }
        case 7: {
            n = vec3(0.15943, 0.14512, 0.13547);
            k = vec3(3.9291, 3.1900, 2.3808);
            metal = 1.0;
            break;
        }
    }

    vec3 F = metal == 1.0 ? fresnelnk(n, k, max(dot(H, V), 0.0)) : fresnel(F0, max(dot(H, V), 0.0));

    #if ALBEDO_METALS == 1
        if (metalID >= 0) {
            metal = 1.0;
            F = fresnelschlick(alb, max(dot(H, V), 0.0));
        }
    #endif

    #if GOLDEN_WORLD == 1
        F = fresnelnk(vec3(0.18299, 0.42108, 1.3734), vec3(3.4242, 2.3459, 1.7704), max(dot(H, V), 0.0));
        metal = 1.0;
    #endif
    
    vec3 specdir = L;
    vec3 diffusedir = normalize(quaternionRotate(normal, q) + randV());
    
    float albchance = (1.0 - metal) * (1.0 - dot(F, vec3(1.0 / 3.0)));
    float specchance = dot(F, vec3(1.0 / 3.0));

    if (metal == 1.0) {
        through *= F;
        doSpec = true;
        return specdir;
    } else if (randF() <= specchance) {
        through *= F;
        through /= specchance;
        doSpec = true;
        return specdir;
    } else {
        through *= (1.0 - metal) * (1.0 - F) * alb / (1.0 - specchance);
        doSpec = false;
        return diffusedir;
    }
    
    return specdir;
}

vec3 sampleSpecular (vec3 alb, float rough, float metal, vec3 F0, vec3 normal, vec3 view, inout vec3 through, out bool doSpec) {
    vec3 r = F0;
    vec3 g = mix(F0, vec3(1.0), 82.0 / 90.0);

    vec4 q = getRotationToZAxis(normal);
    vec3 V = quaternionRotate(view, q);
    
    int MS = 64;
    vec3 wr = -V;
    float hr = 0.0;
 
    int i = 0;
    
    while (i <= MS) {
        hr = ggxh(randF(), wr, hr, rough);
        
        if(hr > 0.0)
            break;
        else
            i++;
        
        wr = sampleSpecularBasis(alb, rough, metal, F0, normal, -wr, through, doSpec);
        if(hr != hr || wr.z != wr.z)
            return vec3(0.0, 0.0, 1.0);
    }
    
    through = max(through, 0.0);
    
    return quaternionRotate(wr, vec4(-q.xyz, q.w));
}

vec3 sampleSpecular (vec3 alb, float rough, float metal, vec3 F0, vec3 normal, vec3 realnormal, vec3 view, inout vec3 through, out bool doSpec) {
    vec4 q = getRotationToZAxis(normal);
    vec3 V = quaternionRotate(view, q);
    vec3 N = quaternionRotate(realnormal, q);
    
    int MS = 64;
    vec3 wr = -V;
    float hr = 0.0;
 
    int i = 0;
    
    while (i <= MS) {
        hr = ggxh(randF(), wr, hr, rough);
        
        if(hr > 0.0 && dot(N, wr) > 0.0)
            break;
        else
            i++;
        
        wr = sampleSpecularBasis(alb, rough, metal, F0, normal, -wr, through, doSpec);
        if(hr != hr || wr.z != wr.z)
            return reflect(-view, normal);
    }

    through = max(through, 0.0);
    
    return quaternionRotate(wr, vec4(-q.xyz, q.w));
}