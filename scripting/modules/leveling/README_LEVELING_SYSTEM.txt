╔═══════════════════════════════════════════════════════════════════════════════╗
║                    LEVELING SYSTEM - SISTEMA DE NIVELES                       ║
║                        Left 4 Dead 2 - SourceMod Plugin                       ║
╚═══════════════════════════════════════════════════════════════════════════════╝

===================================================================================
                              DESCRIPCION GENERAL
===================================================================================

Sistema de leveling completo para L4D2 que permite a los jugadores ganar XP por
realizar acciones en el juego, subir de nivel y obtener beneficios/rewards.

Caracteristicas principales:
✓ Sistema de XP con progresion configurable por dificultad
✓ 4 modos de dificultad (Facil, Normal, Avanzado, Experto)
✓ Base de datos persistente (MySQL/SQLite)
✓ Sincronizacion en tiempo real
✓ Sistema de rewards por niveles
✓ UI en chat con barra de progreso
✓ Comandos para ver estadisticas

===================================================================================
                           ARQUITECTURA DE MODULOS
===================================================================================

📁 modules/leveling/
├── leveling-system.module.sp       → Core del sistema (XP, niveles, BD)
├── leveling-xp-events.module.sp    → Eventos que otorgan XP
├── leveling-rewards.module.sp      → Beneficios por nivel (doble salto, etc)
└── leveling-ui.module.sp           → Interfaz en chat

===================================================================================
                           Configuracion DE BASE DE DATOS
===================================================================================

1. Crear la tabla en tu base de datos:

   CREATE TABLE IF NOT EXISTS player_levels (
       steamid VARCHAR(32) PRIMARY KEY,
       player_name VARCHAR(128),
       current_level INT DEFAULT 0,
       current_xp INT DEFAULT 0,
       total_xp INT DEFAULT 0,
       last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );

2. Configurar databases.cfg (ubicado en addons/sourcemod/configs/databases.cfg):

   "players"
   {
       "driver"    "mysql"
       "host"      "tu-servidor-mysql.com"
       "database"  "nombre_base_datos"
       "user"      "usuario"
       "pass"      "contrasena"
       "port"      "3306"
   }

===================================================================================
                              FORMULAS DE PROGRESION
===================================================================================

El XP requerido para subir de nivel se calcula con:

    XP_Requerido = base_xp * (nivel + 1)^exponente

Donde el exponente cambia segun la dificultad:

┌─────────────┬────────────┬────────────────────────────────────────────────┐
│ DIFICULTAD  │ EXPONENTE  │ EJEMPLO (base_xp = 800)                        │
├─────────────┼────────────┼────────────────────────────────────────────────┤
│ Facil       │ 1.1        │ Nivel 1: 800 XP | Nivel 5: 5,217 XP            │
│ Normal      │ 1.25       │ Nivel 1: 800 XP | Nivel 5: 7,465 XP            │
│ Avanzado    │ 1.4        │ Nivel 1: 800 XP | Nivel 5: 10,702 XP           │
│ Experto     │ 1.6        │ Nivel 1: 800 XP | Nivel 5: 16,646 XP           │
└─────────────┴────────────┴────────────────────────────────────────────────┘

===================================================================================
                            EVENTOS QUE OTORGAN XP
===================================================================================

┌─────────────────────────────┬────────────┬──────────────────────────┐
│ EVENTO                      │ XP         │ CONVAR                   │
├─────────────────────────────┼────────────┼──────────────────────────┤
│ Matar infectado comun       │ 5 XP       │ xp_common_kill           │
│ Matar infectado especial    │ 15 XP      │ xp_special_kill          │
│ Matar Tank                  │ 50 XP      │ xp_tank_kill             │
│ Matar Witch                 │ 40 XP      │ xp_witch_kill            │
│ Headshot (bonus)            │ 10 XP      │ xp_headshot              │
│ Revivir companero           │ 20 XP      │ xp_revive                │
│ Curar companero             │ 5 XP       │ xp_heal                  │
│ Usar desfibrilador          │ 25 XP      │ xp_defibrillator         │
└─────────────────────────────┴────────────┴──────────────────────────┘

