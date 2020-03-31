precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform vec3 u_test;

#define PI 3.141592685
#define TAU (2.0 * PI)

float fill(float x, float size) {
  return 1.0 - step(size, x);
}
  
float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

float rectangleSDF(vec2 st, vec2 s) {
  st = st * 2.0 - 1.0;
  return max(abs(st.x/s.x), abs(st.y/s.y));
}

float rectangleSDF(vec2 st) { // For squares
  return rectangleSDF(st, vec2(1.0));
}

float sin01(float x) {
  return 0.5 * sin(x) + 0.5;
}

float cos010(float x) {
  return (1.0 - cos(x)) / 2.0;
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}

vec2 spin(vec2 st, float theta) {
  return rotateAboutPoint(st, theta, vec2(0.5));
}

float easeCubicInOut(float t) {
    t = t * 2.0; if (t < 1.0) return 0.5 * t * t * t;
    return 0.5 * ((t -= 2.0) * t * t + 2.0);
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
	return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

float atan2(in float y, in float x) {
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

const float DURATION = 6.0;
void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec2 mouse = u_mouse;
  float orientationAngle = atan2(mouse.y - 0.5, mouse.x - 0.5);
  st = spin(st, orientationAngle); // For interaction
  float time = mod(u_time / DURATION, 1.50);
  float section = floor(time);
  vec3 color = vec3(0.0);

  vec2 colST = spin(st, time * TAU);
  vec3 c1 = vec3(colST.x, colST.y, 1.0);

  float offsetAmount = 0.5;
  float size = 1.84;
  float sizeChange = 1.2;
  float rotation = time * PI;
  float bloopiness = 0.0;
  const float NUM_SQUARES = 12.0;

  // Stage one
  if (time < 0.25 || time > 1.25) {
    offsetAmount = 0.0;
    size *= sizeChange;
  } else {
    float t0 = map(time, 0.25, 1.25, 0.0, 1.0);
    size *= mix(sizeChange, 1.0, cos010(t0 * TAU));
    c1 *= mix(1.0, 1.5, cos010(t0 * TAU));
    offsetAmount = mix(offsetAmount, offsetAmount * 1.2, 
      smoothstep(0.5, 0.8, t0)
    );
  }

  float accumulation = 0.0;
  float strokeAccumulation = 0.0;
  float offset = offsetAmount * easeCubicInOut(abs(sin(time * TAU + PI/2.0)));
  for (float i = 0.0; i <= NUM_SQUARES; i += 1.0) {
    float x = -offset / NUM_SQUARES * i + offset / 2.0;
    float y = 0.0;
    float r1 = rotation * (10.0 * abs(x) * time + 1.0);
    float square = rectangleSDF(spin(st - vec2(x, y), r1));

    float sizeModifier = pow((abs(x) + 0.5), 3.0) * pow((1.0 - offset), 3.0);
    accumulation += fill(square, size * sizeModifier);
    strokeAccumulation += stroke(square, size * sizeModifier, 0.001);
  }

  color = c1 * accumulation;
  color += strokeAccumulation;
  
  gl_FragColor = vec4(color, 1.0);
}