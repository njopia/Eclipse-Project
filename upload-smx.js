// ============================================================
//  upload-smx.js
//  Sube automaticamente el .smx al servidor cada vez que cambia
//  Uso: node upload-smx.js
// ============================================================

const SftpClient = require("ssh2-sftp-client");
const chokidar   = require("chokidar");
const path       = require("path");
const readline   = require("readline");

// --- CONFIGURACION ---
const config = {
  host:     "74.91.112.140",
  port:     22,
  username: "eclipse1",
};
const SMX_DIR     = path.join(__dirname, "scripting", "compiled");
const REMOTE_PATH = "/home/eclipse1/serverfiles/left4dead2/addons/sourcemod/plugins";
// ---------------------

function timestamp() {
  return new Date().toLocaleTimeString("es-CL", { hour12: false });
}

function askPassword() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    // Ocultar caracteres mientras escribe
    rl.input.on("keypress", () => {
      const len = rl.line.length;
      readline.moveCursor(rl.output, -len, 0);
      readline.clearLine(rl.output, 1);
      rl.output.write("*".repeat(len));
    });
    rl.question("Contraseña SFTP: ", (pass) => {
      rl.close();
      process.stdout.write("\n");
      resolve(pass);
    });
  });
}

async function upload(localFile) {
  const fileName   = path.basename(localFile);
  const remotePath = `${REMOTE_PATH}/${fileName}`;
  const sftp       = new SftpClient();

  try {
    await sftp.connect(config);
    await sftp.put(localFile, remotePath);
    console.log(`[${timestamp()}] ✔ ${fileName} subido correctamente.`);
  } catch (err) {
    console.error(`[${timestamp()}] ✘ Error al subir ${fileName}:`, err.message);
  } finally {
    await sftp.end();
  }
}

async function main() {
  config.password = await askPassword();

  console.log(`\nWatching: ${SMX_DIR}`);
  console.log(`Remote:   ${config.username}@${config.host}:${REMOTE_PATH}`);
  console.log("Esperando cambios en archivos .smx...\n");

  chokidar
    .watch(SMX_DIR, { ignoreInitial: true, awaitWriteFinish: { stabilityThreshold: 500 } })
    .on("add",    (f) => { if (f.endsWith(".smx")) { console.log(`[${timestamp()}] Detectado (nuevo): ${path.basename(f)}`);   upload(f); }})
    .on("change", (f) => { if (f.endsWith(".smx")) { console.log(`[${timestamp()}] Detectado (cambio): ${path.basename(f)}`); upload(f); }});
}

main();