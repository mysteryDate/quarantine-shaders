precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform float u_radius;

#define PI 3.141592685
#define TAU (2.0 * PI)

float smin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

float fill(float x, float size) {
  return 1.0 - step(size, x);
}

float circleSDF(vec2 st) {
  return length(st - 0.5) * 2.0;
}

float linear010(float x) { // casts 0 -> 1 to 0 -> 1 -> 0
  return -abs(2.0 * x - 1.0) + 1.0;
}

float cos010(float x) {
  return (1.0 - cos(x)) / 2.0;
}

float easeCubicInOut(float t) {
    t = t * 2.0; if (t < 1.0) return 0.5 * t * t * t;
    return 0.5 * ((t -= 2.0) * t * t + 2.0);
}

vec2 rotate(vec2 st, float theta) {
  mat2 rotationMatrix = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
  return rotationMatrix * st;
}

vec2 rotateAboutPoint(vec2 st, float theta, vec2 point) {
  return rotate(st - point, theta) + point;
}

const float DURATION = 12.0;
void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    float time = mod(u_time / DURATION, 1.0);
    vec2 mouse = u_mouse.xy;
    st = rotateAboutPoint(st, time * TAU, vec2(0.5));

    vec3 c1 = vec3(st.x, st.y, cos010(time * TAU));
    vec3 color = mix(vec3(1.0), c1, smoothstep(0.0, 0.4, time));
    color = mix(color, vec3(1.0), smoothstep(0.5, 0.9, time));

    float smallCircleDistance1 = 0.3;
    float smallCircleDistance0 = 0.15;
    float smallCircleSizeRatio0 = 0.1;
    float smallCircleSizeRatio1 = 0.4;
    float size = 0.2;

    float bigCircleSize = mix(1.0, 0.4, smoothstep(0.0, 0.3, time));
    bigCircleSize = mix(bigCircleSize, 1.0, smoothstep(0.4, 0.7, time));
    float bigCircle = circleSDF(st) / bigCircleSize;
    float finalSDF = bigCircle;
    float accumulation = 0.0;
    const float numCircles = 10.0;
    for (float i = 0.0; i < numCircles; i+= 1.0) {
        float normalizedI = i / (numCircles - 1.0);
        float timeOffset = i / numCircles / 4.0;

        float t0 = mod(time + timeOffset, 1.0);
        float theta = (i + 4.0) * 3.83 * t0 * TAU  / numCircles;
        theta *= mouse.x;  // interaction
        vec2 st0 = rotateAboutPoint(st, theta, vec2(0.5));

        float disp = easeCubicInOut(linear010(t0));
        vec2 pos = vec2(0, disp);
        float r0 = mix(smallCircleDistance0, smallCircleDistance1, normalizedI);
        float smallCircle = circleSDF(st0 - pos * r0);
        smallCircle /= mix(smallCircleSizeRatio0, smallCircleSizeRatio1, normalizedI);
        finalSDF = smin(finalSDF, smallCircle, 0.4);
    }

    color *= step(finalSDF, size);
    color += stroke(finalSDF, size, 0.01);

    gl_FragColor = vec4(color, 1.0);
}