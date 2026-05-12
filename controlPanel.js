function update(param, value) {
  param = param.id;
  options[param] = value;
  if (displays[param]) displays[param].innerText = value;
  saveOptions();
}

let displays = {};
let config;
let editing = "";
const userCode = document.getElementById("userCode");
let userCodeContext;

document.addEventListener("DOMContentLoaded", (e) => {
  config = document.getElementById("config");
  let alldisplays = document.getElementsByClassName("display");
  for (let display of alldisplays) {
    displays[display.attributes.ref.value] = display;
  }
  loadOptions();
  let settings = document.getElementsByClassName("setting");
  for (let setting of settings) {
    if (setting.oninput) setting.oninput();
    if (setting.onchange) setting.onchange();
  }
  if (CodeMirror) {
      userCodeContext = CodeMirror.fromTextArea(userCode, {
      lineNumbers: true, 
      theme: "transparent", 
      foldGutter: true, 
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"], 
      fixedGutter: false, 
      tabSize: 2,
      smartIndent: false,
      indentWithTabs: true, // high on that tab milk babyyyy
      extraKeys: {"Ctrl-/": "toggleComment"}
    });
    userCodeContext.on("focus", (e) => {
      textAreaFocused = true;
      keys = {};
    });
  }
});

function togglePannel() {
  if (config.style.display == "none") {
    config.style.display = "block";
  } else {
    config.style.display = "none";
  }
}

function fullscreenPannel() {
  if (config.style.width == Math.floor(window.innerWidth - 50) + "px") {
    config.style.width = "0px";
  } else {
    config.style.width = Math.floor(window.innerWidth - 50) + "px";
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
  let smooth = document.getElementById("smooth");
  let isoCam = document.getElementById("isoCam");
  let moveSpeed = document.getElementById("moveSpeed");
  let stereoscopy = document.getElementById("stereoscopy");
  let flipEyes = document.getElementById("flipEyes");
  let eyeDist = document.getElementById("eyeDist");
  let glitchVis = document.getElementById("glitchVis");
  
  resModifier.value = Math.log2(options.resModifier);
  renderDist.value = Math.log2(options.renderDist);
  worldRes.value = Math.log2(options.worldRes);
  fov.value = options.fov;
  smooth.checked = options.smooth;
  isoCam.checked = options.isoCam;
  moveSpeed.value = Math.log2(options.moveSpeed);
  stereoscopy.checked = options.stereoscopy;
  flipEyes.checked = options.flipEyes;
  eyeDist.value = options.eyeDist;
  glitchVis.checked = options.glitchVis;
  
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
    let savedOptions = JSON.parse(localStorage.getItem("VXEoptions"));
    if (savedOptions) {
      for (option in savedOptions) {
        options[option] = savedOptions[option];
      }
      options.glitchVis = false; // makes it fix on refresh
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
  if (userCodeContext)
    userCodeContext.setValue(code);
  else
    userCode.value = code;
  if (!localStorage.getItem("VXEediting")) localStorage.setItem("VXEediting", "_default");
  editing = localStorage.getItem("VXEediting")
  displays.currentFile.innerText = editing;
}

function quickSaveCode() {
  localStorage.setItem("VXEediting", editing);
  if (userCodeContext)
    localStorage.setItem("VXEautosave", userCodeContext.getValue());
  else
    localStorage.setItem("VXEautosave", userCode.value);
}

let examples = [];

async function fetchExamples() {
  let exampleFile = await fetch("./examples/examples.txt", {cache: "no-store"}).then((response) => response.text());
  examples = exampleFile.split("\n");
}
fetchExamples();

async function loadCode() {
  keys = {};
  let loadedFileName = prompt("Enter name for program (type \"_list\" for list):");
  if (!loadedFileName) {
    return;
  }
  if (loadedFileName == "_list") {
    let programs = getPrograms();
    alert(programs.join(" "));
    loadCode();
    return;
  } else if (loadedFileName == "_delete") {
    deleteCode(); 
    return;
  } else if (loadedFileName == "_default") {
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    if (userCodeContext)
      userCodeContext.setValue(fshaderSplit[1]);
    else
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
    if (userCodeContext)
      userCodeContext.setValue(code.code);
    else
      userCode.value = code.code;
  } else {
    let code = localStorage.getItem("VXEP" + loadedFileName);
    if (!code) {
      alert("not found");
      return;
    }
    if (!confirm("Are you sure you want to load? (unsaved progress will be lost)")) {
      return;
    }
    if (userCodeContext)
      userCodeContext.setValue(code);
    else
      userCode.value = code;
  }
  editing = loadedFileName;
  localStorage.setItem("VXEediting", editing);
  displays.currentFile.innerText = editing;
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
  let currentFile = editing;
  if (currentFile[0] == "_") {
    saveCodeAs(currentFile.slice(1));
    return;
  }
  if (!currentFile) {
    saveCodeAs();
    return;
  }
  if (userCodeContext)
    localStorage.setItem("VXEP" + currentFile, userCodeContext.getValue());
  else
    localStorage.setItem("VXEP" + currentFile, userCode.value);
}

function saveCodeAs(name) {
  keys = {};
  let savedFileName;
  if (name) {
    savedFileName = name;
  } else {
    savedFileName = prompt("Enter name for program:");
  }
  let programs = getPrograms();
  if (!savedFileName) {
    alert("must have name");
    return;
  }
  if (savedFileName == "_list") {
    let programs = getPrograms();
    alert(programs.join(" "));
    saveCodeAs();
    return;
  }
  if (savedFileName[0] == "_") {
    alert("reserved for examples!");
    return;
  }
  if (programs.includes(savedFileName)) {
    if (!confirm("The program " + savedFileName + " already exists, do you want to overwrite it?"))
      return;
  } else if (!confirm("Confirm saving " + savedFileName)) {
    return;
  }
  editing = savedFileName;
  localStorage.setItem("VXEediting", editing);
  displays.currentFile.innerText = editing;
  saveCode();
}

function deleteCode() {
  keys = {};
  let deletedFileName = prompt("Enter name of program to delete:");
  if (!deletedFileName) {
    alert("Deletion cancelled!");
    return;
  }
  if (deletedFileName == "_list") {
    let programs = getPrograms();
    alert(programs.join(" "));
    deleteCode();
    return;
  }
  if (deletedFileName[0] == "_") {
    alert("Cannot delete!");
    return;
  }
  if (localStorage.getItem("VXEP" + deletedFileName)) {
    let signature = prompt(`File "${deletedFileName}" will be deleted and unrecoverable. Type \"delete\" to confirm deletion.`);
    if (signature == "delete") {
      localStorage.removeItem("VXEP" + deletedFileName);
      alert(`File "${deletedFileName}" has been deleted.`);
      return;
    } else if (!signature) {
      alert("Deletion cancelled!");
      return;
    } else {
      alert(`Signature failed, expected "delete", got "${signature}"!`)
    }
  } else {
    alert("Cannot find file!");
    return;
  }
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
        editing = filename[0]
        localStorage.setItem("VXEediting", editing);
        displays.currentFile.innerText = editing;
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
  let filename = editing + ".glsl";
  localStorage.setItem("VXEediting", editing);
  let fileContent;
  if (userCodeContext)
    fileContent = userCodeContext.getValue();
  else
    fileContent = userCode.value;
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