===================================================================================
                          REWARDS/BENEFICIOS POR NIVEL
===================================================================================

┌────────┬─────────────────────────┬──────────────────────────────────────┐
│ NIVEL  │ REWARD                  │ DESCRIPCION                          │
├────────┼─────────────────────────┼──────────────────────────────────────┤
│ 1      │ Doble Salto             │ Permite saltar una segunda vez       │
│        │                         │ en el aire                           │
├────────┼─────────────────────────┼──────────────────────────────────────┤
│ 2      │ +10% Velocidad          │ Aumenta la velocidad de movimiento   │
├────────┼─────────────────────────┼──────────────────────────────────────┤
│ 3      │ +25 HP                  │ Otorga 25 puntos de salud            │
│        │                         │ adicionales al aparecer              │
├────────┼─────────────────────────┼──────────────────────────────────────┤
│ 4      │ Resistencia a Dano      │ Reduce el dano recibido en 5%        │
└────────┴─────────────────────────┴──────────────────────────────────────┘

===================================================================================
                           CONVARS DE Configuracion
===================================================================================

CORE SYSTEM:
-------------
leveling_base_xp                "800"       - XP base para nivel 1
leveling_formula_easy           "1.1"       - Exponente formula Facil
leveling_formula_normal         "1.25"      - Exponente formula Normal
leveling_formula_advanced       "1.4"       - Exponente formula Avanzado
leveling_formula_expert         "1.6"       - Exponente formula Experto
leveling_difficulty             "0"         - Dificultad actual (0-3)
leveling_debug                  "0"         - Debug verboso (0/1)

XP EVENTS:
-----------
xp_common_kill                  "5"         - XP por infectado comun
xp_special_kill                 "15"        - XP por infectado especial
xp_tank_kill                    "50"        - XP por Tank
xp_witch_kill                   "40"        - XP por Witch
xp_headshot                     "10"        - XP bonus por headshot
xp_revive                       "20"        - XP por revivir
xp_heal                         "5"         - XP por curar
xp_defibrillator                "25"        - XP por desfibrilador

REWARDS:
---------
reward_double_jump_level        "1"         - Nivel para doble salto
reward_speed_boost_level        "2"         - Nivel para velocidad
reward_speed_boost_value        "1.1"       - Multiplicador velocidad
reward_health_level             "3"         - Nivel para +HP
reward_health_value             "25"        - HP adicional
reward_damage_reduction_level   "4"         - Nivel para resistencia
reward_damage_reduction_value   "0.95"      - Multiplicador dano

UI:
----
leveling_ui_show_spawn          "1"         - Mostrar info al aparecer
leveling_ui_show_kill           "1"         - Mostrar XP al matar
leveling_ui_progress_bar        "1"         - Mostrar barra progreso

===================================================================================
                             COMANDOS DISPONIBLES
===================================================================================

COMANDOS DE JUGADOR:
---------------------
sm_level    - Muestra informacion de nivel actual
sm_xp       - Alias de sm_level
sm_exp      - Alias de sm_level

OUTPUT EJEMPLO:
---------------
=== INFORMACION DE NIVEL ===
Level: 2
XP Actual: 450 / 1662
XP Total: 2250
Progreso: [████████████░░░░░░░░] 27%

===================================================================================
                              EJEMPLO DE USO
===================================================================================

Configuracion INICIAL:
----------------------
1. Subir el plugin compilado (.smx) a addons/sourcemod/plugins/
2. Configurar databases.cfg con los datos de tu BD remota
3. Crear la tabla player_levels en tu base de datos
4. Reiniciar el servidor o ejecutar: sm plugins load "Eclipse Management System"
5. Configurar ConVars en server.cfg segun preferencias

