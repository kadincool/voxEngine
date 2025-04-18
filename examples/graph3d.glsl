float f(vec2 pos) {
  return sin(pos.x) + sin(pos.y);
}

float g(vec2 pos) {
  return 1.0/sin(pos.x);
}

// tool functions
vec3 voxCol(vec3 pos) {
  return sin((pos / 4.0 + time) / 2.0) / 2.0 + 0.5;
}

// main functions
vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  // if (pos.z >= 32.0) return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, float(floor(pos.y) != 0.0), float(floor(pos.x) != 0.0), 1.0); // back wall
  vec3 scale = vec3(16.0);
  // f(x)
  if (abs(f(pos.xz / scale.xz) * scale.y - pos.y) < 1.0) return vec4(voxCol(pos), 1.0);
  // g(x)
  if (abs(g(pos.xz / scale.xz) * scale.y - pos.y) < 1.0) return vec4(voxCol(pos), 1.0);
  // miss case
  return vec4(1.0, 1.0, 1.0, 0.0);
}