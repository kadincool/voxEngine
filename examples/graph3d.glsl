float f(vec2 pos) {
  return sin(pos.x)/cos(pos.y);
}

float g(vec2 pos) {
  return cos(length(pos));
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
  vec3 scale = vec3(16.0);
  // f(x)
  if (abs(f(pos.xz / scale.xz) * scale.y - pos.y) < 1.0) return vec4(voxCol(pos, vec3(0.0, 1.0, 0.0)) + vec3(1.0, 0.0, 0.0), 1.0);
  // g(x)
  if (abs(g(pos.xz / scale.xz) * scale.y - pos.y) < 1.0) return vec4(voxCol(pos, vec3(1.0, 0.0, 0.0)) + vec3(0.0, -1.0, 1.0), 1.0);
  //* colored axis (remove second slash before * to disable, improving perforrmance)
  if (abs(pos.y) < 0.1 && abs(pos.z) < 0.1) return vec4(voxCol(pos, vec3(1.0, 0.0, 0.0)), 1.0); // x axis
  if (abs(pos.x) < 0.1 && abs(pos.z) < 0.1) return vec4(voxCol(pos, vec3(0.0, 1.0, 0.0)), 1.0); // y axis
  if (abs(pos.x) < 0.1 && abs(pos.y) < 0.1) return vec4(voxCol(pos, vec3(0.0, 0.0, 1.0)), 1.0); // Z axis
  //*/
  // miss case
  return vec4(1.0, 1.0, 1.0, 0.0);
}