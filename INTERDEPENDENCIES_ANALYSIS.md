# Análisis de Interdependencias - Shoulder Cannon

## 📋 Resumen

El plugin `shoulder_cannon.sp` es **técnicamente standalone** pero fue extraído de un sistema mucho más grande (**Eclipse Management System**). Al separarlo, se perdieron algunas dependencias implícitas del contexto original.

## 🔍 Estructura Original Encontrada

```
Eclipse Management System (Plugin Principal)
├── Ion Cannon (ion.sp)
│   ├── Exports natives via ion_cannon.inc
│   │   ├── Ion_CanUse()
│   │   ├── Ion_Activate()
│   │   ├── Ion_GetCooldown()
│   │   ├── Ion_GetCharges()
│   │   └── Ion_SetCharges()
│   └── Maneja todas las mecánicas de disparo
│
├── Buy System (módulo)
│   ├── ion-cannon.feature.sp (integración con tienda)
│   └── Otros features
│
└── Shoulder Cannon (AQUÍ ESTÁ LA CONFUSIÓN)
    ├── Era un submódulo separado
    ├── Sistema independiente de firing
    └── Funciona sin dependencias de includes
```

## ⚠️ Problemas Identificados en shoulder_cannon.sp

### 1. **Entity Creation Issues** ❌
```sourcepawn
// PROBLEMA: prop_dynamic_override puede no existir en todas las versiones
new entity = CreateEntityByName("prop_dynamic_override");

// SOLUCIÓN APLICADA:
new entity = CreateEntityByName("prop_dynamic_override");
if (entity == -1) {
    entity = CreateEntityByName("prop_dynamic");  // Fallback
}
```

**Por qué ocurre:** `prop_dynamic_override` es una entidad customizada que podría no estar disponible en el servidor.

### 2. **Entity Activation Missing** ❌
```sourcepawn
// ANTES (incompleto):
DispatchSpawn(entity);
SetVariantString("!activator");

// DESPUÉS (correcto):
DispatchSpawn(entity);
ActivateEntity(entity);  // ← FALTABA ESTO
SetVariantString("!activator");
```

**Por qué ocurre:** La entidad necesita ser activada para que sea visible en el juego.

### 3. **Timer Creation Without Validation** ❌
```sourcepawn
// PROBLEMA: No verificaba si el timer se creó correctamente
CreateTimer(CannonRate[client], CannonRepeater, Pack, TIMER_FLAG_NO_MAPCHANGE);

// SOLUCIÓN:
new Handle:timer = CreateTimer(...);
if (timer == INVALID_HANDLE) {
    LogMessage("[SC] ERROR: Failed to create timer!");
}
```

**Por qué ocurre:** Si la velocidad de fuego es 0 o negativa, el timer nunca se crea.

### 4. **Fire Rate Validation Missing** ❌
```sourcepawn
// ANTES: No verificaba fire rate
static Float:CannonRate[33];   // Podría ser 0 o negativa

// DESPUÉS: Validación agregada
if (CannonRate[client] <= 0.0) {
    CannonRate[client] = 0.15;  // Reset a valor por defecto
}
```

**Por qué ocurre:** La inicialización podría fallar, dejando el fire rate en 0.

## 🔧 Mejoras Aplicadas

### 1. Fallback para Entity Creation
```sourcepawn
if (entity == -1) {
    LogMessage("[SC] WARNING: prop_dynamic_override failed, using prop_dynamic");
    entity = CreateEntityByName("prop_dynamic");
}
```

### 2. Complete Entity Setup
```sourcepawn
DispatchKeyValue(entity, "model", MODEL_M60);
DispatchKeyValue(entity, "spawnflags", "2");
DispatchSpawn(entity);
ActivateEntity(entity);  // ← Crítico
```

### 3. Timer Validation
```sourcepawn
if (CannonRate[client] <= 0.0) {
    CannonRate[client] = 0.15;
    LogMessage("[SC] ERROR: Invalid fire rate, reset to 0.15");
}

new Handle:timer = CreateTimer(CannonRate[client], CannonRepeater, Pack, ...);
if (timer == INVALID_HANDLE) {
    LogMessage("[SC] ERROR: Failed to create timer!");
}
```

### 4. Debug Completo en Menú Handler
```sourcepawn
public SCMHandler(Handle:menu, MenuAction:action, client, param1)
{
    DebugLog("SCMHandler called - action:%d, client:%d", action, client);
    // ... más logs ...
}
```

## 📊 Comparación: Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| Entity Validation | ❌ | ✅ |
| Entity Activation | ❌ | ✅ |
| Fallback Entities | ❌ | ✅ |
| Timer Validation | ❌ | ✅ |
| Fire Rate Validation | ❌ | ✅ |
| Logs de Debug | Parciales | Completos |
| Tamaño del plugin | 20 KB | 23 KB |

## 🎯 Qué Verificar Cuando No Hay Logs

Si no ves logs de debug en los archivos `.log`, revisa:

1. **¿El plugin está cargado?**
   ```
   sm plugins list | grep -i shoulder
   ```

2. **¿El debug está activado?**
   ```
   sc_debug  // En consola
   ```

3. **¿Los logs están en la ubicación correcta?**
   ```
   [servidor]/logs/L[YYYY-MM-DD].log
   ```

4. **¿Hay permisos de escritura en la carpeta logs?**
   ```
   ls -la [servidor]/logs/
   ```

## 🔴 Problemas Comunes Sin Logs

Si ejecutas el menú pero no ves NADA en los logs:

1. **El plugin nunca se cargó correctamente**
   - Verifica errores en la compilación
   - Revisa `sm plugins list`

2. **El comando de chat no está siendo capturado**
   - Revisa que `Command_Say` esté siendo hooked
   - Verifica que el mensaje llega al servidor

3. **El DebugLog no funciona**
   - Verifica que `LogMessage()` esté funcionando
   - Prueba con `PrintToServer()` directamente

## 💡 Solución Rápida

Si nada funciona después de compilar:

```sourcepawn
// 1. Agrega esto al inicio de OnPluginStart:
PrintToServer("[SHOULDER CANNON] Plugin starting...");

// 2. Recompila
// 3. Recarga el servidor

// Deberías ver el mensaje en la consola
```

Si ese mensaje aparece pero nada más sucede, entonces:
- El Command_Say listener no está funcionando
- Los comandos no están siendo registrados correctamente
- Hay un problema con el registro del plugin

## 📝 Changelog de Fixes

### Versión 1.0.0 Original
- Plugin extraction de Master_3_46[BACKUP]
- Sistema básico de menú
- Sistema básico de firing

### Versión 1.1.0 (Con Debug)
- Sistema completo de logging
- Validación de entidades mejorada
- Fallback para entity creation
- Validación de timers

### Versión 1.1.1 (Con Interdependencies Fix)
- Fallback prop_dynamic_override → prop_dynamic
- ActivateEntity() agregado
- Fire rate validation
- Menu handler debugging
- Timer validation completa

## 🚀 Próximos Pasos

1. **Compilar la versión mejorada:**
   ```bash
   ./compile_shoulder_cannon.bat
   ```

2. **Copiar al servidor:**
   ```
   scripting/compiled/shoulder_cannon.smx → addons/sourcemod/plugins/
   ```

3. **Activar debug:**
   ```
   sc_debug 1
   ```

4. **Monitorear logs:**
   ```
   tail -f logs/L*.log | grep SC_DEBUG
   ```

5. **Probar en juego:**
   ```
   !sc (en el chat)
   ```
