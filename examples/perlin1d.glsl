const float pi = radians(180.0);

float hash11(float x) {
  int xi = int(floor(x));
  xi = (xi << 3) ^ xi;
  xi = xi * (xi * xi * 15731) + 1376312589;
  return float(xi)*(1.0/float(0x7fffffff));
}

float serp(float value) {
  return 0.5 * (1.0  - cos(value * pi));
}

float perlin1d(float pos, float scale) {
  float posLow = floor(pos / scale);
  float posHigh = posLow + 1.0;
  // float lowSlope = hash33(vec3(posLow, 0.0, 0.0)).x;
  // float highSlope = hash33(vec3(posHigh, 0.0, 0.0)).x;
  float lowSlope = hash11(posLow);
  float highSlope = hash11(posHigh);
  float offLow = fract(pos / scale);
  float offHigh = offLow - 1.0;
  float lowDot = dot(lowSlope, offLow);
  float highDot = dot(highSlope, offHigh);
  
  return mix(
    lowDot,
    highDot,
    serp(fract(pos / scale))
  );
  return 0.0;
}

float f(float x) {
  return perlin1d(x, 1.0);
}

// tool functions
float lum(vec3 pos) {
  return sin(pos.x / 4.0 - time) / 2.0 + 0.5;
}

// main functions
vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  vec2 scale = vec2(64.0, 64.0);
  // f(x)
  if (abs(f(pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 16.0) return vec4(1.0, lum(pos), 0.0, 1.0);
  if (pos.z >= 31.0 && (floor(pos.x) == 0.0 || floor(pos.y) == 0.0)) return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, float(floor(pos.y) != 0.0), float(floor(pos.x) != 0.0), 1.0); // wall axis
  if (pos.z >= 32.0) return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, float(floor(pos.y) != 0.0), float(floor(pos.x) != 0.0), 0.5); // back wall
  // miss case
  return vec4(1.0, 1.0, 1.0, 0.0);
}