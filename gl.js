const canvas = document.getElementById("glCanvas");
const gl = canvas.getContext("webgl2");

let corners = [
  -1, -1,
  -1, 1,
  1, -1,
  -1, 1,
  1, -1,
  1, 1
];

let lastTime = Date.now();
let timer = 0;

// shader variables
let vshaderSrc;
let fshaderSrc;
let fshader;
let vshader;
let program;
let posAttrib;
let sresUni;
let timeUni;
let posUni;
let rotUni;
let renderDistUni;
let worldResUni;
let fovMultUni;
let smoothedUni;
let isometricUni;
let posBuffer;
let vertArray;

let fshaderSplit;
// program variables
let camPos = {x: 0.0, y: 0.0, z: 0.0};
let camRot = {x: 0.0, y: 0.0, z: 0.0};
let keys = {};
let options = {
  moveSpeed: 4,
  rotSpeed: 60,
  resModifier: 2,
  renderDist: 128,
  worldRes: 1,
  mouseSen: 15,
  smooth: false,
  fov: 90,
  isoCam: false
};
let textAreaFocused = false;
let mouseHover = false;
let mouseLocked = false;
let running = false;
let autoMove = {
  forward: false,
  backward: false,
  left: false,
  right: false,
  up: false,
  down: false,
  speed: false
};
// let takeScreenshot = false;

async function fetchFiles() {
  // loadOptions();
  vshaderSrc = await fetch("./vshader.glsl").then((response) => response.text());
  fshaderSrc = await fetch("./fshader.glsl").then((response) => response.text());
  fshaderSplit = fshaderSrc.split(/\/\/ snip\r?\n/);
  quickLoadCode();
  // console.log(fshaderSplit);
  compileProgram();
  // running = true;
  setPaused(false);
} fetchFiles();

function compileProgram() {
  quickSaveCode();
  fshaderSrc = fshaderSplit[0] + userCode.value + fshaderSplit[2];
  makeShaderProgram();
  setPaused(false);
}

function makeShaderProgram() {
  let wasRunning = running;
  let errorList = document.getElementById("errorList");
  setPaused();
  
  if (vshader) gl.deleteShader(vshader);
  if (fshader) gl.deleteShader(fshader);
  if (program) gl.deleteProgram(program);
  errorList.innerHTML = "";

  // make shader program
  fshader = gl.createShader(gl.FRAGMENT_SHADER);
  gl.shaderSource(fshader, fshaderSrc);
  gl.compileShader(fshader);
  
  vshader = gl.createShader(gl.VERTEX_SHADER);
  gl.shaderSource(vshader, vshaderSrc);
  gl.compileShader(vshader);
  
  program = gl.createProgram();
  gl.attachShader(program, fshader);
  gl.attachShader(program, vshader);
  gl.linkProgram(program);
  
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.warn(gl.getShaderInfoLog(vshader));
    console.warn(gl.getShaderInfoLog(fshader));
    console.warn(gl.getProgramInfoLog(program));
    
    errorList.innerText = gl.getProgramInfoLog(program);
    throw new Error("program failed to compile");
  }
  
  // get attributes and uniforms
  posAttrib = gl.getAttribLocation(program, "vpos");
  sresUni = gl.getUniformLocation(program, "sres");
  timeUni = gl.getUniformLocation(program, "time");
  posUni = gl.getUniformLocation(program, "camPos");
  rotUni = gl.getUniformLocation(program, "camRot");
  fovMultUni = gl.getUniformLocation(program, "fovMult");
  renderDistUni = gl.getUniformLocation(program, "renderDist");
  worldResUni = gl.getUniformLocation(program, "worldRes");
  smoothedUni = gl.getUniformLocation(program, "smoothed");
  isometricUni = gl.getUniformLocation(program, "isometric");
  
  //buffer vertices
  posBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, posBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(corners), gl.STATIC_DRAW);
  
  vertArray = gl.createVertexArray();
  gl.bindVertexArray(vertArray);
  gl.enableVertexAttribArray(posAttrib);
  gl.vertexAttribPointer(posAttrib, 2, gl.FLOAT, false, 0, 0);
  
  // running = wasRunning;
  setPaused(!wasRunning);
}

// /./
// gl.uniform2f(sresUni, canvas.width, canvas.height);

function clamp(x, min, max) {
  return Math.min(Math.max(x, min), max);
}

