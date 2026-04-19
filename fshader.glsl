#version 300 es
// precision lowp float;
precision highp float;
precision highp int;

#define MAX_RENDER_DIST 8192

out vec4 fcolor;

uniform vec2 sres;
uniform float time;

uniform vec3 camPos;
uniform mat4 camRot;

uniform float renderDist;
uniform float worldRes;
uniform bool smoothed;
uniform float fovMult;
uniform bool isometric;

uniform bool stereoscopy;
uniform float eyeDist;
uniform bool flipEyes;

uniform bool glitchVis;

// user code
// snip
// for help with what you can do, look at https://registry.khronos.org/OpenGL-Refpages/es3.0/
vec4 getSkybox(vec3 dir) {
  return vec4(0.1, 0.1, 0.3, 1.0);
}

vec4 getVoxel(vec3 pos) {
  float value = -dot(cos(pos / 8.0), vec3(1)); // dot with 1 is the same as adding the axis (x, y, z) together
  return vec4(sin(pos / 2.0 + time / 5.0), value);
}
// snip
// end of user code

vec3 raycast(vec3 startPos, vec3 startDir) {
  vec3 rayPos = startPos;
  vec3 rayDir = normalize(startDir);
  
  vec4 fogColor = getSkybox(rayDir).xyzw;
  
  vec3 stepDist = vec3(
    length(rayDir / rayDir.x),
    length(rayDir / rayDir.y),
    length(rayDir / rayDir.z)
  );
  vec3 raySign = sign(rayDir);
  vec3 subPos = fract(rayPos * raySign);

  vec3 stepBack = vec3(equal(subPos, vec3(0.0))) * vec3(equal(raySign, vec3(-1.0)));
  vec3 worldPos = floor(rayPos) - stepBack;
  if (smoothed) worldPos = rayPos - subPos * raySign;
  rayDir *= raySign;
  float travelled = 0.0;
  vec4 rayColor = vec4(0.0);
  rayColor.w = 0.00001; // anti NaN for reasons I don't fully understand
  
  for (int i = 0; i < 3 * MAX_RENDER_DIST; i++) {
    vec3 rayPos = worldPos;
    if (smoothed) rayPos = worldPos + subPos * raySign;
    vec4 tileColor = clamp(getVoxel(rayPos / worldRes), 0.0, 1.0);
    
    vec3 distances = (1.0 - fract(subPos)) * stepDist;
    float nextStep = min(min(distances.x, distances.y), distances.z);
    
    if (tileColor.w != 0.0) {
      float newTint = 1.0 - pow(1.0 - tileColor.w, nextStep / worldRes);
      vec3 newColor = mix(tileColor.xyz, fogColor.xyz, travelled / renderDist * fogColor.w);
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
    if (glitchVis) subPos = round(subPos * 16.0) / 16.0;
    worldPos += floor(subPos) * raySign;
    subPos = fract(subPos);
    if (travelled >= renderDist) 
      return mix(fogColor.xyz, rayColor.xyz, rayColor.w);
    if (rayColor.w >= 0.998) {
      
      return rayColor.xyz;
    }
  }
  return mix(fogColor.xyz, rayColor.xyz, rayColor.w);
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
