precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform float u_radius;
uniform vec3 u_test;

float stroke(float x, float s, float w) {
  float d = step(s, x + w * 0.5) - step(s, x - w * 0.5);
  return clamp(d, 0.0, 1.0);
}

float clamp01(float x) {
  return clamp(x, 0.0, 1.0);
}

const float sqrt3over2 = sqrt(3.0)/2.0;
float triangleSDF(vec2 st) {
  st = 2.0 * (2.0 * st - 1.0);
  return max(sqrt3over2 * abs(st.x) + 0.5 * st.y, -0.5 * st.y);
}

#define PI 3.14159
float polygonSDF(vec2 st, float numSides) {
  st = 2.0 * st - 1.0;
  float a = atan(st.x, st.y) + PI;
  float r = length(st);
  float v = 2.0 * PI/numSides;
  return cos(floor(0.5 + a/v) * v - a) * r;
}

float sin01(float x) {
    return (sin(x) + 1.0) / 2.0;
}

float circleSDF(vec2 st) {
  return length(st - 0.5) * 2.0;
}

float dancer(vec2 st, float c, float size, float width) {
    float lines = circleSDF(st);
    float triangle = triangleSDF(st);
    float rectangle = polygonSDF(st, 4.0);
    float pentagon = polygonSDF(st, 5.0);
    float hexagon = polygonSDF(st, 6.0);

    float circlegon = polygonSDF(st, 
        clamp01((c - 5.0) / 3.0) * 200.0 + 5.0);

    float finalSDF = mix(
        lines, 
            mix(triangle,  
                mix(rectangle, 
                    mix(pentagon, 
                        mix(pentagon, circlegon, clamp01((c - 5.0) / 2.0)), 
                    clamp01(c - 4.0)), 
                clamp01(c - 3.0)), 
            clamp01(c - 2.0)),
        clamp01(c - 1.0)
    );

    float r = size * (1.0 - clamp01((c - 6.0)/2.0)) * clamp01(c);
    return stroke(finalSDF, r, width);
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

const float duration = 20.0;
const float total = 15.0;
void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    vec2 m = u_mouse - 0.5;
    float a = atan2(m.y, m.x);
    st = rotateAboutPoint(st, 2.0 * a, vec2(0.5));
    vec3 color = vec3(0.0);
    float numSteps = 8.0;

    float colorControl = 0.0;
    for (float i = 0.0; i < total; i += 1.0) {
        float time = mod((u_time - i/5.0) / duration, 1.0);
        float c = time * numSteps;
        colorControl += dancer(st, c, 0.5, 0.01) * (1.0 - i/total);
    }

    float colorClock = sin01((u_time + 2.0) * 2.0 * PI / duration);
    vec3 bgColor = mix(
        vec3(0.4392, 0.1294, 0.4392),
        vec3(0.0, 0.0, 0.0),
        colorClock);
    vec3 fgColor = mix(
        vec3(0.0, 1.0, 1.0),
        vec3(1.0),
        colorClock
    );
    color = mix(bgColor, fgColor, colorControl);
    
    gl_FragColor = vec4(color, 1.0);
}