# Guía de Configuración - HUD Dinámico del Sistema !buy

## Introducción
El módulo `hud-system-display.feature.sp` extiende `l4d2_scripted_hud.sp` para mostrar información en tiempo real del sistema !buy (Eclipse Management System).

## Configuración Básica

### Habilitar los HUDs

En el archivo de configuración de l4d2_scripted_hud (típicamente `cfg/sourcemod/l4d2_scripted_hud.cfg`):

```cfg
// ===== HUD 2 - TEAM BONUSES =====
sm_hud2_enabled         "1"      // Activar/desactivar HUD 2
sm_hud2_visible         "1"      // Hacer visible el HUD
sm_hud2_text_align      "1"      // 1=Izquierda, 2=Centro, 3=Derecha
sm_hud2_background      "1"      // Mostrar fondo
sm_hud2_team            "0"      // 0=Todos, 1=Survivors, 2=Infected
sm_hud2_blink           "0"      // Parpadear
sm_hud2_beep            "0"      // Sonar

// ===== Posición HUD 2 =====
sm_hud2_posX            "0.01"   // 0.0=Izquierda, 1.0=Derecha
sm_hud2_posY            "0.01"   // 0.0=Arriba, 1.0=Abajo
sm_hud2_width           "300"    // Ancho del HUD
sm_hud2_height          "150"    // Alto del HUD

// ===== HUD 3 - DEPLOYABLES =====
sm_hud3_enabled         "1"      // Activar/desactivar HUD 3
sm_hud3_visible         "1"      // Hacer visible el HUD
sm_hud3_text_align      "1"      // 1=Izquierda, 2=Centro, 3=Derecha
sm_hud3_background      "1"      // Mostrar fondo
sm_hud3_team            "0"      // 0=Todos, 1=Survivors, 2=Infected
sm_hud3_blink           "0"      // Parpadear
sm_hud3_beep            "0"      // Sonar

// ===== Posición HUD 3 =====
sm_hud3_posX            "0.01"   // 0.0=Izquierda, 1.0=Derecha
sm_hud3_posY            "0.10"   // 0.0=Arriba, 1.0=Abajo (debajo del HUD 2)
sm_hud3_width           "300"    // Ancho del HUD
sm_hud3_height          "150"    // Alto del HUD
```

## Layouts Recomendados

### Layout 1: Esquina Superior Izquierda (Defecto)
```cfg
sm_hud2_posX    "0.01"
sm_hud2_posY    "0.01"
sm_hud3_posX    "0.01"
sm_hud3_posY    "0.12"
```

**Resultado Visual**:
```
┌─────────────────────┐
│ === TEAM BONUSES == │  <- HUD 2
│ Speed Boost: 4:32   │
│ Team Heal CD: 25s   │
│ Survivors: 4/4      │
└─────────────────────┘
┌─────────────────────┐
│ === DEPLOYABLES === │  <- HUD 3
│ UV Light: 250s      │
│ Healing Station: 180│
└─────────────────────┘
```

### Layout 2: Esquina Superior Derecha
```cfg
sm_hud2_posX    "0.70"
sm_hud2_posY    "0.01"
sm_hud2_text_align  "3"  // Alineación a la derecha
sm_hud3_posX    "0.70"
sm_hud3_posY    "0.12"
sm_hud3_text_align  "3"
```

### Layout 3: Esquina Inferior Izquierda
```cfg
sm_hud2_posX    "0.01"
sm_hud2_posY    "0.85"
sm_hud3_posX    "0.01"
sm_hud3_posY    "0.92"
```

### Layout 4: Centro Superior
```cfg
sm_hud2_posX    "0.35"
sm_hud2_posY    "0.01"
sm_hud2_text_align  "2"  // Centro
sm_hud3_posX    "0.35"
sm_hud3_posY    "0.10"
sm_hud3_text_align  "2"
```

## Personalización Avanzada

### Mostrar Solo Team Bonuses (Desactivar Deployables)
```cfg
sm_hud2_enabled  "1"
sm_hud3_enabled  "0"
```

