precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform float u_radius;

float smin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float circleSDF(vec2 st) {
  return length(st) * 2.0;
}

#define PI 3.141592685

void main() {
    vec2 mouse = u_mouse;
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    float t = u_time / 2.0 + length(mouse) * 2.0;

    vec3 color = vec3(0.0);
    color = vec3(st.x, abs(sin(t)), st.y);
    float finalSDF = 1.0;

    const float numCircles = 10.0;
    float minVal = float(9999.9);
    for (float i = 0.0; i < numCircles; i+= 1.0) {
          float angle = t * i + PI/2.0;
          vec2 pos = vec2(cos(angle), sin(angle)) * 0.4 * (i + 1.0) / numCircles;
          float smallCircle = circleSDF(st - 0.5 - pos) / (i / 2.0 + numCircles/2.0); 
          finalSDF = smin(finalSDF, smallCircle, 0.05);
    }

    color *= step(finalSDF, 0.008);

    gl_FragColor = vec4(color, 1.0);
}