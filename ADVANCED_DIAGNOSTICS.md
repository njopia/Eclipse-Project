# Diagnósticos Avanzados - Shoulder Cannon

## 🔬 Testing Step-by-Step

### Paso 1: Verificar Compilación ✓

```bash
# En PowerShell
cd "c:\Users\Socius\Desktop\sm\Eclipse-Project"

# Compilar
"c:\Users\Socius\Desktop\sourcemod\addons\sourcemod\scripting\spcomp.exe" shoulder_cannon.sp -o"scripting/compiled/shoulder_cannon.smx"

# Verificar archivo
ls scripting/compiled/shoulder_cannon.smx
```

**Resultado esperado:** Archivo de 23+ KB sin errores.

---

### Paso 2: Verificar Carga del Plugin

En la **consola del servidor**:

```
sm plugins list | grep -i shoulder
```

**Resultado esperado:**
```
[OK] Name                     File              Status
    .... Shoulder Cannon     shoulder_cannon.  Run
```

Si no aparece → El plugin no se copió correctamente.

---

### Paso 3: Activar Debug Mode

En la **consola del servidor**:

```
sc_debug 1
```

**Resultado esperado:** No hay salida, pero debug está activado.

Para verificar:
```
sm cvar sc_debug
```

Debería mostrar `sc_debug : 1`

---

### Paso 4: Ejecutar Comando en Juego

En **el chat del juego**:

```
!sc
```

**En paralelo, en la consola del servidor:**

```
tail -f logs/L*.log | grep SC_DEBUG
```

---

## 🎯 Interpretación de Resultados

### Escenario A: Sin logs en absoluto

**Significa:** El plugin no está ejecutando nada.

**Causas posibles:**
1. Archivo `.smx` no se copió
2. Plugin cargó pero está deshabilitado
3. Comando de chat no se registró

**Solución:**
```bash
# En consola del servidor
sm plugins reload shoulder_cannon

# Verifica:
sm plugins list
```

---

### Escenario B: Log "Command_Say from client X"

**Significa:** El comando de chat está siendo capturado ✓

**Siguiente paso:** Busca `ShoulderCannonMenuFunc called`

Si no aparece → El menú no se está abriendo.

**Debug:**
```sourcepawn
// Agrega al código si falta:
if (StrEqual(text[startidx], "!sc", false)) {
    LogMessage("[SC] CRITICAL: Matched !sc command");
    ShoulderCannonMenuFunc(client);
}
```

---

### Escenario C: "Menu title set" + "Displaying menu"

**Significa:** El menú se está abriendo ✓

**Siguiente paso:** Verifica si el menú es visible en el cliente.

Si el menú **NO aparece en pantalla** pero los logs dicen que se abre:
- Problema de permisos de cliente
- Cliente no es sobreviviente
- Cliente está muerto

**Debug:**
```log
[SC_DEBUG] Creating menu - HasCannon: 0, Ammo: 500
[SC_DEBUG] Menu title set
[SC_DEBUG] Displaying menu to client 1
```

---

### Escenario D: "Equip Shoulder Cannon" logs

**Significa:** El menú se abrió y el cliente hizo clic ✓

**Logs esperados:**
```
[SC_DEBUG] EquipShoulderCannon called for client 1
[SC_DEBUG] Client 1 passed validation checks
[SC_DEBUG] CreateEntityByName('prop_dynamic_override') returned: XXX
[SC_DEBUG] Entity XXX is valid, setting up...
[SC_DEBUG] Model set to: models/w_models/weapons/w_m60.mdl
[SC_DEBUG] Entity XXX spawned
[SC_DEBUG] Entity XXX activated
[SC_DEBUG] Entity XXX parented to client 1
[SC_DEBUG] Parent attachment set to 'eyes'
[SC_DEBUG] RunRepeater started for client 1 with entity XXX
[SC_DEBUG] RunRepeater: Timer created successfully
```

**Si ves estos logs pero no aparece el cañón:**
- Modelo no precacheado
- Attachment point no válido
- Problema de rendering

---

### Escenario E: "CannonRepeater" logs

**Significa:** El sistema de disparo está funcionando ✓

**Logs esperados:**
```
[SC_DEBUG] CannonRepeater: round=X, client=X, cannon=XXX, iRound=X
[SC_DEBUG] CannonRepeater: Client X is valid and alive
[SC_DEBUG] CannonRepeater: Searching for targets - Ammo: 500
[SC_DEBUG] Found 15 common infected
[SC_DEBUG] Target selection - zombie:380 special:0 witch:0 tank:0, priority:0
[SC_DEBUG] DestroyTarget called - client:X, target:380, type:2
[SC_DEBUG] Cannon XXX is valid, firing at target 380
[SC_DEBUG] Effects created, dealing damage...
```

---

## 🧪 Pruebas Específicas

### Test 1: ¿El comando se captura?

**En juego:**
```
!sc
/sc
say !sc
say_team /sc
```

