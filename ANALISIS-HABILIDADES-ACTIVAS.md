# Análisis Completo de Habilidades Activas
## Sistema de Leveling - Long Action Menu (!buy)

Este documento analiza todas las habilidades activas del archivo backup `Master_3_46[BACKUP] (2).sp` para su posible implementación en el Eclipse Management System.

---

## 📋 Características Comunes de Todas las Habilidades

### Duración y Cooldown
- **Duración**: 60 segundos (300 ticks a 5 ticks por segundo = 60 segundos)
- **Reuse Time (Cooldown)**: 5 minutos (300 segundos)
- **Indicador Visual**: Night Vision activada (`m_bNightVisionOn = 1`) para indicar que la habilidad está activa

### Estructura de Código
Cada habilidad tiene 3 funciones principales:
1. **`Ability[Name](client)`** - Activa la habilidad
2. **`Update[Name](client)`** - Se ejecuta cada tick para mantener efectos
3. **`Destroy[Name](client)`** - Desactiva la habilidad al terminar

### Variables Globales
- `[Name]On[33]` - Estado activo/inactivo (0/1)
- `[Name]Timer[33]` - Contador de tiempo restante en ticks

---

## 🎯 Habilidades Activas Detalladas

### 1. **Detect Zombies** (Nivel 3)
**Descripción**: Permite ver infectados especiales y tanks a través de las paredes durante 60 segundos.

**Implementación**:
```sourcepawn
// Activa visión nocturna
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
DetectGZOn[client] = 1;
DetectGZTimer[client] = 300;

// Crea clones visuales de infectados especiales
CreateClone(client) // Crea prop_dynamic con glow amarillo
```

**Mecánicas Clave**:
- Crea entidades `prop_dynamic` que copian el modelo de infectados especiales
- Los clones tienen `m_iGlowType = 3` con color amarillo (RGB: 250, 250, 0)
- Usa `SDKHook_SetTransmit` para que solo el usuario vea los clones
- Sincroniza animaciones y posición con `CloneMovement()`
- Al desactivar, destruye todos los clones con `KillAllClones()`

**Archivos Relevantes**:
- Líneas: 18562-18732

---

### 2. **Berserker** (Nivel 5)
**Descripción**: Aumenta la velocidad de ataque y da doble daño con armas cuerpo a cuerpo.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
BerserkerOn[client] = 1;
BerserkerTimer[client] = 300;
L4D2_AdrenalineUsed(client, 60.0); // Efecto de adrenalina
```

**Mecánicas Clave**:
- Requiere tener un arma melee equipada para activar
- Modifica velocidad de swing: `SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 1.6)`
- Reduce delay entre ataques: `m_flNextPrimaryAttack - 0.30`
- Doble daño en `OnTakeDamage`: `DealDamageEntity(victim, attacker, 128, damage*2)`
- Efecto visual de partículas en cada hit (`PARTICLE_BERSERKER`)
- Funciona con cualquier melee weapon

**Archivos Relevantes**:
- Activación: 19722-19761
- Velocidad de swing: 18366-18391
- Daño: 24073-24086, 24847-24860

---

### 3. **Acid Bath** (Nivel 9)
**Descripción**: Hace que el ácido de Spitter te cure en lugar de dañarte.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
AcidBathOn[client] = 1;
AcidBathTimer[client] = 300;
```

**Mecánicas Clave**:
- Hook en `OnTakeDamage` detecta daño tipo "insect_swarm" (ácido de spitter)
- Bloquea el daño: `return Plugin_Handled;`
- Convierte daño en curación: `GiveHealth(client, damage_amount, false)`
- Solo funciona con ácido de Spitter, no con explosivos

**Archivos Relevantes**:
- Líneas: 18733-18771

---

