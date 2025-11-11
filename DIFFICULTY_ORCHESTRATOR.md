# Difficulty Orchestrator Module

Sistema centralizado de gestión de modos de dificultad para Eclipse L4D2.

## 🎯 Propósito

El orquestador de dificultad gestiona:
- **Mutual Exclusion**: Solo un modo activo a la vez
- **Progresión Automática**: Desbloqueo de dificultades al ganar campañas
- **Coordinación**: Centraliza la activación/desactivación de modos
- **Extensibilidad**: Preparado para Hell e Inferno

## 🏗️ Arquitectura

```
┌─────────────────────────────────┐
│  Difficulty Orchestrator        │
│  (difficulty-orchestrator.sp)   │
└────────┬────────────────────────┘
         │
         ├─► Bloodmoon Module
         ├─► Hell Module (TODO)
         ├─► Inferno Module (TODO)
         └─► Cow Level Module
```

## 📊 Progresión de Dificultad

```
Normal
  │
  └─► Win Campaign → BLOODMOON (immediate)
                       │
                       └─► Win Campaign → HELL (immediate)
                                           │
                                           └─► Win 2x → INFERNO
                                                         │
                                                         └─► Win 2x → COW LEVEL
                                                                       │
                                                                       └─► Win → COMPLETE! 🎉
```

## 🎮 ConVars

### Core Settings

| ConVar | Default | Description |
|--------|---------|-------------|
| `difficulty_orchestrator_enable` | 1 | Habilita el orquestador |
| `difficulty_progression_enable` | 1 | Progresión automática al ganar |
| `difficulty_mutual_exclusion` | 1 | Solo un modo activo a la vez |
| `difficulty_auto_unlock` | 1 | Desbloqueo automático |

## 🛠️ Comandos Admin

### sm_diffmode
Gestionar modos de dificultad manualmente.

**Uso:**
```
sm_diffmode <mode>
sm_diffmode status
```

**Modos disponibles:**
- `none` - Desactivar todos los modos
- `bloodmoon` - Activar Bloodmoon
- `hell` - Activar Hell (cuando esté implementado)
- `inferno` - Activar Inferno (cuando esté implementado)
- `cowlevel` - Activar Cow Level
- `status` - Ver estado actual

**Ejemplos:**
```
sm_diffmode bloodmoon    // Activa Bloodmoon (desactiva otros)
sm_diffmode status       // Muestra modo actual y progresión
sm_diffmode none         // Desactiva todos los modos
```

### sm_resetprogression
Resetea la progresión de dificultad a cero.

**Uso:**
```
sm_resetprogression
```

Esto:
- Resetea el contador de victorias a 0
- Desactiva todos los modos
- Anuncia el reset a todos los jugadores

## 🔧 Funciones Públicas (API)

### Para Módulos de Dificultad

```sourcepawn
/**
 * Obtiene el modo actual
 * @return DifficultyMode actual
 */
DifficultyMode DifficultyOrchestrator_GetCurrentMode()

/**
 * Establece el modo de dificultad
 * @param mode Modo a activar
 */
void DifficultyOrchestrator_SetMode(DifficultyMode mode)

/**
 * Obtiene el contador de victorias
 * @return Número de victorias en modo actual
 */
int DifficultyOrchestrator_GetWinCount()

/**
 * Establece el contador de victorias
 * @param wins Número de victorias
 */
void DifficultyOrchestrator_SetWinCount(int wins)
```

### DifficultyMode Enum

```sourcepawn
enum DifficultyMode
{
    MODE_NONE = 0,       // Sin modo activo
    MODE_BLOODMOON = 1,  // Bloodmoon
    MODE_HELL = 2,       // Hell (futuro)
    MODE_INFERNO = 3,    // Inferno (futuro)
    MODE_COWLEVEL = 4    // Cow Level
}
```

## 📋 Eventos Hookeados

| Evento | Propósito |
|--------|-----------|
| `finale_win` | Detecta victoria de campaña → procesa progresión |
| `mission_lost` | Resetea contador de victorias |

## 🔄 Flujo de Trabajo

### 1. Inicio del Plugin
```
OnPluginStart()
  ├─► Crear ConVars
  ├─► Hookear eventos
  └─► Registrar comandos admin
```

### 2. Inicio del Mapa
```
OnMapStart()
  ├─► Detectar modo activo
  └─► Aplicar mutual exclusion si es necesario
```

