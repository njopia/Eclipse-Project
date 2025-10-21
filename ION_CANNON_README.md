# Ion Cannon v2.0.0 - Buy System Ready

## 🎯 Descripción

Ion Cannon es un plugin espectacular para Left 4 Dead 2 que permite a los jugadores invocar un devastador ataque orbital con efectos visuales dramáticos. Esta versión 2.0.0 está completamente integrada con sistemas de compras mediante una API pública de natives y forwards.

---

## ✨ Características Principales

### Sistema de Compras
- ✅ **API Nativa completa** para integración con plugins de puntos/tiendas
- ✅ **Sistema de cargas** configurable (por defecto: 3 cargas máximo)
- ✅ **Cooldown** entre usos (por defecto: 45 segundos)
- ✅ **Tracking de kills** para recompensar puntos
- ✅ **Forwards** para notificar activación y finalización

### Efectos Visuales
- ⚡ Rayos láser orbitales rotatorios (6 beams)
- 💥 Anillos de energía expansivos (3 anillos grandes)
- 🔥 Rayo central masivo desde el cielo
- ✨ Múltiples explosiones con partículas
- 🌟 Bengala visual con spotlight

### Efectos de Daño
- 🔥 **Quemado masivo** de infectados en área
- 💀 **Daño continuo** cada 3 segundos
- 🎯 **SOLO daña infectados** (team 3), nunca a sobrevivientes
- 📊 **Tracking de kills** para estadísticas

### Feedback Visual/Audio
- 🎵 Sonidos de láser, explosiones variadas
- 📢 Mensajes en chat con información de cargas
- 🎮 HUD dinámico con estado del Ion Cannon
- ✅ Sonido de confirmación al activar
- ❌ Sonido de error en cooldown/sin cargas

---

## 📦 Instalación

### 1. Archivos Principales
```
addons/sourcemod/plugins/ion.smx
addons/sourcemod/scripting/ion.sp
addons/sourcemod/scripting/include/ion_cannon.inc
```

### 2. Compilación
```bash
cd addons/sourcemod/scripting
spcomp ion.sp
```

### 3. Configuración
El archivo de configuración se genera automáticamente:
```
cfg/sourcemod/ion_cannon_optimized.cfg
```

---

## 🎮 Comandos

### Comandos de Usuario
| Comando | Descripción | Acceso |
|---------|-------------|--------|
| `!ion` / `sm_ion` | Activar Ion Cannon (consume 1 carga) | Usuarios con flag configurado |
| `sm_ion_info [jugador]` | Ver información del Ion Cannon | Todos |

### Comandos de Administración
| Comando | Descripción | Acceso |
|---------|-------------|--------|
| `sm_ion_give <jugador> <cantidad>` | Otorgar cargas | ADMFLAG_CHEATS |
| `sm_ion_reset <jugador>` | Resetear cooldown | ADMFLAG_CHEATS |
| `sm_ion_info <jugador>` | Ver stats de jugador | ADMFLAG_GENERIC |

---

## ⚙️ ConVars

### Visuales
```cfg
ic_model_flare "models/props_unique/hospital/iv_pole.mdl"
ic_sound_crackle "ambient/energy/zap9.wav"
ic_sound_ion "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
ic_particle_flare "weapon_pipebomb"
ic_sprite_beam "materials/sprites/laserbeam.vmt"
ic_sprite_halo "materials/sprites/halo01.vmt"
```

### Temporización
```cfg
ic_delay 10.0              // Segundos hasta primera explosión
ic_window 17.0             // Duración total del efecto
ic_pulse_every 3.0         // Frecuencia de daño continuo
ic_tick_rotate 0.5         // Intervalo rayos orbitales
ic_tick_ring 5.0           // Intervalo anillos grandes
ic_tick_center 1.5         // Intervalo rayo central
```

### Daño
```cfg
ic_dmg_common 10           // Daño a infectados comunes
ic_dmg_si 10               // Daño a infectados especiales
```

### Sistema de Compras (NUEVO)
```cfg
ic_max_charges 3           // Máximo de cargas por jugador
ic_cooldown 45.0           // Cooldown entre usos (segundos)
ic_charges_per_round 1     // Cargas restauradas al inicio de ronda
ic_charges_on_buy 1        // Cargas otorgadas al comprar
```

### Screen Shake
```cfg
ic_shake_r1 900            // Radio shake fuerte
ic_shake_r2 1800           // Radio shake medio
ic_shake_r3 2600           // Radio shake suave
```

### Permisos
```cfg
ic_access_flag ""          // Flag requerido (vacío = todos)
```

---

## 🔌 API para Desarrolladores

### Incluir el API
```sourcepawn
#include <ion_cannon>
```

### Natives Disponibles

#### Ion_CanUse
```sourcepawn
/**
 * Verifica si un cliente puede usar el Ion Cannon
 * @param client    Índice del cliente
 * @return          true si puede usarlo, false si no
 */
native bool Ion_CanUse(int client);
```