**En logs, busca:**
```
[SC_DEBUG] Command_Say from client X: !sc
```

---

### Test 2: ¿El menú se abre?

**Interactivamente:**
```
// En consola del servidor:
sm_execclient 1 shouldercannon

// Debería abrir el menú para client 1
```

**En logs, busca:**
```
[SC_DEBUG] Displaying menu to client 1
```

---

### Test 3: ¿La entidad se crea?

**Código de prueba:**
```sourcepawn
// Temporal en OnPluginStart:
public void TestEntityCreation() {
    int ent = CreateEntityByName("prop_dynamic_override");
    LogMessage("[TEST] prop_dynamic_override: %d", ent);

    if (ent == -1) {
        ent = CreateEntityByName("prop_dynamic");
        LogMessage("[TEST] prop_dynamic fallback: %d", ent);
    }
}
```

**En logs, busca:**
```
[TEST] prop_dynamic_override: XXX (o -1)
[TEST] prop_dynamic fallback: YYY
```

---

### Test 4: ¿El timer se ejecuta?

**En logs, busca:**
```
[SC_DEBUG] RunRepeater: Creating timer with rate 0.150 seconds
[SC_DEBUG] RunRepeater: Timer created successfully
[SC_DEBUG] CannonRepeater: round=X, client=X, cannon=XXX
```

Si no ves `CannonRepeater` → El timer no está disparando.

**Solución:**
- Verificar fire rate válido
- Verificar que el servidor está procesando
- Verificar que el cliente sigue vivo

---

## 📊 Matriz de Diagnóstico

| Log encontrado | Significa | Siguiente paso |
|---|---|---|
| `Command_Say` | ✓ Chat capturado | Busca `MenuFunc` |
| `ShoulderCannonMenuFunc` | ✓ Menú abierto | Busca `Equip` |
| `EquipShoulderCannon` | ✓ Equipo iniciado | Busca `CreateEntity` |
| `Entity XXX is valid` | ✓ Entidad creada | Busca `RunRepeater` |
| `RunRepeater: Timer created` | ✓ Timer ejecutándose | Busca `CannonRepeater` |
| `CannonRepeater: round=X` | ✓ Sistema disparo activo | Busca `Found X infected` |
| `DestroyTarget called` | ✓ Disparando | Busca `Dealing damage` |

---

## 🔴 Errores Críticos a Buscar

```log
[SC_DEBUG] ERROR: Failed to create valid entity for client X
```
→ Entidad no se puede crear. Fallback a prop_dynamic.

```log
[SC_DEBUG] ERROR: Cannon XXX is invalid or not found!
```
→ Entidad fue deletida o invalidada.

```log
[SC_DEBUG] ERROR: Failed to create timer!
```
→ Fire rate es 0 o negativa. Validación fallida.

```log
[SC_DEBUG] ERROR: Model mismatch!
```
→ Modelo no es el esperado. Verificar precaching.

---

## 🛠️ Herramientas de Debug Recomendadas

### 1. Monitor de Logs en Real-Time (Windows PowerShell)
```powershell
Get-Content "[ruta]/logs/L*.log" -Wait -Tail 50 | Select-String "SC_DEBUG"
```

### 2. Filtrar por Cliente
```bash
grep "SC_DEBUG.*client 1" logs/L*.log
```

### 3. Filtrar por Tipo de Error
```bash
grep "SC_DEBUG.*ERROR" logs/L*.log
```

### 4. Ver Timeline Completa
```bash
grep "SC_DEBUG" logs/L*.log | head -100
```

---

## 📋 Checklist de Resolución

- [ ] Compilación sin errores
- [ ] Plugin cargado (`sm plugins list`)
- [ ] Debug mode activado (`sc_debug 1`)
- [ ] Comando capturado (`Command_Say`)
- [ ] Menú abierto (`ShoulderCannonMenuFunc`)
- [ ] Equipo iniciado (`EquipShoulderCannon`)
- [ ] Entidad creada (`Entity XXX is valid`)
- [ ] Timer creado (`RunRepeater: Timer created`)
- [ ] Repeater ejecutándose (`CannonRepeater`)
- [ ] Objetivos encontrados (`Found X infected`)
- [ ] Disparando (`DestroyTarget called`)
- [ ] Daño aplicado (`Dealing damage`)

---

## 📞 Si Aún No Funciona

1. **Recopila los logs:**
   ```bash
   grep "SC_DEBUG" logs/L*.log > shoulder_cannon_debug.txt
   ```

2. **Incluye:**
   - Versión del servidor
   - Versión de SourceMod
   - Versión de SDK Tools
   - Mapa en uso
   - Número de jugadores

3. **Ejecuta pruebas de entidad:**
   ```
   test_entity_creation
   ```

4. **Verifica permisos:**
   ```
   stat addons/sourcemod/plugins/shoulder_cannon.smx
   ```
