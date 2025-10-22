# Shoulder Cannon - Quick Start Guide

## ⚡ 30 Segundos Setup

### 1. Copiar Plugin (15 segundos)
```bash
cp scripting/compiled/shoulder_cannon.smx /path/to/server/addons/sourcemod/plugins/
```

### 2. Recargar (5 segundos)
En consola del servidor:
```
sm plugins reload shoulder_cannon
```

### 3. Probar (10 segundos)
En juego, en chat:
```
!sc
```

✅ **¡Listo!**

---

## 🎯 Comandos Rápidos

| Comando | Ubicación | Resultado |
|---------|-----------|-----------|
| `!sc` | Chat | Abre menú |
| `/sc` | Chat | Abre menú |
| `sm_sc` | Consola | Abre menú |
| `sc_debug 1` | Consola | Activa logs |
| `sc_debug 0` | Consola | Desactiva logs |

---

## 🐛 Si No Funciona

### Paso 1: ¿El plugin está cargado?
```
sm plugins list | grep -i shoulder
```
Debería mostrar `shoulder_cannon` con estado `Run`.

**Si NO aparece:**
```
# Verifica que el archivo existe:
ls -la addons/sourcemod/plugins/shoulder_cannon.smx

# Si no existe, cópialo
cp scripting/compiled/shoulder_cannon.smx addons/sourcemod/plugins/

# Recarga
sm plugins reload shoulder_cannon
```

### Paso 2: ¿El debug está activado?
```
sc_debug 1
```

### Paso 3: ¿El comando se captura?
En juego:
```
!sc
```

En console:
```
tail -f logs/L*.log | grep SC_DEBUG
```

Deberías ver:
```
[SC_DEBUG] Command_Say from client X: !sc
```

---

## 📊 Logs Esperados

**Mínimo:**
```
[SC_DEBUG] Command_Say from client 1: !sc
[SC_DEBUG] ShoulderCannonMenuFunc called for client 1
[SC_DEBUG] Displaying menu to client 1
```

**Ideal (Cañón funcionando):**
```
[SC_DEBUG] EquipShoulderCannon called for client 1
[SC_DEBUG] Entity 450 is valid, setting up...
[SC_DEBUG] Entity 450 spawned
[SC_DEBUG] RunRepeater started for client 1 with entity 450
[SC_DEBUG] CannonRepeater: round=1, client=1, cannon=450
[SC_DEBUG] Found 10 common infected
[SC_DEBUG] DestroyTarget called - client:1, target:380, type:2
```

---

## ✅ Checklist

- [ ] Plugin compilado (20.7 KB)
- [ ] Archivo copiado a plugins/
- [ ] Plugin cargado (`sm plugins list`)
- [ ] Debug activado (`sc_debug 1`)
- [ ] Comando funciona (`!sc`)
- [ ] Menú aparece
- [ ] Opción "Equip" funciona
- [ ] Cañón aparece en juego
- [ ] Cañón dispara

---

## 🎮 Cómo Usar en Juego

1. **Abre el menú:** `!sc`
2. **Selecciona "Equip":** Click
3. **Verás el menú nuevamente** (opción de "desEquip" aparece)
4. **Configura opciones:**
   - Auto Equip: Si/No
   - Disable: Activa/Desactiva disparo
   - Never Target: Tipos a ignorar
   - Target First: Prioridad de objetivos
   - Fire Rate: Velocidad

---

## 🔧 Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| No hay logs | `sc_debug 1` |
| Menú no abre | Verifica `!sc` en chat |
| Cañón no aparece | Revisa logs de entity creation |
| No dispara | Busca logs de `CannonRepeater` |
| Muy lento/rápido | Ajusta fire rate en menú |
| Desaparece al mover | Revisa attachment point |

---

## 📁 Estructura de Archivos

```
project/
├── shoulder_cannon.sp              ← Código fuente
├── scripting/
│   └── compiled/
│       └── shoulder_cannon.smx     ← ¡COPIAR ESTO!
├── shoulder_cannon_debug.cfg       ← Config (opcional)
├── SHOULDER_CANNON_DEBUG.md        ← Guía completa
├── QUICK_START.md                  ← Este archivo
└── ...
```

---

## 🚀 Deployment

```bash
# Step 1: Copy
cp scripting/compiled/shoulder_cannon.smx [server]/addons/sourcemod/plugins/

# Step 2: Reload
sm plugins reload shoulder_cannon

# Step 3: Verify
sm plugins list | grep shoulder

# Step 4: Debug (if needed)
sc_debug 1
tail -f logs/L*.log | grep SC_DEBUG
```

---

## 💾 Compilar Nuevamente

Si necesitas recompilar el código:

```bash
cd /path/to/project
./compile_shoulder_cannon.bat
```

O manualmente:
```bash
"c:\path\to\spcomp.exe" shoulder_cannon.sp -o"scripting/compiled/shoulder_cannon.smx"
```

---

## 📞 Still Not Working?

1. **Copiar log completo:**
   ```bash
   grep SC_DEBUG logs/L*.log > debug.txt
   ```

2. **Incluir en reporte:**
   - `debug.txt` completo
   - Versión de SourceMod
   - Versión de servidor
   - Qué hace y qué NO hace

---

**Version:** 1.1.1
**Status:** Production Ready
**Last Updated:** 2025-10-21
