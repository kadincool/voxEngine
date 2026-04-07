#version 300 es
// precision lowp float;
precision highp float;

#define MAX_RENDER_DIST 8192

out vec4 fcolor;

uniform vec2 sres;
uniform float time;

uniform vec3 camPos;
uniform mat4 camRot;

uniform float renderDist;
uniform float worldRes;
uniform float fovMult;
uniform bool isometric;

uniform bool stereoscopy;
uniform float eyeDist;
uniform bool flipEyes;

// user code
// snip
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
  return vec4(sat(voxCol(pos), 0.4), pos.y <= (sin(pos.x / 10.0) + sin(pos.z / 10.0)) * 10.0);
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

// vec4 raycast(vec3 pos, vec3 dir) {
//   mat3 slopes = mat3(
//     dir / dir.x,
//     dir / dir.y,
//     dir / dir.z
//   );
//   vec3 stepDist = vec3(length(slopes[0]), length(slopes[1]), length(slopes[2]));
//   float traveled = 0.0;
// 
//   for (int i = 0; i < 2 * maxRenderDist + 2; i++) {
//     
//     vec3 offsets = offToNext(pos, dir);
//     vec3 dists = abs(offsets * stepDist);
//     float distToTravel = 2.0;
//     int travelAxis = -1;
//     if (dir.x != 0.0 && dists.x < distToTravel) {
//       distToTravel = dists.x;
//       travelAxis = 0;
//     }
//     if (dir.y != 0.0 && dists.y < distToTravel) {
//       distToTravel = dists.y;
//       travelAxis = 1;
// 
//     }
//     if (dir.z != 0.0 && dists.z < distToTravel) {
//       distToTravel = dists.z;
//       travelAxis = 2;
//     }
//     pos += dir * distToTravel;
//     if (travelAxis == 0) {
//       pos.x = round(pos.x);
//     }
//     if (travelAxis == 1) {
//       pos.y = round(pos.y);
//     }
//     if (travelAxis == 2) {
//       pos.z = round(pos.z);
//     }
//     traveled += distToTravel;
//     // TODO increase voxel size as travels
//     
//     if (traveled >= float(renderDist)) {
//       return getSkybox(dir);
//     }
//     // smooth function or voxel function
//     vec3 checkPos;
// //     if (smoothed) {
// //       checkPos = vec3(pos); // smooth
// //     } else {
//     checkPos = vec3(
//       ceilFloor(pos.x - float(dir.x < 0.0), dir.x < 0.0),
//       ceilFloor(pos.y - float(dir.y < 0.0), dir.y < 0.0),
//       ceilFloor(pos.z - float(dir.z < 0.0), dir.z < 0.0)
//     ); // voxel // */
// //     }
//     vec4 voxel = getVoxel(checkPos / worldRes);
//     if (voxel.w == 1.0) {
//       return vec4(vec3(1.0 - traveled / float(renderDist)) * voxel.xyz + getSkybox(dir).xyz * traveled / float(renderDist), 1.0);
// // TODO allow for partially transparent voxels that partially obscure view
//       // return vec4(vec3(1.0 - tanh(traveled / float(renderDist) * 4.0)), 1.0);
//     }
//   }
//   return vec4(vec3(0.0), 1.0);
// }
// TODO add raycast for lighting

vec3 raycast(vec3 startPos, vec3 startDir) {
  vec3 rayPos = startPos;
  vec3 rayDir = normalize(startDir);
  
  vec3 fogColor = getSkybox(rayDir).xyz;
  
  vec3 stepDist = vec3(
    length(rayDir / rayDir.x),
    length(rayDir / rayDir.y),
    length(rayDir / rayDir.z)
  );
  
  vec3 raySign = sign(rayDir);
  vec3 subPos = fract(rayPos * raySign);
  vec3 stepBack = vec3(equal(subPos, vec3(0.0))) * vec3(equal(raySign, vec3(-1.0)));
  vec3 worldPos = floor(rayPos) - stepBack;
  rayDir *= raySign;
  float travelled = 0.0;
  vec4 rayColor = vec4(0.0);
  
  for (int i = 0; i < 3 * MAX_RENDER_DIST; i++) {
    vec4 tileColor = clamp(getVoxel(worldPos / worldRes), 0.0, 1.0);
    
    vec3 distances = (1.0 - fract(subPos)) * stepDist;
    float nextStep = min(min(distances.x, distances.y), distances.z);
    
    if (tileColor.w != 0.0) {
      float newTint = 1.0 - pow(1.0 - tileColor.w, nextStep);
      vec3 newColor = mix(tileColor.xyz, fogColor, travelled / renderDist);
      float addTint = newTint * (1.0 - rayColor.w);
      float totalTint = rayColor.w + addTint;
      rayColor.xyz = rayColor.xyz * (rayColor.w / totalTint) + newColor * (addTint / totalTint);
      rayColor.w += addTint;
      // TODO: if full tint (1.0), do shadow cast
    }
    
    subPos += rayDir * nextStep;
    travelled += nextStep;
    // snap to nearest 2^14th to remove floating point errors
    subPos = round(subPos * 16384.0) / 16384.0;
    worldPos += floor(subPos) * raySign;
    subPos = fract(subPos);
    if (travelled >= renderDist) 
      return mix(fogColor, rayColor.xyz, rayColor.w);
    if (rayColor.w >= 0.998) {
      
      return rayColor.xyz;
    }
  }
  return mix(fogColor, rayColor.xyz, rayColor.w);
}

vec4 color(vec2 uv, vec3 camPos) {
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

  return vec4(raycast(pos * worldRes, dir), 1.0);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - sres) / sres.y;
  if (stereoscopy) {
    vec3 pos;
    if (uv.x > 0.0) {
      pos -= (camRot * vec4(eyeDist, vec3(0.0))).xyz;
      uv.x -= 0.5;
    } else {
      pos += (camRot * vec4(eyeDist, vec3(0.0))).xyz;
      uv.x += 0.5;
    }
    if (flipEyes) pos *= -1.0;
    pos += camPos;
    fcolor = color(uv, pos);
//   } else if (anaglyph3d) {
//     vec3 eyeDir = (camRot * vec4(eyeDist, vec3(0.0))).xyz;
//     if (flipEyes) eyeDir *= -1.0;
//     fcolor = color(uv, camPos + eyeDir) * vec4(0.0, 1.0, 1.0, 1.0);
//     fcolor += color(uv, camPos - eyeDir) * vec4(1.0, 0.0, 0.0, 0.0);
  } else {
    fcolor = color(uv, camPos);
  }
}
