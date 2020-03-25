precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform vec3 u_test;

#define PI 3.141592685
const float sqrt3over2 = sqrt(3.0)/2.0;

float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

vec3 bridge(vec3 c, float d, float s, float w) {
  c *= 1.0 - stroke(d, s, 2.0 * w);
  return c + stroke(d, s, w);
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}
  
float circleSDF(vec2 st) {
  return length(st - 0.5) * 2.0;
}

float vesicaSDF(vec2 st, float w) {
  vec2 offset = vec2(w * 0.5, 0.0);
  return max(circleSDF(st - offset),
             circleSDF(st + offset));
}

const vec2 CENTER = vec2(0.5);
const float size = 0.45;
const float strokeWidth = 0.05;
const float vesicaSlope = 0.3;
const vec2 offset = vec2(0.0, 0.189);
// const int numPoints = 11;

float flowerSDF(vec2 st, float N, float ratio) {
  st = 2.0 * st - 1.0;
  float radius = 1.0 * length(st) * ratio / 0.5;
  float angle = atan(st.y, st.x);
  float petalNum = 0.5 * N;
  return 1.0 - (abs(ratio * cos(angle * petalNum)) + 0.5) / radius;
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
	return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

float sin01(float x) {
  return 0.5 * sin(x) + 0.5;
}

void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec2 m = u_mouse;
  float t = u_time / 4.0;
  float scale = map(sin01(t), 0.0, 1.0, 0.2, 1.0);
  st = (st - 0.5) / scale + 0.5;
  vec2 colst = 1.0 - abs(rotate(st - 0.5, 2.0 * PI * t / 3.0)) * 2.0;
  vec3 color1 = vec3(colst.x, colst.y, sin01(t + PI/2.0) + 0.5);
  vec3 color = vec3(0.0);

  float numPetals = map(sin(t), -1.0, 1.0, 0.0, 3.0);

  const float NUM = 6.0;
  float colorScale = map(sin01(t), 0.0, 1.0, 0.5, 1.0);
  for (float i = 0.0; i < NUM; i += 1.0) {
    float flower = flowerSDF(
      rotateAboutPoint(st, i * PI/3.0 + m.x * i, vec2(0.5)), 
      numPetals, 1.5);
    color += stroke(flower, 0.2, 0.03);
    color += fill(flower, 0.2) * 0.4 * colorScale * color1;
  }

  gl_FragColor = vec4(color, 1.0);
}