### Mostrar Solo Deployables
```cfg
sm_hud2_enabled  "0"
sm_hud3_enabled  "1"
```

### Solo Survivors Ven los HUDs
```cfg
sm_hud2_team    "1"  // 1 = Team Survivors
sm_hud3_team    "1"
```

### Habilitar Efectos de Parpadeo
```cfg
sm_hud2_blink   "1"  // Parpadear cuando el Speed Boost está activo
sm_hud3_blink   "1"
```

### HUDs Animados
```cfg
// Mover HUD2 horizontalmente
sm_hud2_x_speed     "10.0"      // Velocidad de movimiento en X
sm_hud2_x_direction "0"         // 0=Izquierda a Derecha, 1=Contrario
sm_hud2_x_min       "0.01"      // Posición mínima en X
sm_hud2_x_max       "0.70"      // Posición máxima en X
```

## Resolución y Escalado

### Ajustar Ancho y Alto según Resolución

**Para 1920x1080**:
```cfg
sm_hud2_width   "350"
sm_hud2_height  "160"
sm_hud3_width   "350"
sm_hud3_height  "160"
```

**Para 1280x720**:
```cfg
sm_hud2_width   "250"
sm_hud2_height  "120"
sm_hud3_width   "250"
sm_hud3_height  "120"
```

## Solución de Problemas

### El HUD no aparece
1. Verificar que `sm_hud2_enabled` = "1"
2. Verificar que `sm_hud2_visible` = "1"
3. Comprobar que la posición (X, Y) está dentro del rango 0.0-1.0
4. Recargar plugins: `sm reload l4d2_scripted_hud`

### El HUD aparece pero sin actualizar
1. Verificar que `hud-system-display.feature.sp` está compilado
2. Comprobar en la consola: `sm plugins list` (buscar "Eclipse management system")
3. Verificar que el timer está ejecutándose sin errores

### El HUD muestra información de Tank en lugar de Team Bonuses
1. Esto significa que el módulo HUD Display no está disponible
2. Recompilar Eclipse Management System principal
3. Verificar includes en `buy-menu.module.sp`

### Conflictos de HUD
Si otros plugins usan los slots HUD 2 y 3:
- Cambiar a usar HUD 1 o HUD 4
- Editar las llamadas en `l4d2_scripted_hud.sp` a otros slots disponibles

## Monitoreo

### Verificar que el módulo está activo
En consola del servidor:
```
sm plugins list | grep Eclipse
```

Debería mostrar:
```
[OK] Eclipse management system
```

### Ver logs
```
tail -f logs/Eclipse_Management_System.log | grep "HUD Display"
```

## Personalización Avanzada: Extender el Módulo

Si deseas agregar más datos a los HUDs, edita `hud-system-display.feature.sp`:

```sourcepawn
// Agregar nueva información en BuildTeamBonusesHUDText()
static void BuildTeamBonusesHUDText()
{
    // ... código existente ...

    // Ejemplo: Agregar información de Ion Cannon
    float ionTime = GetIonCannonRemaining(client);
    if (ionTime > 0.0)
    {
        Format(tempBuffer, sizeof(tempBuffer), "Ion Cannon: %.1fs\n", ionTime);
        StrCat(buffer, sizeof(buffer), tempBuffer);
    }
}
```

## Cambios en Tiempo Real

Para cambiar la configuración sin recargar:
```
sm_hud2_posX "0.5"        // Cambiar posición en tiempo real
sm_hud2_visible "0"       // Ocultar HUD
sm_hud2_visible "1"       // Mostrar HUD
```

## Integración con Otros Plugins

El módulo HUD Display es completamente independiente de l4d2_scripted_hud:
- Si l4d2_scripted_hud no está cargado, no hay error
- Si hud-system-display no está disponible, muestra comportamiento original

Esto hace que sea seguro agregarlos/quitarlos en cualquier momento.

## Notas Finales

- Los cambios en configuración aplican inmediatamente
- No requiere reconexión de jugadores
- Soporta Hot-reload de plugins
- Es compatible con todas las resoluciones y relaciones de aspecto
