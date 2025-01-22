vec4 quaternionMultiply(vec4 a, vec4 b) {
    return vec4(
        a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x,
        -a.x * b.z + a.y * b.w + a.z * b.x + a.w * b.y,
        a.x * b.y - a.y * b.x + a.z * b.w + a.w * b.z,
        -a.x * b.x - a.y * b.y - a.z * b.z + a.w * b.w
    );
}

vec3 quaternionRotate(vec3 pos, vec3 axis, float angle) {
    vec4 q = vec4(sin(angle / 2.0) * axis, cos(angle / 2.0));
    vec4 qInv = vec4(-q.xyz, q.w);
    return quaternionMultiply(quaternionMultiply(q, vec4(pos, 0)), qInv).xyz;
}

vec3 quaternionRotate(vec3 pos, vec4 q) {
    vec4 qInv = vec4(-q.xyz, q.w);
    return quaternionMultiply(quaternionMultiply(q, vec4(pos, 0)), qInv).xyz;
}

vec4 getRotationToZAxis(vec3 vec) {

	// Handle special case when input is exact or near opposite of (0, 0, 1)
	if (vec.z < -0.99999f) return vec4(1.0f, 0.0f, 0.0f, 0.0f);

	return normalize(vec4(vec.y, -vec.x, 0.0f, 1.0f + vec.z));
}

vec3 fresnelSchlick(vec3 F0, float cosTheta) {
    return F0 + (1.0 - F0) * pow((1.0 - cosTheta), 5.0);
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

vec3 sampleGGXVNDF(vec3 Ve, vec2 alpha2D, vec2 u) {
	vec3 Vh = normalize(vec3(alpha2D.x * Ve.x, alpha2D.y * Ve.y, Ve.z));

	float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
	vec3 T1 = lensq > 0.0f ? vec3(-Vh.y, Vh.x, 0.0f) * inversesqrt(lensq) : vec3(1.0f, 0.0f, 0.0f);
	vec3 T2 = cross(Vh, T1);

	float r = sqrt(u.x);
	float phi = 2.0 * pi * u.y;
	float t1 = r * cos(phi);
	float t2 = r * sin(phi);
	float s = 0.5f * (1.0f + Vh.z);
	t2 = mix(sqrt(1.0f - t1 * t1), t2, s);

	vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(0.0f, 1.0f - t1 * t1 - t2 * t2)) * Vh;

	return normalize(vec3(alpha2D.x * Nh.x, alpha2D.y * Nh.y, max(0.0f, Nh.z)));
}

vec3 brdf (vec3 alb, float rough, float metal, vec3 F0, vec3 normal, vec3 view, vec3 light) {
    return vec3(max(dot(light, normal), 0.0) / pi);
    vec4 q = getRotationToZAxis(normal);
    vec3 V = quaternionRotate(view, q);
    vec3 L = quaternionRotate(light, q);
    vec3 H = normalize(V + L);
    
    float HdotV = clamp(dot(H, V), 0.0, 1.0);
    float NdotH = clamp(H.z, 0.0, 1.0);
    
    vec3 F = fresnelSchlick(F0, HdotV);
    float D = distributionGGX(H, rough);
    float G = smithUncorrelatedGeometry(V, L, rough);
    
    vec3 spec = F * D * G / max(4.0 * V.z * L.z, 0.001);

    return ((1.0 - metal) * (1.0 - fresnelSchlick(F0, max(L.z, 0.0))) * (1.0 - fresnelSchlick(F0, max(dot(normal, view), 0.0))) * alb / pi + spec) * max(L.z, 0.0);
}

vec3 sampleSpecular(vec3 alb, float rough, float metal, vec3 F0, vec3 normal, vec3 view, out vec3 brdf) {
    brdf = vec3(0.5);
    return reflect(-view, normal);
    vec4 q = getRotationToZAxis(normal);
    vec3 V = quaternionRotate(view, q);
    vec3 M = sampleGGXVNDF(V, vec2(rough), vec2(randF(), randF()));
    vec3 L = reflect(-V, M);
    vec3 H = normalize(V + L);


    vec3 F = fresnelSchlick(F0, max(dot(H, V), 0.0));
    float G2 = smithUncorrelatedGeometry(V, L, rough);
    float G1 = smithShadowing(V, rough);
    brdf = F * G2 / G1;
    
    vec3 specdir = quaternionRotate(L, vec4(-q.xyz, q.w));
    vec3 diffusedir = normalize(normal + randDir(rand2F()));
    
    float specchance = dot(F, vec3(1.0 / 3.0));
    if (randF() <= specchance) {
        brdf /= specchance;
        return specdir;
    } else {
        brdf = (1.0 - metal) * (1.0 - fresnelSchlick(F0, max(dot(diffusedir, normal), 0.0))) * (1.0 - fresnelSchlick(F0, max(dot(view, normal), 0.0))) * alb / (1.0 - specchance);
        return diffusedir;
    }
    
    return specdir;
}