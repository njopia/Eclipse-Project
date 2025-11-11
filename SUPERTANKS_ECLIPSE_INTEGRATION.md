# 🎮 SuperTanks Nightmare - Eclipse Integration

## 📋 Resumen

Sistema completo de integración entre **Natan SuperTanks Nightmare** y **Eclipse Management System**. Proporciona una experiencia de juego unificada con recompensas, modos de dificultad dinámicos, y sinergia completa entre ambos sistemas.

---

## ✨ Características Principales

### 🏆 **Sistema de Recompensas**

Matar SuperTanks otorga **puntos de Currency + XP** para el sistema Eclipse:

| SuperTank Type | Puntos Base | Con Expert (x4) | Con Cow Level (x4x5) |
|----------------|-------------|-----------------|----------------------|
| Default Tank   | 100         | 400             | 2,000                |
| Smasher Tank   | 150         | 600             | 3,000                |
| Warp Tank      | 120         | 480             | 2,400                |
| Meteor Tank    | 180         | 720             | 3,600                |
| Spitter Tank   | 130         | 520             | 2,600                |
| Heal Tank      | 140         | 560             | 2,800                |
| Fire Tank      | 160         | 640             | 3,200                |
| Ice Tank       | 140         | 560             | 2,800                |
| Jockey Tank    | 130         | 520             | 2,600                |
| **Ghost Tank** | **200**     | **800**         | **4,000**            |
| **Shock Tank** | **150**     | **600**         | **3,000**            |
| **Witch Tank** | **170**     | **680**         | **3,400**            |
| **Shield Tank**| **190**     | **760**         | **3,800**            |
| **Cobalt Tank**| **180**     | **720**         | **3,600**            |
| **Jumper Tank**| **150**     | **600**         | **3,000**            |
| **Gravity Tank**|**200**     | **800**         | **4,000**            |
| **DEMON TANK** | **500 + 1000 BONUS** | **2000 + 4000** | **10000 + 20000** |

#### Multiplicadores Activos:
- **Dificultad del servidor**: Easy x1, Normal x2, Advanced x3, Expert x4
- **Nivel del jugador**: +2% por nivel (Nivel 50 = +100% extra)
- **Modo de dificultad Eclipse**:
  - Bloodmoon: +50% adicional
  - Hell Mode: +100% adicional
  - Inferno: +200% adicional
  - Cow Level: +400% adicional

---

### 🔥 **Integración con Modos de Dificultad Eclipse**

Los modos de dificultad Eclipse afectan a los SuperTanks:

#### **Bloodmoon Mode** 🌕
- SuperTanks: **+50% HP, +10% velocidad**
- Recompensas: **+50% puntos**
- Visual: Ambiente rojizo

#### **Hell Mode** 🔥
- SuperTanks: **+100% HP, +20% velocidad**
- Recompensas: **+100% puntos**
- Spawns más frecuentes

#### **Inferno Mode** 🌋
- SuperTanks: **+200% HP, +30% velocidad**
- Recompensas: **+200% puntos**
- Tanks extremadamente resistentes

#### **Cow Level** 🐄
- SuperTanks: **+500% HP, +50% velocidad**
- Recompensas: **+400% puntos**
- ¡Locura total!

---

### ⚡ **Integración con Habilidades Eclipse**

Las habilidades de Eclipse funcionan con SuperTanks:

| Habilidad        | Efecto en SuperTanks                                    |
|------------------|---------------------------------------------------------|
| **Berserker**    | +50% daño contra SuperTanks                             |
| **Instagib**     | 5% chance de quitar 50% HP actual (+0.1% por nivel)     |
| **Flame Shield** | +25% daño de fuego contra SuperTanks                    |
| **Acid Bath**    | +30% daño ácido DoT contra SuperTanks                   |
| **Heat Seeker**  | +40% daño explosivo contra SuperTanks                   |
| **Shoulder Cannon** | +100% daño masivo contra SuperTanks                  |

