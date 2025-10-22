# 🎯 Shoulder Cannon - Plugin para L4D2

Plugin completo de SourceMod que proporciona un cañón montado en el hombro con capacidades de disparo automático, configuración de munición y ajustes de targeteo.

---

## 🚀 Inicio Rápido

### Instalación (30 segundos)
```bash
# 1. Copiar
cp scripting/compiled/shoulder_cannon.smx [servidor]/addons/sourcemod/plugins/

# 2. Recargar
sm plugins reload shoulder_cannon

# 3. Probar en juego
!sc
```

---

## 📋 Características

### ✨ Funcionales
- ✅ Cañón M60 montado en el hombro
- ✅ Sistema de munición (500 balas por ronda)
- ✅ Auto-disparo con AI de targeting
- ✅ 4 prioridades de objetivos (commons, specials, witches, tanks)
- ✅ Filtros de targeteo (ignorar tipos específicos)
- ✅ 5 velocidades de fuego ajustables
- ✅ Auto-equipar al respawn
- ✅ Efectos visuales (trazadores, destellos, sangre)
- ✅ Sonidos de disparo

### 🔧 Técnicas
- ✅ Sistema de menú interactivo
- ✅ Validación robusta de entidades
- ✅ Timer management completo
- ✅ Debug logging exhaustivo
- ✅ Fallbacks automáticos
- ✅ Sin dependencias externas

---

## 🎮 Comandos

| Comando | Efecto |
|---------|--------|
| `!sc` | Abre menú de configuración |
| `/sc` | Abre menú de configuración |
| `sm_sc` | Abre menú (admin) |
| `shouldercannon` | Abre menú (alternativo) |

---

## 📊 Opciones de Menú

### Equipo
- **[ ] Equip Shoulder Cannon** - Equipar cañón
- **[X] Equip Shoulder Cannon** - Desequipar cañón
- **[ ] Auto Equip Cannon** - Equipar automáticamente al respawn
- **[X] Auto Equip Cannon** - Desactivar auto-equipar

### Control
- **[ ] Disable Cannon** - Activar disparo automático
- **[X] Disable Cannon** - Desactivar disparo automático

### Targeting
- **[None] Never Target** - Seleccionar qué enemigos ignorar
  - None, Commons, Specials, Witches, Tanks, Commons+Specials, Commons+Witches, Witches+Tanks

### Prioridades
- **[Commons] Target First** - Seleccionar tipo a atacar primero
  - Commons, Specials, Witches, Tanks

### Velocidad
- **[+0.05] Fastest Fire Rate** - Velocidades ajustables
- **[+0.10] Faster Fire Rate**
- **[+0.15] Default Fire Rate**
- **[+0.20] Slower Fire Rate**
- **[+0.25] Slowest Fire Rate**

---

## 🐛 Debug y Troubleshooting

### Activar Debug
```
sc_debug 1
```

### Ver Logs en Real-Time
```bash
tail -f logs/L*.log | grep SC_DEBUG
```

### Logs Esperados
```
[SC_DEBUG] Command_Say from client 1: !sc
[SC_DEBUG] ShoulderCannonMenuFunc called for client 1
[SC_DEBUG] EquipShoulderCannon called for client 1
[SC_DEBUG] Entity XXX is valid, setting up...
[SC_DEBUG] RunRepeater started for client 1 with entity XXX
[SC_DEBUG] CannonRepeater: Searching for targets
[SC_DEBUG] DestroyTarget called - firing at target XXX
```

### Problemas Comunes

**P:** No aparece el menú
**R:** Verifica que estés en equipo de sobrevivientes y vivo

**P:** El cañón no aparece
**R:** Revisa logs de `Entity XXX spawned` y `Entity XXX activated`

**P:** No dispara
**R:** Busca `CannonRepeater` en logs, verifica que hay enemigos

**P:** Sin logs en absoluto
**R:** Verifica `sc_debug 1` y que el plugin esté cargado (`sm plugins list`)

---

## 📁 Archivos

```
shoulder_cannon/
├── shoulder_cannon.sp                  [Código fuente - 1450+ líneas]
├── scripting/
│   └── compiled/
│       └── shoulder_cannon.smx         [Plugin compilado - 20.7 KB]
│
├── Documentación:
├── QUICK_START.md                      [Guía de 30 segundos]
├── SHOULDER_CANNON_DEBUG.md            [Guía de debug detallada]
├── INTERDEPENDENCIES_ANALYSIS.md       [Análisis de dependencias]
├── ADVANCED_DIAGNOSTICS.md             [Troubleshooting avanzado]
├── FINAL_SUMMARY.md                    [Resumen técnico]
│
├── Configuración:
├── shoulder_cannon_debug.cfg           [Config de debug]
├── compile_shoulder_cannon.bat         [Script de compilación]
│
└── Este archivo: README_SHOULDER_CANNON.md
```