EJEMPLO server.cfg:
-------------------
// Sistema de Leveling
leveling_difficulty "1"              // Dificultad Normal
leveling_base_xp "800"                // 800 XP base

// Recompensas XP
xp_common_kill "5"
xp_special_kill "15"
xp_tank_kill "50"

// UI
leveling_ui_show_spawn "1"
leveling_ui_show_kill "1"

===================================================================================
                              FLUJO DEL SISTEMA
===================================================================================

1. JUGADOR SE CONECTA
   └─> Se carga su nivel/XP desde la base de datos

2. JUGADOR REALIZA ACCION (ej: matar Tank)
   └─> leveling-xp-events.module.sp detecta el evento
       └─> Leveling_AwardXP(client, 50, "Matar Tank")
           └─> Se actualiza g_iPlayerXP[client]
           └─> Se verifica si sube de nivel
               └─> SI: Leveling_OnLevelUp(client)
                   └─> Mostrar mensaje en chat
                   └─> LevelingRewards_ApplyRewards(client, nivel)
           └─> Se actualiza BD en tiempo real (async)
           └─> Se muestra XP ganado en chat

3. JUGADOR APARECE EN MAPA
   └─> Se aplican rewards segun nivel
   └─> Se muestra info de nivel/XP

4. JUGADOR SE DESCONECTA
   └─> Se resetean variables en memoria
   └─> Datos quedan guardados en BD (persistentes)

===================================================================================
                              LOGS Y DEBUG
===================================================================================

ARCHIVOS DE LOG:
----------------
addons/sourcemod/logs/Leveling_System.log    - Log del sistema de leveling
addons/sourcemod/logs/Eclipse_Management_System.log - Log general

ACTIVAR DEBUG:
--------------
sm_cvar leveling_debug 1

EJEMPLO OUTPUT DEBUG:
---------------------
[INIT] Leveling System v1.0.0 inicializado
[LOAD] Player - Nivel: 2, XP: 450/1662, Total: 2250
[XP] Player +15 XP (Matar infectado especial) - Nivel: 2, XP: 465/1662
[LEVELUP] Player alcanzo Nivel 3
[ERROR] Fallo al cargar datos de nivel: Connection timeout

===================================================================================
                         INTEGRACION CON CURRENCY
===================================================================================

El sistema de leveling esta SEPARADO del sistema de currency:

- CURRENCY (dinero) → Se usa para comprar items en el buy menu
- LEVELING (XP)     → Se usa para subir de nivel y ganar rewards

Ambos sistemas reaccionan a los mismos eventos del juego pero de forma
independiente. Por ejemplo:

    Matar Tank → +20 CURRENCY (dinero) + 50 XP (experiencia)

===================================================================================
                           TROUBLESHOOTING
===================================================================================

PROBLEMA: Los jugadores no ganan XP
SOLUCION:
  - Verificar que la BD este conectada correctamente
  - Revisar logs en addons/sourcemod/logs/Leveling_System.log
  - Activar debug: sm_cvar leveling_debug 1

PROBLEMA: El doble salto no funciona
SOLUCION:
  - Verificar que el jugador sea nivel 1 o superior
  - Revisar que no haya conflictos con otros plugins de movimiento

PROBLEMA: Los datos no persisten entre mapas
SOLUCION:
  - Verificar conexion a BD remota en databases.cfg
  - Verificar que la tabla player_levels exista

PROBLEMA: Error "symbol already defined: OnClientDisconnect"
SOLUCION:
  - Ya esta resuelto: la llamada se agrego al OnClientDisconnect existente
    en buy-menu.module.sp

===================================================================================
                          AUTOR Y LICENCIA
===================================================================================

Autor: Eclipse Team
Version: 1.0.0
Compatible con: L4D2, SourceMod 1.11+

===================================================================================