function render(takeScreenshot = false) {
  // let startTime = performance.now();
  gl.viewport(0, 0, canvas.width, canvas.height);
  
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);
  gl.useProgram(program);

  let rotMat = new DOMMatrix();
  rotMat.rotateSelf(camRot.x, camRot.y, camRot.z);

  gl.uniform2f(sresUni, canvas.width, canvas.height);
  gl.uniform3f(posUni, camPos.x, camPos.y, camPos.z);
  gl.uniformMatrix4fv(rotUni, false, rotMat.toFloat32Array());
  gl.uniform1f(timeUni, timer / 1000);
  gl.uniform1f(renderDistUni, options.renderDist);
  gl.uniform1f(worldResUni, options.worldRes);
  gl.uniform1f(fovMultUni, Math.tan(options.fov / 360 * Math.PI));
  gl.uniform1i(smoothedUni, options.smooth);
  gl.uniform1i(isometricUni, options.isoCam);

  gl.bindVertexArray(vertArray);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
  
  if (takeScreenshot) {
    canvas.toBlob((blob) => saveBlob(blob, "VOXENGINE" + Date.now()));
  } 
  
  // requestAnimationFrame((end) => {console.log(Math.round(end - startTime))});
}

function frame() {
  let delta = Date.now() - lastTime;
  lastTime += delta;
  if (running) {
    timer += delta;
    delta /= 1000;

    //movement
    let rotMat = new DOMMatrix();
    // rotMat.rotateSelf(camRot.x, camRot.y, camRot.z);
    // rotMat.rotateSelf(camRot.x, 0.0, 0.0);
    rotMat.rotateSelf(0.0, camRot.y, 0.0);
    // rotMat.rotateSelf(0.0, 0.0, camRot.z);

    // if (keys.Space) console.log(rotMat);
    let moveSpeed = options.moveSpeed * (keys.ShiftLeft || autoMove.speed ? 4 : 1); 
    let rotSpeed = options.rotSpeed * (keys.ShiftLeft ? 3 : 1); 

    if (keys.KeyW || autoMove.forward) {
      camPos.x += delta * moveSpeed * rotMat.m31;
      camPos.y += delta * moveSpeed * rotMat.m32;
      camPos.z += delta * moveSpeed * rotMat.m33;
    }
    if (keys.KeyS || autoMove.backward) {
      camPos.x -= delta * moveSpeed * rotMat.m31;
      camPos.y -= delta * moveSpeed * rotMat.m32;
      camPos.z -= delta * moveSpeed * rotMat.m33;
    }
    if (keys.KeyA || autoMove.left) {
      camPos.x -= delta * moveSpeed * rotMat.m11;
      camPos.y -= delta * moveSpeed * rotMat.m12;
      camPos.z -= delta * moveSpeed * rotMat.m13;
    }
    if (keys.KeyD || autoMove.right) {
      camPos.x += delta * moveSpeed * rotMat.m11;
      camPos.y += delta * moveSpeed * rotMat.m12;
      camPos.z += delta * moveSpeed * rotMat.m13;
    }
    if (keys.KeyE || autoMove.up) {
      camPos.y += delta * moveSpeed;
    }
    if (keys.KeyQ || autoMove.down) {
      camPos.y -= delta * moveSpeed;
    }

    displays.posX.innerText = Math.floor(camPos.x * 1000) / 1000;
    displays.posY.innerText = Math.floor(camPos.y * 1000) / 1000;
    displays.posZ.innerText = Math.floor(camPos.z * 1000) / 1000;
    displays.rotX.innerText = Math.floor(camRot.x * 1000) / 1000;
    displays.rotY.innerText = Math.floor(camRot.y * 1000) / 1000;
    displays.rotZ.innerText = Math.floor(camRot.z * 1000) / 1000;

    if (keys.ArrowLeft) camRot.y -= delta * rotSpeed;
    if (keys.ArrowRight) camRot.y += delta * rotSpeed;
    if (keys.ArrowUp) camRot.x -= delta * rotSpeed;
    if (keys.ArrowDown) camRot.x += delta * rotSpeed;
    
    camRot.x = clamp(camRot.x, -90, 90);
    // camRot.y = camRot.y % 360;
    camRot.y %= 360;

    if (canvas.width != window.innerWidth * options.resModifier) canvas.width = window.innerWidth * options.resModifier;
    if (canvas.height != window.innerHeight * options.resModifier) canvas.height = window.innerHeight * options.resModifier;
    render();
  }

  requestAnimationFrame(frame);
}
frame();

function resetPos() {
  camPos.x = 0;
  camPos.y = 0;
  camPos.z = 0;
  displays.posX.innerText = Math.floor(camPos.x * 1000) / 1000;
  displays.posY.innerText = Math.floor(camPos.y * 1000) / 1000;
  displays.posZ.innerText = Math.floor(camPos.z * 1000) / 1000;
}

