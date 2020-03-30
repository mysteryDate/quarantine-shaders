#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.141592685
#define TAU (2.0 * PI)
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float DURATION = 5.0;
void main() {
  float time = mod(u_time, 1.0) * DURATION;
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  vec2 mouse = u_mouse.xy;
  vec3 color = vec3(0.0);
  
  gl_FragColor = vec4(color, 1.0);
}