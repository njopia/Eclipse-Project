# Eclipse L4D2 - Referencia Rápida de Comandos

## 🎮 Comandos de Dificultad

### Comandos Completos

| Comando | Descripción | Permiso |
|---------|-------------|---------|
| `sm_diffmode <modo>` | Cambiar modo de dificultad | ROOT |
| `sm_diffmode status` | Ver estado actual | ROOT |
| `sm_resetprogression` | Resetear progresión | ROOT |

**Modos disponibles:** `none`, `bloodmoon`, `hell`, `inferno`, `cowlevel`

### ⚡ Alias Cortos (NUEVOS)

| Comando | Equivalente a | Descripción |
|---------|---------------|-------------|
| `sm_bm` | `sm_diffmode bloodmoon` | Activar Bloodmoon |
| `sm_cow` | `sm_diffmode cowlevel` | Activar Cow Level |
| `sm_diffstatus` | `sm_diffmode status` | Ver estado |
| `sm_diffreset` | `sm_resetprogression` | Resetear |

### Ejemplos de Uso

```bash
# Activar Bloodmoon (método largo)
sm_diffmode bloodmoon

# Activar Bloodmoon (método corto)
sm_bm

# Activar Cow Level
sm_cow

# Ver estado actual
sm_diffstatus

# Desactivar todos los modos
sm_diffmode none

# Resetear progresión a 0
sm_diffreset
```

## 🔧 ConVars de Modos

### Activación Directa

```bash
bloodmoon_enable 1       # Activa Bloodmoon
bloodmoon_enable 0       # Desactiva Bloodmoon

cowlevel_enable 1        # Activa Cow Level
cowlevel_enable 0        # Desactiva Cow Level
```

**Nota:** Con `difficulty_mutual_exclusion 1` (default), activar un modo desactiva automáticamente el otro.

## ⚙️ ConVars del Orquestador

### Configuración General

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `difficulty_orchestrator_enable` | 1 | Habilita el orquestador |
| `difficulty_mutual_exclusion` | 1 | Solo un modo activo a la vez |
| `difficulty_progression_enable` | 1 | Progresión automática al ganar |
| `difficulty_auto_unlock` | 1 | Desbloqueo automático |

### Ejemplos

```bash
# Permitir múltiples modos simultáneos (testing)
difficulty_mutual_exclusion 0

# Deshabilitar progresión automática
difficulty_progression_enable 0

# Deshabilitar completamente el orquestador
difficulty_orchestrator_enable 0
```

## 🌙 ConVars de Bloodmoon

### Configuración Principal

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `bloodmoon_enable` | 0 | Activar/desactivar Bloodmoon |
| `bloodmoon_damage_mult` | 1.35 | Multiplicador de daño |
| `bloodmoon_fade` | 1 | Efecto fade rojo |
| `bloodmoon_change_difficulty` | 1 | Cambiar a Experto |

### Configuración de Director

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `bloodmoon_common_limit` | 45 | Límite de zombies comunes |
| `bloodmoon_mob_min` | 25 | Tamaño mínimo de horda |
| `bloodmoon_mob_max` | 35 | Tamaño máximo de horda |
| `bloodmoon_mega_mob` | 60 | Tamaño de mega horda |

### Eventos Automáticos

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `bloodmoon_tank_spawn` | 1 | Spawn automático de tanks |
| `bloodmoon_tank_interval` | 60.0 | Intervalo entre tanks (segundos) |
| `bloodmoon_panic_events` | 1 | Panic events periódicos |
| `bloodmoon_panic_interval` | 45.0 | Intervalo entre panics (segundos) |
| `bloodmoon_breeder_events` | 1 | Eventos de breeder |
| `bloodmoon_breeder_chance` | 25 | Probabilidad 1/N de breeder |

