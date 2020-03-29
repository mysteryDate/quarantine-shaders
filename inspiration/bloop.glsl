precision highp float;

#pragma glslify: gradient = require(../../lib/gradient)
#pragma glslify: hash = require(../../lib/hash)
#pragma glslify: impulse = require(../../lib/iq/impulse)
#pragma glslify: map = require(../../lib/map)
#pragma glslify: smoothUnion = require(../../lib/iq/smoothUnion)

float circleSDF(vec2 st, float radius) {
  return length(st) - radius;
}

vec4 hash1to4(float x) {
  vec4 seed = vec4(hash(vec2(x)));
  seed.y = hash(seed.xx + 12.329);
  seed.z = hash(seed.xy * PI + 43.239);
  seed.w = hash(seed.xz * 417.109 - PI*0.1);
  return seed;
}

float randomDotSDF(vec2 st, float t, float index) {
  vec4 seed = hash1to4(index);

  float angle = 2.0 * PI * seed.x;
  float size = mix(0.15, 0.2, seed.y);
  float speed = mix(1.5, 2.0, seed.z);
  float popiness = mix(10.0, 30.0, seed.w);

  float alpha = t * t * speed;

  vec2 center = vec2(
    alpha * cos(angle),
    alpha * sin(angle)
  );
  float radius = size * impulse(popiness, alpha);

  return circleSDF(st - center, radius);
}

uniform vec2 u_resolution;
uniform float u_time;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float aspect = u_resolution.x / u_resolution.y;
  uv.x *= aspect;
  uv.x += 0.5 - aspect/2.0;

  vec2 st = map(uv, 0.0, 1.0, -1.0, 1.0);

  const float magicOffset = 29.0; // to find a nicer beginning
  const float loopTime = 5.0;
  const int numParticles = 20;

  float d = 1e12;
  for (int i = 0; i < numParticles; i++) {
    float shiftedTime = u_time;
    shiftedTime -= loopTime * float(i) / float(numParticles);
    shiftedTime += magicOffset;
    float t = fract(shiftedTime / loopTime);
    float loopIndex = floor(shiftedTime / loopTime);
    float seed = loopIndex + float(i) * 142.8;
    float k = 0.3;
    d = smoothUnion(d, randomDotSDF(st, t, seed), k);
  }

  float alpha = 1.0 - step(0.0, d);

  vec3 bg = gradient(st,
    vec3(0.8, 0.85, 0.9),
    vec3(0.9, 0.95, 0.95),
    vec2(-1.0, -1.0),
    vec2(1.0, 0.8)
  );
  vec3 fg = mix(
    vec3(0.0, 0.2, 0.6),
    vec3(0.0, 0.3, 0.9),
    dot(st, st)
  );
  vec3 color = mix(bg, fg, alpha);

  gl_FragColor = vec4(color, 1.0);
}
