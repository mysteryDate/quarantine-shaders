#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.141592685
#define TAU 2.0 * PI

float circleSDF(vec2 st) {
  return length(st - 0.5) * 2.0;
}

float polygonSDF(vec2 st, int numSides) {
  st = 2.0 * st - 1.0;
  float a = atan(st.x, st.y) + PI;
  float r = length(st);
  float v = 2.0 * PI/float(numSides);
  return cos(floor(0.5 + a/v) * v - a) * r;
}

float rectangleSDF(vec2 st, vec2 s) {
  st = st * 2.0 - 1.0;
  return max(abs(st.x/s.x), abs(st.y/s.y));
}

float rectangleSDF(vec2 st) { // For squares
  return rectangleSDF(st, vec2(1.0));
}
