# 🐛 Bug Fix Report - Shoulder Cannon v1.1.2

## Bugs Identificados y Corregidos

### 🔴 BUG #1: Targeting Priority Incorrecta
**Severidad:** CRÍTICA
**Síntoma:** Solo ataca Specials aunque selecciones Commons o Tanks en el menú

#### Causa
El menú estaba rotando a la SIGUIENTE opción en lugar de establecer la seleccionada:
```sourcepawn
// INCORRECTO (antes):
if (StrEqual(name, "[Commons] Target First", false)) {
    CannonTargetFirst[client] = 1;  // ← Cambia a Specials!
}
```

#### Solución
Ahora establece correctamente el valor basado en la opción seleccionada:
```sourcepawn
// CORRECTO (después):
if (StrEqual(name, "[Commons] Target First", false)) {
    CannonTargetFirst[client] = 0;  // ← case 0 = Commons
}
if (StrEqual(name, "[Specials] Target First", false)) {
    CannonTargetFirst[client] = 1;  // ← case 1 = Specials
}
if (StrEqual(name, "[Witches] Target First", false)) {
    CannonTargetFirst[client] = 2;  // ← case 2 = Witches
}
if (StrEqual(name, "[Tanks] Target First", false)) {
    CannonTargetFirst[client] = 3;  // ← case 3 = Tanks
}
```

---

### 🔴 BUG #2: M60 No Se Ve Visualmente
**Severidad:** CRÍTICA
**Síntoma:** La entidad se crea pero no aparece en pantalla

#### Causa
El hook `Transmit_ShoulderCannon` estaba ocultando la entidad:
```sourcepawn
// INCORRECTO (antes):
public Action:Transmit_ShoulderCannon(entity, client)
{
    for (new i = 1; i <= MaxClients; i++) {
        if (CannonEnt[i] == entity) {
            if (i == client) {
                return Plugin_Handled;  // ← OCULTA al propietario!
            } else {
                return Plugin_Continue;
            }
        }
    }
    return Plugin_Handled;  // ← Default también oculta
}
```

#### Solución
Ahora permite que todos vean la entidad:
```sourcepawn
// CORRECTO (después):
public Action:Transmit_ShoulderCannon(entity, client)
{
    if (entity > 32 && IsValidEntity(entity)) {
        if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
            for (new i = 1; i <= MaxClients; i++) {
                if (CannonEnt[i] == entity) {
                    // Show to everyone (owner and other players)
                    return Plugin_Continue;  // ← Permite ver
                }
            }
        }
    }
    return Plugin_Continue;  // ← Default permite ver
}
```

---

## ✅ Cambios Aplicados

| Bug | Línea | Tipo | Fix |
|-----|-------|------|-----|
| #1 | 1483 | Logic | `= 1` → `= 0` |
| #1 | 1484 | Text | "Specials" → "Commons" |
| #1 | 1489 | Logic | `= 2` → `= 1` |
| #1 | 1490 | Text | "Witches" → "Specials" |
| #1 | 1495 | Logic | `= 3` → `= 2` |
| #1 | 1496 | Text | "Tanks" → "Witches" |
| #1 | 1501 | Logic | `= 0` → `= 3` |
| #1 | 1502 | Text | "Commons" → "Tanks" |
| #2 | 415-433 | Hook | Rewrite completo |

---

## 🧪 Pruebas Recomendadas

### Test 1: Targeting Priority
1. Equipar cañón: `!sc` → "[ ] Equip Shoulder Cannon"
2. Ir al menú: `!sc`
3. Seleccionar prioridades:
   - `[Commons] Target First` → Debe atacar commons primero
   - `[Specials] Target First` → Debe atacar specials primero
   - `[Witches] Target First` → Debe atacar witches primero
   - `[Tanks] Target First` → Debe atacar tanks primero
4. Verificar que ataca el tipo correcto

### Test 2: Visual Visibility
1. Equipar cañón: `!sc` → "[ ] Equip Shoulder Cannon"
2. Verificar que aparece la M60 en el hombro del jugador
3. Otros jugadores también deben verla
4. Debe seguir al jugador al moverse

---

## 📊 Estadísticas

| Métrica | Valor |
|---------|-------|
| Bugs encontrados | 2 |
| Bugs solucionados | 2 |
| Líneas modificadas | ~30 |
| Funciones afectadas | 2 |
| Compilación | ✅ Exitosa |
| Tamaño | 20.6 KB |

---

## 📝 Changelog

### v1.1.1 → v1.1.2
- ✅ FIX: Target priority rotation (Bug #1)
- ✅ FIX: M60 visibility/rendering (Bug #2)
- ✅ Improved debug logging for targeting
- ✅ Simplified Transmit hook

### Issues Resueltas
- ❌ "Solo ataca especiales" → ✅ Ataca según prioridad
- ❌ "No se ve la M60" → ✅ M60 visible para todos

---

## 🚀 Instalación del Fix

```bash
# 1. Compilar
cd c:\Users\Socius\Desktop\sm\Eclipse-Project
./compile_shoulder_cannon.bat

# 2. Copiar
cp scripting/compiled/shoulder_cannon.smx [servidor]/addons/sourcemod/plugins/

# 3. Recargar
sm plugins reload shoulder_cannon

# 4. Probar
!sc (en juego)
```

---

## 🔍 Debug Logs para Verificar

Con `sc_debug 1`, deberías ver:

### Targeting Working:
```
[SC_DEBUG] Target selection - zombie:X special:0 witch:0 tank:0, priority:0
[SC_DEBUG] DestroyTarget called - client:X, target:X, type:2
```

### M60 Visible:
```
[SC_DEBUG] Entity XXX spawned
[SC_DEBUG] Entity XXX activated
[SC_DEBUG] SDKHook_SetTransmit hooked
```

---

## ⚠️ Notas Importantes

1. Los bugs eran lógicos, no de compilación
2. El primero causaba que SIEMPRE atacara la opción "case 1" (Specials)
3. El segundo ocultaba visualmente la entidad
4. Ambos son CRÍTICOS y afectan gameplay directo

---

**Version:** 1.1.2
**Status:** READY
**Compiled:** ✅
**Date:** 2025-10-21
**All bugs fixed!** 🎉