---

### 📊 **Ventajas por Nivel**

El sistema de leveling de Eclipse otorga ventajas progresivas:

| Nivel | Ventajas                                              |
|-------|-------------------------------------------------------|
| 1-9   | Bonus base de XP por kill (+2% daño por nivel)        |
| 10+   | Resistencia aumentada a habilidades de SuperTanks     |
| 20+   | Detección mejorada (glows más brillantes)             |
| 30+   | Chance de daño crítico 2x contra SuperTanks           |
| 50+   | Inmunidad parcial a efectos (Ghost disarm, etc.)      |

---

## 🎯 **Comandos**

### **Comandos de Jugador**
```
sm_supertankstats     - Ver tus estadísticas de SuperTanks
```

### **Comandos de Admin**
```
sm_nightmare          - Activar/Desactivar Nightmare Mode
```

---

## ⚙️ **ConVars de Integración**

### **Recompensas por SuperTank**
```
eclipse_st_reward_default "100"      // Puntos base por Default Tank
eclipse_st_reward_smasher "150"      // Puntos base por Smasher Tank
eclipse_st_reward_warp "120"         // Puntos base por Warp Tank
eclipse_st_reward_meteor "180"       // Puntos base por Meteor Tank
eclipse_st_reward_spitter "130"      // Puntos base por Spitter Tank
eclipse_st_reward_heal "140"         // Puntos base por Heal Tank
eclipse_st_reward_fire "160"         // Puntos base por Fire Tank
eclipse_st_reward_ice "140"          // Puntos base por Ice Tank
eclipse_st_reward_jockey "130"       // Puntos base por Jockey Tank
eclipse_st_reward_ghost "200"        // Puntos base por Ghost Tank
eclipse_st_reward_shock "150"        // Puntos base por Shock Tank
eclipse_st_reward_witch "170"        // Puntos base por Witch Tank
eclipse_st_reward_shield "190"       // Puntos base por Shield Tank
eclipse_st_reward_cobalt "180"       // Puntos base por Cobalt Tank
eclipse_st_reward_jumper "150"       // Puntos base por Jumper Tank
eclipse_st_reward_gravity "200"      // Puntos base por Gravity Tank
eclipse_st_reward_demon "500"        // Puntos base por Demon Tank (+1000 bonus)
```

### **Toggles de Integración**
```
eclipse_st_difficulty_integration "1"   // Modos Eclipse afectan SuperTanks
eclipse_st_abilities_integration "1"    // Habilidades Eclipse funcionan con SuperTanks
eclipse_st_leveling_integration "1"     // Niveles otorgan ventajas contra SuperTanks
```

---

## 📈 **Sistema de Estadísticas**

Cada jugador tiene tracking de:
- **Total de SuperTanks eliminados**
- **Kills por tipo de SuperTank** (0-16)
- **Top 5 tipos más eliminados**

Ver con: `sm_supertankstats`

---

## 🔧 **Arquitectura Técnica**

### **Módulos Integrados**

#### 1. **modules/supertanks-eclipse-integration.module.sp**
   - Sistema de recompensas
   - Modificadores de dificultad
   - Bonus de habilidades
   - Tracking de estadísticas

#### 2. **Modificaciones en SuperTanks**
   - `st_events.inc`: Hook de muerte de tanks → recompensas
   - `st_tank_base.inc`: Hook de spawn → modificadores de stats
   - `st_damage.inc`: Hook de daño → bonus de habilidades

#### 3. **Integración en Eclipse Management System**
   - Includes de SuperTanks (33 archivos)
   - Inicialización en OnPluginStart
   - Precache en OnMapStart
   - Comando de stats

---

## 💡 **Ejemplos de Uso**

