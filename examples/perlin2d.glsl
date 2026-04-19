const int k = 1103515245;
const float pi = radians(180.0);

// see: https://www.shadertoy.com/view/NflXW7
vec3 hash33(vec3 x) {
  ivec3 xi = ivec3(floor(x));
  xi = ((xi>>8)^xi.yzx)*k;
  xi = ((xi>>8)^xi.yzx)*k;
  xi = ((xi>>8)^xi.yzx)*k;
  
  return vec3(xi)*(1.0/float(0x7fffffff));
}
float hash21(vec2 x) {
  return hash33(vec3(x, 1.0)).x;
  /* ivec2 xi = ivec2(floor(x));
  xi = (xi << 3) ^ xi;
  xi = xi * (xi * xi * 15731) + 1376312589;
  int c = (xi.x << 3) ^ xi.y * 1103515245;
  return float(c)*(1.0/float(0x7fffffff));*/
}

float serp(float value) {
  return 0.5 * (1.0  - cos(value * pi));
}

vec2 floatToVec2(float x) {
  return vec2(sin(x * pi), cos(x * pi));
}

float perlin2d(vec2 pos) {
  vec2 p0 = floor(pos);
  vec2 p1 = p0 + vec2(1.0, 0.0);
  vec2 p2 = p0 + vec2(0.0, 1.0);
  vec2 p3 = p0 + vec2(1.0, 1.0);
  vec2 s0 = floatToVec2(hash21(p0));
  vec2 s1 = floatToVec2(hash21(p1));
  vec2 s2 = floatToVec2(hash21(p2));
  vec2 s3 = floatToVec2(hash21(p3));
  vec2 o0 = pos - p0;
  vec2 o1 = pos - p1;
  vec2 o2 = pos - p2;
  vec2 o3 = pos - p3;
  float d0 = dot(s0, o0);
  float d1 = dot(s1, o1);
  float d2 = dot(s2, o2);
  float d3 = dot(s3, o3);
  return mix(
    mix(d0, d1, serp(o0.x)),
    mix(d2, d3, serp(o0.x)),
    serp(o0.y)
  );
}

float f(vec2 pos) {
  return perlin2d(pos) - 1.0;
}

// tool functions
vec3 voxCol(vec3 pos) {
  return sin((pos / 2.0 + time) / 2.0) / 2.0 + 0.5;
}

vec3 voxCol(vec3 pos, vec3 col) {
  return (sin((pos / 2.0 + time) / 2.0) / 2.0 + 0.5) * col;
}

// main functions
vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  vec3 scale = vec3(32.0);
  // f(x)
  if (abs(f(pos.xz / scale.xz) * scale.y - pos.y) < 1.0) return vec4(voxCol(pos, vec3(0.0, 1.0, 0.0)) + vec3(1.0, 0.0, 0.0), 1.0);
  // water
  if (pos.y <= -1.0 * scale.y) return vec4(0.0, 0.5, 1.0, 0.1);
  // colored axis
  // if (dot(vec3(equal(pos, vec3(0.0))), vec3(1.0)) >= 2.0) 
    // return vec4(voxCol(pos, vec3(notEqual(pos, vec3(0.0)))), 0.5);
  // miss case
  return vec4(1.0, 1.0, 1.0, 0.0);
}