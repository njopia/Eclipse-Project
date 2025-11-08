# L4D2 Dynamic Spawn Manager

## 📋 Descripción

Plugin **standalone** para Left 4 Dead 2 que gestiona dinámicamente el spawn de zombies, infectados especiales y jefes basándose en la cantidad de jugadores y dificultad del servidor.

**Extraído y mejorado desde:** `onepiece3.sp`
**Completamente independiente:** No requiere ningún otro plugin para funcionar.

---

## ✨ Características

### **🎯 Escalado Automático Según Jugadores**

El plugin ajusta automáticamente cada **5 segundos**:

- ✅ **Intervalos de spawn de hordas comunes** (`z_mob_spawn_*`)
- ✅ **Límites de infectados especiales** por tipo (Boomer, Charger, Hunter, Jockey, Smoker, Spitter, Tank)
- ✅ **Cantidad máxima de especiales** simultáneos en el mapa
- ✅ **Vida del Tank** según cantidad de jugadores y dificultad
- ✅ **Vida de la Witch** según cantidad de jugadores
- ✅ **Tiempos de spawn de especiales** (más rápido con más jugadores)

### **⚡ Hordas Forzadas Automáticas**

- Trigger de `director_force_panic_event` cada X segundos (configurable)
- Solo en modos **Coop** y **Realism**
- Mantiene la presión sobre los supervivientes

### **🎮 Compatible con Todos los Modos**

- ✅ Coop
- ✅ Realism
- ✅ Survival
- ❌ Versus (se desactiva automáticamente)

---

## 📊 Tabla de Escalado

| Jugadores | Spawn Min | Spawn Max | Tank HP | Witch HP | Especiales |
|-----------|-----------|-----------|---------|----------|------------|
| ≤4        | 90s       | 180s      | 5,000   | 1,000    | 4          |
| 5         | 90s       | 170s      | 6,000   | 1,000    | 5          |
| 8         | 90s       | 140s      | 6,000   | 3,000    | 8          |
| 12        | 60s       | 90s       | 7,000   | 4,100    | 12         |
| 16        | 50s       | 80s       | 10,000  | 4,600    | 16         |
| 20        | 30s       | 80s       | 12,000  | 5,000    | 20         |
| 20+       | **20s**   | **80s**   | 12,000  | 5,000    | 20+        |

**Nota:** Los valores varían según dificultad y configuración.

---

## 🔧 Instalación

### **1. Compilar el plugin**

```bash
cd /home/user/Eclipse-Project
spcomp scripting/l4d2_dynamic_spawn_manager.sp -o plugins/l4d2_dynamic_spawn_manager.smx
```

### **2. Copiar archivos**

```bash
# Plugin compilado
cp plugins/l4d2_dynamic_spawn_manager.smx /path/to/l4d2/addons/sourcemod/plugins/

# Configuración
cp cfg/sourcemod/l4d2_dynamic_spawn_manager.cfg /path/to/l4d2/cfg/sourcemod/
```

### **3. Cargar el plugin**

Reinicia el servidor o ejecuta:
```
sm plugins load l4d2_dynamic_spawn_manager
```

---

## ⚙️ ConVars

### **General**

| ConVar | Default | Min | Max | Descripción |
|--------|---------|-----|-----|-------------|
| `sm_dsm_enabled` | 1 | 0 | 1 | Activar/Desactivar plugin |
| `sm_dsm_update_interval` | 5.0 | 1.0 | 60.0 | Intervalo de actualización (segundos) |

### **Hordas Automáticas**

| ConVar | Default | Min | Max | Descripción |
|--------|---------|-----|-----|-------------|
| `sm_dsm_auto_horde` | 1 | 0 | 1 | Activar hordas forzadas |
| `sm_dsm_force_horde_interval` | 60.0 | 0.0 | 300.0 | Intervalo entre hordas (0=desactivado) |

### **Multiplicadores**

| ConVar | Default | Min | Max | Descripción |
|--------|---------|-----|-----|-------------|
| `sm_dsm_tank_hp_mult` | 1.0 | 0.1 | 5.0 | Multiplicador de HP del Tank |
| `sm_dsm_witch_hp_mult` | 1.0 | 0.1 | 5.0 | Multiplicador de HP de la Witch |
| `sm_dsm_diff_tank_reduction` | 5000 | 0 | 20000 | Reducción de HP del Tank en Hard |

---

## 📝 Ejemplos de Configuración

### **Servidor Casual (Fácil)**
```cfg
sm_dsm_tank_hp_mult "0.7"           // Tanks con 70% HP
sm_dsm_witch_hp_mult "0.5"          // Witches con 50% HP
sm_dsm_force_horde_interval "90.0"  // Hordas cada 90 segundos
```

### **Servidor Hardcore**
```cfg
sm_dsm_tank_hp_mult "1.5"           // Tanks con 150% HP
sm_dsm_witch_hp_mult "1.5"          // Witches con 150% HP
sm_dsm_force_horde_interval "30.0"  // Hordas cada 30 segundos
sm_dsm_diff_tank_reduction "0"      // Sin reducción por dificultad
```

