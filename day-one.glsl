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
  return length(st - 0.5) * 2.0;
}

#define PI 3.141592685

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    // st.x *= u_resolution.x / u_resolution.y;
    float t = u_time / 3.0;

    vec3 color = vec3(0.0);
    color = vec3(st.x, st.y, abs(sin(t * 2.0)));

    float bigCircle = circleSDF(st);
    float finalSDF = bigCircle;
    const float numCircles = 10.0;
    for (float i = 0.0; i < numCircles; i+= 1.0) {
        float a = float(i);
        float tt = t + a * 2.0 * PI/numCircles;
        float r = 0.35 * sin(u_time + tt);
        float smallCircle = circleSDF(
            st - vec2(sin(tt), cos(tt)) * r);
        smallCircle /= 0.4 * pow(0.9, a);
        finalSDF = smin(finalSDF, smallCircle, 0.4);
    }

    color *= step(finalSDF, 0.4);

    gl_FragColor = vec4(color, 1.0);
}