function setPos() {
  keys = {};
  camPos.x = Number(prompt("Position X:") || camPos.x);
  camPos.y = Number(prompt("Position Y:") || camPos.y);
  camPos.z = Number(prompt("Position Z:") || camPos.z);
  displays.posX.innerText = Math.floor(camPos.x * 1000) / 1000;
  displays.posY.innerText = Math.floor(camPos.y * 1000) / 1000;
  displays.posZ.innerText = Math.floor(camPos.z * 1000) / 1000;
}

function resetRot() {
  camRot.x = 0;
  camRot.y = 0;
  camRot.z = 0;
  if (options.isoCam) {
    camRot.x = 45;
    camRot.y = 45;
  }
  displays.rotX.innerText = Math.floor(camRot.x * 1000) / 1000;
  displays.rotY.innerText = Math.floor(camRot.y * 1000) / 1000;
  displays.rotZ.innerText = Math.floor(camRot.z * 1000) / 1000;
}

function setRot() {
  keys = {};
  camRot.x = Number(prompt("Rotation X:") || camRot.x);
  camRot.y = Number(prompt("Rotation Y:") || camRot.y);
  camRot.z = Number(prompt("Rotation Z:") || camRot.z);
  displays.rotX.innerText = Math.floor(camRot.x * 1000) / 1000;
  displays.rotY.innerText = Math.floor(camRot.y * 1000) / 1000;
  displays.rotZ.innerText = Math.floor(camRot.z * 1000) / 1000;
}

function gridSnap() {
  camPos.x = Math.round(camPos.x);
  camPos.y = Math.round(camPos.y);
  camPos.z = Math.round(camPos.z);
  camRot.x = Math.round(camRot.x / 15.0) * 15.0;
  camRot.y = Math.round(camRot.y / 15.0) * 15.0;
  camRot.z = Math.round(camRot.z / 15.0) * 15.0;
  displays.posX.innerText = Math.floor(camPos.x * 1000) / 1000;
  displays.posY.innerText = Math.floor(camPos.y * 1000) / 1000;
  displays.posZ.innerText = Math.floor(camPos.z * 1000) / 1000;
  displays.rotX.innerText = Math.floor(camRot.x * 1000) / 1000;
  displays.rotY.innerText = Math.floor(camRot.y * 1000) / 1000;
  displays.rotZ.innerText = Math.floor(camRot.z * 1000) / 1000;
}

function takeScreenshot() {
  if (canvas.width != 1920 * options.resModifier) canvas.width = 1920 * options.resModifier;
  if (canvas.height != 1080 * options.resModifier) canvas.height = 1080 * options.resModifier;
  render(true);
}

async function saveBlob(blob, name) {
  let link = document.createElement("a");
  let objectUrl = URL.createObjectURL(blob);
  link.href = objectUrl;
  link.download = name;
  
  document.body.appendChild(link);
  link.click();

  URL.revokeObjectURL(objectUrl);
  document.body.removeChild(link);
}

document.addEventListener("keydown", (e) => {
  if (mouseHover) keys[e.code] = true;
  if (e.code == "KeyO" && e.ctrlKey) {
    e.preventDefault();
    panic();
  }
  if (e.code == "KeyR" && e.ctrlKey) {
    e.preventDefault();
    compileProgram();
  }
  if (e.code == "Space") {
    if (mouseHover) {
      togglePannel();
    }
  }
  if (e.code == "KeyP" && mouseHover) {
    togglePause();
  }
});
document.addEventListener("keyup", (e) => {if (mouseHover) keys[e.code] = false;});

canvas.addEventListener("mousedown", (e) => {
  canvas.requestPointerLock();
});
canvas.addEventListener("mouseenter", (e) => {
  mouseHover = true;
  document.getElementById("doNothing").focus();
  textAreaFocused = false;
  // canvas.focus();
});
canvas.addEventListener("mouseleave", (e) => {mouseHover = false; keys = {};});
document.addEventListener("pointerlockchange", (e) => {
  mouseLocked = Boolean(document.pointerLockElement);
  if (mouseLocked) mouseHover = true;
  // if (!mouseLocked) keys = {};
});
document.addEventListener("mousemove", (e) => {
  if (mouseLocked && running) {
    camRot.y += e.movementX * options.mouseSen / 100;
    camRot.x += e.movementY * options.mouseSen / 100;
  }
});
userCode.addEventListener("focus", (e) => {
  textAreaFocused = true;
  keys = {};
});
