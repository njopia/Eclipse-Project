# SuperTanks Nightmare - Guía de Modularización

## Estado Actual

### ✓ Completado

1. **Estructura de carpetas creada:**
   ```
   scripting/supertanks/
   ├── tanks/          (Para módulos de tanques individuales)
   ├── nightmare/      (Para sistema de modo pesadilla)
   ├── systems/        (Para sistemas del juego)
   └── utilities/      (Para utilidades y funciones comunes)
   ```

2. **Archivos base creados:**
   - `st_constants.inc` - Todas las constantes (modelos, partículas, armas)
   - `SUPERTANKS_README.md` - Documentación de la estructura
   - `MODULARIZATION_GUIDE.md` - Esta guía

3. **Archivo principal modular:**
   - `natan_supertanks_modular.sp` - Plantilla para la versión modular

### ⏳ Pendiente

El archivo original (`Natan_SuperTanks_Nightmare.sp`) tiene 5,737 líneas que deben separarse en módulos.

## Proceso de Modularización

### Fase 1: Configuración y Variables (Prioridad Alta)

#### 1.1 Crear `st_variables.inc`
Extraer todas las variables globales (líneas 248-320 del original):
- Variables de estado del plugin
- Arrays de configuración de tanques
- Variables del modo pesadilla
- Variables de entorno
- Arrays relacionados con jugadores

#### 1.2 Crear `st_config.inc`
Extraer todo el sistema de ConVars (líneas 128-565 del original):
- Declaraciones de todos los ConVars
- Función de creación de ConVars
- Callbacks de cambio de ConVars
- Carga de valores iniciales

### Fase 2: Utilidades (Prioridad Alta)

#### 2.1 Crear `utilities/st_sdk.inc`
Extraer inicialización de SDK (buscar "InitSDKCalls"):
- SDKSpitBurst
- SDKInfectedHitByVomitJar
- SDKIsMissionFinalMap
- Wrappers para llamadas SDK

#### 2.2 Crear `utilities/st_utils.inc`
Extraer funciones utilitarias:
- `IsValidClient()`, `IsSurvivor()`, `IsTank()`, etc.
- Funciones de conteo (`CountSurvivorsAliveAll`, `CountTanks`, etc.)
- Cálculos de distancia
- Conversiones de color
- Utilidades de armas

#### 2.3 Crear `utilities/st_precache.inc`
Extraer código de precarga (buscar "PrecacheModel", "PrecacheSound"):
- Precarga de modelos
- Precarga de sonidos
- Precarga de partículas

#### 2.4 Crear `utilities/st_timers.inc`
Extraer manejo de timers:
- `TimerUpdate01`
- `TimerUpdate1`
- Timers específicos de tanques
- Timers del modo pesadilla

### Fase 3: Sistemas Base (Prioridad Media)

#### 3.1 Crear `systems/st_events.inc`
Extraer todos los event hooks:
- `Round_Start`, `Round_End`
- `Player_Death`, `Player_Spawn`
- Eventos de finale
- `OnMapStart`, `OnClientPostAdminCheck`

#### 3.2 Crear `systems/st_damage.inc`
Extraer sistema de daño:
- `OnPlayerTakeDamage`
- `OnEntityTakeDamage`
- `DealDamagePlayer`
- Inmunidad al fuego
- Daño de escudos

#### 3.3 Crear `systems/st_effects.inc`
Extraer sistema de efectos:
- `CreateParticle`, `AttachParticle`
- `PerformFade`
- `ScreenShake`
- Efectos de blur
- Manejo de colores

#### 3.4 Crear `systems/st_spawning.inc`
Extraer sistema de spawn:
- `SpawnInfectedInterval`
- `ForceSpawnInfected`
- Control de spawn de infectados especiales

#### 3.5 Crear `systems/st_finale.inc`
Extraer manejo de finale:
- Detección de finale
- Spawn por oleadas
- `ReturnChapterData`

### Fase 4: Tanques (Prioridad Media)

#### 4.1 Crear `tanks/st_tank_base.inc`
Funciones base de tanques:
- `RandomizeTank()` - Asignación de tipo de tanque
- `TankController()` - Control principal del tanque
- `ExecTankDeath()` - Manejo de muerte del tanque
- Aplicación de salud/velocidad
- Mecánicas de lanzamiento de rocas

#### 4.2 Crear módulos individuales de tanques
Cada archivo debe contener:
- Habilidades específicas del tanque
- Timers del tanque
- Efectos de partículas
- Lógica de daño personalizada

**Ejemplo para `tanks/st_tank_smasher.inc`:**
```sourcepawn
#if defined _st_tank_smasher_included
 #endinput
#endif
#define _st_tank_smasher_included

// Smasher Tank Implementation
// Abilities: High damage melee, maim survivors, remove bodies

stock SkillSmashClaw(target)
{
    // Implementación del ataque aplastante
}

public Action:Timer_SmashClawKill(Handle:timer, any:client)
{
    // Timer para matar víctimas aplastadas
}

stock SmasherTankThink(tank)
{
    // Lógica de actualización por frame del Smasher
}
```

**Lista de archivos de tanques a crear:**
1. `st_tank_smasher.inc` - Tank aplastador
2. `st_tank_warp.inc` - Tank de teletransporte
3. `st_tank_meteor.inc` - Tank de meteoros
4. `st_tank_spitter.inc` - Tank escupidor
5. `st_tank_heal.inc` - Tank sanador
6. `st_tank_fire.inc` - Tank de fuego
7. `st_tank_ice.inc` - Tank de hielo
8. `st_tank_jockey.inc` - Tank de jockeys
9. `st_tank_ghost.inc` - Tank fantasma
10. `st_tank_shock.inc` - Tank eléctrico
11. `st_tank_witch.inc` - Tank de brujas
12. `st_tank_shield.inc` - Tank con escudos
13. `st_tank_cobalt.inc` - Tank veloz
14. `st_tank_jumper.inc` - Tank saltador
15. `st_tank_gravity.inc` - Tank de gravedad
16. `st_tank_demon.inc` - Tank demonio