### **Servidor Sin Hordas Forzadas**
```cfg
sm_dsm_auto_horde "0"               // Desactivar hordas automáticas
```

---

## 🔌 CVars del Juego que Modifica

El plugin ajusta automáticamente estos CVars según la configuración:

### **Infectados Especiales**
- `l4d_infectedbots_max_specials` - Total de especiales simultáneos
- `l4d_infectedbots_boomer_limit` - Límite de Boomers
- `l4d_infectedbots_charger_limit` - Límite de Chargers
- `l4d_infectedbots_hunter_limit` - Límite de Hunters
- `l4d_infectedbots_jockey_limit` - Límite de Jockeys
- `l4d_infectedbots_smoker_limit` - Límite de Smokers
- `l4d_infectedbots_spitter_limit` - Límite de Spitters
- `l4d_infectedbots_tank_limit` - Límite de Tanks
- `l4d_infectedbots_spawn_time_min` - Tiempo mínimo entre spawns
- `l4d_infectedbots_spawn_time_max` - Tiempo máximo entre spawns

### **Zombies Comunes**
- `z_mob_spawn_min_interval_normal` - Intervalo mínimo entre hordas
- `z_mob_spawn_max_interval_normal` - Intervalo máximo entre hordas
- `z_mega_mob_spawn_min_interval` - Intervalo mínimo mega hordas
- `z_mega_mob_spawn_max_interval` - Intervalo máximo mega hordas

### **Jefes**
- `z_tank_health` - Vida del Tank
- `z_witch_health` - Vida de la Witch

---

## 🧪 Dependencias

### **Requeridas:**
- SourceMod 1.10+
- Left 4 Dead 2

### **Plugins Recomendados (opcional):**
- `l4d_infectedbots.smx` - Para control de infectados bots
- Cualquier plugin de ranking/skill si quieres activar `GetMastersCount()`

---

## 🔄 Integración con Sistema de Skill (Opcional)

El plugin incluye una función `GetMastersCount()` que actualmente está deshabilitada.

**Para activarla:**

1. Modifica la función `GetMastersCount()` en el código:

```cpp
int GetMastersCount(int maxSkill)
{
    // Ejemplo de integración con tu sistema de skill
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
        {
            // Aquí integras con tu sistema de ranking
            // int clientSkill = TuSistemaDeSkill_GetClientSkill(i);
            // if (clientSkill <= maxSkill && clientSkill > 0)
            //     count++;
        }
    }
    return count;
}
```

2. Recompila el plugin.

**Beneficio:** Jugadores expertos otorgan bonificaciones:
- +1 Tank extra con 4+ jugadores skill ≤5
- +1 Especial extra con 7+ jugadores skill ≤5
- Tiempo de spawn de especiales reducido

---

## 📖 Comparación con onepiece3.sp

| Característica | onepiece3.sp | l4d2_dynamic_spawn_manager.sp |
|----------------|--------------|-------------------------------|
| **Dependencias** | 20+ sistemas integrados | ✅ **Ninguna** (standalone) |
| **Tamaño** | 7,372 líneas | ✅ **~450 líneas** |
| **Gestión de spawn** | ✅ Sí | ✅ Sí |
| **Balance de equipos** | ✅ Sí | ❌ No (enfocado solo en spawn) |
| **Sistema de autenticación** | ✅ Sí | ❌ No |
| **Base de datos** | ✅ Requerida | ✅ **No requerida** |
| **Configuración** | Hardcoded | ✅ **ConVars personalizables** |
| **Documentación** | Escasa | ✅ **Completa** |

---

## 🐛 Troubleshooting

### **El plugin no modifica los spawns**

1. Verifica que `sm_dsm_enabled` esté en `1`
2. Revisa que no estés en modo **Versus** (se desactiva automáticamente)
3. Comprueba logs: `sm plugins info l4d2_dynamic_spawn_manager`

### **Hordas automáticas no funcionan**

1. Verifica `sm_dsm_auto_horde "1"`
2. Verifica `sm_dsm_force_horde_interval` > 0
3. Comprueba que estés en modo **Coop** o **Realism**

### **Valores de HP incorrectos**

Verifica los multiplicadores:
```
sm_cvar sm_dsm_tank_hp_mult
sm_cvar sm_dsm_witch_hp_mult
```

---

## 📜 Licencia

GPL v3 - Uso libre con atribución.

---

## 🤝 Créditos

- **Código original:** onepiece3.sp (Woonan modified by Xtreme-Infection)
- **Refactorización:** Eclipse Project
- **Versión standalone:** Claude AI Assistant

---

## 📞 Soporte

Para reportar bugs o solicitar features, crea un issue en el repositorio del proyecto.

---

**¡Disfruta de un gameplay dinámico y escalable!** 🧟‍♂️🔥
