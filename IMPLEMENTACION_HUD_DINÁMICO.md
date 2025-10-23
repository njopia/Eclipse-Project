# Implementación: HUD Dinámico del Sistema !buy

## Descripción General
Se ha implementado un sistema de extensión para mostrar valores dinámicos del Eclipse Management System en el HUD scripted de L4D2.

## Archivos Modificados/Creados

### 1. **Nuevo Módulo Creado**
- **Archivo**: `scripting/modules/buy module/features/0-menu/hud-system-display.feature.sp`
- **Propósito**: Módulo extensor que captura datos dinámicos del sistema !buy y los formatea para mostrar en HUD
- **Características**:
  - Timer actualizado cada 0.5 segundos
  - Construye texto para HUD2 (Team Bonuses)
  - Construye texto para HUD3 (Deployables)
  - Funciones stock para acceso desde l4d2_scripted_hud.sp

### 2. **Archivo Modificado: buy-menu.module.sp**
- **Cambios**:
  - Agregado include: `#tryinclude "features/0-menu/hud-system-display.feature.sp"`
  - Agregada llamada en `buyMenuOnPluginStart()`: `HUDSystemDisplay_OnPluginStart();`

### 3. **Archivo Modificado: l4d2_scripted_hud.sp**
- **Cambios en GetHUD2_Text()**:
  - Intenta obtener datos del módulo HUD Display primero
  - Si existen datos del sistema !buy, los muestra
  - Si no, fallback a mostración de información de Tank (original)

- **Cambios en GetHUD3_Text()**:
  - Intenta obtener datos de deployables primero
  - Si existen datos, los muestra
  - Si no, fallback a mostración de salud de supervivientes (original)

## Datos Mostrados

### HUD2 - Team Bonuses
```
=== TEAM BONUSES ===
Speed Boost: 4:32
Team Heal: READY
Survivors: 4/4
```

### HUD3 - Deployables
```
=== DEPLOYABLES ===
UV Light: 250s
Healing Station: 180s
```

## Configuración

### En l4d2_scripted_hud.cfg
Para habilitar los HUDs:
```
sm_hud2_enabled        "1"         // Activar HUD2 (Team Bonuses)
sm_hud3_enabled        "1"         // Activar HUD3 (Deployables)
sm_hud2_visible        "1"         // Hacer visible HUD2
sm_hud3_visible        "1"         // Hacer visible HUD3
sm_hud2_posX          "0.01"       // Posición X (0.01 = izquierda)
sm_hud2_posY          "0.01"       // Posición Y (0.01 = arriba)
sm_hud3_posX          "0.01"       // Posición X
sm_hud3_posY          "0.10"       // Posición Y
```

## Funciones Disponibles

### Desde hud-system-display.feature.sp

```sourcepawn
// Inicializa el sistema de HUD dinámico
stock void HUDSystemDisplay_OnPluginStart()

// Obtiene el texto personalizado para HUD2 (Team Bonuses)
stock void GetTeamBonusesHUDText(char[] output, int size)

// Obtiene el texto personalizado para HUD3 (Deployables)
stock void GetDeployablesHUDText(char[] output, int size)
```

## Extensiones Futuras

### Funciones que pueden implementarse:

1. **Para UV Light**:
   - `IsUVLightActive(client)` - Verificar si está activo
   - `GetUVLightRemaining(client)` - Obtener tiempo restante

2. **Para Healing Station**:
   - `IsHealingStationActive(client)` - Verificar si está activo
   - `GetHealingStationRemaining(client)` - Obtener tiempo restante

3. **Para Team Heal**:
   - `GetTeamHealRemaining(client)` - Obtener tiempo restante del efecto (si se implementa)
   - Actualmente solo existe `GetTeamHealCooldown(client)`

### Cómo Implementarlas

En los archivos correspondientes (`uv-light.feature.sp`, `healing-station.feature.sp`):

```sourcepawn
// Agregar variables similares a Team Speed Boost
static float g_fUVLightEnd[MAXPLAYERS + 1];

// Agregar funciones de acceso
stock bool IsUVLightActive(int client)
{
    return g_fUVLightEnd[client] > GetGameTime();
}

stock float GetUVLightRemaining(int client)
{
    float remaining = g_fUVLightEnd[client] - GetGameTime();
    return (remaining > 0.0) ? remaining : 0.0;
}
```

## Ventajas del Sistema

✅ **Modular**: Cada feature puede proporcionear sus propios datos
✅ **Dinámico**: Se actualiza en tiempo real cada 0.5 segundos
✅ **Flexible**: Permite múltiples layouts de HUD
✅ **Backwards Compatible**: Si no hay datos del sistema, usa el comportamiento original
✅ **Escalable**: Fácil agregar más datos sin modificar l4d2_scripted_hud

## Compilación

```bash
# Compilar Eclipse Management System principal
spcomp.exe scripting/Eclipse Management System.sp

# El módulo se compila como parte del archivo principal
```

## Notas Técnicas

- El timer de actualización se ejecuta cada 0.5 segundos (configurable en `HUD_UPDATE_INTERVAL`)
- Los datos se almacenan en buffers globales: `g_sHUD2_CustomText` y `g_sHUD3_CustomText`
- Las funciones usan directivas `#if defined` para detección de disponibilidad
- El sistema es tolerante a fallos: si una función no existe, muestra el contenido original

## Testing

Para verificar que el sistema funciona:
1. Compilar y recargar plugins
2. Ver el HUD en la pantalla (posiciones configurables en cvar)
3. Activar un Team Bonus y verificar que se actualiza en tiempo real
4. Desplegar un deployable y verificar en HUD3

## Troubleshooting

**El HUD no aparece**:
- Verificar que `sm_hud2_enabled` y `sm_hud3_enabled` están en "1"
- Verificar la posición (X, Y) en los CVARs
- Verificar que `l4d2_scripted_hud.sp` está compilado correctamente

**Muestra información de Tank en lugar de Team Bonuses**:
- Significa que `GetTeamBonusesHUDText()` no está siendo llamado
- Verificar que `hud-system-display.feature.sp` está siendo incluido
- Verificar que `HUDSystemDisplay_OnPluginStart()` fue llamado