### Fase 5: Modo Pesadilla (Prioridad Baja)

#### 5.1 Crear `nightmare/st_nightmare_core.inc`
- Activación/desactivación del modo
- Sistema de cuenta regresiva
- `ExecNightmare()` - Loop principal
- Comando de administrador

#### 5.2 Crear `nightmare/st_nightmare_difficulty.inc`
- `AutoDifficulty()` - Ajuste automático
- Multiplicadores de dificultad
- Escalado progresivo

#### 5.3 Crear `nightmare/st_nightmare_spawning.inc`
- Spawn mejorado de infectados
- Gestión de intervalos
- Tasas de spawn basadas en dificultad

#### 5.4 Crear `nightmare/st_nightmare_environment.inc`
- Control de niebla
- Corrección de color
- Control de puertas de saferoom
- Entidades ambientales

### Fase 6: Archivo Principal (Prioridad Final)

#### 6.1 Actualizar `natan_supertanks_nightmare.sp`
Una vez todos los módulos estén creados, el archivo principal debe ser:

```sourcepawn
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"

// Include all modules
#include "supertanks/st_constants.inc"
#include "supertanks/st_variables.inc"
#include "supertanks/st_config.inc"

// Utilities
#include "supertanks/utilities/st_sdk.inc"
#include "supertanks/utilities/st_utils.inc"
#include "supertanks/utilities/st_precache.inc"
#include "supertanks/utilities/st_timers.inc"

// Systems
#include "supertanks/systems/st_events.inc"
#include "supertanks/systems/st_damage.inc"
#include "supertanks/systems/st_effects.inc"
#include "supertanks/systems/st_spawning.inc"
#include "supertanks/systems/st_finale.inc"

// Tank Base
#include "supertanks/tanks/st_tank_base.inc"

// Tank Types
#include "supertanks/tanks/st_tank_smasher.inc"
#include "supertanks/tanks/st_tank_warp.inc"
// ... (todos los demás tanques)

// Nightmare Mode
#include "supertanks/nightmare/st_nightmare_core.inc"
#include "supertanks/nightmare/st_nightmare_difficulty.inc"
#include "supertanks/nightmare/st_nightmare_spawning.inc"
#include "supertanks/nightmare/st_nightmare_environment.inc"

public Plugin:myinfo =
{
    name = "[L4D2] Natan SuperTanks Nightmare",
    author = "Natan",
    description = "16 types of super tanks + Nightmare Mode",
    version = PLUGIN_VERSION,
    url = ""
};

public OnPluginStart()
{
    // Minimal initialization
    // Most work delegated to module initialization functions
    ST_Config_Init();
    ST_SDK_Init();
    ST_Events_Init();
    // etc.
}
```

## Estrategia de Extracción

### Método Recomendado

1. **Hacer backup del archivo original**
2. **Trabajar en pequeñas secciones** - No intentar modularizar todo de una vez
3. **Compilar frecuentemente** - Verificar que cada módulo compile correctamente
4. **Buscar patrones** - Usar grep/búsqueda para encontrar funciones relacionadas:
   ```
   grep "SkillSmashClaw" Natan_SuperTanks_Nightmare.sp
   grep "Smasher" Natan_SuperTanks_Nightmare.sp
   ```

### Herramientas de Extracción

Puedes usar comandos para extraer secciones específicas:

```bash
# Extraer líneas específicas (ejemplo: líneas 1000-1200)
sed -n '1000,1200p' Natan_SuperTanks_Nightmare.sp > temp_section.sp

# Buscar todas las funciones de un tanque específico
grep -n "Smasher\|SkillSmashClaw" Natan_SuperTanks_Nightmare.sp
```

### Include Guards

Todos los archivos .inc deben tener include guards:

```sourcepawn
#if defined _nombre_del_modulo_included
 #endinput
#endif
#define _nombre_del_modulo_included

// Código del módulo aquí
```

## Testing

### Compilación

Después de cada módulo creado:

```bash
spcomp natan_supertanks_nightmare.sp
```

### Verificación

1. **Sin errores de compilación** - El plugin debe compilar limpiamente
2. **Funcionalidad mantenida** - Probar en servidor de prueba
3. **Sin duplicación** - Verificar que no haya funciones duplicadas entre módulos

## Beneficios de la Modularización

1. **Mantenibilidad** - Más fácil encontrar y modificar código específico
2. **Colaboración** - Múltiples desarrolladores pueden trabajar en paralelo
3. **Depuración** - Más fácil identificar el origen de bugs
4. **Extensibilidad** - Agregar nuevos tanques es más simple
5. **Reutilización** - Las utilidades pueden usarse en otros plugins
6. **Legibilidad** - Archivos más pequeños y enfocados

## Soporte

Si tienes problemas con la modularización:

1. Verifica que todos los archivos .inc tengan include guards
2. Asegúrate de que el orden de #include sea correcto (dependencias primero)
3. Compila con el flag -v para ver mensajes detallados: `spcomp -v archivo.sp`
4. Revisa que todas las funciones estén declaradas antes de usarse

## Notas Finales

- El archivo original (`Natan_SuperTanks_Nightmare.sp`) debe mantenerse como respaldo
- La modularización es un proceso iterativo - no tiene que ser perfecto de inmediato
- Prioriza los módulos más críticos primero (variables, config, SDK)
- Documenta cualquier cambio significativo en la lógica

---

**Última actualización:** 2025
**Estado:** Estructura base creada, modularización en progreso
