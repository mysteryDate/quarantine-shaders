precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
#define PI 3.141592685

float circleSDF(vec2 st) {
  return length(st) * 2.0;
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

const float sqrt3over2 = sqrt(3.0)/2.0;
float triangleSDF(vec2 st) {
  st = 2.0 * (2.0 * st - 1.0);
  return max(sqrt3over2 * abs(st.x) + 0.5 * st.y, -0.5 * st.y);
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

void main() {
  vec2 mouse = u_mouse;
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec3 color = vec3(0.0);

  float a = atan2(mouse.y - 0.5, mouse.x - 0.5);

  float circle = circleSDF(st - mouse);
  color += fill(circle, 0.1);

  float triangle = triangleSDF(rotateAboutPoint(st, a, vec2(0.5)));
  color += fill(triangle, 0.2);

  color.rb += mouse.xy;

  gl_FragColor = vec4(color, 1.0);
}