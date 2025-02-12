#define SCATTER_EVENTS 5 //Scatter events [0 1 2 3 4 5 6 7 8 9 10]
#define SAMPLES 1 //Samples [1 2 3 4 5 10 15 20 25 50 75 100]
#define TURBIDITY 1.05 //Turbidity [1.0 1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1 1.11 1.12 1.13 1.14 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

uniform vec3 sunPosition;
const float sunPathRotation = SUNROT;
const vec3 sunrd = normalize(mat3(gbufferModelViewInverse) * sunPosition);
//vec3 sunrd = normalize(vec3(1.0, -0.3, -10.0));

const float turbidity = TURBIDITY;
const float airNumberDensity = 2.5035422e25;
const float ozonePeakDensity = 5e-6;
const float ozonePeakAltitude = 35e3;
const float ozoneNumberDensity = airNumberDensity * exp(-ozonePeakAltitude / 8e3) * (134.628 / 48.0) * ozonePeakDensity;
const float ozoneUnitConversion = 1e-4;

float BetaM (float wl) {
    const float junge = 4.0;

    float c = (0.6544 * turbidity - 0.6510) * 4e-18;
    float K = (0.773335 - 0.00386891 * wl) / (1.0 - 0.00546759 * wl);
    return 0.434 * c * pi * pow(2.0 * pi / (wl * 1e-9), junge - 2.0) * K;
}

float rayleighCrossSection (float lambda, float nAir) {
    float lambdaMeter = lambda * 1e-9;
    float lambdaMicro = lambda * 1e-3;

    float rayleigh = (8.0 * pi * pi * pi * pow(nAir * nAir - 1.0, 2.0)) / (3.0 * pow(lambdaMeter, 4.0) * airNumberDensity);

    float waveNumber = 1.0 / lambdaMicro;

    float N2  = 1.034  + 3.17e-12 * waveNumber * waveNumber;
    float CO2 = 1.1364 + 2.53e-11 * waveNumber * waveNumber;

    float kingCorrectionFactor = (N2 + CO2) * 0.5;
    
    return rayleigh * kingCorrectionFactor;
}

float rayleighCrossSection (float wl) {
    return rayleighCrossSection(wl, 1.00029);
}

