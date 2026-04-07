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
  running = !running;
  displays.paused.innerText = !running;
  if (running) {
    paused.style.display = "none";
  } else {
    paused.style.display = "block";
  }
}

function setPaused(pause = true) {
  let paused = document.getElementById("paused");
  running = !pause;
  displays.paused.innerText = !running;
  if (running) {
    paused.style.display = "none";
  } else {
    paused.style.display = "block";
  }
}

function setSlidersToValues() {
  let resModifier = document.getElementById("resModifier");
  let renderDist = document.getElementById("renderDist");
  let worldRes = document.getElementById("worldRes");
  let fov = document.getElementById("fov");
  let isoCam = document.getElementById("isoCam");
  let moveSpeed = document.getElementById("moveSpeed");
  let stereoscopy = document.getElementById("stereoscopy");
  let flipEyes = document.getElementById("flipEyes");
  let eyeDist = document.getElementById("eyeDist");
  
  resModifier.value = Math.log2(options.resModifier);
  renderDist.value = Math.log2(options.renderDist);
  worldRes.value = Math.log2(options.worldRes);
  fov.value = options.fov;
  isoCam.checked = options.isoCam;
  moveSpeed.value = Math.log2(options.moveSpeed);
  stereoscopy.checked = options.stereoscopy;
  flipEyes.checked = options.flipEyes;
  eyeDist.value = options.eyeDist;
  
  resModifier.oninput();
  renderDist.oninput();
  worldRes.oninput();
  fov.oninput();
  isoCam.onchange();
  moveSpeed.oninput();
  eyeDist.oninput();
}

function toggleElement(elemName) {
  let elem = document.getElementById(elemName);
  if (elem.style.display == "none")
    elem.style.display = "block";
  else
    elem.style.display = "none";
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
  } catch(err) {
    console.error(err);
  }
}

// code functions
function quickLoadCode() { // init
  let code = localStorage.getItem("VXEautosave");
  if (code == null) {
    code = fshaderSplit[1];
  }
  userCode.value = code;
  if (!localStorage.getItem("VXEediting")) localStorage.setItem("VXEediting", "unnamed");
  displays.currentFile.innerText = localStorage.getItem("VXEediting");
}

function quickSaveCode() {
  localStorage.setItem("VXEautosave", userCode.value);
}

const sysFiles = ["default", "list"]; 
let examples = [];

async function fetchExamples() {
  let exampleFile = await fetch("./examples/examples.txt", {cache: "no-store"}).then((response) => response.text());
  examples = exampleFile.split("\n");
}
fetchExamples();

async function loadCode() {
  keys = {};
  let loadedFileName = prompt("Enter name for program (type 'list' for list):");
  if (!loadedFileName) {
    return;
  }
  if (loadedFileName == "list") {
    let programs = getPrograms();
    alert(programs.join(" "));
    loadCode();
    return;
  } else if (loadedFileName == "_default") {
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    userCode.value = fshaderSplit[1];
  } else if (loadedFileName[0] == "_") {
    let code = await loadExample(loadedFileName);
    if (!code.ok) {
      alert("not found");
      return;
    }
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    userCode.value = code.code;
  } else if (sysFiles.includes(loadedFileName)) {
    alert("unavailable (you shouldn't be able to see this)");
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

async function loadExample(example) {
  let code = await fetch("./examples/" + example.slice(1) + ".glsl", {cache: "no-store"});
  if (!code.ok)
    return {ok: false, code: ""};
  code = await code.text();
  return {ok: true, code: code};
}

function saveCode() {
  quickSaveCode();
  let currentFile = localStorage.getItem("VXEediting");
  if (currentFile[0] == "_") {
    saveCodeAs(currentFile.slice(1));
    return;
  }
  if (!currentFile || sysFiles.includes(currentFile)) {
    saveCodeAs();
    return;
  }
  localStorage.setItem("VXEP" + currentFile, userCode.value);
}

function saveCodeAs(name) {
  keys = {};
  let loadedFileName;
  if (name) {
    loadedFileName = name;
  } else {
    loadedFileName = prompt("Enter name for program:");
  }
  let programs = getPrograms();
  if (!loadedFileName) {
    alert("must have name");
    return;
  }
  if (loadedFileName[0] == "_") {
    alert("reserved for examples!");
    return;
  }
  if (sysFiles.includes(loadedFileName)) {
    alert("name unavailable");
    return;
  }
  if (programs.includes(loadedFileName)) {
    if (!confirm("The program " + loadedFileName + " already exists, do you want to overwrite it?"))
      return;
  } else if (!confirm("Confirm saving " + loadedFileName)) {
    return;
  }
  localStorage.setItem("VXEediting", loadedFileName);
  displays.currentFile.innerText = localStorage.getItem("VXEediting");
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

function getPrograms() {
  programs = [];
  for (let key of Object.keys(localStorage)) {
    if (key.slice(0, 4) == "VXEP") {
      programs.push(key.slice(4));
    }
  }
  programs.push("_default");
  for (let example of examples) {
    programs.push("_" + example);
  }
  programs.sort();
  return programs;
}