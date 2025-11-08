# SuperTanks Nightmare - Estado de Modularización

**Fecha:** 2025-01-06
**Archivo Original:** Natan_SuperTanks_Nightmare.sp (5,737 líneas)
**Estado:** En Progreso - Fase 1 y Fase 2 Completadas Parcialmente

---

## ✅ COMPLETADO

### Estructura de Carpetas
```
scripting/supertanks/
├── tanks/          ✓ Creada
├── nightmare/      ✓ Creada
├── systems/        ✓ Creada
└── utilities/      ✓ Creada
```

### Archivos Core Completados

#### 1. **st_constants.inc** ✅
- **Ubicación:** `scripting/supertanks/st_constants.inc`
- **Tamaño:** ~150 líneas
- **Contenido:**
  - Fade flags (FFADE_IN, FFADE_OUT, etc.)
  - Modelos de sobrevivientes (8 modelos)
  - Modelos de tanques
  - Modelos de armas view (11 armas)
  - Modelos de props (gascan, propane)
  - Efectos de partículas (12 partículas)
  - Array de classnames de armas (47 armas)

#### 2. **st_variables.inc** ✅
- **Ubicación:** `scripting/supertanks/st_variables.inc`
- **Tamaño:** ~250 líneas
- **Contenido:**
  - ConVar Handles (128 handles para todos los tanques)
  - SDK Call Handles (3 handles)
  - Variables de estado del plugin
  - Arrays de configuración de tanques (16 tanques)
  - Configuraciones específicas por tanque
  - Variables del modo pesadilla
  - Variables de entorno
  - Arrays relacionados con jugadores [33]
  - Variables misceláneas

#### 3. **st_config.inc** ✅
- **Ubicación:** `scripting/supertanks/st_config.inc`
- **Tamaño:** ~650 líneas
- **Contenido:**
  - `ST_Config_CreateConVars()` - Crea todos los ConVars
  - `ST_Config_LoadValues()` - Carga valores iniciales
  - `ST_Config_HookConVars()` - Registra callbacks
  - **Callbacks Implementados:**
    - `GamemodeCvarChanged()` - Valida gamemode (coop/realism)
    - `SuperTanksCvarChanged()` - Activa/desactiva el plugin
    - `SuperTanksSettingsChanged()` - Actualiza configuración general
    - `DefaultTanksSettingsChanged()` - Maneja configuración de tanque default
    - `TanksSettingsChanged()` - Actualiza configuración de todos los tanques
    - `NightmareChanged()` - Maneja cambios en modo pesadilla
    - `NightmareBeginChanged()` - Maneja inicio de countdown

### Documentación Completada

#### 4. **SUPERTANKS_README.md** ✅
- Estructura completa del proyecto
- Lista de 17 tipos de tanques
- Instrucciones de compilación
- Dependencias requeridas

#### 5. **MODULARIZATION_GUIDE.md** ✅
- Guía detallada en 6 fases
- Estrategias de extracción
- Ejemplos de código
- Instrucciones de testing
- ~300 líneas de documentación

#### 6. **natan_supertanks_modular.sp** ✅
- Archivo plantilla del plugin principal
- Estructura documentada
- Listo para integrar módulos

---

## 🔄 EN PROGRESO

Ninguno actualmente.

---

## ⏳ PENDIENTE

### Fase 2: Utilidades (Prioridad Alta)

#### utilities/st_sdk.inc
- Funciones a extraer:
  - `InitSDKCalls()` - Inicialización de SDK
  - `L4D2_SpitBurst()` - Wrapper SDK
  - `L4D2_InfectedHitByVomitJar()` - Wrapper SDK
  - `L4D2_IsMissionFinalMap()` - Wrapper SDK
- **Líneas aproximadas:** ~100-150
- **Estado:** Pendiente

#### utilities/st_utils.inc
- Funciones a extraer:
  - Validación de clientes (IsValidClient, IsSurvivor, IsTank, etc.)
  - Funciones de conteo (CountSurvivorsAliveAll, CountTanks, etc.)
  - Cálculos de distancia (SurvInRange, GetNearestSurvivorDist, etc.)
  - Utilidades de entidades (GetRayHitPos, TraceRayDontHitSelfAndLive)
  - Conversiones de color (RGB_TO_INT, GetEntRenderColor, etc.)
  - Utilidades de armas (ForceWeaponDrop, DropSlot)
  - Actualización de velocidad (UpdateMovementSpeed)
- **Líneas aproximadas:** ~400-500
- **Estado:** Pendiente