const float ozoneCrossSection[441] = float[441](
    6.80778e-24,
    6.72106e-24,
    6.66971e-24,
    6.87827e-24,
    7.63950e-24,
    9.04948e-24,
    1.02622e-23,
    1.05505e-23,
    1.00303e-23,
    9.66106e-24,
    9.92189e-24,
    1.09556e-23,
    1.25580e-23,
    1.41026e-23,
    1.47637e-23,
    1.47593e-23,
    1.47278e-23,
    1.58624e-23,
    1.85887e-23,
    2.24518e-23,
    2.55393e-23,
    2.69799e-23,
    2.71700e-23,
    2.59416e-23,
    2.48635e-23,
    2.54214e-23,
    2.82383e-23,
    3.24288e-23,
    3.57929e-23,
    3.71260e-23,
    3.68606e-23,
    3.68453e-23,
    3.94202e-23,
    4.53838e-23,
    5.34144e-23,
    6.21470e-23,
    6.89342e-23,
    7.15131e-23,
    7.02279e-23,
    6.68451e-23,
    6.40985e-23,
    6.51215e-23,
    7.09484e-23,
    7.97582e-23,
    8.64796e-23,
    8.84751e-23,
    8.70576e-23,
    8.63018e-23,
    9.02596e-23,
    1.00978e-22,
    1.17515e-22,
    1.36812e-22,
    1.55564e-22,
    1.70593e-22,
    1.77413e-22,
    1.74113e-22,
    1.63969e-22,
    1.53825e-22,
    1.50061e-22,
    1.57091e-22,
    1.73006e-22,
    1.89872e-22,
    1.99180e-22,
    1.99402e-22,
    1.95992e-22,
    1.95885e-22,
    2.05664e-22,
    2.28073e-22,
    2.60481e-22,
    2.97688e-22,
    3.36293e-22,
    3.73195e-22,
    4.00920e-22,
    4.10428e-22,
    4.00191e-22,
    3.77591e-22,
    3.55367e-22,
    3.43550e-22,
    3.50045e-22,
    3.72443e-22,
    3.99079e-22,
    4.17388e-22,
    4.24576e-22,
    4.24739e-22,
    4.25983e-22,
    4.36706e-22,
    4.63007e-22,
    5.06215e-22,
    5.61756e-22,
    6.25345e-22,
    6.92671e-22,
    7.60101e-22,
    8.17582e-22,
    8.53087e-22,
    8.59583e-22,
    8.41161e-22,
    8.09704e-22,
    7.77762e-22,
    7.58661e-22,
    7.61105e-22,
    7.82768e-22,
    8.13525e-22,
    8.41416e-22,
    8.60281e-22,
    8.69574e-22,
    8.77739e-22,
    8.90289e-22,
    9.18185e-22,
    9.63101e-22,
    1.02541e-21,
    1.10497e-21,
    1.19583e-21,
    1.29472e-21,
    1.39640e-21,
    1.49041e-21,
    1.57014e-21,
    1.62239e-21,
    1.64414e-21,
    1.63511e-21,
    1.60943e-21,
    1.57830e-21,
    1.55493e-21,
    1.54503e-21,
    1.55300e-21,
    1.57805e-21,
    1.61238e-21,
    1.64978e-21,
    1.68423e-21,
    1.71542e-21,
    1.74504e-21,
    1.77787e-21,
    1.81470e-21,
    1.86234e-21,
    1.92426e-21,
    1.99836e-21,
    2.08321e-21,
    2.17570e-21,
    2.27551e-21,
    2.37767e-21,
    2.48026e-21,
    2.57787e-21,
    2.66735e-21,
    2.74553e-21,
    2.80416e-21,
    2.84156e-21,
    2.86077e-21,
    2.86533e-21,
    2.85907e-21,
    2.85266e-21,
    2.86095e-21,
    2.87845e-21,
    2.92588e-21,
    2.97008e-21,
    3.02468e-21,
    3.08141e-21,
    3.13490e-21,
    3.18141e-21,
    3.22207e-21,
    3.26213e-21,
    3.29445e-21,
    3.32516e-21,
    3.35579e-21,
    3.38847e-21,
    3.41886e-21,
    3.45674e-21,
    3.50070e-21,
    3.55041e-21,
    3.61007e-21,
    3.67904e-21,
    3.76616e-21,
    3.85792e-21,
    3.95625e-21,
    4.05115e-21,
    4.14698e-21,
    4.23308e-21,
    4.31213e-21,
    4.37493e-21,
    4.44152e-21,
    4.49554e-21,
    4.54212e-21,
    4.59922e-21,
    4.65627e-21,
    4.70549e-21,
    4.75188e-21,
    4.78362e-21,
    4.79933e-21,
    4.79812e-21,
    4.78287e-21,
    4.74991e-21,
    4.70931e-21,
    4.65747e-21,
    4.61692e-21,
    4.57024e-21,
    4.52700e-21,
    4.48817e-21,
    4.45931e-21,
    4.43458e-21,
    4.41148e-21,
    4.40927e-21,
    4.40508e-21,
    4.41249e-21,
    4.43419e-21,
    4.46445e-21,
    4.50560e-21,
    4.56963e-21,
    4.64735e-21,
    4.73301e-21,
    4.82020e-21,
    4.91050e-21,
    4.99163e-21,
    5.06017e-21,
    5.11838e-21,
    5.16436e-21,
    5.18613e-21,
    5.19008e-21,
    5.17248e-21,
    5.13839e-21,
    5.07516e-21,
    5.00213e-21,
    4.92632e-21,
    4.84196e-21,
    4.75813e-21,
    4.66949e-21,
    4.58682e-21,
    4.50504e-21,
    4.42659e-21,
    4.34938e-21,
    4.27621e-21,
    4.20827e-21,
    4.14570e-21,
    4.08986e-21,
    4.03221e-21,
    3.99139e-21,
    3.94294e-21,
    3.90294e-21,
    3.85486e-21,
    3.80352e-21,
    3.75269e-21,
    3.69724e-21,
    3.64581e-21,
    3.59756e-21,
    3.53981e-21,
    3.48189e-21,
    3.42639e-21,
    3.36507e-21,
    3.30716e-21,
    3.24798e-21,
    3.19212e-21,
    3.13235e-21,
    3.07385e-21,
    3.01187e-21,
    2.94933e-21,
    2.88675e-21,
    2.83154e-21,
    2.77990e-21,
    2.73430e-21,
    2.69151e-21,
    2.64926e-21,
    2.60694e-21,
    2.56838e-21,
    2.52929e-21,
    2.49407e-21,
    2.45557e-21,
    2.41588e-21,
    2.37737e-21,
    2.33497e-21,
    2.29460e-21,
    2.25198e-21,
    2.21134e-21,
    2.16653e-21,
    2.12952e-21,
    2.09231e-21,
    2.05119e-21,
    2.01199e-21,
    1.96873e-21,
    1.93030e-21,
    1.89301e-21,
    1.85458e-21,
    1.80984e-21,
    1.76722e-21,
    1.72459e-21,
    1.68500e-21,
    1.64647e-21,
    1.60911e-21,
    1.57194e-21,
    1.53783e-21,
    1.50400e-21,
    1.47295e-21,
    1.44342e-21,
    1.41512e-21,
    1.38809e-21,
    1.36429e-21,
    1.34049e-21,
    1.31934e-21,
    1.30100e-21,
    1.28154e-21,
    1.26035e-21,
    1.23594e-21,
    1.20922e-21,
    1.18024e-21,
    1.14995e-21,
    1.11892e-21,
    1.09140e-21,
    1.06392e-21,
    1.03712e-21,
    1.01065e-21,
    9.84534e-22,
    9.58011e-22,
    9.31230e-22,
    9.06905e-22,
    8.83424e-22,
    8.61809e-22,
    8.41371e-22,
    8.23199e-22,
    8.07479e-22,
    7.92359e-22,
    7.78960e-22,
    7.66918e-22,
    7.56724e-22,
    7.45938e-22,
    7.36321e-22,
    7.26761e-22,
    7.17708e-22,
    7.10170e-22,
    7.04603e-22,
    7.00521e-22,
    6.95807e-22,
    6.87983e-22,
    6.75690e-22,
    6.59167e-22,
    6.38658e-22,
    6.17401e-22,
    5.97986e-22,
    5.79980e-22,
    5.64879e-22,
    5.52304e-22,
    5.40930e-22,
    5.28950e-22,
    5.14905e-22,
    5.00676e-22,
    4.86900e-22,
    4.74324e-22,
    4.63744e-22,
    4.54117e-22,
    4.47413e-22,
    4.42084e-22,
    4.38598e-22,
    4.35751e-22,
    4.32496e-22,
    4.30002e-22,
    4.28472e-22,
    4.27365e-22,
    4.29043e-22,
    4.31385e-22,
    4.35345e-22,
    4.40512e-22,
    4.46268e-22,
    4.50925e-22,
    4.51983e-22,
    4.49671e-22,
    4.41359e-22,
    4.27561e-22,
    4.09127e-22,
    3.88901e-22,
    3.68851e-22,
    3.50462e-22,
    3.34368e-22,
    3.20386e-22,
    3.08569e-22,
    2.99026e-22,
    2.90708e-22,
    2.83838e-22,
    2.77892e-22,
    2.72682e-22,
    2.67864e-22,
    2.63381e-22,
    2.60147e-22,
    2.57597e-22,
    2.55903e-22,
    2.54995e-22,
    2.55263e-22,
    2.56910e-22,
    2.59848e-22,
    2.64943e-22,
    2.72251e-22,
    2.81519e-22,
    2.92565e-22,
    3.03612e-22,
    3.13434e-22,
    3.20710e-22,
    3.23925e-22,
    3.21425e-22,
    3.14522e-22,
    3.03211e-22,
    2.89017e-22,
    2.73981e-22,
    2.59406e-22,
    2.46085e-22,
    2.34234e-22,
    2.23936e-22,
    2.14826e-22,
    2.06425e-22,
    1.98427e-22,
    1.90789e-22,
    1.83692e-22,
    1.77111e-22,
    1.71523e-22,
    1.66604e-22,
    1.63367e-22,
    1.60371e-22,
    1.57834e-22,
    1.55432e-22,
    1.53961e-22,
    1.52632e-22,
    1.51695e-22,
    1.51650e-22,
    1.53341e-22,
    1.56550e-22,
    1.61557e-22,
    1.68582e-22,
    1.76205e-22,
    1.84627e-22,
    1.93246e-22,
    2.01741e-22,
    2.09583e-22,
    2.16778e-22,
    2.22566e-22,
    2.25770e-22,
    2.25611e-22,
    2.22491e-22,
    2.16317e-22,
    2.07365e-22,
    1.96101e-22,
    1.82575e-22,
    1.69093e-22,
    1.55152e-22,
    1.42655e-22,
    1.31245e-22,
    1.21519e-22,
    1.12924e-22,
    1.05472e-22
);

