precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
#define PI 3.141592685
#define TAU 2.0 * PI

float circleSDF(vec2 st) {
  return length(st - 0.5) * 2.0;
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}
  
float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
	return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}

float crescent(vec2 st, float size, float ratio, float offsetRatio) {
  float bigCircle = circleSDF(st);
  float maxOffset = size / 2.0 + size * ratio / 2.0;
  float minOffset = size / 2.0 - size * ratio / 2.0;
  float offset = map(offsetRatio, 0.0, 1.0, minOffset, maxOffset);
  float smallCircle = circleSDF(st - vec2(1.0, 0.0) * offset);

  return max(fill(bigCircle, size) - fill(smallCircle, size * ratio), 0.0);
}

float cos010(float x) {
  return (1.0 - cos(x)) / 2.0;
}

float easeCubicInOut(float t) {
    t = t * 2.0; if (t < 1.0) return 0.5 * t * t * t;
    return 0.5 * ((t -= 2.0) * t * t + 2.0);
}

float atan2(in float y, in float x) {
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

vec3 rgb2hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(in vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  rgb = rgb * rgb * (3.0 - 2.0 * rgb);
  return c.z * mix(vec3(1.0), rgb, c.y);
}

const float DURATION = 10.0;
void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec3 color = vec3(0.0);
  float t1 = mod(u_time / DURATION, 1.0);
  // t1 = u_test.x;
  st = rotateAboutPoint(st, -PI / 8.0, vec2(0.5));
  float t0 = mod(t1 * 2.0, 1.0);

  // The gradient
  float angle = atan2(st.x - 0.25, st.y - 0.3);
  vec3 c1 = vec3(
    cos010(angle + 4.0 * t0 * PI/2.0), 
    0.0, 
    pow(1.0 - length(st - 0.25), 1.0) 
  ) * 1.2;

  float internalRotation = 1.0;
  // Start and end on a crescent
  float irTime = 1.0 / 5.0;
  float irClock = 1.0;
  if (t0 < irTime) {
    irClock = t0 / irTime; 
    internalRotation = easeCubicInOut(irClock);
    c1 = mix(vec3(1.0), c1, internalRotation);
  } else if (1.0 - t0 < irTime) {
    irClock = (1.0 - t0) / irTime;
    internalRotation = easeCubicInOut(irClock);
    c1 = mix(vec3(1.0), c1, internalRotation);
  }

  // Transitioning to a circle
  float baseRatio = 0.8;
  float ratio = baseRatio;
  float ratioTransitionTime = 0.1;
  if (t1 < ratioTransitionTime) {
    ratio = map(
      easeCubicInOut(t1 / ratioTransitionTime), 0.0, 1.0, 0.0, baseRatio);
  } else if (t1 > 1.0 - ratioTransitionTime) {
    ratio = map(
      easeCubicInOut((1.0 - t1) / ratioTransitionTime), 1.0, 0.0, baseRatio, 0.0);
  }

  float size = 0.3;
  float offsetRatio = 0.03;
  float borderWidth = 0.005;

  float accumulation = 0.0;
  float border = 0.0;
  float distMultiplier = 0.2 * cos010(t0 * TAU);
  for (int i = 0; i < 8; i++) {
    float a = float(i);
    float angle = a * PI / 4.0;
    vec2 dist = vec2(cos(angle), sin(angle)) * distMultiplier; 
    vec2 cresST = rotateAboutPoint(st + dist, 
      PI / 4.0 * a * internalRotation + PI / 6.0 + t0 * TAU, 
      vec2(0.5));
    float cres = crescent(cresST, size, ratio, offsetRatio);
    border += stroke(circleSDF(cresST), size, borderWidth);
    accumulation += cres; 
  }

  float swap = mod(accumulation, 2.0);
  color += swap * c1;
  vec3 hsv = rgb2hsv(c1);
  if (t1 > 0.5)
    hsv.r += 0.5;
  hsv.r += 0.2;
  vec3 c2 = hsv2rgb(hsv);
  color += accumulation / 2.0 * c2;
  color += border * step(0.55, t1) * 0.5;

  gl_FragColor = vec4(color, 1.0);
}