#### utilities/st_precache.inc
- Funciones a extraer:
  - Precarga en OnMapStart
  - CheckModelPreCache()
  - CheckSoundPreCache()
  - Todas las llamadas PrecacheModel()
  - Todas las llamadas PrecacheSound()
  - Todas las llamadas PrecacheParticle()
- **Líneas aproximadas:** ~100-150
- **Estado:** Pendiente

#### utilities/st_timers.inc
- Funciones a extraer:
  - TimerUpdate01 - Loop principal 0.1s
  - TimerUpdate1 - Loop principal 1s
  - UpdateTimers()
  - TimerUpdateClients()
  - FrameUpdateClients()
  - Timers específicos de tanques
  - Timers de efectos
- **Líneas aproximadas:** ~200-250
- **Estado:** Pendiente

### Fase 3: Sistemas Base (Prioridad Media)

#### systems/st_events.inc
- Event hooks a extraer:
  - Round_Start, Round_End
  - Player_Death, Player_Spawn, Player_Use, Player_Now_It
  - Ability_Use
  - Difficulty_Changed
  - Finale events (4 handlers)
  - OnMapStart
  - OnClientPostAdminCheck
  - OnEntityCreated/OnEntityDestroyed
  - OnGameFrame
- **Líneas aproximadas:** ~300-350
- **Estado:** Pendiente

#### systems/st_damage.inc
- Funciones a extraer:
  - OnPlayerTakeDamage forward
  - OnEntityTakeDamage forward
  - DealDamagePlayer()
  - DealDamageEntity()
  - Lógica de inmunidad al fuego
  - Sistema de escudos
  - Multiplicadores de daño nightmare
- **Líneas aproximadas:** ~400-500
- **Estado:** Pendiente

#### systems/st_effects.inc
- Funciones a extraer:
  - CreateParticle()
  - AttachParticle()
  - AttachParticleLoc()
  - PrecacheParticle()
  - PerformFade() - efectos de pantalla
  - ScreenShake()
  - BlurEffect(), RemoveBlurEffect()
  - Manejo de render color
  - Manejo de glow color
- **Líneas aproximadas:** ~300-350
- **Estado:** Pendiente

#### systems/st_spawning.inc
- Funciones a extraer:
  - SpawnInfectedInterval()
  - SpawnTankTimer()
  - Tank wave timers (TimerTankWave2, TimerTankWave3)
  - ForceSpawnInfected()
  - Manejo de entidades de spawn
  - Conteo/limitación de spawns
- **Líneas aproximadas:** ~250-300
- **Estado:** Pendiente

#### systems/st_finale.inc
- Funciones a extraer:
  - Event handlers de finale (4 eventos)
  - Tracking de stages de finale
  - Spawn de tanques por oleadas
  - IsMissionFinalMap wrapper
  - ReturnChapterData()
  - Lógica de spawn específica de finale
- **Líneas aproximadas:** ~200-250
- **Estado:** Pendiente

### Fase 4: Tanques (Prioridad Media)

#### tanks/st_tank_base.inc
- Funciones base a extraer:
  - RandomizeTank() - Asignación de tipo
  - TankController() - Control principal
  - ExecTankDeath() - Muerte del tanque
  - Aplicación de salud/velocidad
  - Mecánicas de lanzamiento de rocas
  - Tracking de tanques
- **Líneas aproximadas:** ~200-250
- **Estado:** Pendiente

#### Módulos Individuales de Tanques (16 archivos)
Cada uno ~100-250 líneas:
1. **tanks/st_tank_smasher.inc** - Tank aplastador
2. **tanks/st_tank_warp.inc** - Tank de teletransporte
3. **tanks/st_tank_meteor.inc** - Tank de meteoros
4. **tanks/st_tank_spitter.inc** - Tank escupidor
5. **tanks/st_tank_heal.inc** - Tank sanador
6. **tanks/st_tank_fire.inc** - Tank de fuego
7. **tanks/st_tank_ice.inc** - Tank de hielo
8. **tanks/st_tank_jockey.inc** - Tank de jockeys
9. **tanks/st_tank_ghost.inc** - Tank fantasma
10. **tanks/st_tank_shock.inc** - Tank eléctrico
11. **tanks/st_tank_witch.inc** - Tank de brujas + manejo de witches
12. **tanks/st_tank_shield.inc** - Tank con escudos
13. **tanks/st_tank_cobalt.inc** - Tank veloz
14. **tanks/st_tank_jumper.inc** - Tank saltador
15. **tanks/st_tank_gravity.inc** - Tank de gravedad
16. **tanks/st_tank_demon.inc** - Tank demonio
- **Estado:** Pendiente todos

### Fase 5: Modo Pesadilla (Prioridad Baja)