### Efectos Visuales

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `bloodmoon_color_correction` | 1 | Post-processing |
| `bloodmoon_color_file` | `materials/correction/ghost.raw` | Archivo de color |
| `bloodmoon_color_weight` | 0.4 | Intensidad (0.0-1.0) |
| `bloodmoon_use_precipitation` | 1 | Usar precipitación |
| `bloodmoon_precip_type` | 3 | Tipo: 1=lluvia 2=ceniza 3=nieve 4=lluvia_l4d |
| `bloodmoon_lightstyle` | b | LightStyle a aplicar |
| `bloodmoon_fog_enable` | 1 | Habilitar niebla |

## 🐄 ConVars de Cow Level

### Configuración Principal

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `cowlevel_enable` | 0 | Activar/desactivar Cow Level |
| `cowlevel_panic_interval` | 45.0 | Intervalo entre panic events |
| `cowlevel_remove_specials` | 1 | Remover infectados especiales |

### Efectos Visuales

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `cowlevel_color_correction` | 1 | Post-processing |
| `cowlevel_color_file` | `materials/correction/thirdstrike.raw` | Archivo de color |
| `cowlevel_color_weight` | 0.5 | Intensidad (0.0-1.0) |

### Sonidos

| ConVar | Default | Descripción |
|--------|---------|-------------|
| `cowlevel_megamob_sound` | 1 | Sonidos de mega mob |
| `cowlevel_megamob_sound_chance` | 15 | Probabilidad 1/N |

## 📊 Progresión de Dificultad

### Sistema de Unlock

```
Normal Campaign Win
    ↓
Bloodmoon (desbloqueado)
    ↓
Hell (immediate unlock)
    ↓
Inferno (2 victorias requeridas)
    ↓
Cow Level (2 victorias requeridas)
    ↓
¡Completado!
```

### Ver Progreso

```bash
sm_diffstatus
```

Muestra:
- Modo actual activo
- Número de victorias en modo actual
- Estado de mutual exclusion
- Estado de auto-progresión

## 🎯 Escenarios Comunes

### Testing de Modos

```bash
# Permitir múltiples modos activos
difficulty_mutual_exclusion 0

# Activar ambos
bloodmoon_enable 1
cowlevel_enable 1

# Ver estado
sm_diffstatus
```

### Producción Normal

```bash
# Mutual exclusion activa (default)
difficulty_mutual_exclusion 1

# Cambiar entre modos
sm_bm              # Solo Bloodmoon
sm_cow             # Solo Cow Level (Bloodmoon se desactiva)
```

### Resetear Todo

```bash
# Opción 1: Comando
sm_diffreset

# Opción 2: ConVar
difficulty_orchestrator_enable 0
```

## 🔐 Permisos

Todos los comandos `sm_*` requieren:
```
ADMFLAG_ROOT
```

Los ConVars pueden ser cambiados por admins con acceso a:
```
rcon
```

## 📝 Notas Importantes

1. **Mutual Exclusion está ACTIVADA por default** - Solo un modo a la vez
2. **Los comandos alias son más rápidos** - Usa `sm_bm` en vez de `sm_diffmode bloodmoon`
3. **ConVars también activan mutual exclusion** - `bloodmoon_enable 1` desactivará Cow Level
4. **La progresión es automática** - Al ganar campañas se desbloquean nuevos modos
5. **Map start delay** - Eventos no se ejecutan durante los primeros 10 segundos

## 🆘 Troubleshooting

### El modo no se activa

```bash
# Verificar que el orquestador esté habilitado
difficulty_orchestrator_enable 1

# Verificar estado
sm_diffstatus
```

### Múltiples modos activos

```bash
# Verificar mutual exclusion
difficulty_mutual_exclusion 1

# Forzar desactivación
sm_diffmode none
sm_bm
```

### Progresión no funciona

```bash
# Verificar auto-unlock
difficulty_auto_unlock 1

# Verificar progresión
difficulty_progression_enable 1

# Ver estado
sm_diffstatus
```

## 📚 Más Información

- **Documentación Completa:** `DIFFICULTY_ORCHESTRATOR.md`
- **Review de Modos:** `REVIEW_MODES.md`
- **Logs:** `addons/sourcemod/logs/` (buscar "Difficulty Orchestrator")

---

**Última actualización:** 2025 - Eclipse Management System