### 4. **LifeStealer** (Nivel 12)
**Descripción**: Cura al usuario una pequeña porción del daño infligido.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
LifeStealerOn[client] = 1;
LifeStealerTimer[client] = 300;
```

**Mecánicas Clave**:
- Hook en `OnTakeDamage` cuando el usuario daña infectados
- Fórmula de curación: `damage_healed = (level / 5) * damage_scale`
- Si el jugador está incapacitado, puede auto-revivirse
- Efectos visuales: Glow rojo en el enemigo golpeado (RGB: 102, 0, 0)
- Funciona contra: infectados comunes, especiales, tanks y witches
- Llama a `StealLife(client, damage)` en cada hit
- Si está incapacitado: `L4D2_ReviveSurvivor(client)`

**Archivos Relevantes**:
- Activación: 19593-19631
- Robo de vida: 19632-19721

---

### 5. **FlameShield** (Nivel 16)
**Descripción**: Crea un escudo de fuego que enciende a cualquier zombie cercano.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
FlameShieldOn[client] = 1;
FlameShieldTimer[client] = 300;
```

**Mecánicas Clave**:
- Enciende al jugador: `IgniteEntity(client, 1.0)` (sin recibir daño de fuego)
- Efecto de partículas continuo (`PARTICLE_FLAMESHIELD`) adherido al jugador
- Daña zombies en un radio de 125 unidades cada 0.3 segundos
- Daño constante: 10 HP por tick
- Si está siendo agarrado por Smoker, daña al Smoker automáticamente
- Usa `FindEntityByClassname` para detectar zombies cercanos
- 3 pulsos de daño por segundo (timers a 0.3 y 0.6 segundos)

**Archivos Relevantes**:
- Activación: 19897-19973
- Sistema de daño: 19974-20009

---

### 6. **NightCrawler** (Nivel 18)
**Descripción**: Otorga el poder de teletransportación. Presiona [Walk] para cambiar entre sobrevivientes.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
NightCrawlerOn[client] = 1;
NightCrawlerTimer[client] = 300;
SetEntityRenderColor(client, 0, 0, 255, 255); // Azul
```

**Mecánicas Clave**:
- Tecla [Walk] (`IN_SPEED`) para cambiar de objetivo
- `PickNextTeleTarget(client)` selecciona el siguiente sobreviviente vivo
- Variable global `Teleporter[client]` almacena el objetivo actual
- Al teletransportarse: `TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR)`
- Rompe agarres de infectados automáticamente al teletransportarse
- Si está incapacitado, se auto-revive al teletransportarse
- Efecto de partículas (`PARTICLE_NIGHTCRAWLER`) en el destino
- Sonido: "weapons/fx/nearmiss/bulletltor13.wav"
- Color azul del jugador para indicar que está activo
- Cooldown de 0.3 segundos entre cambios de objetivo

**Archivos Relevantes**:
- Activación: 19779-19823
- Sistema de teleport: 18286-18361
- Selección de objetivo: 18303-18327
- Detección de tecla: 23700-23718

---

### 7. **Rapid Fire** (Nivel 23)
**Descripción**: Aumenta rápidamente la velocidad de disparo del M16 y recarga su munición rápidamente.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
RapidFireOn[client] = 1;
RapidFireTimer[client] = 300;
```

**Mecánicas Clave**:
- **SOLO funciona con M16 Assault Rifle** (`weapon_rifle`)
- Requiere tener el M16 equipado para activar
- Aumenta velocidad de disparo: `m_flPlaybackRate = 1.3`
- Reduce delay entre disparos: `m_flNextPrimaryAttack - 0.15`
- Recarga automática: añade +1 bala al clip si está ≤50 balas
- No requiere recargar manualmente durante la habilidad
- Funciona cada frame si no está recargando (`m_bInReload < 1`)
- Efectos de partículas en impactos

**Archivos Relevantes**:
- Activación: 19824-19862
- Velocidad de disparo: 19863-19892

---

