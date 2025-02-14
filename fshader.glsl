#version 300 es
// precision lowp float;
precision highp float;

#define maxRenderDist 8192

out vec4 fcolor;

uniform vec2 sres;
uniform float time;

uniform vec3 camPos;
uniform mat4 camRot;

uniform float renderDist;
uniform float worldRes;
uniform float fovMult;
uniform bool smoothed;
uniform bool isometric;

// user code
// snip
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
// snip
// end of user code

// boolean decides wether to round up or down
float ceilFloor(float number, bool toCeil) {
  return (toCeil ? ceil(number) : floor(number));
}

vec3 offToNext(vec3 pos, vec3 dir) {
  return vec3(
    (ceilFloor(pos.x + sign(dir.x), dir.x < 0.0) - pos.x),
    (ceilFloor(pos.y + sign(dir.y), dir.y < 0.0) - pos.y),
    (ceilFloor(pos.z + sign(dir.z), dir.z < 0.0) - pos.z)
  );
}

vec4 raycast(vec3 pos, vec3 dir) {
  mat3 slopes = mat3(
    dir / dir.x,
    dir / dir.y,
    dir / dir.z
  );
  vec3 stepDist = vec3(length(slopes[0]), length(slopes[1]), length(slopes[2]));
  float traveled = 0.0;

  for (int i = 0; i < 2 * maxRenderDist + 2; i++) {
    
    vec3 offsets = offToNext(pos, dir);
    vec3 dists = abs(offsets * stepDist);
    float distToTravel = 2.0;
    int travelAxis = -1;
    if (dir.x != 0.0 && dists.x < distToTravel) {
      distToTravel = dists.x;
      travelAxis = 0;
    }
    if (dir.y != 0.0 && dists.y < distToTravel) {
      distToTravel = dists.y;
      travelAxis = 1;

    }
    if (dir.z != 0.0 && dists.z < distToTravel) {
      distToTravel = dists.z;
      travelAxis = 2;
    }
    pos += dir * distToTravel;
    if (travelAxis == 0) {
      pos.x = round(pos.x);
    }
    if (travelAxis == 1) {
      pos.y = round(pos.y);
    }
    if (travelAxis == 2) {
      pos.z = round(pos.z);
    }
    traveled += distToTravel;
    
    if (traveled >= float(renderDist)) {
      return getSkybox(dir);
    }
    // smooth function or voxel function
    vec3 checkPos;
    if (smoothed) {
      checkPos = vec3(pos); // smooth
    } else {
      checkPos = vec3(
        ceilFloor(pos.x - float(dir.x < 0.0), dir.x < 0.0),
        ceilFloor(pos.y - float(dir.y < 0.0), dir.y < 0.0),
        ceilFloor(pos.z - float(dir.z < 0.0), dir.z < 0.0)
      ); // voxel // */
    }
    vec4 voxel = getVoxel(checkPos / worldRes);
    if (voxel.w == 1.0) {
      return vec4(vec3(1.0 - traveled / float(renderDist)) * voxel.xyz + getSkybox(dir).xyz * traveled / float(renderDist), 1.0);
      // return vec4(vec3(1.0 - tanh(traveled / float(renderDist) * 4.0)), 1.0);
    }
  }
  return vec4(vec3(0.0), 1.0);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - sres) / sres.y;
  // vec2 uv = (gl_FragCoord.xy * 2.0) / sres - 1.0;

  // perspective camera
  // vec3 pos = camPos;
  // vec3 dir = normalize(vec3(uv * fovMult, 1.0));
  // dir = normalize((camRot * vec4(dir, 1.0)).xyz);
  vec3 pos;
  vec3 dir;
  if (isometric) {
    // isometric camera
    pos = vec3(uv, 0.0) * fovMult * 100.0;
    pos = (camRot * vec4(pos, 0.0)).xyz;
    pos += camPos;
    dir = vec3(0.0, 0.0, 1.0);
    dir = normalize((camRot * vec4(dir, 1.0)).xyz);
  } else {
    // perspective camera
    pos = camPos;
    dir = normalize(vec3(uv * fovMult, 1.0));
    dir = normalize((camRot * vec4(dir, 1.0)).xyz);
  }

  fcolor = raycast(pos * worldRes, dir);
}