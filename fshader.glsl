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

uniform bool sbs3d;
uniform bool anaglyph3d;
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
    // TODO increase voxel size as travels
    
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
// TODO allow for partially transparent voxels that partially obscure view
      // return vec4(vec3(1.0 - tanh(traveled / float(renderDist) * 4.0)), 1.0);
    }
  }
  return vec4(vec3(0.0), 1.0);
}
// TODO add raycast for lighting

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

  return raycast(pos * worldRes, dir);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - sres) / sres.y;
  if (sbs3d) {
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
  } else if (anaglyph3d) {
    vec3 eyeDir = (camRot * vec4(eyeDist, vec3(0.0))).xyz;
    if (flipEyes) eyeDir *= -1.0;
    fcolor = color(uv, camPos + eyeDir) * vec4(0.0, 1.0, 1.0, 1.0);
    fcolor += color(uv, camPos - eyeDir) * vec4(1.0, 0.0, 0.0, 0.0);
  } else {
    fcolor = color(uv, camPos);
  }
}
