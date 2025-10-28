# CONSOLIDADO DE COMANDOS - SISTEMA ECLIPSE
**Eclipse Management System - Left 4 Dead 2**

---

## ÍNDICE
1. [Comandos de Jugador](#comandos-de-jugador)
2. [Comandos de Información](#comandos-de-información)
3. [Comandos Administrativos](#comandos-administrativos)
4. [Sistema de Menú de Compra](#sistema-de-menú-de-compra)
5. [Sistema de Nivelación](#sistema-de-nivelación)
6. [Habilidades Activas](#habilidades-activas)

---

## COMANDOS DE JUGADOR

### Sistema de Compra
| Comando | Descripción | Acceso |
|---------|-------------|--------|
| `buy` | Abre el menú de compra principal | Todos |
| `sm_buy` | Abre el menú de compra principal | Todos |

**Funcionalidades del menú de compra:**
- **Instantáneos**:
  - Convert HP: Convierte HP en otro beneficio
  - Fire Yell: Grito de fuego
  - Power Yell: Grito de poder
  - Leap of Desperation: Salto desesperado

- **Acciones Largas**:
  - Survivor Speed: Aumento de velocidad temporal

- **Desplegables**:
  - Ammo Pack: Paquete de munición
  - Defense Grid: Rejilla defensiva
  - Healing Station: Estación de curación
  - Ion Cannon: Cañón de iones
  - UV Light: Luz ultravioleta

- **Bonificaciones de Equipo**:
  - Team Heal: Curación de equipo
  - Team Speed Boost: Aumento de velocidad de equipo

---

## COMANDOS DE INFORMACIÓN

### Información de Nivel y XP
| Comando | Descripción | Acceso |
|---------|-------------|--------|
| `sm_level` | Muestra tu información de nivel y experiencia | Todos |
| `sm_xp` | Muestra tu información de nivel y experiencia | Todos |
| `sm_exp` | Muestra tu información de nivel y experiencia | Todos |

**Información mostrada:**
- Nivel actual
- XP actual / XP requerido para siguiente nivel
- XP total acumulado
- Barra de progreso visual
- Porcentaje de progreso

### Información de Rewards
| Comando | Descripción | Acceso |
|---------|-------------|--------|
| `sm_rewards` | Muestra el menú de tus rewards activos | Todos |
| `sm_myrewards` | Muestra el menú de tus rewards activos | Todos |
| `sm_skills` | Muestra el menú de tus rewards activos | Todos |
| `sm_perks` | Muestra el menú de tus rewards activos | Todos |

**Menú de Rewards incluye:**
- Ver Rewards Activos
- Ver Rewards Bloqueados
- Ver Todos los Rewards
- Próximo Reward a desbloquear
- Descripción detallada de cada reward
- Niveles requeridos

---

## COMANDOS ADMINISTRATIVOS

### Gestión del Sistema
| Comando | Descripción | Acceso | Flags |
|---------|-------------|--------|-------|
| `rp` | Recarga todos los plugins | Admin | ROOT |
| `rt` | Recarga las traducciones | Admin | ROOT |

### Gestión de Dinero
| Comando | Descripción | Acceso | Flags |
|---------|-------------|--------|-------|
| `sm_givemoney` | Abre menú para dar dinero a jugadores | Admin | GENERIC |
| `sm_money` | Abre menú para dar dinero a jugadores | Admin | GENERIC |

**Funcionalidades:**
- Seleccionar jugador (excluye bots)
- Cantidades predefinidas: 25, 50, 100, 250, 500, 1000
- Opción de cantidad personalizada
- Registro de transacciones en logs

**Uso alternativo:**
```
sm_givemoney <cantidad>
```
Después de abrir el menú y seleccionar jugador objetivo.

### Debug de Leveling
| Comando | Descripción | Acceso | Flags |
|---------|-------------|--------|-------|
| `sm_rewardsdebug` | Abre el menú de debug de rewards | Admin | ROOT |
| `sm_rdebug` | Abre el menú de debug de rewards | Admin | ROOT |
| `sm_setlevel` | Establece el nivel de un jugador temporalmente | Admin | ROOT |

**Uso de sm_setlevel:**
```
sm_setlevel <jugador> <nivel>
```

**Menú de Debug incluye:**
- Testing de Rewards Pasivos
- Activación manual de rewards
- Gestión de nivel temporal
- Niveles predefinidos: 1, 10, 20, 30, 40, 50
- Reset de overrides de debug

---

## SISTEMA DE MENÚ DE COMPRA

### Estructura del Menú
El menú de compra está organizado en las siguientes categorías:

#### 1. INSTANTÁNEOS (Efectos inmediatos)
- **Convert HP**: Convierte puntos de vida en beneficios
- **Fire Yell**: Grito que causa daño de fuego en área
- **Power Yell**: Grito que causa daño y knockback
- **Leap of Desperation**: Salto de emergencia para escapar

#### 2. ACCIONES LARGAS (Efectos con duración)
- **Survivor Speed**: Aumento temporal de velocidad de movimiento

#### 3. DESPLEGABLES (Objetos colocables)
- **Ammo Pack**: Despliega munición para el equipo
- **Defense Grid**: Sistema de defensa automático
- **Healing Station**: Estación que cura gradualmente
- **Ion Cannon**: Cañón orbital de alto daño (INTEGRADO 100%)
- **UV Light**: Luz que daña a infectados

#### 4. BONIFICACIONES DE EQUIPO
- **Team Heal**: Curación instantánea para todo el equipo
- **Team Speed Boost**: Velocidad aumentada para todo el equipo

---

## SISTEMA DE NIVELACIÓN

### Obtención de XP
El sistema otorga experiencia por las siguientes acciones:

#### Combate
- **Infectado común muerto**: XP variable
- **Infectado especial muerto**: XP según tipo
  - Smoker, Hunter, Jockey, Spitter, Charger: XP medio
  - Boomer: XP bajo
- **Tank muerto**: XP alto
- **Witch muerta**: XP alto

#### Cooperación
- **Curar compañero**: XP por uso exitoso de botiquín
- **Revivir compañero**: XP por revivir
- **Usar desfibrilador**: XP por resucitar con desfibrilador

#### Progreso
- **Salir del área segura**: XP al iniciar mapa
- **Completar mapa**: XP al finalizar mapa

### Sistema de Progreso
- **Nivel máximo**: 50 (configurable)
- **XP requerido**: Escala progresivamente por nivel
- **Progreso persistente**: XP y nivel se guardan en base de datos
- **Interfaz visual**: Barra de progreso y notificaciones en chat

---

## REWARDS PASIVOS POR NIVEL

### Lista Completa de Rewards
| Nivel | Reward | Descripción |
|-------|--------|-------------|
| 1 | **Double Jump** | Permite realizar un segundo salto en el aire |
| 2 | **Acrobatics** | +Altura de salto, -50% daño de caída |
| 3 | **Health Bonus** | +25 HP adicionales al aparecer |
| 4 | **Medic** | Bonus HP de items curativos (Pills: +50, Adrenaline: +25, First Aid: +200) |
| 6 | **Pack Rat** | +25% capacidad de munición |
| 8 | **Desert Cobra** | Magnum al ser incapacitado |
| 9 | **Damage Reduction** | -5% daño recibido |
| 10 | **Gene Mutations I** | +100 HP máximo, +1 HP/5s regeneración |
| 11 | **Self Revive** | Auto-revive con tecla USE (2.5s) |
| 13 | **Sleight of Hand** | Recarga 2x más rápida |
| 15 | **Knife** | Apuñalar para liberarse de especiales (1.5s) |
| 17 | **Hard to Kill** | HP de incapacitación: 300 → 500 |
| 19 | **Arms Dealer** | Mochila expandida: 9 → 40 items |
| 20 | **Gene Mutations II** | +200 HP máximo (total: +300), +2 HP/5s regeneración |
| 22 | **Surgeon** | -50% tiempo de uso de items de curación |
| 24 | **Extreme Conditioning** | +25% velocidad de movimiento |
| 26 | **BullsEye** | Laser sight gratis en armas primarias |
| 29 | **Size Matters** | Recarga M60 y Grenade Launcher en ammo piles |
| 30 | **Gene Mutations III** | +300 HP máximo (total: +600), +3 HP/5s regeneración |
| 32 | **Master at Arms** | Daño melee x2 (100 → 200) |
| 35 | **Hardened Stance** | Elimina stagger de Witch |
| 38 | **Critical Hit** | 10% probabilidad de crítico (1.5x - 3.0x daño) |
| 40 | **Gene Mutations IV** | +400 HP máximo (total: +1000), +4 HP/5s regeneración |
| 41 | **Commando** | Recarga M60 en ammo piles, cartucho extendido de 300 balas |
| 44 | **Second Chance** | Auto-revive automático 1 vez por ronda |
| 47 | **Laser Rounds** | Munición láser para rifles y SMGs con daño aumentado e incineración |

---

## HABILIDADES ACTIVAS

Las habilidades activas se desbloquean al alcanzar ciertos niveles y pueden activarse usando el menú de compra o comandos específicos.

### Acid Bath
**Nivel requerido:** Variable (configurado en sistema)

**Descripción:** Crea un charco de ácido que daña a los infectados que entran en contacto.

**Características:**
- Área de efecto
- Daño continuo a infectados
- Duración limitada
- Visual de partículas ácidas

### Berserker
**Nivel requerido:** Variable (configurado en sistema)

**Descripción:** Aumenta significativamente el daño cuerpo a cuerpo y la resistencia al daño.

**Características:**
- Daño melee aumentado
- Reducción de daño recibido
- Efecto visual de furia
- Duración temporal con cooldown

### LifeStealer
**Nivel requerido:** Variable (configurado en sistema)

**Descripción:** Cada golpe a enemigos roba vida y la transfiere al jugador.

**Características:**
- Robo de vida por golpe
- Efecto visual en enemigos afectados
- Duración temporal
- Cooldown entre usos

### Shoulder Cannon (Cañón de Hombro)
**Nivel requerido:** Variable (configurado en sistema)

**Descripción:** Despliega un cañón en el hombro que dispara automáticamente a infectados.

**Características:**
- Disparo automático
- Múltiples modos de disparo
- Munición limitada
- Sistema de recarga
- Visual completo con modelo y efectos

**Modos de disparo:**
- Automático continuo
- Ráfaga controlada
- Disparo de precisión

### Speed Freak
**Nivel requerido:** Variable (configurado en sistema)

**Descripción:** Aumenta drásticamente la velocidad de movimiento y ataque.

**Características:**
- Velocidad de movimiento muy aumentada
- Velocidad de ataque aumentada
- Efectos visuales de velocidad
- Duración temporal
- Cooldown entre activaciones

**Uso:**
Todas las habilidades activas se gestionan a través del sistema de nivelación y pueden tener:
- Cooldowns individuales
- Costos de activación en puntos
- Duraciones configurables
- Efectos visuales y sonoros únicos

---

## CONVARS DEL SISTEMA

### Sistema de Leveling
```
leveling_ui_show_spawn "1"           // Mostrar nivel/XP al aparecer (0/1)
leveling_ui_show_kill "1"            // Mostrar XP ganado al matar (0/1)
leveling_ui_progress_bar "1"         // Mostrar barra de progreso ASCII (0/1)
leveling_info_enabled "1"            // Habilita menú de información de rewards (0/1)
leveling_debug_enabled "1"           // Habilita sistema de debug (0/1)
```

### Sistema de Compra
```
admin_money_enabled "1"              // Habilita menú de admin para dar dinero (0/1)
sm_spawnammo_debug "0"               // Activa debug verboso (0/1)
```

### Configuración General
Todas las convars se pueden modificar en:
- `cfg/sourcemod/plugin.eclipse.cfg` (si existe)
- Consola del servidor
- Archivos de configuración personalizados

---

## NOTAS IMPORTANTES

### Sistema de Persistencia
- **XP y Nivel**: Se guardan en base de datos SQLite/MySQL
- **Rewards**: Se calculan en tiempo real según el nivel
- **Cooldowns**: Se resetean al cambiar de mapa
- **Debug**: Los niveles de debug son temporales (solo para testing)

### Permisos Administrativos
- **ADMFLAG_ROOT**: Acceso completo al sistema (rp, rt, debug)
- **ADMFLAG_GENERIC**: Comandos administrativos básicos (givemoney)
- **ADMFLAG_CHEATS**: Comandos de prueba y desarrollo

### Sistema de Logs
El sistema registra automáticamente:
- Transacciones de dinero admin → jugador
- Cambios de nivel
- Activación de habilidades
- Errores del sistema

**Ubicación de logs:**
```
logs/eclipse_system.log
addons/sourcemod/logs/eclipse_system_YYYYMMDD.log
```

### Compatibilidad
- **L4D2 Version**: Compatible con últimas versiones
- **Sourcemod**: Requiere SM 1.10 o superior
- **Metamod**: Requiere MM 1.11 o superior
- **Extensiones**: SDKHooks, SDKTools

---

## SOLUCIÓN DE PROBLEMAS

### Los comandos no funcionan
1. Verificar que el plugin esté cargado: `sm plugins list`
2. Verificar permisos en `configs/admins.cfg`
3. Revisar logs de errores en `logs/errors_*.log`

### XP no se guarda
1. Verificar conexión a base de datos
2. Revisar `addons/sourcemod/configs/databases.cfg`
3. Verificar permisos de escritura en `data/` folder

### Rewards no se activan
1. Verificar nivel requerido: `sm_level`
2. Revisar si hay overrides de debug activos
3. Usar `sm_rdebug` para testing manual

### Problemas de rendimiento
1. Reducir XP events si hay lag
2. Ajustar frecuencia de regeneración de HP
3. Limitar número de partículas activas simultáneas

---

## INTEGRACIONES COMPLETADAS

### Ion Cannon - Integración 100%
**Estado:** COMPLETADO ✓

El sistema Ion Cannon ha sido completamente integrado al núcleo de Eclipse, eliminando la dependencia del plugin standalone.

#### Antes de la integración:
- Plugin standalone separado: `standalone plugins/ion.sp` (1551 líneas)
- API pública con 5 natives y 2 forwards
- 20+ ConVars configurables
- 6 comandos de consola (!ion, sm_ion, admin commands)
- Archivo de configuración externo
- Tamaño: ~45KB

#### Después de la integración:
- Módulo integrado: `modules/buy module/features/03-deployables/ion-cannon/ion-cannon.module.sp` (680 líneas)
- Sin API pública - funciones internas
- Configuración fija en defines
- Solo accesible vía menú de compra
- Sin comandos de consola
- Tamaño: ~15KB

#### Características mantenidas:
✓ Efectos visuales completos:
  - 6 beams orbitales rotatorios
  - Explosiones en anillo
  - Beam central desde el cielo
  - Efectos de partículas
  - Screen shake
  - Explosiones físicas

✓ Sistema de daño:
  - Daño a infectados comunes: 10 HP por tick
  - Daño a infectados especiales: 10 HP por tick
  - Solo daña team 3 (infectados)
  - Seguridad para sobrevivientes

✓ Sistema de cargas:
  - 3 cargas máximas
  - Restauración al inicio de ronda
  - Cooldown de 45 segundos entre usos
  - Tracking por jugador

✓ Sistema de cleanup:
  - Validación de tokens
  - Limpieza de entidades
  - Gestión de timers
  - Prevención de memory leaks

#### Beneficios de la integración:
- **Rendimiento**: Reducción de ~30KB en el tamaño del plugin
- **Mantenibilidad**: Todo el código en un solo proyecto
- **Simplicidad**: Sin dependencias externas
- **Seguridad**: Sin exposición de API pública
- **Consistencia**: Integrado con el sistema de moneda Eclipse

#### Archivos modificados:
1. `modules/buy module/features/03-deployables/ion-cannon/ion-cannon.module.sp` (NUEVO)
2. `modules/buy module/features/03-deployables/ion-cannon.feature.sp` (ACTUALIZADO)
3. `modules/buy module/buy-menu.module.sp` (ACTUALIZADO)
4. `Eclipse Management System.sp` (ACTUALIZADO)

#### Archivo obsoleto:
❌ `standalone plugins/ion.sp` - YA NO ES NECESARIO

### Bloodmoon Mode - Integración 100%
**Estado:** COMPLETADO ✓

El modo Bloodmoon ha sido completamente integrado como módulo del sistema Eclipse.

#### Características:
- Efectos visuales de pantalla (red fade)
- Modificación de dificultad del director
- Sistema de fog controller
- Efectos de partículas
- Activación manual y automática
- Integrado con sistema de hooks

#### Archivos:
- `modules/modes/bloodmoon.module.sp` (680 líneas)
- Traducciones en `translations/eclipse.phrases.txt`

#### Archivo obsoleto:
❌ `standalone plugins/bloodmoon.sp` - YA NO ES NECESARIO

---

## CRÉDITOS Y VERSIÓN

**Sistema:** Eclipse Management System
**Versión:** 3.x
**Desarrollador:** Socius
**Plataforma:** Left 4 Dead 2
**Sourcemod Version:** 1.10+

**Módulos incluidos:**
- Sistema de Nivelación
- Sistema de Experiencia
- Sistema de Rewards
- Sistema de Moneda
- Sistema de Compra
- Habilidades Activas
- Debug y Testing Tools

---

**Última actualización:** 2025-10-28
**Archivo:** COMANDOS_ECLIPSE.md
