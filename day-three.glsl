precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform vec3 u_test;

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

#define PI 3.141592685
#define EPSILON 1e-6
const float triSize = 0.35;
float rightTriangleSDF(vec2 st) {
  st += triSize / 2.0; 
  float result = abs(st.x + st.y) + EPSILON;
  float edge = step(0.0, st.y) * step(0.0, st.x);
  result *= 999999.9 * (1.0 - edge) + 1.0;
  return result;
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}

float stepBetween(float x, float min, float max) {
  return step(min, x) * (1.0 - step(max, x));
}

float rectangleSDF(vec2 st, vec2 s) {
  return max(abs(st.x/s.x), abs(st.y/s.y));
}

float squareSDF(vec2 st) { // For squares
  return rectangleSDF(st, vec2(1.0));
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
	return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

float quarticInOut(float t) {
  return t < 0.5
    ? +8.0 * pow(t, 4.0)
    : -8.0 * pow(t - 1.0, 4.0) + 1.0;
}

const float duration = 10.0;
const float NUM_ANIMATION_STEPS = 4.0;
const vec3 c1 =vec3(0.6196, 0.8627, 0.9059);
const vec3 c2 =vec3(0.6588, 0.251, 0.8196);
void main() {
  float time = mod(u_time / duration, 1.0) * NUM_ANIMATION_STEPS * 2.0;
  // time = 0.0;

  vec3 fgColor = mix(c1, c2, step(NUM_ANIMATION_STEPS, time));
  vec3 bgColor = mix(c2, c1, step(NUM_ANIMATION_STEPS, time));
  time = mod(time, NUM_ANIMATION_STEPS);
  float c = 0.0;

  vec2 st = gl_FragCoord.xy / u_resolution.yy;
  if (u_resolution.x > u_resolution.y)
    st = gl_FragCoord.xy / u_resolution.xx;

  
  float spinTime = 1.8;
  if (stepBetween(time, 0.0, spinTime) > 0.0) {
    // Rotate triangles
    time = map(time, 0.0, spinTime, 0.0, 1.0);
    time = quarticInOut(time);
    // float b = triSize * 0.9;
    float b = 0.5 - triSize / 2.0;
    // Clockwise from lowerright
    mat4 positions = mat4(
      b, b, 0.0, 0.0,
      b, 1.0 - b, 0.0, 0.0,
      1.0 - b, 1.0 - b, 0.0, 0.0,
      1.0 - b, b, 0.0, 0.0
    );
    vec4 rotations = vec4(0.0, 1.5 * PI, PI, PI/2.0);

    for (int i = 0; i < 4; i++) {
      vec2 offset = vec2(positions[i][0], positions[i][1]);
      float triangle = rightTriangleSDF(
        rotateAboutPoint(
          st - offset, time * PI + rotations[i], vec2(0.0)));
      c += fill(triangle, triSize); 
    }
  } else if (stepBetween(time, spinTime, 4.0) > 0.0) {
    // time = map
    time = map(time, spinTime, 3.8, 0.0, 1.0);
    time = min(time, 1.0);
    time = quarticInOut(time);
    c += 1.0;
    float hypotenuse = sqrt(triSize * triSize * 2.0);
    float square = squareSDF(
      rotateAboutPoint(st - 0.5, PI * 0.25, vec2(0.0))
    );
    c += fill(square, hypotenuse / 2.0);

    float bigSquare = fill(squareSDF(st - 0.5), 
      mix(0.5, triSize, time)
    );
    c -= bigSquare;
  }
  c = mod(c, 2.0);
  vec3 color = mix(bgColor, fgColor, c);

  gl_FragColor = vec4(color, 1.0);

  // gl_FragColor = vec4(bgColor, 1.0);
  // if (st.x < 0.5)
  //   gl_FragColor = vec4(fgColor, 1.0);
}