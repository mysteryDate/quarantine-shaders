precision mediump float;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
#define PI 3.14159
const float sqrt3over2 = sqrt(3.0)/2.0;

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

float circleSDF(vec2 st) {
  return length(st);
}

float polygonSDF(vec2 st, int numSides) {
  float a = atan(st.x, st.y) + PI;
  float r = length(st);
  float v = 2.0 * PI/float(numSides);
  return cos(floor(0.5 + a/v) * v - a) * r;
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
	return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * (st - vec2(0.5)) + vec2(0.5);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float easeBackInOut(float t) {
    t *= 2.0; float s = 1.70158;
    if (t < 1.0) return 0.5 * (t * t * (((s *= (1.525)) + 1.0) * t - s));
    return 0.5 * ((t -= 2.0) * t * (((s *= (1.525)) + 1.0) * t + s) + 2.0);
}

float easeQuartInOut(float t) {
    t = t * 2.0; if (t < 1.0) return 0.5 * t * t * t * t;
    return -0.5 * ((t -= 2.0) * t * t * t - 2.0);
}

float atan2(in float y, in float x) {
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

// if 0 > x > 1, returns a curve from 0 -> 1 -> 0
float powerEase010(float x, float power) {
  return -pow(power, 2.0) * pow(x - 0.5, power) + 1.0;
}

const float SIZE = 0.13;
const float NUMSTEPS = 6.0;
const float DURATION = 7.0;
const float rot = 2.0 * PI / 3.0;
float splitAmount = 1.0 / 100.0;
float circleDistance = 2.5;
float circleSize = 0.55;
float bloopiness = 0.4;
float colorTransitionTime = 0.5;
void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec2 mouse = u_mouse;
  float angle = atan2(mouse.y - 0.5, mouse.x - 0.5) - PI/6.0 + rot;
  st = rotate(st, angle);
  vec3 color = vec3(0.0);
  float time = u_time;

  vec2 triST = st;
  for (int i = 0; i < 3; i++) {
    float a = float(i);
    float t1 = mod(time / DURATION, 1.0) * NUMSTEPS; 
    float separation = float(i) * t1 * splitAmount;
    t1 += separation;

    vec2 cirST = rotate(st, rot * floor(t1 / 2.0));
    vec2 triST = rotate(st, rot * floor(t1 / 2.0));
    vec2 circleOffset = vec2(0.0);

    if (mod(t1, 2.0) > 1.0) {
      // Rotate the triangle
      float easedT = floor(t1) + easeBackInOut(fract(t1));
      triST = rotate(triST, fract(easedT) * rot);
      easedT = powerEase010(fract(t1), 2.0);
      bloopiness *= map(1.0 - easedT, 0.0, 1.0, 0.7, 1.0);
    } else if (t1 < 5.0) {
      // Bounce out the circle
      float easedT = powerEase010(fract(t1), 4.0);
      circleOffset = SIZE * circleDistance * vec2(0.0, 1.0) * easedT;
      circleOffset *= vec2(0.0, 1.0) + separation * 2.0;
      triST = (triST - 0.5) / (1.0 - 1.5 * circleOffset.y) + 0.5;
    }

    float triangle = polygonSDF(triST - 0.5, 3);
    float circle = circleSDF((cirST - 0.5 + circleOffset) / circleSize);
    float sdf = smin(circle, triangle, bloopiness);
    color[i] = fill(sdf, SIZE);
  }

  // Black to white transition
  float cT = colorTransitionTime / NUMSTEPS;
  float t0 = mod(time / (DURATION * 2.0), 1.0);
  float colorControl = 0.0;
  if (t0 > 0.5 - cT && t0 < 0.5 + cT) {
    colorControl = map(t0, 0.5 - cT, 0.5 + cT, 0.0, 1.0);
    colorControl = easeQuartInOut(colorControl);
  } if (t0 > 0.5 + cT) {
    colorControl = 1.0;
  } if (t0 < cT) {
    colorControl = map(t0, 0.0, cT, 0.5, 1.0);
    colorControl = 1.0 - easeQuartInOut(colorControl); 
  } if (t0 > 1.0 - cT) {
    colorControl = map(t0, 1.0 - cT, 1.0, 0.0, 0.5);
    colorControl = 1.0 - easeQuartInOut(colorControl);
  }
  color = mix(color, 1.0 - color, colorControl);

  gl_FragColor = vec4(color, 1.0);
}