float BetaO (float wl) {
    return clamp(wl, 390.0, 830.0) == wl ? ozoneCrossSection[int(wl - 390.0)] * ozoneNumberDensity * ozoneUnitConversion : 0.0;
}

vec2 RSI (vec3 ro, vec3 rd, vec4 sph) {
    ro = ro - sph.xyz;
    float a = sph.a * sph.a;
    float b = dot(ro, rd);
    float c = b * b + a - dot(ro, ro);

    if (c < 0.0) return vec2(-1.0);

    c = sqrt(c);
    return -b + vec2(-c, c);
}

float sunrad = 6.963e8 / 1.496e11;
//float sunrad = radians(1.0);
float moonrad = 1.737e6 / 3.844e8;

int odpoints = 6;

//vec3 scatterr = vec3(1.8e-6, 14.5e-6, 44.1e-6);
//vec3 scatterm = vec3(21e-6);
//vec3 scattero = vec3(PreethamBetaO_Fit(680.0), PreethamBetaO_Fit(550.0), PreethamBetaO_Fit(440.0)) * 2.5035422e25 * exp(-25e3 / 8e3) * 134.628 / 48.0 * 3e-6;

vec3 scattero = vec3(BetaO(680.0), BetaO(550.0), BetaO(440.0));
vec3 scatterr = vec3(rayleighCrossSection(680.0), rayleighCrossSection(550.0), rayleighCrossSection(440.0));
vec3 scatterm = vec3(BetaM(680.0), BetaM(550.0), BetaM(440.0));

