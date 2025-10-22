# Shoulder Cannon - Guía de Debug

## 🔧 Compilación

```bash
cd "c:\Users\Socius\Desktop\sm\Eclipse-Project"
./compile_shoulder_cannon.bat
```

O manualmente:
```bash
"c:\Users\Socius\Desktop\sourcemod\addons\sourcemod\scripting\spcomp.exe" shoulder_cannon.sp -o"scripting/compiled/shoulder_cannon.smx"
```

## 📦 Instalación

1. **Copiar el plugin compilado:**
   ```
   scripting/compiled/shoulder_cannon.smx → [servidor]/addons/sourcemod/plugins/
   ```

2. **Copiar la configuración de debug (opcional):**
   ```
   shoulder_cannon_debug.cfg → [servidor]/cfg/
   ```

3. **Reiniciar el servidor o recargar el plugin:**
   ```
   sm plugins reload shoulder_cannon
   ```

## 🐛 Modo Debug

### Activar Debug Mode

En la consola del servidor:
```
sc_debug 1
exec shoulder_cannon_debug.cfg
```

### Desactivar Debug Mode

```
sc_debug 0
```

### Ver Logs en Tiempo Real

Los logs se escriben en:
```
[servidor]/logs/L[fecha].log
```

Todos los mensajes de debug tienen el prefijo `[SC_DEBUG]`

## 📊 Logs de Debug Disponibles

### 1. Comandos de Chat
```
[SC_DEBUG] Command_Say from client X: !sc
[SC_DEBUG] Command !sc or /sc detected from client X
[SC_DEBUG] Client X is on team 2 (survivors), opening menu
```

### 2. Creación del Menú
```
[SC_DEBUG] ShoulderCannonMenuFunc called for client X
[SC_DEBUG] Creating menu - HasCannon: 0, Ammo: 500
[SC_DEBUG] Menu title set
[SC_DEBUG] Displaying menu to client X
```

### 3. Equipamiento del Cañón
```
[SC_DEBUG] EquipShoulderCannon called for client X
[SC_DEBUG] Client X passed validation checks
[SC_DEBUG] Client X doesn't have cannon, creating new one
[SC_DEBUG] CreateEntityByName returned: XXX
[SC_DEBUG] Entity XXX is valid, setting up...
[SC_DEBUG] Model set to: models/w_models/weapons/w_m60.mdl
[SC_DEBUG] Entity XXX spawned
[SC_DEBUG] Entity XXX parented to client X
[SC_DEBUG] Parent attachment set to 'eyes'
[SC_DEBUG] Collision/shadow disabled, scale set to 0.43
[SC_DEBUG] Entity XXX teleported to offset position
[SC_DEBUG] RunRepeater started for client X with entity XXX
[SC_DEBUG] SDKHook_SetTransmit hooked
```

### 4. Sistema de Disparo (CannonRepeater)
```
[SC_DEBUG] CannonRepeater: round=X, client=X, cannon=XXX, iRound=X
[SC_DEBUG] CannonRepeater: Client X is valid and alive
[SC_DEBUG] CannonRepeater: Cannon entity XXX is valid
[SC_DEBUG] CannonRepeater: Entity classname: prop_dynamic
[SC_DEBUG] CannonRepeater: Model name: models/w_models/weapons/w_m60.mdl
[SC_DEBUG] CannonRepeater: CannonOn=0, Incap=0, Held=0
[SC_DEBUG] CannonRepeater: Searching for targets - Ammo: 500
```

### 5. Búsqueda de Objetivos
```
[SC_DEBUG] Found X common infected
[SC_DEBUG] Found X witches
[SC_DEBUG] Found X specials, X tanks
[SC_DEBUG] Target selection - zombie:XXX special:0 witch:0 tank:0, priority:0
```

### 6. Disparo a Objetivo
```
[SC_DEBUG] DestroyTarget called - client:X, target:XXX, type:2
[SC_DEBUG] Cannon XXX is valid, firing at target XXX
[SC_DEBUG] Effects created, dealing damage...
[SC_DEBUG] Dealing entity damage to target XXX
[SC_DEBUG] DestroyTarget completed for target XXX
```

### 7. Sin Objetivos
```
[SC_DEBUG] No targets found, continuing loop...
```

## ❌ Errores Comunes y Sus Logs

### Error: El menú no se abre
**Log esperado:**
```
[SC_DEBUG] Command_Say from client X: !sc
[SC_DEBUG] Command !sc or /sc detected from client X
```

**Si no aparece:** El comando no está siendo capturado. Verificar que el plugin está cargado.

### Error: El cañón no aparece visualmente
**Log esperado:**
```
[SC_DEBUG] Entity XXX is valid, setting up...
[SC_DEBUG] Model set to: models/w_models/weapons/w_m60.mdl
```

**Posibles causas:**
- Modelo no precacheado
- Problema con el attachment point "eyes"
- Entidad no válida

### Error: El cañón no dispara
**Logs a revisar:**
```
[SC_DEBUG] CannonRepeater: CannonOn=0, Incap=0, Held=0
[SC_DEBUG] CannonRepeater: Searching for targets - Ammo: 500
[SC_DEBUG] Found X common infected
```

**Si ammo = 0:**
```
[SC_DEBUG] Out of ammo!
```

**Si no hay objetivos:**
```
[SC_DEBUG] No targets found, continuing loop...
```

**Si está deshabilitado:**
```
[SC_DEBUG] Cannon disabled or player incap/held, looping...
```

### Error: Entidad inválida
```
[SC_DEBUG] ERROR: Failed to create valid entity for client X
[SC_DEBUG] ERROR: Cannon XXX is invalid or not found!
```

### Error: Validación de cliente falla
```
[SC_DEBUG] Client X failed validation - InGame: X, IsBot: X, Alive: X, Team: X
```

## 🧪 Comandos de Prueba

### En el juego:
```
!sc          - Abrir menú
/sc          - Abrir menú (alternativo)
sm_sc        - Abrir menú (comando admin)
```

### En consola del servidor:
```
sm plugins list                    - Ver plugins cargados
sm plugins info shoulder_cannon    - Info del plugin
sm plugins reload shoulder_cannon  - Recargar plugin
sm plugins unload shoulder_cannon  - Descargar plugin
sc_debug 1                         - Activar debug
sc_debug 0                         - Desactivar debug
```

## 📝 Checklist de Debug

Cuando reportes un problema, incluye esta información:

- [ ] ¿El plugin está cargado? (`sm plugins list`)
- [ ] ¿sc_debug está en 1?
- [ ] ¿Qué comando usaste? (!sc, /sc, sm_sc)
- [ ] ¿Qué equipo? (Survivors = 2, Infected = 3)
- [ ] ¿Estás vivo?
- [ ] ¿Aparece el menú?
- [ ] ¿Se crea el cañón?
- [ ] ¿Hay enemigos cerca?
- [ ] Copia los últimos 50-100 logs con `[SC_DEBUG]`

## 🔍 Filtrar Logs

Para ver solo los logs de Shoulder Cannon:

**Windows (PowerShell):**
```powershell
Get-Content "[servidor]\logs\L*.log" | Select-String "SC_DEBUG"
```

**Linux:**
```bash
grep "SC_DEBUG" /path/to/server/logs/L*.log
```

## 📞 Soporte

Si después de revisar los logs el problema persiste:

1. Activa `sc_debug 1`
2. Reproduce el problema
3. Copia todos los logs con `[SC_DEBUG]`
4. Describe paso a paso lo que hiciste
5. Incluye la versión del plugin y del servidor
