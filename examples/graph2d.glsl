float f(float x) {
  return sin(x);
}

// derivative of f
float df(float x) {
  return cos(x);
}

float g(float x) {
  return 1.0/sin(x);
}

float tlan(float n, float x) { // tangent line at n
  return df(n) * x + f(n) - df(n) * n;
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
  if (pos.z >= 32.0) return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, float(floor(pos.y) != 0.0), float(floor(pos.x) != 0.0), 1.0); // back wall
  vec2 scale = vec2(16.0, 16.0);
  // f(x)
  if (abs(f(pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 16.0) return vec4(1.0, lum(pos), 0.0, 1.0);
  // dy/dx f(x)
  // if (abs(df(pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 16.0) return vec4(0.0, lum(pos), 0.0, 1.0);
  // tangent line
  if (abs(tlan(camPos.x / scale.x, pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 20.0) return vec4(0.0, 1.0, lum(pos), 1.0);
  // g(x)
  // if (abs(g(pos.x / scale.x) * scale.y - pos.y) < 1.0 && pos.z >= 16.0) return vec4(lum(pos), 0.0, 1.0, 1.0);
  // miss case
  return vec4(1.0, 1.0, 1.0, 0.0);
}