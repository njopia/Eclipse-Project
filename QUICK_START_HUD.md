# Quick Start - HUD Dinámico del Sistema !buy

## 🚀 Inicio Rápido (30 segundos)

### 1. Compilar
```bash
spcomp.exe scripting/Eclipse Management System.sp
```

### 2. Recargar Plugins
```
sm reload l4d2_scripted_hud
sm reload Eclipse Management System
```

### 3. Configuración Básica (cfg/sourcemod/l4d2_scripted_hud.cfg)
```cfg
// Activar HUDs
sm_hud2_enabled     "1"
sm_hud3_enabled     "1"
sm_hud2_visible     "1"
sm_hud3_visible     "1"

// Posicionamiento
sm_hud2_posX        "0.01"
sm_hud2_posY        "0.01"
sm_hud3_posX        "0.01"
sm_hud3_posY        "0.12"
```

### 4. ¡Listo! Ahora verás:
```
┌─────────────────────┐
│ === TEAM BONUSES == │
│ Speed Boost: 5:00   │
│ Team Heal CD: 60s   │
│ Survivors: 4/4      │
└─────────────────────┘

┌─────────────────────┐
│ === DEPLOYABLES === │
│ UV Light: 299s      │
│ Healing: 298s       │
└─────────────────────┘
```

## 📋 Lo Que Se Muestra

### HUD2 - Team Bonuses
- **Team Speed Boost**: Tiempo restante del boost (MM:SS)
- **Team Heal**: Cooldown hasta que pueda activarse (segundos)
- **Survivors**: Contador de supervivientes activos

### HUD3 - Deployables
- **UV Light**: Tiempo restante en segundos
- **Healing Station**: Tiempo restante en segundos

## ⚙️ Configuración Esencial

| CVAR | Valor | Descripción |
|------|-------|-------------|
| `sm_hud2_enabled` | 1 | Activar HUD Team Bonuses |
| `sm_hud3_enabled` | 1 | Activar HUD Deployables |
| `sm_hud2_visible` | 1 | Hacer visible HUD2 |
| `sm_hud3_visible` | 1 | Hacer visible HUD3 |
| `sm_hud2_posX` | 0.01 | Posición X (0=izq, 1=der) |
| `sm_hud2_posY` | 0.01 | Posición Y (0=arriba, 1=abajo) |
| `sm_hud2_team` | 0 | Team (0=todos, 1=survivors) |

## 🎨 Layouts Rápidos

### Esquina Superior Izquierda (Defecto)
```cfg
sm_hud2_posX "0.01"
sm_hud2_posY "0.01"
sm_hud3_posX "0.01"
sm_hud3_posY "0.12"
```

### Esquina Superior Derecha
```cfg
sm_hud2_posX "0.70"
sm_hud2_posY "0.01"
sm_hud2_text_align "3"
sm_hud3_posX "0.70"
sm_hud3_posY "0.12"
```

### Centro Superior
```cfg
sm_hud2_posX "0.35"
sm_hud2_posY "0.01"
sm_hud2_text_align "2"
sm_hud3_posX "0.35"
sm_hud3_posY "0.10"
```

## 🔧 Problemas Comunes

| Problema | Solución |
|----------|----------|
| No aparece nada | Verificar `sm_hud2_enabled = 1` |
| Aparece pero no se actualiza | Recompilar Eclipse Management System |
| Muestra Tank info en lugar de Bonuses | Revisar compilación del módulo HUD |
| Solapamiento con otros HUDs | Cambiar posición con `sm_hud2_posX` |

## 📁 Archivos Modificados

- ✅ `scripting/modules/buy module/buy-menu.module.sp` - Include nuevo módulo
- ✅ `l4d2_scripted_hud.sp` - Integración de funciones dinámicas
- ✅ `scripting/modules/buy module/features/0-menu/hud-system-display.feature.sp` - NUEVO

## 📚 Documentación Completa

Para más detalles, lee:
- `IMPLEMENTACION_HUD_DINÁMICO.md` - Cómo funciona
- `GUIA_CONFIGURACION_HUD.md` - Todas las opciones
- `ARQUITECTURA_TECNICA_HUD.md` - Detalles técnicos

## ⏱️ Intervalo de Actualización

Los datos se actualizan cada **0.5 segundos**. Modifica en `hud-system-display.feature.sp`:
```sourcepawn
#define HUD_UPDATE_INTERVAL 0.5  // Cambiar a 0.25 para más rápido, 1.0 para más lento
```

## 🎯 Características

✅ Muestra valores del sistema !buy en tiempo real
✅ Actualización dinámica sin necesidad de recargar
✅ Totalmente configurable
✅ Backwards compatible (fallback a comportamiento original)
✅ Modular y extensible
✅ Bajo overhead de CPU/memoria

## 🚨 Importante

Asegúrate de que:
1. **Eclipse Management System** está compilado
2. **l4d2_scripted_hud** está cargado
3. **Los CVARs están en `cfg/sourcemod/l4d2_scripted_hud.cfg`**

Sin estas 3 cosas, el sistema no funcionará.

## 💡 Tips

- Usa `sm_hud2_blink "1"` para que el HUD parpadee cuando hay un evento importante
- Usa diferentes posiciones para cada mapa si lo necesitas
- Puedes desactivar HUD3 si no usas deployables: `sm_hud3_enabled "0"`
- Los cambios en CVARs aplican inmediatamente sin necesidad de recargar

## 📞 Soporte

Si algo no funciona:
1. Revisar `logs/Eclipse_Management_System.log`
2. Verificar con `sm plugins list | grep Eclipse`
3. Leer los documentos en la carpeta del proyecto

---

**¡Listo!** Tu HUD dinámico del sistema !buy debería estar funcionando ahora. 🎉
