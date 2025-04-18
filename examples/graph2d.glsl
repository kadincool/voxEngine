float f(float x) {
  return sin(x);
}

float g(float x) {
  return cos(x);
}

// tool functions
vec3 voxCol(vec3 pos) {
  return sin((pos * 10.0 + time) / 2.0) / 2.0 + 0.5;
}

vec3 graysc(vec3 col) {
  return vec3(dot(col, vec3(1.0)) / 3.0); // add all channels together and divide by 3
}

vec3 sat(vec3 col, float sat) {
  return mix(graysc(col), col, sat);
}

// main functions
vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  if (pos.z >= 16.0) return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, float(floor(pos.y) != 0.0), float(floor(pos.x) != 0.0), 1.0); // back wall
  vec2 scale = vec2(10.0, 10.0);
  if (abs(f(pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 4.0) return vec4(1.0, sin(pos.x / 4.0 - time) / 4.0 + 0.25, 0.0, 1.0);
  return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, 0.0, 1.0, abs(g(pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 4.0);
}