### 8. **Chainsaw Massacre** (Nivel 25)
**Descripción**: Da una motosierra con munición infinita. Matar infectados da XP bonus.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
ChainsawMassOn[client] = 1;
ChainsawMassTimer[client] = 300;
CheatCommand(client, "give", "chainsaw"); // Da la motosierra
```

**Mecánicas Clave**:
- Auto-equipa una chainsaw al activar
- Munición infinita (no se acaba el combustible)
- **Bonus XP al matar con chainsaw**:
  - Zombie común: +1 XP
  - Zombie poco común: +1 XP
  - Lesser Witch: +5 XP
  - Witch: +12 XP
  - Infectados especiales: XP variable según tipo
- Verifica que el arma usada sea "weapon_chainsaw"
- El bonus XP se multiplica por `GetXPDiff(1)` (dificultad)
- Mantiene el combustible lleno constantemente

**Archivos Relevantes**:
- Activación: 18772-18811
- Bonus XP: 2648-2653, 2735-2740, 2818-2823, 2896-2901, 3080-3086
- Munición infinita: 3760-3770

---

### 9. **Heat Seeker** (Nivel 27)
**Descripción**: Hace que los proyectiles del Grenade Launcher sean teledirigidos. Munición infinita. Presiona [Walk] para cambiar prioridad de objetivos.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
HeatSeekerOn[client] = 1;
HeatSeekerTimer[client] = 300;
```

**Mecánicas Clave**:
- **SOLO funciona con Grenade Launcher** (`weapon_grenade_launcher`)
- Requiere tener el Grenade Launcher equipado para activar
- Tecla [Walk] (`IN_SPEED`) para cambiar prioridad de objetivos:
  1. Infectados especiales
  2. Tanks
  3. Witches
  4. Infectados comunes
- Los proyectiles detectan al enemigo más cercano según prioridad
- Modifica la velocidad del proyectil para perseguir al objetivo
- Munición infinita: recarga automática del cargador
- Timer `HeatSeekerProjTimer` actualiza trayectoria cada tick
- Usa `TeleportEntity` para ajustar dirección del proyectil

**Archivos Relevantes**:
- Activación: 18812-18850
- Sistema de seguimiento: 18851+
- Selección de prioridad: 23719-23724

---

### 10. **Speed Freak** (Nivel 31)
**Descripción**: Da velocidad de movimiento extremadamente rápida y uso rápido de items de curación. Solo tendrás 50 HP en este estado.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

// Reducir HP a 50
new health = GetEntProp(client, Prop_Send, "m_iHealth");
SetEntProp(client, Prop_Send, "m_iMaxHealth", 50);
if (health > 50)
{
    SetEntProp(client, Prop_Send, "m_iHealth", 50);
}

SpeedFreakOn[client] = 1;
SpeedFreakTimer[client] = 300;
```

**Mecánicas Clave**:
- **HP máximo reducido a 50** (penalización)
- Si tienes más de 50 HP, se reduce a 50 al activar
- Velocidad de movimiento masivamente aumentada (multiplier en `UpdateMovementSpeed`)
- Items de curación se usan mucho más rápido
- Al desactivar, el HP máximo **NO se restaura automáticamente** a 100
- Vulnerabilidad extrema: cualquier golpe puede ser letal
- Balance: velocidad a cambio de fragilidad

**Archivos Relevantes**:
- Activación: 19180-19226
- HP máximo: 19186-19191

---

### 11. **Healing Aura** (Nivel 33)
**Descripción**: Cura lentamente a todos los sobrevivientes cercanos incluyendo al usuario. Cuanto más cerca estén, más rápido se curan.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
HealingAuraOn[client] = 1;
HealingAuraTimer[client] = 300;
```

**Mecánicas Clave**:
- Cura al usuario automáticamente: 5 HP por tick
- Detecta sobrevivientes en un radio variable (distancia-based)
- **Curación basada en distancia**:
  - Muy cerca: curación rápida
  - Lejos: curación lenta
- Fórmula: `heal_amount = f(distance)` - inversamente proporcional
- Efectos visuales: Glow verde en jugadores afectados (RGB: 0, alpha, 0)
- Glow con parpadeo (`m_bFlashing = 1`)
- Variables globales:
  - `HealingAuraTarget[i]` - Cantidad de curación a aplicar
  - `HealingAuraPlayer[i]` - ID del healer
- Controller: `HealingAuraController()` actualiza objetivos cada tick
- Healer: `HealingAuraHealer()` aplica la curación
- Funciona en incapacitados (puede revivir si cura suficiente)

**Archivos Relevantes**:
- Activación: 19227-19266
- Sistema de curación: 19284-19450+
- Efectos visuales: 19267-19283

