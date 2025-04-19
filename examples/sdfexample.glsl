// SDFs
float SDFSphere(vec3 pos, float rad) {
  return length(pos) - rad;
}

float SDFCalc(vec3 pos) {
  // return SDFSphere(pos, 10.0);
  pos -= vec3(0.0, 0.0, 20.0);
  return max(-SDFSphere(pos - vec3(10.0, 0.0, 0.0) * sin(time) - vec3(0.0, 15.0, 0.0) * cos(time), 8.0), SDFSphere(pos, 10.0));
}

// trick to get normal
vec3 normal(vec3 pos) {
  float dist = SDFCalc(pos);
  vec2 small = vec2(0.01, 0);
  return normalize(vec3(
    dist-SDFCalc(pos-small.xyy),
    dist-SDFCalc(pos-small.yxy),
    dist-SDFCalc(pos-small.yyx)
  ));
}

// main functions
vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  return vec4(vec3(dot(normal(pos), normalize(vec3(1.0, 1.0, -1.0)))), SDFCalc(pos) < 0.0);
}