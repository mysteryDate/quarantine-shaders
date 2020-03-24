precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform vec3 u_test;

#define PI 3.141592685
const float sqrt3over2 = sqrt(3.0)/2.0;

float smin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float triangleSDF(vec2 st) {
  st = 3.0 * st;
  return max(sqrt3over2 * abs(st.x) + 0.5 * st.y, -0.5 * st.y);
}

float hexagonSDF(vec2 st) {
  st = abs(st);
  float result = sqrt3over2 * st.x + 0.5 * st.y;
  result = max(result, abs(st.y));
  return result;
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

float sin01(float x) {
  return 0.5 * sin(x) + 0.5;
}

const float NUM = 6.0;
void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  float t = u_time / 1.5;
  vec2 m = u_mouse / u_resolution.xy;
  vec3 color = vec3(0.0);
  vec2 colst = 1.0 - abs(rotate(st - 0.5, -t / 2.0)) * 2.0;
  vec3 color1 = vec3(colst.x, colst.y, sin01(t) + 0.5);

  float finalSDF = 99999.9;
  float spread = 0.25 + length(m - 0.5) / 2.0 - 0.25;
  float bloopiness = 0.45;
  float size = 0.1;
  float overlapSize = 0.1;
  for (float i = 0.0; i < NUM; i += 1.0) {
    float tri = triangleSDF(
      rotate(
        rotate(st - 0.5, PI/3.0 * i + t) - spread,
      t));
    finalSDF = smin(finalSDF, tri, bloopiness);
  }
  float hex = hexagonSDF(rotate(st - 0.5, 0. * t));
  finalSDF = smin(finalSDF, hex, bloopiness);

  float meldy = fill(finalSDF, size);
  color = mix(color, color1, meldy);

  gl_FragColor = vec4(color * 1.0, 1.0);
}