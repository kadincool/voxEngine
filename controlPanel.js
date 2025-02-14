function update(param, value) {
  param = param.id;
  options[param] = value;
  if (displays[param]) displays[param].innerText = value;
  if (running) saveOptions();
}

let displays = {};
let config;
const userCode = document.getElementById("userCode");

document.addEventListener("DOMContentLoaded", (e) => {
  config = document.getElementById("config");
  let alldisplays = document.getElementsByClassName("display");
  for (let display of alldisplays) {
    displays[display.attributes.ref.value] = display;
  }
  let settings = document.getElementsByClassName("setting");
  // // console.log(settings);
  for (let setting of settings) {
    // update(setting, setting.value);
    if (setting.oninput) setting.oninput();
    if (setting.onchange) setting.onchange();
  }
  loadOptions();
});

function togglePannel() {
  if (config.style.display == "none") {
    config.style.display = "block";
  } else {
    config.style.display = "none";
  }
}

function fullscreenPannel() {
  if (config.style.width == Math.floor(window.innerWidth - 50) + "px") { // && config.style.height == Math.floor(window.innerHeight - 50) + "px"
    config.style.width = "0px";
    // config.style.height = "0px";
  } else {
    config.style.width = Math.floor(window.innerWidth - 50) + "px";
    // config.style.height = Math.floor(window.innerHeight - 50) + "px";
  }
}

function togglePause() {
  let paused = document.getElementById("paused");
  let button = document.getElementById("pauseButton")
  running = !running;
  displays.paused.innerText = !running;
  if (running) {
    paused.style.display = "none";
    button.innerText = "pause";
  } else {
    paused.style.display = "block";
    button.innerText = "play";
  }
}

function setSlidersToValues() {
  let resModifier = document.getElementById("resModifier");
  let renderDist = document.getElementById("renderDist");
  let worldRes = document.getElementById("worldRes");
  let fov = document.getElementById("fov");
  let smooth = document.getElementById("smooth");
  let isoCam = document.getElementById("isoCam");
  let moveSpeed = document.getElementById("moveSpeed");
  resModifier.value = Math.log2(options.resModifier);
  renderDist.value = Math.log2(options.renderDist);
  worldRes.value = Math.log2(options.worldRes);
  fov.value = options.fov;
  smooth.checked = options.smooth;
  isoCam.checked = options.isoCam;
  moveSpeed.value = Math.log2(options.moveSpeed);
  resModifier.oninput();
  renderDist.oninput();
  worldRes.oninput();
  fov.oninput();
  // smooth.onchange();
  // isoCam.onchange();
  moveSpeed.oninput();
}

function panic() {
  running = true;
  togglePause();
  let resSlider = document.getElementById("resModifier");
  let distSlider = document.getElementById("renderDist");
  resSlider.value = resSlider.min;
  distSlider.value = distSlider.min;
  resSlider.oninput();
  distSlider.oninput();
}

function saveOptions() {
  localStorage.setItem("options", JSON.stringify(options));
}

function loadOptions() {
  try {
    let savedOptions = JSON.parse(localStorage.getItem("options"))
    if (savedOptions) {
      options = savedOptions;
      setSlidersToValues();
    }
  } catch(err) {
    console.error(err);
  }
  // resetPos();
  // resetRot();
}

function quickLoadCode() {
  let code = localStorage.getItem("autosave");
  if (code == null) {
    code = fshaderSplit[1];
  }
  userCode.value = code;
}

function quickSaveCode() {
  localStorage.setItem("autosave", userCode.value);
}

const sysFiles = ["autosave", "options", "programs", "editing", "default"]; //TODO: make all localStorage start with VXE

function loadCode() {
  keys = {};
  let loadedFileName = prompt("Enter name for program:");
  if (loadedFileName == "default") {
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    userCode.value = fshaderSplit[1];
  } else if (sysFiles.includes(loadedFileName)) {
    alert("unavailable");
    return;
  } else {
    let code = localStorage.getItem(loadedFileName);
    if (!code) {
      return;
    }
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    userCode.value = code;
  }
  localStorage.setItem("editing", loadedFileName);
}

function saveCode() {
  quickSaveCode();
  let currentFile = localStorage.getItem("editing");
  if (currentFile == "default") {
    saveCodeAs();
    return;
  }
  localStorage.setItem(currentFile, userCode.value);
}

function saveCodeAs() {
  keys = {};
  let loadedFileName = prompt("Enter name for program:");
  let programs = JSON.parse(localStorage.getItem("programs"));
  if (programs == null) {
    programs = [];
  }
  if (!loadedFileName || sysFiles.includes(loadedFileName)) {
    alert("name unavailable");
    return;
  }
  if (programs.includes(loadedFileName) && !confirm("The program " + loadedFileName + " already exists, do you want to overwrite it?")) {
    return;
  } else if (!confirm("Confirm saving " + loadedFileName)) {
    return;
  }
  localStorage.setItem("editing", loadedFileName);
  programs.push(loadedFileName);
  localStorage.setItem("programs", JSON.stringify(loadedFileName));

}
