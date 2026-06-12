# Auto Upload SMX

Sube automáticamente el `.smx` compilado al servidor cada vez que cambia, sin configuración de SSH keys ni credenciales hardcodeadas.

## Requisitos

- [Node.js](https://nodejs.org/) v18+

## Setup (primera vez)

```bash
npm install
```

## Uso

```bash
node upload-smx.js
```

Al arrancar pedirá la contraseña SFTP **una sola vez**. Mientras la terminal esté abierta, cada compilación sube el `.smx` automáticamente.

Para detenerlo: `Ctrl+C`

## Cómo funciona

1. Monitorea la carpeta `scripting/compiled/` en busca de cambios en archivos `.smx`
2. Al detectar uno nuevo o modificado, lo sube por SFTP a `plugins/` en el servidor
3. La contraseña vive solo en memoria — nunca se escribe en disco

## Configuración

Si el servidor o las credenciales cambian, edita la sección `CONFIGURACION` al inicio de `upload-smx.js`:

```js
const config = {
  host:     "FTP IP ADDRESS", //string
  port:     PORT, //integer
  username: "username", //sftp - ftp user account string
};
const REMOTE_PATH = "SFTP - FTP REMOTE PATH TO PLUGIN"; //Example: "/home/.../left4dead2/addons/sourcemod/plugins"
```

## Notas

- `node_modules/` está en `.gitignore` — no se versiona
- La contraseña **nunca** se guarda en el repo
- Probado en Windows con Node v24