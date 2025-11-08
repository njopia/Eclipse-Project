# SuperTanks Nightmare - Próximos Pasos para Completar Modularización

**Estado Actual:** 37% Completado (2,125 de 5,737 líneas)
**Compilación:** ✅ Exitosa (natan_supertanks_modular_v2.sp)

---

## ✅ COMPLETADO (Fase 1-2)

### Módulos Funcionales
1. **st_constants.inc** - Constantes (#define)
2. **st_variables.inc** - Variables globales + WeaponClassname array
3. **st_config.inc** - Sistema completo de ConVars
4. **utilities/st_sdk.inc** - SDK calls
5. **utilities/st_precache.inc** - Precaching
6. **utilities/st_utils.inc** - Funciones de utilidad esenciales

### Funcionalidad Base
- ✅ Compilación sin errores
- ✅ Inicialización del plugin
- ✅ 128+ ConVars funcionando
- ✅ SDK calls operativos
- ✅ Precarga de recursos
- ✅ Comando sm_nightmare

---

## 🔄 FASE 3: TIMERS Y CONTROL (Siguiente)

### utilities/st_timers.inc

**Funciones a extraer:**

```sourcepawn
// Timer principal 0.1s - Muestra salud de tanques
public Action:TimerUpdate01(Handle:timer)
- Verifica IsServerProcessing()
- Muestra HP de tanques en crosshair
- ~30 líneas

// Timer principal 1.0s - Loop de control
public Action:TimerUpdate1(Handle:timer)
- Llama TankController()
- Llama SpawnInfectedInterval()
- Llama TimerUpdateClients()
- Llama ExecGameModes()
- ~15 líneas

// Actualización de clientes
TimerUpdateClients()
- Actualiza velocidad de jugadores
- Gestiona efectos de shock
- ~20 líneas

// Actualización por frames
FrameUpdateClients()
- Actualización continua de estados
- ~15 líneas
```

**Ubicación en original:**
- TimerUpdate01: Línea 5694
- TimerUpdate1: Línea 5727
- TimerUpdateClients: Buscar con grep
- FrameUpdateClients: Buscar con grep

**Estimado:** ~100-150 líneas

---

## 🔄 FASE 4: SISTEMA DE EVENTOS

### systems/st_events.inc

**Event Hooks a extraer:**

```sourcepawn
// Eventos de ronda
HookEvent("round_start", Round_Start)
HookEvent("round_end", Round_End)

// Eventos de jugador
HookEvent("player_death", Player_Death)
HookEvent("player_spawn", Player_Spawn)
HookEvent("player_use", Player_Use)
HookEvent("player_now_it", Player_Now_It)
HookEvent("ability_use", Ability_Use)

// Eventos de finale
HookEvent("finale_start", Finale_Start)
HookEvent("finale_win", Finale_Win)
HookEvent("finale_escape_start", Finale_Escape_Start)
HookEvent("finale_vehicle_leaving", Finale_Vehicle_Leaving)

// Eventos de dificultad
HookEvent("difficulty_changed", Difficulty_Changed)

// Forwards
OnMapStart()
OnClientPostAdminCheck(client)
OnClientDisconnect(client)
OnEntityCreated(entity, classname[])
OnEntityDestroyed(entity)
OnGameFrame()
```

**Estimado:** ~300-350 líneas

---

## 🔄 FASE 5: SISTEMA BASE DE TANQUES

### tanks/st_tank_base.inc

**Funciones críticas:**

```sourcepawn
// Asignación de tipo de tanque
RandomizeTank(client)
- Selecciona tipo aleatorio
- Aplica configuración
- ~80 líneas

// Control principal de tanques
TankController()
- Loop principal de tanques
- Gestiona habilidades
- ~150 líneas

// Muerte de tanque
ExecTankDeath(client)
- Limpieza de estados
- Efectos de muerte
- ~50 líneas

// Lanzamiento de rocas
Rock throw mechanics
- Control de intervalo
- Aplicación por tipo
- ~40 líneas
```

**Ubicación en original:**
- RandomizeTank: Buscar "RandomizeTank"
- TankController: Buscar "TankController"
- ExecTankDeath: Buscar "ExecTankDeath"

**Estimado:** ~200-300 líneas

---

## 🔄 FASE 6: SISTEMAS DE JUEGO

### systems/st_damage.inc

**Componentes:**

```sourcepawn
// Daño a jugadores
public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
- Inmunidad al fuego
- Daño de tanques especiales
- ~200 líneas

// Daño a entidades
public Action:OnEntityTakeDamage(entity, &attacker, &inflictor, &Float:damage, &damagetype)
- Daño a tanques
- Escudos
- ~200 líneas

// Funciones auxiliares
DealDamagePlayer(client, damage, attacker)
DealDamageEntity(entity, damage, attacker)
- ~50 líneas
```

**Estimado:** ~400-500 líneas

### systems/st_effects.inc

**Componentes:**

```sourcepawn
// Partículas
CreateParticle(entity, particle_name[], Float:pos[3])
AttachParticle(entity, particle_name[])
AttachParticleLoc(entity, particle_name[], Float:offset[3])

// Efectos de pantalla
PerformFade(client, duration, color[4], flags)
ScreenShake(client, amplitude, duration)
BlurEffect(client)
RemoveBlurEffect(client)

// Colores
SetEntRenderColor(entity, r, g, b)
SetEntGlowColor(entity, r, g, b)
```

**Estimado:** ~300-350 líneas

### systems/st_spawning.inc

**Componentes:**

```sourcepawn
// Spawn de infectados
SpawnInfectedInterval()
- Control de spawn periódico
- ~100 líneas

// Spawn de tanques
SpawnTankTimer()
TimerTankWave2()
TimerTankWave3()
- Spawns por oleadas
- ~150 líneas

// Funciones auxiliares
ForceSpawnInfected()
SpawnInfectedBot(type)
- ~50 líneas
```

**Estimado:** ~250-300 líneas

### systems/st_finale.inc

**Componentes:**

```sourcepawn
// Event handlers
Finale_Start(Handle:event, const String:name[], bool:dontBroadcast)
Finale_Win(Handle:event, const String:name[], bool:dontBroadcast)
Finale_Escape_Start(Handle:event, const String:name[], bool:dontBroadcast)
Finale_Vehicle_Leaving(Handle:event, const String:name[], bool:dontBroadcast)

// Datos de mapa
ReturnChapterData()
- Determina mapa/capítulo
- ~100 líneas

// Control de finale
Finale stage management
- ~100 líneas
```

**Estimado:** ~200-250 líneas

---

## 🔄 FASE 7: TANQUES INDIVIDUALES (16 módulos)

Cada tanque tiene su propio módulo con:

```sourcepawn
// Ejemplo: tanks/st_tank_smasher.inc

// Habilidad principal
SkillSmashClaw(target)
- Ataque aplastante
- ~30 líneas

// Timer específico
Timer_SmashClawKill(Handle:timer, any:client)
- Mata después del aplaste
- ~20 líneas

// Control por frame
SmasherTankThink(tank)
- Actualización continua
- ~30 líneas

// Efectos
SmasherEffects(tank)
- Partículas, sonidos
- ~20 líneas
```

**Tanques a crear (16):**
1. st_tank_smasher.inc (~100 líneas)
2. st_tank_warp.inc (~100 líneas)
3. st_tank_meteor.inc (~200 líneas)
4. st_tank_spitter.inc (~100 líneas)
5. st_tank_heal.inc (~80 líneas)
6. st_tank_fire.inc (~100 líneas)
7. st_tank_ice.inc (~100 líneas)
8. st_tank_jockey.inc (~120 líneas)
9. st_tank_ghost.inc (~120 líneas)
10. st_tank_shock.inc (~150 líneas)
11. st_tank_witch.inc (~250 líneas) + manejo de witches
12. st_tank_shield.inc (~150 líneas)
13. st_tank_cobalt.inc (~100 líneas)
14. st_tank_jumper.inc (~100 líneas)
15. st_tank_gravity.inc (~150 líneas)
16. st_tank_demon.inc (~150 líneas)

**Total estimado:** ~2,000 líneas

---

## 🔄 FASE 8: MODO PESADILLA (4 módulos)

### nightmare/st_nightmare_core.inc

```sourcepawn
// Control principal
ExecNightmare()
- Loop principal del modo
- ~150 líneas

// Countdown
StartCountdown()
- Sistema de cuenta regresiva
- ~50 líneas

// Comando
Command_Nightmare(client, args)
- Activar/desactivar
- ~30 líneas

// Callbacks
NightmareChanged()
NightmareBeginChanged()
- ~50 líneas
```

**Estimado:** ~300 líneas

### nightmare/st_nightmare_difficulty.inc

```sourcepawn
// Auto-dificultad
AutoDifficulty(reset)
- Ajuste automático
- ~100 líneas

// Configurar dificultad
SetGameDifficulty(difficulty)
- Aplica configuración
- ~50 líneas

// Multiplicadores
CalculateDifficultyMultipliers()
- Cálculos de escalado
- ~50 líneas
```

**Estimado:** ~200 líneas

### nightmare/st_nightmare_spawning.inc

```sourcepawn
// Spawn mejorado
Enhanced spawn system
- Spawn más agresivo
- ~100 líneas

// Control de intervalos
Spawn rate management
- ~50 líneas
```

**Estimado:** ~150 líneas

### nightmare/st_nightmare_environment.inc

```sourcepawn
// Control de niebla
EnableFogRealism()
DisableFogRealism()
RenableFogRealism()
- ~100 líneas

// Corrección de color
CreateColorCorrection()
- ~50 líneas

// Puertas de saferoom
CloseSRDoor()
IdentifySRDoor()
- ~50 líneas
```

**Estimado:** ~200 líneas

---

## 📊 RESUMEN DE TRABAJO RESTANTE

| Fase | Módulos | Líneas Est. | Prioridad |
|------|---------|-------------|-----------|
| 3. Timers | 1 | ~150 | Alta |
| 4. Events | 1 | ~350 | Alta |
| 5. Tank Base | 1 | ~250 | Alta |
| 6. Systems | 4 | ~1,500 | Media |
| 7. Tanks | 16 | ~2,000 | Media |
| 8. Nightmare | 4 | ~850 | Baja |
| **TOTAL** | **27** | **~5,100** | - |

**Nota:** El estimado es mayor que las líneas restantes (3,612) porque incluye:
- Refactorización
- Documentación inline
- Include guards
- Funciones auxiliares adicionales

---

## 🚀 ORDEN RECOMENDADO DE IMPLEMENTACIÓN

### Semana 1: Core Essentials
1. ✅ Timers (st_timers.inc)
2. ✅ Events (st_events.inc)
3. ✅ Tank Base (st_tank_base.inc)

**Resultado:** Plugin básico funcional con tanques pero sin habilidades especiales

### Semana 2: Game Systems
4. ✅ Damage (st_damage.inc)
5. ✅ Effects (st_effects.inc)
6. ✅ Spawning (st_spawning.inc)
7. ✅ Finale (st_finale.inc)

**Resultado:** Sistemas de juego completos

### Semana 3-4: Tank Abilities
8-23. ✅ 16 módulos de tanques individuales

**Resultado:** Todas las habilidades de tanques funcionando

### Semana 5: Nightmare Mode
24-27. ✅ 4 módulos de pesadilla

**Resultado:** Modo pesadilla completo

---

## 🛠️ HERRAMIENTAS PARA ACELERAR

### Script de Extracción Automática

```python
# extract_function.py
# Extrae funciones específicas del archivo original

import sys
import re

def extract_function(source_file, function_name):
    with open(source_file, 'r') as f:
        lines = f.readlines()

    in_function = False
    brace_count = 0
    function_lines = []

    for line in lines:
        if function_name in line and ('public' in line or 'stock' in line):
            in_function = True

        if in_function:
            function_lines.append(line)
            brace_count += line.count('{') - line.count('}')

            if brace_count == 0 and len(function_lines) > 1:
                break

    return ''.join(function_lines)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python extract_function.py <source_file> <function_name>")
        sys.exit(1)

    result = extract_function(sys.argv[1], sys.argv[2])
    print(result)
```

### Comandos Útiles

```bash
# Buscar todas las funciones de un tanque específico
grep -n "Smasher\|SkillSmashClaw" Natan_SuperTanks_Nightmare.sp

# Extraer rango de líneas específico
sed -n '1000,1500p' Natan_SuperTanks_Nightmare.sp > temp_extract.sp

# Contar líneas de una función
grep -A 100 "public Action:TimerUpdate01" Natan_SuperTanks_Nightmare.sp | head -50
```

---

## ✅ CHECKLIST POR MÓDULO

Al crear cada módulo:

- [ ] Incluir include guard
- [ ] Documentar funciones principales
- [ ] Mantener nombres de funciones originales
- [ ] Compilar después de cada módulo
- [ ] Agregar include en el archivo principal
- [ ] Actualizar MODULARIZATION_STATUS.md
- [ ] Probar funcionalidad básica

---

## 📝 PLANTILLA PARA NUEVOS MÓDULOS

```sourcepawn
#if defined _st_module_name_included
 #endinput
#endif
#define _st_module_name_included

// ============================================================================
// MODULE NAME
// Description of what this module does
// ============================================================================

/**
 * Function description
 *
 * @param param1    Description
 * @return          Description
 */
stock FunctionName(param1)
{
    // Implementation
}

// ============================================================================
// ADDITIONAL FUNCTIONS
// ============================================================================

// More functions here...
```

---

## 🎯 META FINAL

**Plugin 100% Funcional y Modular**

- ✅ Todos los 16 tanques con habilidades
- ✅ Modo pesadilla completo
- ✅ Todos los sistemas funcionando
- ✅ Código limpio y organizado
- ✅ Fácil de mantener y extender
- ✅ Documentación completa

**Beneficios:**
- Agregar nuevos tanques: Solo crear un nuevo archivo .inc
- Modificar habilidades: Editar solo el archivo del tanque específico
- Debugging: Más fácil localizar problemas
- Colaboración: Múltiples desarrolladores trabajando en paralelo

---

*Documento generado: 2025-01-06*
*Estado: 37% completado, base funcional establecida*
