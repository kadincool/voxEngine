float sdfcircle(vec2 pos, vec2 circPos, float radius) {
  return distance(pos, circPos) - radius;
}

float spatialHash(vec4 pos) {
  vec4 dirHash = sin(pos) * vec4(17317.0, 37663.0, 59233.0, 81689.0);
  return fract(sin(dirHash.x + dirHash.y + dirHash.z + dirHash.w) * 104659.0);
}

vec4 getSkybox(vec3 dir) {
  return vec4(0.125, 0.0625, 0.25, 1.0);
  // return vec4(-abs(dir), 1.0);
  // return vec4(0.0, 0.0, 0.0, 1.0);
}


vec3 noise(vec3 pos, vec3 baseColor, float weight) {
  return baseColor * (1.0 - weight) + vec3(spatialHash(vec4(pos, 5.0)), spatialHash(vec4(pos, 6.0)), spatialHash(vec4(pos, 7.0))) * weight;
}

vec3 gsNoise(vec3 pos, vec3 baseColor, float weight) {
  return baseColor * (1.0 - weight) + vec3(spatialHash(vec4(pos, 5.0))) * weight;
}

vec4 getVoxel(vec3 pos) { // TODO: optimise bounding boxes
  // if (pos.x > 20.0) return vec4(gsNoise(pos, vec3(1.0), 0.1), length(pos.xy + vec2(sin(pos.z / 10.0) + 40.0, cos(pos.z / 10.0)) * 10.0) > 16.0);
  if (pos.x > 200.0) return vec4(gsNoise(pos, vec3(1.0), 0.1), length(pos.xy + vec2(-400.0, 0.0) + vec2(sin(pos.z / 50.0), cos(pos.z / 50.0)) * 50.0) > 64.0);
  if (pos.x >= 0.0 && abs(pos.y - sin(pos.z / 4.0) * 4.0) < 1.0) return vec4(sin(pos.z / 4.0 + time) / 2.0 + 0.5, 0.0, 0.0, 1.0); // sine graph
  if (pos.x >= 16.0) return vec4(sin(pos.z / 4.0 + time) / 2.0 + 0.5, float(floor(pos.y) != 0.0), float(floor(pos.z) != 0.0), 1.0); // back wall
  // if (pos.x >= 0.0 && abs(pos.y - 1.0 / sin(pos.z / 4.0) * 4.0) < 1.0 / worldRes) return vec4(sin(pos.z / 4.0 + time) / 2.0 + 0.5, 0.0, 0.0, 1.0); // cosecant graph
  // if (abs(pos.y - (1.0 / sin(pos.z / 4.0)) * (1.0 / sin(pos.x / 4.0)) * 4.0) < 1.0) return vec4(sin(pos.z / 4.0 + time) / 2.0 + 0.5, 0.0, 0.0, 1.0); // 3d cosecant
  
  if (pos.x >= -100.0) return vec4(1.0, 1.0, 1.0, 0.0); //keep space for graph

  if (pos.x < -100.0 && length(pos.zy) > 16.0 && length(pos.zy) < 18.0) return vec4(sin(pos.x / 4.0 - time) / 2.0 + 0.5, 1.0, 1.0, 1.0); // striped tunnel
  
  // cosecant lantern festival
  if (pos.x < -1000.0 && pos.y > 40.0 && pos.y < 140.0 && abs(pos.y - ((1.0 / sin(pos.z / 4.0)) * (1.0 / sin(pos.x / 4.0)) * 4.0) + sin(pos.x / 20.0 + time / 10.0) * 4.0) < 1.0) return vec4(vec3(1.0, 0.33, 0.0) * (sin((pos.x + pos.z) / 4.0 + time) / 2.0 + 0.5), 1.0);
  
  // random snow
  if (pos.x > -1000.0 && spatialHash(vec4(pos, 77.0)) > 0.99) return vec4(noise(pos, vec3(1.0), 0.25), 1.0);
  

  // if (ceil(pos.y) < -16.0) return vec4(spatialHash(vec4(ceil(pos), 0.0 + floor(time))), spatialHash(vec4(ceil(pos), 0.1 + floor(time))), spatialHash(vec4(ceil(pos), 0.2 + floor(time))), 1.0); // disco floor
  if (pos.y < 8.0 && floor(pos.y) < -16.0 + spatialHash(vec4(pos.xz, 0.0, 0.0 + floor(time))) * 8.0) return vec4(spatialHash(vec4(pos, 0.1 + floor(time))), spatialHash(vec4(pos, 0.2 + floor(time))), spatialHash(vec4(pos, 0.3 + floor(time))), 1.0); // spikey disco floor
  
  // if (pos.y < sin(pos.z / 4.0) * 3.0 - 5.0) return vec4(0.5 + sin(pos.z / 4.0 + time) / 2.0, 0.0, 0.0, 1.0); // floor sine wave

  // return vec4(1.0, 1.0, 1.0, 1.0);
  // return 1.0, 1.0, 1.0, length(pos.xy) > 16.0;
  return vec4(1.0, 1.0, 1.0, 0.0); // alpha of 0 makes it not hit
}
