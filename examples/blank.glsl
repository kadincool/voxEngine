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
  return vec4(sat(voxCol(pos), 0.2), pos.y <= (sin(pos.x / 10.0) + sin(pos.z / 10.0)) * 10.0);
}