### **Escenario 1: Jugador Nivel 50 en Inferno Mode**
```
Nivel 50 mata Demon Tank en Expert + Inferno:
- Base: 500 puntos
- Expert: x4 = 2,000 puntos
- Inferno Mode: x3 = 6,000 puntos
- Nivel 50: +100% = 12,000 puntos
- Demon Bonus: +4,000 = 16,000 puntos
TOTAL: 16,000 Currency + 16,000 XP
```

### **Escenario 2: Berserker + Instagib**
```
Jugador con Berserker activo ataca Ghost Tank:
- Daño base: 100
- Berserker: +50% = 150
- Chance Instagib: 5% + (nivel*0.1%) = hasta 10%
- Si activa: 50% HP del Ghost Tank
```

### **Escenario 3: Cow Level Apocalypse**
```
SuperTank en Cow Level:
- HP: x6 (6000% del HP original)
- Velocidad: +50%
- Recompensa: x5 (500% puntos extra)
- Ejemplo: Gravity Tank en Expert = 200*4*5 = 4,000 puntos
```

---

## 🎨 **Mensajes al Jugador**

### **Al matar SuperTank común**
```
[Eclipse] Eliminaste Fire Tank! +640 puntos (x4 dificultad)
```

### **Al matar SuperTank especial (Ghost+)**
```
[Eclipse] NombreJugador eliminó un Ghost Tank!
[Eclipse] Eliminaste Ghost Tank! +800 puntos (x4 dificultad)
```

### **Al matar Demon Tank**
```
[Eclipse] ¡DEMON TANK DERROTADO! NombreJugador recibe 4000 puntos bonus!
[Eclipse] Eliminaste Demon Tank! +2000 puntos (x4 dificultad)
```

---

## 🚀 **Rendimiento y Optimización**

- ✅ Todas las funciones usan hooks condicionales (#if defined ECLIPSE_INTEGRATION)
- ✅ Tracking en memoria (sin BD adicional)
- ✅ Mensajes optimizados (solo para tanks especiales)
- ✅ Sin lag adicional en OnGameFrame

---

## 📝 **Notas de Desarrollo**

### **Orden de Carga**
1. Eclipse Core Systems (DB, SDK, Utils)
2. Leveling System
3. Abilities System
4. Currency System
5. Difficulty Modes
6. **SuperTanks Nightmare** (33 includes)
7. **SuperTanks-Eclipse Integration**
8. Frags System

### **Hooks Críticos**
- `ST_Event_Player_Death`: Otorga recompensas al matar tank
- `TankSpawnTimer`: Modifica stats según modo Eclipse
- `OnPlayerTakeDamage`: Aplica bonus de habilidades

---

## 🎯 **Configuración Recomendada**

### **Server Balanceado**
```
eclipse_st_difficulty_integration 1
eclipse_st_abilities_integration 1
eclipse_st_leveling_integration 1
st_on 1
st_finale_only 0
difficulty_orchestrator_enable 1
```

### **Server Extremo**
```
eclipse_st_reward_demon 1000
nightmare_on 1
difficulty_progression_enable 1
// Cow Level con Nightmare = Infierno literal
```

---

## ✅ **Estado de la Integración**

- ✅ Sistema de recompensas: **COMPLETO**
- ✅ Integración con dificultad: **COMPLETO**
- ✅ Integración con habilidades: **COMPLETO**
- ✅ Sistema de leveling: **COMPLETO**
- ✅ Tracking de estadísticas: **COMPLETO**
- ✅ Comandos y CVars: **COMPLETO**
- ✅ Documentación: **COMPLETO**

---

## 🎮 **¡Listo para Jugar!**

El sistema está completamente integrado y funcional. Los jugadores ahora tienen:
- 💰 Recompensas masivas por matar SuperTanks
- ⚔️ Habilidades Eclipse que funcionan contra SuperTanks
- 📈 Ventajas progresivas según nivel
- 🔥 Desafíos extremos con modos de dificultad
- 📊 Sistema completo de estadísticas

**¡Que comience la cacería de SuperTanks!** 🦾