---

### 12. **Soulshield** (Nivel 37)
**Descripción**: Crea un campo de energía poderoso alrededor del usuario que niega todo daño recibido.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
SoulShieldOn[client] = 1;
SoulShieldTimer[client] = 300;
CreateSoulShield(client); // Crea efectos visuales
```

**Mecánicas Clave**:
- **INMUNIDAD TOTAL al daño** durante 60 segundos
- Hook en `OnTakeDamage`: `return Plugin_Handled;` (bloquea todo daño)
- Efectos visuales espectaculares:
  - 2 `beam_spotlight` (arriba y abajo del jugador)
  - Color dorado (RGB: 255, 215, 0)
  - Render color del jugador en dorado
- Variables globales: `SoulShieldGlow[client][2]` para las luces
- Las luces siguen al jugador (`SetParent`)
- `SDKHook_SetTransmit` oculta las luces al propio usuario (evita cegarlo)
- Al desactivar, destruye las entidades de luz y restaura color normal

**Archivos Relevantes**:
- Activación: 19453-19462
- Creación de escudo: 19464-19538
- Update: 19539-19557
- Destrucción: 19558-19592

---

### 13. **Polymorph** (Nivel 39)
**Descripción**: Transforma zombies comunes en items útiles al atacarlos. Hay 1-2% de probabilidad de que salga mal.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
PolyMorphOn[client] = 1;
PolyMorphTimer[client] = 300;
```

**Mecánicas Clave**:
- Hook en `OnTakeDamage` cuando atacas infectados comunes
- Mata instantáneamente al zombie
- **Spawn de items aleatorios**:
  - Medkit
  - Pills
  - Adrenaline
  - Defibrillator
  - Molotov
  - Pipe bomb
  - Bile jar
  - Munición
  - Armas (pistol, smg, shotgun, etc.)
- **1-2% chance de "salir mal"**: puede spawnearse algo negativo o un infectado especial
- Efecto de partículas (`PARTICLE_POLYMORPH`) en la transformación
- Sonido: "npc/infected/gore/bullets/bullet_impact_04.wav"
- Solo funciona en infectados comunes (`IsInfected(entity)`)
- No funciona en especiales, tanks o witches

**Archivos Relevantes**:
- Activación: 20049-20087
- Transformación: 20088-20200+
- Detección: 24111-24122

---

### 14. **Instagib** (Nivel 46)
**Descripción**: Da munición anti-virus especial a tus armas, extremadamente letal para cualquier infectado.

**Implementación**:
```sourcepawn
SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
InstaGibOn[client] = 1;
InstaGibTimer[client] = 300;
```

**Mecánicas Clave**:
- **MATA INSTANTÁNEAMENTE** a cualquier infectado (común, especial, tank, witch)
- Hook en `OnTakeDamage`: cambia el daño a un valor masivo
- Funciona con cualquier arma de fuego
- Verifica que el arma esté equipada: `IsEntityEquippedWeapon(attacker, weapon)`
- En infectados comunes: `AcceptEntityInput(victim, "Kill")` (muerte instantánea)
- En infectados especiales/tanks: `DealDamagePlayer(victim, attacker, 999999, damage)`
- Efectos de partículas en cada kill (`PARTICLE_SPARKSA`)
- La habilidad más poderosa del sistema
- Útil para niveles altos contra hordas masivas

**Archivos Relevantes**:
- Activación: 20010-20048
- Detección de hits: 24124-24140, 24894-24910

---

## 🔧 Sistema de Gestión de Habilidades

### Activación
Las habilidades se activan desde el menú de compra (!buy) en la sección "Long Action":

```sourcepawn
// Ejemplo de activación desde menú
if (StrContains(name, "Berserker", false) != -1)
{
    if (BerserkerTimer[client] <= 0)
    {
        if (IsMeleeEquipped(client))
        {
            AbilityBerserker(client);
            PrintToChat(client, "\x04[Ability]\x01 Berserker Activated");
        }
        else
        {
            PrintToChat(client, "\x05[Lethal-Injection]\x01 You need a melee weapon.");
        }
    }
    else
    {
        PrintToChat(client, "\x05[Lethal-Injection]\x01 You have to wait %i seconds to use this again.", BerserkerTimer[client]);
    }
}
```

