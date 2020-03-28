precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
#define PI 3.141592685
const float sqrt3over2 = sqrt(3.0)/2.0;

float polygonSDF(vec2 st, int numSides) {
  st = 2.0 * st - 1.0;
  float a = atan(st.x, st.y) + PI;
  float r = length(st);
  float v = 2.0 * PI/float(numSides);
  return cos(floor(0.5 + a/v) * v - a) * r;
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}

float cos01(float x) {
  return (cos(x) + 1.0) / 2.0;
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
	return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

float cos010(float x) {
  return (1.0 - cos(x)) / 2.0;
}

const float TIMELINE_DURATION = 1.0;
const float DURATION = 20.0;
const float SIZE = 0.2;
const float MAX_DIST = -1.0;
const float MIN_DIST = 0.0;
const float BLOOPINESS = 0.1;
const float BORDER_SIZE = 0.005;

void main() {
  vec2 mouse = u_mouse / u_resolution.xy;
  vec2 st = gl_FragCoord.xy;
  float t = mod(u_time / DURATION, 1.0) * 2.0 * PI;
  st = (map(cos010(t), 0.0, 1.0, 1.0, 2.0) * (st - 0.5)) + 0.5;
  vec3 outputColor = vec3(0.0);

  vec2 colst = 1.0 - abs(rotate(st - 0.5, t)) * 2.0;
  vec3 color1 = vec3(colst.y, colst.x, cos01(t));
  vec3 color2 = vec3(colst.x, cos01(t + PI/2.0) + 0.5, colst.y);
  color1 = mix(vec3(1.0), color2, cos010(t));

  float innerColorStrength = (1.0 - cos010(t * 2.0));
  float outerColorStrength = cos010(t);
  color2 *= outerColorStrength;

  float accumulation = 0.0;
  float invAccumulation = 0.0;
  float borders = 0.0;
  float invBorders = 0.0;
  float innerRotation = cos010(t);
  innerRotation = 2.0 * PI * 5.0 / 6.0 * cos010(t);
  float separation = 0.26 * cos010(t);
  separation *= map(length(mouse - 0.5), 0.0, 5.0, 1.0, 10.0);
  for (int j = 0; j < 3; j++) {
    float ja = float(j) * separation;
    for (int i = 0; i < 6; i++) {
      float a = float(i);
      float angle = a * PI / 3.0;
      vec2 dist = vec2(cos(angle), sin(angle)); 
      dist *= map(1.0 - cos(t), 0.0, 1.0, (MIN_DIST + 1.0) * SIZE, (MAX_DIST + 1.0) * SIZE);
      vec2 triST = rotateAboutPoint(st + dist, PI / 3.0 * a + PI / 6.0, vec2(0.5));
      triST.x += ja;
      triST = rotateAboutPoint(triST, innerRotation, vec2(0.5));
      float tri = polygonSDF(triST, 3);
      accumulation += fill(tri, SIZE);
      borders += stroke(tri, SIZE, BORDER_SIZE);

      // Inverted triangle
      triST = rotateAboutPoint(triST, 1.0 * PI / 3.0, vec2(0.5, 0.5));
      triST -= vec2(0.0, SIZE);
      tri = polygonSDF(triST, 3);
      invAccumulation += fill(tri, SIZE);
      invBorders += stroke(tri, SIZE, BORDER_SIZE);
    }
  }

  outputColor += color1 * mod(accumulation, 2.0);
  outputColor += borders * innerColorStrength;
  outputColor += invBorders * outerColorStrength;

  gl_FragColor = vec4(outputColor, 1.0);
}