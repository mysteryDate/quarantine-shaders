precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform float u_radius;
uniform vec3 u_test;

#define PI 3.14159
const float sqrt3over2 = sqrt(3.0)/2.0;

float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

float triangleSDF(vec2 st) {
  st = 2.0 * (2.0 * st - 1.0);
  return max(sqrt3over2 * abs(st.x) + 0.5 * st.y, -0.5 * st.y);
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

float cos01(float x) {
    return (cos(x) + 1.0) / 2.0;
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}

float atan2(in float y, in float x) {
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

const float duration = 16.0;
const float NUM = 12.0;
const float size = 0.5;
void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    vec2 mouse = u_mouse;
    float t = mod(u_time / duration, 1.0) * 2.0 * PI + PI;
    float a = atan2(mouse.y - 0.5, mouse.x - 0.5) - 1.5;
    st = rotateAboutPoint(st, 0.0, vec2(0.5));
    vec2 colst = 1.0 - abs(rotate(st, t)) * 2.0;
    vec3 color = vec3(colst, cos01(t + PI/2.0) + 0.5);
    vec3 outCol = vec3(0.0);

    float spread = 0.3 * cos01(t);
    for (float i = 1.0; i <= NUM; i++) {
      float displacement = sin(PI * i / 4.0 * t) * spread; 
      vec2 uv = ((1.0 + abs(3.0 * displacement)) * 
        (vec2(st.x + displacement, st.y) - 0.5)) + 0.5;
      float tri = triangleSDF(rotateAboutPoint(uv, a, vec2(0.5)));
      outCol += stroke(tri, size, 0.01) * 0.1;
      outCol += fill(tri, size) * color * (spread);
    }
    
    gl_FragColor = vec4(outCol, 1.0);
}