### Actualización (Update Loop)
Se ejecuta cada tick del servidor (aproximadamente 5 ticks = 1 segundo):

```sourcepawn
stock UpdateAbility(client, ability)
{
    switch (ability)
    {
        case 1: UpdateDetectGZ(client);
        case 2: UpdateBerserker(client);
        case 3: UpdateAcidBath(client);
        case 4: UpdateLifeStealer(client);
        case 5: UpdateFlameShield(client);
        case 6: UpdateNightCrawler(client);
        case 7: UpdateRapidFire(client);
        case 8: UpdateChainsawMass(client);
        case 9: UpdateHeatSeeker(client);
        case 10: UpdateSpeedFreak(client);
        case 11: UpdateHealingAura(client);
        case 12: UpdateSoulShield(client);
        case 13: UpdatePolyMorph(client);
        case 14: UpdateInstaGib(client);
    }
}
```

### Desactivación
Cuando el timer llega a 0, se llama a la función Destroy:

```sourcepawn
stock DestroyAbility(client, ability)
{
    switch (ability)
    {
        case 1: DestroyDetectGZ(client);
        case 2: DestroyBerserker(client);
        case 3: DestroyAcidBath(client);
        case 4: DestroyLifeStealer(client);
        case 5: DestroyFlameShield(client);
        case 6: DestroyNightCrawler(client);
        case 7: DestroyRapidFire(client);
        case 8: DestroyChainsawMass(client);
        case 9: DestroyHeatSeeker(client);
        case 10: DestroySpeedFreak(client);
        case 11: DestroyHealingAura(client);
        case 12: DestroySoulShield(client);
        case 13: DestroyPolyMorph(client);
        case 14: DestroyInstaGib(client);
    }
}
```

### Verificación de Estado Activo
Función helper para saber si un jugador tiene alguna habilidad activa:

```sourcepawn
stock bool:HasActiveAbility(client)
{
    if (SoulShieldOn[client] == 1 ||
        LifeStealerOn[client] == 1 ||
        BerserkerOn[client] == 1 ||
        NightCrawlerOn[client] == 1 ||
        RapidFireOn[client] == 1 ||
        FlameShieldOn[client] == 1 ||
        InstaGibOn[client] == 1 ||
        PolyMorphOn[client] == 1 ||
        DetectGZOn[client] == 1 ||
        AcidBathOn[client] == 1 ||
        ChainsawMassOn[client] == 1 ||
        HeatSeekerOn[client] == 1 ||
        SpeedFreakOn[client] == 1)
    {
        return true;
    }
    return false;
}
```

---

## 🎨 Efectos Visuales y Partículas

### Partículas Usadas
```sourcepawn
// Definiciones de partículas
static const String:PARTICLE_BERSERKER[] = "sparks_generic_random";
static const String:PARTICLE_NIGHTCRAWLER[] = "weapon_pipebomb_child_firesmoke";
static const String:PARTICLE_FLAMESHIELD[] = "fire_jet_01_flame";
static const String:PARTICLE_POLYMORPH[] = "fireworks_sparkshower_01e";
static const String:PARTICLE_SPARKSA[] = "electrical_arc_01_system";
static const String:PARTICLE_LS_BOLT[] = "storm_lightning_01_thin"; // LifeStealer
```

### Sonidos
```sourcepawn
// Sonidos de habilidades
"weapons/fx/nearmiss/bulletltor13.wav" // NightCrawler teleport
"npc/infected/gore/bullets/bullet_impact_04.wav" // Polymorph
// AbilityShout(client) - Sonido genérico al activar
```

---

## 📊 Requisitos de Implementación

### Dependencias
1. **SDKHooks** - Para hooks de daño y transmit
2. **Left4DHooks** - Para funciones específicas de L4D2
3. **Timers** - Sistema de timers para efectos continuos
4. **Entity System** - Creación y manipulación de entidades