### 3. Victoria de Campaña
```
Event_FinaleWin()
  ├─► Marcar finale completado
  └─► Timer de 5s → ProcessProgression()
      ├─► Verificar requisitos
      ├─► Desbloquear siguiente modo
      ├─► Anunciar unlock
      └─► Activar modo via SetMode()
```

### 4. Cambio Manual de Modo
```
Command_DiffMode()
  ├─► Validar modo
  └─► SetMode()
      ├─► EnforceMutualExclusion()
      │   └─► Desactivar otros modos
      └─► ActivateMode()
          └─► Activar ConVar del modo
```

## 🎯 Mutual Exclusion

Cuando está habilitado (`difficulty_mutual_exclusion 1`):

1. **Al activar un modo**, el orquestador:
   - Desactiva automáticamente los otros modos
   - Setea los ConVars correspondientes a `0`
   - Activa solo el modo solicitado

2. **Detección automática**:
   - En cada `OnMapStart`, detecta qué modo está activo
   - Si hay múltiples activos, prioriza: Cow Level > Inferno > Hell > Bloodmoon

3. **Deshabilitación**:
   - Si se desactiva mutual exclusion, múltiples modos pueden coexistir
   - Útil para testing y desarrollo

## 🚀 Añadir Nuevos Modos

Para agregar Hell o Inferno:

### 1. Crear el módulo
```sourcepawn
// scripting/modules/modes/hell.module.sp
Handle g_cvar_Hell_Enable = INVALID_HANDLE;
// ... implementación
```

### 2. Actualizar el orquestador
```sourcepawn
// En EnforceMutualExclusion()
if (activeMode != MODE_HELL && GetConVarBool(g_cvar_Hell_Enable))
{
    SetConVarBool(g_cvar_Hell_Enable, false);
}

// En ActivateMode()
case MODE_HELL:
{
    if (!GetConVarBool(g_cvar_Hell_Enable))
        SetConVarBool(g_cvar_Hell_Enable, true);
}
```

### 3. Agregar traducciones
```
"DiffOrch_HellUnlocked"
{
    "en"  "Hell Difficulty Unlocked!"
    ...
}
```

### 4. Ajustar progresión
```sourcepawn
#define PROGRESSION_BLOODMOON_TO_HELL  0  // Victorias necesarias
```

## 📈 Estado Actual

| Modo | Estado | Progresión |
|------|--------|------------|
| Bloodmoon | ✅ Implementado | 0 wins → Hell |
| Hell | 🔧 Placeholder | 2 wins → Inferno |
| Inferno | 🔧 Placeholder | 2 wins → Cow Level |
| Cow Level | ✅ Implementado | 1 win → Complete |

## 🐛 Debugging

Para debugging, usar:

```
sm_diffmode status
```

Muestra:
- Modo actual
- Victorias en modo actual
- Estado de mutual exclusion
- Estado de auto progresión

Logs en `addons/sourcemod/logs/`:
```
[Difficulty Orchestrator] Mode changed: 0 → 1
[Difficulty Orchestrator] Deactivating Cow Level (mutual exclusion)
```

## 🔐 Permisos

| Comando | Flag Requerida |
|---------|----------------|
| `sm_diffmode` | ADMFLAG_ROOT |
| `sm_resetprogression` | ADMFLAG_ROOT |

## 📝 Notas de Implementación

1. **Orden de Inicialización**: El orquestador DEBE inicializarse ANTES que los módulos individuales de dificultad

2. **ConVar Hooks**: Los módulos individuales pueden usar sus propios hooks de ConVar, el orquestador no interfiere

3. **Persistencia**: La progresión actual NO persiste entre reinicios del servidor (TODO: agregar database)

4. **Thread Safety**: Todos los cambios de modo son síncronos y thread-safe

## 🎯 Mejoras Futuras

- [ ] Persistencia de progresión en database
- [ ] Implementar Hell module
- [ ] Implementar Inferno module
- [ ] Sistema de achievements por modo
- [ ] Estadísticas de tiempo en cada modo
- [ ] Votación para cambio de dificultad
- [ ] Configuración per-map de progresión

## 📚 Referencias

- Master Backup: Implementación original en Master_3_46[BACKUP] (2).sp
- Bloodmoon: `scripting/modules/modes/bloodmoon.module.sp`
- Cow Level: `scripting/modules/modes/cow-level.module.sp`