float planetrad = 6371e3;
float atmoheight = 110e3;

vec2 scaleheights = vec2(8.4, 1.25);

float atmorad = planetrad + atmoheight;
float atmolowerlim = planetrad;

float rphase(float c) {
    return  3.0 * (1.0 + c * c) / 16.0 / pi;
}

float mphase (float c) {
    float g = 0.76;

    float e = 1.0;
    for (int i = 0; i < 8; i++) {
        float gFromE = 1.0 / e - 2.0 / log(2.0 * e + 1.0) + 1.0;
        float deriv = 4.0 / ((2.0 * e + 1.0) * log(2.0 * e + 1.0) * log(2.0 * e + 1.0)) - 1.0 / (e * e);
        if (abs(deriv) < 0.00000001) break;
        e = e - (gFromE - g) / deriv;
    }

    return e / (2.0 * pi * (e * (1.0 - c) + 1.0) * log(2.0 * e + 1.0));
}

vec2 raymiedens (in float h) {
    return exp(-h / scaleheights);
}

//From Jessie
float ozonedens (in float h) {
    float o1 = 25.0 *     exp(( 0.0 - h) /   8.0) * 0.5;
    float o2 = 30.0 * pow(exp((18.0 - h) /  80.0), h - 18.0);
    float o3 = 75.0 * pow(exp((25.3 - h) /  35.0), h - 25.3);
    float o4 = 50.0 * pow(exp((30.0 - h) / 150.0), h - 30.0);
    return (o1 + o2 + o3 + o4) / 134.628;
}

vec3 dens2 (float height) {
    height = (max(height, planetrad) - planetrad) / 1000.0;
    vec2 raymie = raymiedens(height);
    float ozone = ozonedens(height);

    return vec3(raymie, ozone);
}

