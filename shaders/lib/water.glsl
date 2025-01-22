vec2 wave(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);

  return vec2(wave, -dx);
}

float getwaves(vec2 position) {
  float iter = 0.0;
  float freq = 1.0;
  float time = 1.0;
  float weight = 1.0;
  float sumval = 0.0;
  float sumw = 0.0;

  for(int i = 0; i < 10; i++) {
    vec2 p = vec2(sin(iter), cos(iter));
    vec2 res = wave(position, p, freq, frameTimeCounter * time);

    position += p * res.y * weight * 0.2;

    sumval += res.x * weight;
    sumw += weight;
    weight *= 0.74;
    freq *= 1.18;
    time *= 1.07;

    iter += 1232.399963;
  }
  return pow(sumval / sumw, 4.0);
}

vec3 waternorm(vec2 pos, float stepSize) {
    vec2 e = vec2(stepSize, 0.0);

    vec3 px1 = vec3(pos.x - e.x, getwaves(pos - e.xy), pos.y - e.y);
    vec3 px2 = vec3(pos.x + e.x, getwaves(pos + e.xy), pos.y + e.y);
    vec3 py1 = vec3(pos.x - e.y, getwaves(pos - e.yx), pos.y - e.x);
    vec3 py2 = vec3(pos.x + e.y, getwaves(pos + e.yx), pos.y + e.x);
    
    return normalize(cross(px2 - px1, py2 - py1));
}