#### Ion_Activate
```sourcepawn
/**
 * Activa el Ion Cannon (llamado desde sistema de compras)
 * @param client    Índice del cliente
 * @return          true si se activó, false si falló
 */
native bool Ion_Activate(int client);
```

#### Ion_GetCooldown
```sourcepawn
/**
 * Obtiene el cooldown restante
 * @param client    Índice del cliente
 * @return          Segundos restantes (0 = disponible)
 */
native float Ion_GetCooldown(int client);
```

#### Ion_GetCharges
```sourcepawn
/**
 * Obtiene las cargas restantes
 * @param client    Índice del cliente
 * @return          Número de cargas
 */
native int Ion_GetCharges(int client);
```

#### Ion_SetCharges
```sourcepawn
/**
 * Establece las cargas de un cliente
 * @param client    Índice del cliente
 * @param charges   Número de cargas
 */
native void Ion_SetCharges(int client, int charges);
```

### Forwards Disponibles

#### Ion_OnActivate
```sourcepawn
/**
 * Llamado cuando el Ion Cannon se activa
 * @param client    Cliente que lo activó
 */
forward void Ion_OnActivate(int client);
```

#### Ion_OnComplete
```sourcepawn
/**
 * Llamado cuando el Ion Cannon termina
 * @param client    Cliente
 * @param kills     Infectados eliminados (para recompensar puntos)
 */
forward void Ion_OnComplete(int client, int kills);
```

---

## 📝 Ejemplo de Integración

Ver archivo completo: `scripting/ion_buy_example.sp`

```sourcepawn
#include <sourcemod>
#include <ion_cannon>

public Action Cmd_BuyIon(int client, int args)
{
    int cost = 5000;

    // Verificar si puede usar
    if (!Ion_CanUse(client))
    {
        float cooldown = Ion_GetCooldown(client);
        PrintToChat(client, "Cooldown: %.0fs", cooldown);
        return Plugin_Handled;
    }

    // Verificar puntos (tu sistema)
    if (GetClientPoints(client) < cost)
    {
        PrintToChat(client, "Puntos insuficientes!");
        return Plugin_Handled;
    }

    // Cobrar puntos
    SetClientPoints(client, GetClientPoints(client) - cost);

    // Activar Ion Cannon
    if (Ion_Activate(client))
    {
        PrintToChat(client, "Ion Cannon activado!");
    }

    return Plugin_Handled;
}

// Recompensar puntos por kills
public void Ion_OnComplete(int client, int kills)
{
    int bonus = kills * 10;
    SetClientPoints(client, GetClientPoints(client) + bonus);
    PrintToChat(client, "Bonus: +%d puntos (%d kills)", bonus, kills);
}
```

---

## 💰 Balance Sugerido

```
Costo de compra: 3000-5000 puntos
Cooldown: 45-60 segundos
Cargas por compra: 1 uso
Bonus por kill: 10-20 puntos/kill
Kills promedio: 15-30 infectados
ROI: ~300-600 puntos (10-20% del costo)
```

---

## 🔧 Solución de Problemas

### El Ion no hace daño
- Verificar que `ic_dmg_common` y `ic_dmg_si` sean > 0
- Verificar que haya infectados en el radio (800 unidades)

### No se ven los efectos visuales
- Verificar que los sprites estén correctamente precached
- Revisar los logs en `addons/sourcemod/logs/ion_cannon.log`

### Cooldown no funciona
- Verificar `ic_cooldown` en el cfg
- Usar `sm_ion_info` para ver el estado actual

### Natives no disponibles
- Verificar que `ion.smx` esté cargado
- Incluir `#include <ion_cannon>` en tu plugin
- Recompilar con `ion_cannon.inc` en la carpeta include

---

## 📊 Changelog

### v2.0.0 (2025-01-XX)
- ✅ Sistema completo de API nativa para buy systems
- ✅ Sistema de cargas y cooldown
- ✅ Tracking de kills para recompensas
- ✅ Forwards para eventos (OnActivate, OnComplete)
- ✅ Comandos de administración (give, reset, info)
- ✅ Feedback visual/audio mejorado
- ✅ Archivo .inc para desarrolladores
- ✅ Plugin de ejemplo funcional

### v1.2.0
- Optimización de precache
- Limpieza de sonidos duplicados
- Sistema de debug mejorado

---

## 👨‍💻 Créditos

- **Author**: Socius (port + optimizer + buy integration)
- **Version**: 2.0.0
- **Game**: Left 4 Dead 2

---

## 📄 Licencia

Este plugin es de código abierto. Libre para usar y modificar.

---

## 🆘 Soporte

Para reportar bugs o solicitar features:
1. Revisar los logs en `addons/sourcemod/logs/ion_cannon.log`
2. Verificar que todas las ConVars estén correctamente configuradas
3. Usar `sm_ion_info` para debugging

---

¡Disfruta del poder del Ion Cannon! ⚡💥
