const int k = 1103515245;
const float pi = radians(180.0);

float serp(float value) {
  return 0.5 * (1.0  - cos(value * pi));
}

// see: https://www.shadertoy.com/view/NflXW7
vec3 hash33(vec3 x) {
  ivec3 xi = ivec3(floor(x));
  xi = ((xi>>8)^xi.yzx)*k;
  xi = ((xi>>8)^xi.yzx)*k;
  xi = ((xi>>8)^xi.yzx)*k;
  
  return vec3(xi)*(1.0/float(0x7fffffff));
}

vec2 hash32(vec3 x) {
  return hash33(x).xy;
}

vec3 vec2ToVec3(vec2 x) {
  vec2 longitude = vec2(sin(x.x * pi), cos(x.x * pi));
  float latMult = sqrt(1.0 - x.y * x.y);
  //latMult = 0.0;
  // if (!(latMult > -1.0)) latMult = 0.0;
  return normalize(vec3(longitude * latMult, x.y));
}

float perlin3d(vec3 pos) {
  vec3 p0 = floor(pos);
  vec3 p1 = p0 + vec3(1.0, 0.0, 0.0);
  vec3 p2 = p0 + vec3(0.0, 1.0, 0.0);
  vec3 p3 = p0 + vec3(1.0, 1.0, 0.0);
  vec3 p4 = p0 + vec3(0.0, 0.0, 1.0);
  vec3 p5 = p0 + vec3(1.0, 0.0, 1.0);
  vec3 p6 = p0 + vec3(0.0, 1.0, 1.0);
  vec3 p7 = p0 + vec3(1.0, 1.0, 1.0);
  vec3 s0 = vec2ToVec3(hash32(p0));
  vec3 s1 = vec2ToVec3(hash32(p1));
  vec3 s2 = vec2ToVec3(hash32(p2));
  vec3 s3 = vec2ToVec3(hash32(p3));
  vec3 s4 = vec2ToVec3(hash32(p4));
  vec3 s5 = vec2ToVec3(hash32(p5));
  vec3 s6 = vec2ToVec3(hash32(p6));
  vec3 s7 = vec2ToVec3(hash32(p7));
  vec3 o0 = pos - p0;
  vec3 o1 = pos - p1;
  vec3 o2 = pos - p2;
  vec3 o3 = pos - p3;
  vec3 o4 = pos - p4;
  vec3 o5 = pos - p5;
  vec3 o6 = pos - p6;
  vec3 o7 = pos - p7;
  float d0 = dot(s0, o0);
  float d1 = dot(s1, o1);
  float d2 = dot(s2, o2);
  float d3 = dot(s3, o3);
  float d4 = dot(s4, o4);
  float d5 = dot(s5, o5);
  float d6 = dot(s6, o6);
  float d7 = dot(s7, o7);
  return mix(
    mix(
      mix(d0, d1, serp(o0.x)),
      mix(d2, d3, serp(o0.x)),
      serp(o0.y)
    ),
    mix(
      mix(d4, d5, serp(o0.x)),
      mix(d6, d7, serp(o0.x)),
      serp(o0.y)
    ),
    serp(o0.z)
  );
}

vec3 cloud(vec3 pos) {
  return mix(
    vec3(1.0, 1.0, 1.0),
    vec3(0.9, 0.9, 0.9),
    abs(hash33(pos).x));
}

vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  return vec4(cloud(pos), perlin3d(pos / 32.0) * 2.0);
}