### Hooks Necesarios
- `SDKHook_OnTakeDamage` - Para modificar daño (todas las habilidades de combate)
- `SDKHook_SetTransmit` - Para efectos visuales personalizados
- `OnPlayerRunCmd` - Para input de teclas (NightCrawler, Heat Seeker)
- `OnEntityCreated` - Para interceptar proyectiles (Heat Seeker)

### Variables Globales Requeridas
```sourcepawn
// Estados de habilidades (para cada habilidad)
static DetectGZOn[33];
static BerserkerOn[33];
static AcidBathOn[33];
// ... (14 habilidades total)

// Timers de cooldown
static DetectGZTimer[33];
static BerserkerTimer[33];
static AcidBathTimer[33];
// ... (14 habilidades total)

// Variables específicas de habilidades
static Teleporter[33]; // NightCrawler
static ChoiceDelay[33]; // Delay para cambio de objetivo
static HealingAuraTarget[33]; // Healing Aura
static HealingAuraPlayer[33]; // Healing Aura
static SoulShieldGlow[33][2]; // Soulshield luces
static ZombieClone[MAXPLAYERS+1]; // Detect Zombies
```

---

## 🎯 Recomendaciones de Implementación

### Prioridad Alta (Más fáciles de implementar)
1. **Berserker** - Solo modifica velocidad y daño de melee
2. **Acid Bath** - Simple hook de daño
3. **LifeStealer** - Hook de daño con curación
4. **Speed Freak** - Modifica velocidad de movimiento

### Prioridad Media
5. **Chainsaw Massacre** - Requiere dar item y detectar kills
6. **Instagib** - Hook de daño simple pero muy poderoso
7. **FlameShield** - Requiere detección de proximidad y daño continuo
8. **Healing Aura** - Sistema de curación en área

### Prioridad Baja (Más complejas)
9. **Detect Zombies** - Requiere crear clones de entidades
10. **NightCrawler** - Sistema de teletransportación complejo
11. **Rapid Fire** - Requiere modificar propiedades de arma específica
12. **Heat Seeker** - Requiere manipulación de proyectiles
13. **Polymorph** - Spawn de items aleatorios
14. **Soulshield** - Efectos visuales complejos

### Balanceo Sugerido
- **Instagib** (Nivel 46): Considerar reducir duración o aumentar cooldown (es muy OP)
- **Soulshield** (Nivel 37): Inmunidad total puede ser demasiado fuerte
- **Speed Freak** (Nivel 31): El HP de 50 es un buen balance
- **Polymorph** (Nivel 39): Aumentar probabilidad de fallo para mayor riesgo

---

## 📝 Notas Adicionales

### Sistema de XP Bonus
Algunas habilidades otorgan XP bonus al matar:
- **Chainsaw Massacre**: Da XP extra por cada kill con chainsaw

### Restricciones de Armas
Algunas habilidades requieren armas específicas:
- **Berserker**: Requiere melee weapon
- **Rapid Fire**: Requiere M16 Assault Rifle
- **Heat Seeker**: Requiere Grenade Launcher
- **Chainsaw Massacre**: Da y requiere Chainsaw

### Interacciones Especiales
- **NightCrawler**: Rompe agarres de infectados y auto-revive
- **LifeStealer**: Puede auto-revivirse si está incapacitado
- **FlameShield**: Daña a Smokers que te agarren
- **Soulshield**: Inmunidad total (no bloquea empujones/knockback)

### Modo Nightmare
Algunas habilidades están deshabilitadas en modo Nightmare:
- Berserker
- Polymorph
- Instagib
- LifeStealer (parcialmente)

---

## ✅ Conclusión

El sistema de habilidades activas es robusto y bien estructurado. Cada habilidad tiene un propósito claro y mecánicas únicas. La implementación en el Eclipse Management System requeriría:

1. Crear módulos individuales para cada habilidad
2. Integrar con el sistema de leveling existente
3. Agregar opciones al menú de compra (!buy)
4. Implementar el sistema de timers y cooldowns
5. Agregar efectos visuales y de sonido
6. Balancear para el gameplay actual del servidor

El código del backup es una excelente referencia y puede ser adaptado módulo por módulo al sistema actual.
