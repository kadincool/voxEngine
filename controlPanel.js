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

function setPaused(pause = true) {
  let paused = document.getElementById("paused");
  let button = document.getElementById("pauseButton")
  running = !pause;
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
  setPaused();
  let resSlider = document.getElementById("resModifier");
  let distSlider = document.getElementById("renderDist");
  resSlider.value = resSlider.min;
  distSlider.value = distSlider.min;
  resSlider.oninput();
  distSlider.oninput();
}

function saveOptions() {
  localStorage.setItem("VXEoptions", JSON.stringify(options));
}

function loadOptions() {
  try {
    let savedOptions = JSON.parse(localStorage.getItem("VXEoptions"))
    if (savedOptions) {
      options = savedOptions;
      setSlidersToValues();
    }
    // setPaused(false);
  } catch(err) {
    console.error(err);
  }
  // resetPos();
  // resetRot();
}

function quickLoadCode() { // init
  let code = localStorage.getItem("VXEautosave");
  if (code == null) {
    code = fshaderSplit[1];
  }
  userCode.value = code;
  if (!localStorage.getItem("VXEediting")) localStorage.setItem("VXEediting", "unnamed")
  displays.currentFile.innerText = localStorage.getItem("VXEediting");
}

function quickSaveCode() {
  localStorage.setItem("VXEautosave", userCode.value);
}

const sysFiles = ["autosave", "options", "programs", "editing", "default", "list", "unnamed"]; //TODO remove sysfiles check because not able to interfere anymore
// TODO make example files to load from
let ownFiles = [];

function loadCode() {
  keys = {};
  let loadedFileName = prompt("Enter name for program:");
  if (!loadedFileName) {
    return;
  }
  if (loadedFileName == "list") {
    alert(localStorage.getItem("VXEprograms"));
    return;
  } else if (loadedFileName == "unnamed" || loadedFileName == "default") {
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    userCode.value = fshaderSplit[1];
  } else if (sysFiles.includes(loadedFileName)) {
    alert("unavailable");
    return;
  } else {
    let code = localStorage.getItem("VXEP" + loadedFileName);
    if (!code) {
      alert("not found");
      return;
    }
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    userCode.value = code;
  }
  localStorage.setItem("VXEediting", loadedFileName);
  displays.currentFile.innerText = localStorage.getItem("VXEediting");
  compileProgram();
}

function saveCode() {
  quickSaveCode();
  let currentFile = localStorage.getItem("VXEediting");
  if (sysFiles.includes(currentFile)) {
  // if (currentFile == "default") {
    saveCodeAs();
    return;
  }
  if (sysFiles.includes(currentFile)) {
    saveCodeAs();
    return;
  }
  localStorage.setItem("VXEP" + currentFile, userCode.value);
}

function saveCodeAs(name) {
  keys = {};
  let loadedFileName
  if (name) {
    loadedFileName = name;
  } else {
    loadedFileName = prompt("Enter name for program:");
  }
  let programs = JSON.parse(localStorage.getItem("VXEprograms"));
  if (programs == null) {
    programs = [];
    // TODO check for existing programs
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
  localStorage.setItem("VXEediting", loadedFileName);
  displays.currentFile.innerText = localStorage.getItem("VXEediting");
  programs.push(loadedFileName);
  localStorage.setItem("VXEprograms", JSON.stringify(programs));
  saveCode();
}

function importCode() {
  keys = {};
  let fileLoader = document.createElement("input");
  fileLoader.type = "file";
  fileLoader.onchange = function(event) {
    if (event.target.files.length > 0) {
      if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
        return;
      }
      let file = event.target.files[0];
      let filename = file.name.split(".");
      let reader = new FileReader();
      reader.readAsText(file);
      reader.onload = function(event) {
        userCode.value = event.target.result;
        localStorage.setItem("VXEediting", filename[0]);
        displays.currentFile.innerText = localStorage.getItem("VXEediting");
        saveCode();
        compileProgram();
      }
    } else {
      alert("load failed");
    }
  }
  fileLoader.click();
}

function exportCode() {
  keys = {};
  let filename = localStorage.getItem("VXEediting") + ".glsl";
  let fileContent = userCode.value;
  let file = new Blob([fileContent], {type: "text/plain"});
  saveBlob(file, filename);
}