vec3 lighttrans (vec3 ro, vec3 rd) {
    float dist = dot(ro, rd);
    dist = sqrt(dist * dist + atmorad * atmorad - dot(ro, ro)) - dist;
    float t = dist / float(odpoints);
    vec3 step = rd * t;
    ro += step * 0.5;

    vec3 sum = vec3(0.0);
    for (int i = 0; i < odpoints; i++, ro += step) {
        float height = length(ro);
        sum += dens2(height);
    }

    vec3 od = (scatterr * t * sum.x) + (scatterm * t * sum.y) + (scattero * t * sum.z);
    vec3 trans = exp(-od);
    if (any(isnan(trans))) trans = vec3(0.0);
    if (any(isinf(trans))) trans = vec3(1.0);

    return trans;
}

vec3 lighttrans2 (vec3 ro, vec3 rd, float dist) {
    float t = dist / float(odpoints);
    vec3 step = rd * t;
    ro += step * 0.5;

    vec3 sum = vec3(0.0);
    for (int i = 0; i < odpoints; i++, ro += step) {
        float height = length(ro);
        sum += dens2(height);
    }

    vec3 od = (scatterr * t * sum.x) + (scatterm * t * sum.y) + (scattero * t * sum.z);
    vec3 trans = exp(-od);
    if (any(isnan(trans))) trans = vec3(0.0);
    if (any(isinf(trans))) trans = vec3(1.0);

    return trans;
}

float plancks (float wl, float temp) {
    const float h = 6.62607015e-16;
    const float c = 2.99792458e17;
    const float k = 1.380649e-5;

    float p1 = 2.0 * h * pow(c, 2.0) * pow(wl, -5.0);
    float p2 = exp((h * c) / (wl * k * temp)) - 1.0;

    return p1 / p2;
}

float traceatmo (vec3 ro, vec3 rd, out bool plani) {
    vec2 atmo = RSI(ro, rd, vec4(vec3(0.0), atmorad));
    vec2 plan = RSI(ro, rd, vec4(vec3(0.0), atmolowerlim));

    bool atmoi = atmo.y >= 0.0;
    plani = plan.x >= 0.0;

    vec2 idk = vec2((plani && plan.x < 0.0) ? plan.y : max(atmo.x, 0.0), (plani && plan.x > 0.0) ? plan.x : atmo.y);

    return length(idk.y - idk.x);
}

vec3 skypt (vec3 ro, vec3 rd, vec3 lrd, vec3 intens, vec3 col) {
    vec3 through = vec3(1.0);
    vec3 scattering = vec3(0.0);

    vec3 moonintens = intens * 2.0 * pi * (1.0 - cos(moonrad));
    
    vec3 p = ro;

    bool plani = false;

    vec3 trans = lighttrans2(ro, rd, traceatmo(p, rd, plani));

    col = plani ? vec3(0.0) : col;
    
    for (int i = 0; i < SCATTER_EVENTS; i++) {
        float t = traceatmo(p, rd, plani);
        float dist = t * randF();
        
        vec3 od = lighttrans2(p, rd, dist);
        
        p = p + rd * dist;
        
        vec3 mass = dens2(length(p));
        if (mass.x > 1e35) break;
        if (mass.y > 1e35) break;
        if (mass.z > 1e35) break;
        if (any(isnan(mass))) mass = vec3(0.0);
        
        vec3 newDir = randV();
        
        float mu = dot(rd, newDir);

        float rayphase = rphase(mu) * 4.0 * pi;
        float miephase = mphase(mu) * 4.0 * pi;
        
        float mu2 = dot(rd, lrd);

        float rayphase2 = rphase(mu2) * 4.0 * pi;
        float miephase2 = mphase(mu2) * 4.0 * pi;

        float mu3 = -mu2;

        float rayphase3 = rphase(mu3) * 4.0 * pi;
        float miephase3 = mphase(mu3) * 4.0 * pi;
        
        scattering += through * (scatterr * mass.x * rayphase2 + scatterm * mass.y * miephase2) * od * lighttrans(p, lrd) * t * intens;
        scattering += through * (scatterr * mass.x * rayphase3 + scatterm * mass.y * miephase3) * od * lighttrans(p, -lrd) * t * moonintens;
        through *= (scatterr * mass.x * rayphase + scatterm * mass.y * miephase) * od * t;
        
        rd = newDir;
    }
    
    return scattering + col * trans;
}

