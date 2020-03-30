#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.141592685
#define TAU 2.0 * PI
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
  
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

float atan2(in float y, in float x) {
    return x == 0.0 ? sign(y)*PI/2.0 : atan(y, x);
}

float cos010(float x) {
  return (1.0 - cos(x)) / 2.0;
}

float wavyCircleSDF(vec2 st, float size, float waviness, 
    float frequency, float phase, float width, float t) {
  st -= 0.5;
  float theta = t * TAU;
  float angle = atan2(st.y, st.x) + PI;

  float amplitude = 0.0;
  for (int i = 0; i < 3; i++) {
    float dt = abs(angle - theta - TAU + TAU * float(i)) / width;
    float angle = cos010(dt + PI) * size * waviness;
    if (dt > PI) angle = 0.0;
    amplitude = max(amplitude, angle);
  }
  
  float r = length(st) * 2.0;
  r += sin(frequency * angle + phase) * amplitude;
  return r;
}

float DURATION = 12.0;
float NUM_STEPS = 5.0;
void main() {
  float time = mod(u_time / DURATION, 1.0);
  float t0 = fract(time * NUM_STEPS);
  float section = floor(time * NUM_STEPS);
  float tf = time * NUM_STEPS;

  vec2 st = gl_FragCoord.xy / u_resolution.x;
  // Squaring things up
  st.y -= (u_resolution.y / u_resolution.x - 1.0) / 2.0;
  if (st.y > 1.0 || st.y < 0.0) { return; }
  vec2 mouse = u_mouse.xy;
  vec3 color = vec3(0.0);

  float finaleControl = smoothstep(2.5, 3.2, tf) * 
    (1.0 - smoothstep(3.6, 5.0, tf));

  // Size of the waves
  float waviness0 = 0.1;
  float wavinessf = 0.4;
  float waviness = mix(waviness0, 
      mix(wavinessf, waviness0, smoothstep(3.7, 5.0, tf)),
    smoothstep(0.8, 3.2, tf));
  float waveFrequency = 6.0;
  float waveWidth = 0.3;
    
  float size0 = 0.4;
  float size1 = 0.3;
  float size = mix(
    size0, 
      mix(size1, size0, smoothstep(3.5, 5.0, tf)),
    smoothstep(2.0, 3.0, tf)); 

  float cs0 = 0.0;
  float cs1 = 0.02;
  float csf = 0.03;
  float colorSeparation = mix(
    cs0, 
      mix(cs1, csf, smoothstep(2.5, 3.2, tf)),
    smoothstep(0.8, 1.2, tf));
  colorSeparation = mix(colorSeparation, cs0, smoothstep(3.5, 4.9, tf));
  

  // separate other rings
  float stt = 0.5; // separation transition time;
  float separationStrength = 0.07;
  float separation = smoothstep(2.5 - stt, 2.5 + stt, tf) 
    * (1.0 - smoothstep(4.0, 5.0, tf)) * separationStrength;

  // Thicken the lines
  float startLineThickness = 0.01;
  float endLineThickness = 0.03;
  float ltt = 0.5; // line thickness transition time
  float ltControl = smoothstep(2.5 - stt, 2.5 + stt, tf) 
    * (1.0 - smoothstep(3.8, 4.2, tf));
  float lineThickness = mix(startLineThickness, endLineThickness, ltControl);

  // Fade in other rings
  float ott = 0.5;
  float otherRingStrength = smoothstep(1.0 - ott, 1.0 + ott, tf) 
    * (1.0 - smoothstep(4.0, 5.0, tf));

  const float NUM_RINGS = 16.0;
  for (int j = 0; j < 3; j++) {
    for (float i = 0.0; i < NUM_RINGS; i++) {
      float normalizedI = map(i, 0.0, NUM_RINGS - 1.0, 0.0, 1.0);
      float s1 = size * (i * separation + 1.0);
      float ww1 = waveWidth * map(i, 0.0, NUM_RINGS - 1.0, 1.0, 3.0 + finaleControl);
      float t1 = t0 + float(j) * colorSeparation;
      float strength = mix(1.0 - step(0.01, normalizedI), 
        1.0 - smoothstep(0.0, 1.0, normalizedI), otherRingStrength);

      float circle = wavyCircleSDF(st, s1, waviness, waveFrequency, 0.0, ww1, t1);
      color[j] += strength * stroke(circle, s1, lineThickness);
      circle = wavyCircleSDF(st, s1, waviness, waveFrequency, PI, ww1, t1);
      float sec1Color = max(color[j], strength * stroke(circle, s1, lineThickness) * 0.5);
      float sec3Color = color[j] + strength * stroke(circle, s1, lineThickness) * 0.5;
      color[j] = mix(sec1Color, sec3Color, finaleControl);
    }
  }
  
  gl_FragColor = vec4(color, 1.0);
}