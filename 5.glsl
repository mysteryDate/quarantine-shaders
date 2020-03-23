precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform vec3 u_test;

#define PI 3.141592685

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

const float sqrt3over2 = sqrt(3.0)/2.0;
float triangleSDF(vec2 st) {
  // st = 2.0 * (2.0 * st - 1.0);
  return max(sqrt3over2 * abs(st.x) + 0.5 * st.y, -0.5 * st.y);
}

float circleSDF(vec2 st) {
  return length(st) * 2.0;
}

float sin01(float x) {
  return 0.5 * sin(x) + 0.5;
}

float smin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

const float NUM = 6.0;
void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec2 m = u_mouse;
  float t = u_time / 2.0;
  vec3 color = vec3(0.0);
  vec3 color1 = vec3(st.x, sin01(t * 4.0), st.y);

  float finalSDF = 99999.0;
  float colorControl = 0.0 + 2.0 * (u_mouse.x - 0.5);
  float offset = 0.4 * sin(t);
  for (float i = 0.0; i <= NUM; i += 1.0) {
    float x = 0.5 - offset / NUM * i + offset / 2.0;
    float y = 0.5;
    float triangle = triangleSDF(st - vec2(x, y));
    colorControl += fill(triangle, 0.08);
    // finalSDF += triangle;
    finalSDF = smin(finalSDF, triangle, u_test.x);
  }

  color = mix(color, color1, fill(finalSDF, 0.2));
  color = mix(vec3(0.0), color1, colorControl);

  gl_FragColor = vec4(color, 1.0);
}