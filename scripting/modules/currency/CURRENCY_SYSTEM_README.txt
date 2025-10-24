===============================================================
ECLIPSE MANAGEMENT SYSTEM - CURRENCY EVENTS IMPLEMENTATION
===============================================================

DESCRIPCIÓN GENERAL:
El sistema de currency ahora está vinculado a eventos del juego.
Los jugadores ganan puntos por diferentes acciones en el juego.

===============================================================
MÓDULOS CREADOS:
===============================================================

1. currency-events.module.sp
   - Eventos básicos: Matar infectados, Tank, Witch
   - Eventos de curación: Heal, Revive, Defibrillator
   - Maneja headshots como bonus
   - 8 ConVars configurables

2. currency-advanced-events.module.sp
   - Eventos especiales: Escapes de infectados especiales
   - Survival mode completion
   - Saves (liberar amigos de infectados)
   - 7 ConVars adicionales

3. currency-stats.module.sp
   - Rastrea estadísticas por jugador
   - Total de currency ganada por sesión
   - Contadores de kills, headshots, revives, heals
   - Función para mostrar stats a jugadores

===============================================================
CONVARS DISPONIBLES:
===============================================================

EVENTOS BÁSICOS:
- currency_common_kill (default: 1)
- currency_special_kill (default: 5)
- currency_tank_kill (default: 20)
- currency_witch_kill (default: 15)
- currency_headshot (default: 2) - Bonus por headshot

CURACIÓN Y REVIVE:
- currency_revive (default: 3)
- currency_heal (default: 1)
- currency_defibrillator (default: 5)

EVENTOS AVANZADOS:
- currency_incap_save (default: 2)
- currency_smoker_save (default: 3)
- currency_hunter_save (default: 3)
- currency_charger_save (default: 3)
- currency_jockey_save (default: 3)
- currency_spitter_save (default: 2)
- currency_survival_round (default: 10)

===============================================================
EVENTOS DEL JUEGO VINCULADOS:
===============================================================

MUERTES:
✓ infected_death - Matar infectado común
✓ tank_killed - Matar Tank
✓ witch_killed - Matar Witch

CURACIÓN:
✓ heal_success - Curar compañero
✓ revive_success - Revivir compañero
✓ defibrillator_used - Usar desfibrilador (L4D2)

ESCAPES/SAVES:
✓ tongue_pull_stopped - Escapar de Smoker
✓ pounce_stopped - Escapar de Hunter
✓ jockey_ride_end - Bajarse del Jockey
✓ charger_impact - Impacto de Charger
✓ survival_round_start - Completar ronda Survival

===============================================================
ARCHIVOS ESTRUCTURALES:
===============================================================

scripting/modules/currency/
├── currency-events.module.sp           (Eventos básicos y avanzados)
├── currency-advanced-events.module.sp  (Saves y eventos especiales)
├── currency-stats.module.sp            (Estadísticas por jugador)
└── currency-config.txt                 (Guía de configuración)

===============================================================
FUNCIONES STOCK DISPONIBLES:
===============================================================

PARA OTORGAR CURRENCY:
- AwardCurrency(client, amount, reason)

PARA MODIFICAR RECOMPENSAS:
- CurrencyEvents_SetCommonReward(amount)
- CurrencyEvents_SetSpecialReward(amount)
- CurrencyEvents_SetTankReward(amount)
- CurrencyEvents_SetWitchReward(amount)
- CurrencyAdvancedEvents_SetIncapSaveReward(amount)
- CurrencyAdvancedEvents_SetSmokerSaveReward(amount)
- CurrencyAdvancedEvents_SetHunterSaveReward(amount)
- CurrencyAdvancedEvents_SetChargerSaveReward(amount)
- CurrencyAdvancedEvents_SetJockeySaveReward(amount)
- CurrencyAdvancedEvents_SetSpitterSaveReward(amount)

PARA OBTENER INFORMACIÓN:
- GetPlayerCurrency(client)
- CurrencyStats_GetTotalEarned(client)
- CurrencyStats_GetCommonKills(client)
- CurrencyStats_GetSpecialKills(client)
- CurrencyStats_GetHeadshots(client)
- CurrencyStats_PrintPlayerStats(client)

===============================================================
ARQUITECTURA MODULAR:
===============================================================

Siguiendo el patrón del proyecto:

1. Cada módulo es INDEPENDIENTE pero COMPATIBLE
2. Se incluyen con #tryinclude en archivo principal
3. Utilizan #if !defined checks para evitar duplicados
4. Uso de ConVars para configuración dinámica
5. Stock functions para funcionalidad compartida

Inicialización:
OnPluginStart()
  → CurrencyEvents_OnPluginStart()
    → CurrencyAdvancedEvents_OnPluginStart()
    → Luego en CurrencyStats_OnPluginStart() si se necesita

===============================================================
CAMBIOS EN ARCHIVOS EXISTENTES:
===============================================================

Eclipse Management System.sp:
- Agregados includes para módulos currency
- Llamada a CurrencyEvents_OnPluginStart() en OnPluginStart()

buy-menu.module.sp:
- OnClientDisconnect: Agregada llamada a ResetPlayerCurrencyStats()
- AwardCurrency(): Agregada llamada a CurrencyStats_AddEarnings()

===============================================================
EJEMPLO DE USO:
===============================================================

Para cambiar el reward de matar comunes a 5 puntos:
  sm_cvar currency_common_kill 5

Para darle 100 puntos a un jugador específico:
  (Usaría AdminSetPlayerCurrency si se implementa)

Para ver stats de un jugador (usar stock function):
  CurrencyStats_PrintPlayerStats(client)

===============================================================
FLUJO DE DATOS:
===============================================================

Evento del Juego
  ↓
HookEvent detecta evento
  ↓
Valida al jugador
  ↓
Consulta ConVar para reward
  ↓
Llama a AwardCurrency()
  ↓
  ├→ Suma a g_iPlayerCurrency[client]
  ├→ Llama a CurrencyStats_AddEarnings()
  └→ Muestra mensaje al jugador

===============================================================
NOTAS IMPORTANTES:
===============================================================

1. MODULARIDAD:
   Los módulos pueden activarse/desactivarse comentando
   el #tryinclude en Eclipse Management System.sp

2. CONFIGURACIÓN:
   Todos los valores son ConVars editables en tiempo real
   No requiere recompilación para ajustar

3. COMPATIBILIDAD:
   ✓ L4D1 y L4D2 compatible
   ✓ Verificaciones de team y validación de cliente

4. EXTENSIBILIDAD:
   Fácil de agregar nuevos eventos:
   - Copiar estructura de evento existente
   - Crear nuevo ConVar
   - Agregar HookEvent

5. ESTADÍSTICAS:
   Las stats se resetean por desconexión del jugador
   Perfectas para auditoría y debugging

===============================================================
