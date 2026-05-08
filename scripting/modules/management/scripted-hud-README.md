# Eclipse Management System — Scripted HUD Module

Módulo de HUD para Left 4 Dead 2 que muestra información del servidor en pantalla, con rotación dinámica de mensajes cargados desde base de datos.

---

## Características

- HUD persistente en pantalla para todos los jugadores (o por equipo)
- Rotación automática de mensajes desde base de datos (cada 10 segundos)
- Auto-recarga de mensajes desde DB cada 30 segundos sin reiniciar
- Parpadeo automático cuando hay un Tank vivo
- Mensajes por defecto si la DB no está disponible
- Comando admin para recargar mensajes en caliente
- Configuracion completa vía ConVars

---

## Requisitos

- SourceMod 1.10+
- Left 4 Dead 2
- MySQL o SQLite
- El módulo debe incluirse desde el plugin principal del EMS

---

## Base de datos

### Configuracion en `databases.cfg`

El módulo usa la entrada `DB_HUD_MESSAGES` definida en el plugin principal. Asegúrate de tener la sección correspondiente en `addons/sourcemod/configs/databases.cfg`:

```
"Databases"
{
    "hud_messages"
    {
        "driver"    "mysql"
        "host"      "localhost"
        "database"  "eclipse_ems"
        "user"      "tu_usuario"
        "pass"      "tu_contraseña"
        "port"      "3306"
    }
}
```

### Crear la tabla

```sql
CREATE TABLE IF NOT EXISTS server_hud_messages (
    id        INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    message   VARCHAR(128)     NOT NULL,
    is_active TINYINT(1)       NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);
```

### Insertar mensajes de ejemplo

```sql
INSERT INTO server_hud_messages (message, is_active) VALUES
('Welcome to Eclipse Server!', 1),
('Type !buy to access the shop', 1),
('Earn XP by killing zombies', 1),
('Level up to unlock bonuses', 1),
('Have fun playing!', 1);
```

### Desactivar un mensaje sin eliminarlo

```sql
UPDATE server_hud_messages SET is_active = 0 WHERE id = 3;
```

### Eliminar un mensaje

```sql
DELETE FROM server_hud_messages WHERE id = 3;
```

### Query usada por el plugin

```sql
SELECT message FROM server_hud_messages WHERE is_active = 1 ORDER BY id ASC;
```

---

## ConVars

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `ems_hud_enable` | `1` | Activa/desactiva el HUD |
| `ems_hud_update_interval` | `0.1` | Intervalo de actualización en segundos |
| `ems_hud1_text` | `""` | Texto fijo (vacío = automático desde DB) |
| `ems_hud1_text_align` | `1` | Alineación: 1=Izquierda, 2=Centro, 3=Derecha |
| `ems_hud1_blink_tank` | `1` | Parpadear cuando hay Tank vivo |
| `ems_hud1_blink` | `0` | Parpadeo constante |
| `ems_hud1_beep` | `0` | Sonido al parpadear |
| `ems_hud1_visible` | `1` | Visibilidad del HUD |
| `ems_hud1_background` | `0` | Mostrar fondo |
| `ems_hud1_team` | `0` | Equipo: 0=Todos, 1=Survivors, 2=Infected |
| `ems_hud1_x` | `0.02` | Posición X en pantalla |
| `ems_hud1_y` | `0.015` | Posición Y en pantalla |
| `ems_hud1_width` | `1.5` | Ancho del área de texto |
| `ems_hud1_height` | `0.026` | Alto del área de texto |

---

## Comandos

| Comando | Acceso | Descripción |
|---------|--------|-------------|
| `sm_reload_hud` | ROOT | Recarga mensajes desde la DB inmediatamente |

---

## Comportamiento

### Rotación de mensajes
Los mensajes rotan cada **10 segundos** en orden ascendente por `id`. El formato en pantalla es:

```
[hostname]  ☠  [mensaje actual]
```

### Auto-recarga
Cada **30 segundos** el plugin recarga automáticamente los mensajes desde la DB, permitiendo agregar o desactivar mensajes sin reiniciar el servidor ni ejecutar comandos.

### Fallback
Si la DB no está disponible o no hay mensajes activos, el plugin carga 5 mensajes por defecto hardcodeados para que el HUD nunca quede vacío.

### Tank vivo
Si `ems_hud1_blink_tank 1` está activo, el HUD parpadeará automáticamente mientras haya un Tank vivo en el juego.

---

## Integración

Este archivo es un módulo (`#include`) del Eclipse Management System. No es un plugin standalone. Se incluye desde el plugin principal:

```sourcepawn
#include "eclipse/scripted_hud_module"
```

Y se inicializa llamando en los forwards correspondientes:

```sourcepawn
public void OnPluginStart()    { ScriptedHUD_OnPluginStart(); }
public void OnConfigsExecuted(){ ScriptedHUD_OnConfigsExecuted(); }
public void OnMapStart()       { ScriptedHUD_OnMapStart(); }
public void OnMapEnd()         { ScriptedHUD_OnMapEnd(); }
```