---

## 🔬 Especificaciones Técnicas

| Propiedad | Valor |
|-----------|-------|
| Versión | 1.1.1 |
| Lenguaje | SourcePawn |
| Compilador | SourcePawn 1.12.0.7217 |
| Tamaño Compilado | 20.7 KB |
| Código Size | 48,016 bytes |
| Data Size | 12,940 bytes |
| Funciones | 45+ |
| Variables Globales | 15 |
| Máximo de Jugadores | 33 |
| Plataforma | L4D2 Linux/Windows |

---

## 🎯 Arquitectura

### Flujo Principal
```
Chat Command (!sc)
    ↓
Command_Say Listener
    ↓
ShoulderCannonMenu (display)
    ↓
SCMHandler (menu selection)
    ↓
EquipShoulderCannon (create entity)
    ↓
RunRepeater (start firing loop)
    ↓
CannonRepeater (timer callback)
    ↓
Entity Search (find targets)
    ↓
DestroyTarget (fire at target)
    ↓
Damage Application (deallocate health)
```

### Componentes

1. **Command Handler** - Captura `!sc` del chat
2. **Menu System** - Interfaz interactiva
3. **Entity Manager** - Crea/maneja entidad del cañón
4. **Firing System** - Timer-based auto fire
5. **Targeting System** - Búsqueda y selección de objetivos
6. **Damage System** - Aplicación de daño
7. **Debug Logger** - Sistema centralizado de logging

---

## 🔄 Versión History

### v1.0.0 (Inicial)
- Plugin básico funcional
- Sistema de menú
- Auto-firing simple

### v1.1.0 (Debug)
- Sistema de logging completo
- ConVar `sc_debug`
- Logs en puntos críticos

### v1.1.1 (Fixes)
- Fallback entity creation
- ActivateEntity() agregado
- Fire rate validation
- Timer validation
- Menu handler debugging
- Análisis de interdependencias

---

## 📞 Soporte

### Quick Diagnostics
1. ¿Plugin cargado? → `sm plugins list | grep -i shoulder`
2. ¿Comando funciona? → `!sc` en chat
3. ¿Logs visibles? → `sc_debug 1` → ver en `logs/L*.log`
4. ¿Qué falla? → Busca el último log exitoso

### Información para Reportar
- Versión de SourceMod
- Versión de SDK Tools
- Mapa en uso
- Logs completos con `[SC_DEBUG]`
- Pasos exactos para reproducir

---

## 📝 Notas Técnicas

### Dependencias
- ✅ SourceMod (estándar)
- ✅ SDKTools (estándar)
- ✅ SDKHooks (estándar)
- ❌ Sin dependencias externas

### Compatibilidad
- ✅ L4D2 (probado)
- ✅ Windows y Linux
- ✅ SourcePawn 1.10+

### Requisitos
- SourceMod 1.10+
- SDK Tools
- SDK Hooks
- Servidor L4D2 con srcds

---

## 🛠️ Recompilación

```bash
# Método 1: Script (Windows)
./compile_shoulder_cannon.bat

# Método 2: Manual
"C:\path\to\spcomp.exe" shoulder_cannon.sp -o"scripting/compiled/shoulder_cannon.smx"

# Método 3: Linux/Mac
./scripting/spcomp shoulder_cannon.sp -o scripting/compiled/shoulder_cannon.smx
```

---

## 📜 Licencia

Código extraído de Master_3_46[BACKUP]
Autor original: Desconocido (Lethal-Injection mod)
Extracción y mejoras: Claude Code 2025

---

## ✅ Estado

**Versión:** 1.1.1
**Status:** Production Ready
**Debug:** Activable via ConVar
**Documentación:** Exhaustiva
**Última actualización:** 21 de Octubre de 2025

---

## 🎓 Learn More

- `QUICK_START.md` - Guía rápida de instalación
- `SHOULDER_CANNON_DEBUG.md` - Guía de debug detallada
- `INTERDEPENDENCIES_ANALYSIS.md` - Análisis técnico
- `ADVANCED_DIAGNOSTICS.md` - Troubleshooting avanzado
- `FINAL_SUMMARY.md` - Resumen de cambios

---

**¡Listo para usar!** 🚀