vec3 sky (vec3 ro, vec3 rd, vec3 col) {
    ro.y += planetrad;
    
    vec3 sunintens = vec3(plancks(680.0, 5800.0), plancks(550.0, 5800.0), plancks(440.0, 5800.0));
    vec3 sunirradiance = sunintens * 2.0 * pi * (1.0 - cos(sunrad));
    //vec3 moonirradiance = sunirradiance * 2.0 * pi * (1.0 - cos(moonrad));

    vec3 sun = dot(rd, sunrd) > cos(sunrad) ? sunintens : col;
    sun = dot(rd, -sunrd) > cos(sunrad) ? sunirradiance : sun;
        
    vec3 sum = vec3(0.0);
    for (int i = 0; i < SAMPLES - min(frameCounter, 0); i++) {
        vec3 sampledsunrd = coneDir(sunrd, sunrad);
        sum += skypt(ro, rd, sampledsunrd, sunirradiance, sun);
        //sum += skypt(ro, rd, -sampledsunrd, moonirradiance, vec3(0.0));
    }
    
    //return vec3(1.0);
    return sum / float(SAMPLES);
}

vec3 sky2 (vec3 ro, vec3 rd, vec3 col) {
    ro.y += planetrad;
    
    vec3 sunintens = vec3(plancks(680.0, 5800.0), plancks(550.0, 5800.0), plancks(440.0, 5800.0));
    vec3 sunirradiance = sunintens * 2.0 * pi * (1.0 - cos(sunrad));
    //vec3 moonirradiance = sunirradiance * 2.0 * pi * (1.0 - cos(moonrad));

    vec3 sun = col;
        
    vec3 sum = vec3(0.0);
    for (int i = 0; i < SAMPLES - min(frameCounter, 0); i++) {
        vec3 sampledsunrd = coneDir(sunrd, sunrad);
        sum += skypt(ro, rd, sampledsunrd, sunirradiance, sun);
        //sum += skypt(ro, rd, -sampledsunrd, moonirradiance, vec3(0.0));
    }
    
    return sum / float(SAMPLES);
}

vec3 sky (vec3 rd, vec3 col) {
    vec3 ro = vec3(0.0);
    ro.y += planetrad;
    
    vec3 sunintens = vec3(plancks(680.0, 5800.0), plancks(550.0, 5800.0), plancks(440.0, 5800.0));
    vec3 sunirradiance = sunintens * 2.0 * pi * (1.0 - cos(sunrad));
    //vec3 moonirradiance = sunirradiance * 2.0 * pi * (1.0 - cos(moonrad));

    vec3 sun = dot(rd, sunrd) > cos(sunrad) ? sunintens : col;
    sun = dot(rd, -sunrd) > cos(sunrad) ? sunirradiance : sun;
        
    vec3 sum = vec3(0.0);
    for (int i = 0; i < SAMPLES - min(frameCounter, 0); i++) {
        vec3 sampledsunrd = coneDir(sunrd, sunrad);
        sum += skypt(ro, rd, sampledsunrd, sunirradiance, sun);
        //sum += skypt(ro, rd, -sampledsunrd, moonirradiance, vec3(0.0));
    }
    
    //return vec3(1.0);
    return sum / float(SAMPLES);
}

vec3 sky2 (vec3 rd, vec3 col) {
    vec3 ro = vec3(0.0);
    ro.y += planetrad;
    
    vec3 sunintens = vec3(plancks(680.0, 5800.0), plancks(550.0, 5800.0), plancks(440.0, 5800.0));
    vec3 sunirradiance = sunintens * 2.0 * pi * (1.0 - cos(sunrad));
    //vec3 moonirradiance = sunirradiance * 2.0 * pi * (1.0 - cos(moonrad));

    vec3 sun = col;
        
    vec3 sum = vec3(0.0);
    for (int i = 0; i < SAMPLES - min(frameCounter, 0); i++) {
        vec3 sampledsunrd = coneDir(sunrd, sunrad);
        sum += skypt(ro, rd, sampledsunrd, sunirradiance, sun);
        //sum += skypt(ro, rd, -sampledsunrd, moonirradiance, vec3(0.0));
    }
    
    return sum / float(SAMPLES);
}