#### nightmare/st_nightmare_core.inc
- Funciones a extraer:
  - Activación/desactivación
  - Sistema de countdown (StartCountdown)
  - ExecNightmare() - Loop principal
  - Command_Nightmare - Comando admin
  - Manejo de ticks de nightmare
- **Líneas aproximadas:** ~300-400
- **Estado:** Pendiente

#### nightmare/st_nightmare_difficulty.inc
- Funciones a extraer:
  - AutoDifficulty() - Ajuste automático
  - SetGameDifficulty()
  - Lógica de escalado
  - Multiplicadores de infectados especiales
  - Cálculo de dificultad progresiva
- **Líneas aproximadas:** ~200-250
- **Estado:** Pendiente

#### nightmare/st_nightmare_spawning.inc
- Funciones a extraer:
  - Spawn mejorado de infectados
  - Gestión de intervalos
  - SpawnInfectedBot()
  - SpawnInfected con flag auto
  - Cálculo de spawn rate
- **Líneas aproximadas:** ~150-200
- **Estado:** Pendiente

#### nightmare/st_nightmare_environment.inc
- Funciones a extraer:
  - Control de niebla (EnableFogRealism, DisableFogRealism, RenableFogRealism)
  - Corrección de color (CreateColorCorrection)
  - Sistema de time of day
  - Manejo de entidades ambientales
  - Control de puertas de saferoom (CloseSRDoor, IdentifySRDoor)
- **Líneas aproximadas:** ~200-250
- **Estado:** Pendiente

### Fase 6: Integración Final

#### Actualizar natan_supertanks_nightmare.sp
- Integrar todos los módulos con #include
- Implementar OnPluginStart() simplificado
- Registrar comando sm_nightmare
- Llamar funciones de inicialización de módulos
- Testing completo
- **Estado:** Pendiente

---

## 📊 ESTADÍSTICAS

### Progreso de Extracción
- **Líneas extraídas:** ~1,050 líneas (variables + config)
- **Líneas restantes:** ~4,687 líneas
- **Progreso aproximado:** 18% completado

### Archivos Creados
- **Archivos .inc:** 3/25+ (12%)
- **Documentación:** 3/3 (100%)
- **Estructura:** 4/4 carpetas (100%)

### Módulos por Prioridad
- **Alta (Fase 1-2):** 3/7 completados (43%)
- **Media (Fase 3-4):** 0/22 pendientes (0%)
- **Baja (Fase 5):** 0/4 pendientes (0%)

---

## 🎯 PRÓXIMOS PASOS RECOMENDADOS

1. ✅ **Completado:** Variables y configuración base
2. **Siguiente:** Crear utilities/st_sdk.inc (más simple, ~100-150 líneas)
3. **Después:** Crear utilities/st_precache.inc (búsqueda de patrones)
4. **Luego:** Crear utilities/st_utils.inc (funciones de utilidad)
5. **Continuar:** Sistemas base (events, damage, effects)
6. **Final:** Módulos de tanques individuales

---

## 📝 NOTAS

### Ventajas de la Estructura Actual
- Separación clara de responsabilidades
- Configuración centralizada y manejable
- Fácil de extender con nuevos tanques
- Documentación completa
- Include guards implementados

### Puntos a Considerar
- El archivo original sigue funcional (intacto)
- La modularización es incremental
- Cada módulo puede testearse independientemente
- La compilación completa requiere todos los módulos

### Dependencias Entre Módulos
```
natan_supertanks_nightmare.sp
├── st_constants.inc (no dependencies)
├── st_variables.inc (depends: constants)
├── st_config.inc (depends: variables)
├── utilities/
│   ├── st_sdk.inc (depends: variables)
│   ├── st_utils.inc (depends: variables)
│   ├── st_precache.inc (depends: constants)
│   └── st_timers.inc (depends: variables, utils)
├── systems/
│   ├── st_events.inc (depends: variables, utils, sdk)
│   ├── st_damage.inc (depends: variables, utils)
│   ├── st_effects.inc (depends: variables, utils)
│   ├── st_spawning.inc (depends: variables, utils, sdk)
│   └── st_finale.inc (depends: variables, utils, sdk)
├── tanks/
│   ├── st_tank_base.inc (depends: variables, utils, effects)
│   └── st_tank_*.inc (depends: tank_base, effects, utils)
└── nightmare/
    └── st_nightmare_*.inc (depends: variables, utils, spawning)
```

---

**Última actualización:** 2025-01-06
**Responsable:** Modularización automática
**Estado general:** ✅ Fundamentos completados, listo para continuar con utilidades
