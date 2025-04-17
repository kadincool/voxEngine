vec3 voxCol(vec3 pos) {
  return vec3(dot(sin((pos * 10.0 + time) / 2.0) / 2.0 + 0.5, vec3(1)) / 3.0);
  return vec3(sin((pos * 10.0 + time) / 2.0) / 2.0 + 0.5);
  return vec3((sin((pos.x + time) / 2.0) + sin((pos.y + time) / 2.0) + sin((pos.z + time) / 2.0)) / 6.0 + 0.5);
  return vec3((sin((pos.x + time) / 2.0) / 2.0 + 0.5 + sin((pos.y + time) / 2.0) / 2.0 + 0.5 + sin((pos.z + time) / 2.0) / 2.0 + 0.5) / 3.0);
  return vec3(sin((pos.x + time) / 2.0) / 2.0 + 0.5, sin((pos.y + time) / 2.0) / 2.0 + 0.5, sin((pos.z + time) / 2.0) / 2.0 + 0.5);
  return vec3(sin(pos.x * 3.0 + pos.y * 5.0 + pos.z * 7.0) / 2.0 + 0.5);
  return vec3(mod((pos.x * 0.4 + pos.y * 0.5 + pos.z * 0.6), 1.0));
  return vec3(mod(pos.x / 4.0, 1.0), mod(pos.y / 4.0, 1.0), mod(pos.z / 4.0, 1.0));
  return vec3(mod((pos.x + pos.y + pos.z) / 4.0, 1.0));
}

vec4 getSkybox(vec3 dir) {
  return vec4(0, 0, 0, 1.0);
}

vec4 getVoxel(vec3 pos) {
  return vec4(voxCol(pos), pos.y <= sin(pos.x / 10.0) * 10.0);
  return vec4(sin(pos.x / 4.0 + time) / 2.0 + 0.5, sin(pos.y / 4.0 + time) / 2.0 + 0.5, sin(pos.z / 4.0 + time) / 2.0 + 0.5, pos.y <= sin(pos.x / 10.0) * 10.0);
  return vec4(1.0, 1.0, 1.0, 0.0); // alpha of 0 makes it not hit
}