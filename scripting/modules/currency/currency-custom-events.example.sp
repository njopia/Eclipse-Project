#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === CURRENCY CUSTOM EVENTS EXAMPLE ===
// Este archivo es un TEMPLATE para agregar eventos personalizados
// Copiar y renombrar a: currency-custom-events.module.sp
// Luego descomentar #tryinclude en Eclipse Management System.sp
//==================================================

// --- ConVars para eventos personalizados ---
Handle cvar_CurrencyCustomEvent1 = INVALID_HANDLE;
Handle cvar_CurrencyCustomEvent2 = INVALID_HANDLE;

/**
 * Ejemplo: Inicializar eventos personalizados
 * Llamar desde CurrencyEvents_OnPluginStart() si se necesita
 */
public void CurrencyCustomEvents_OnPluginStart()
{
	// Crear ConVars
	cvar_CurrencyCustomEvent1 = CreateConVar("currency_custom_event1", "10", "Puntos por evento personalizado 1", FCVAR_PLUGIN);
	cvar_CurrencyCustomEvent2 = CreateConVar("currency_custom_event2", "5", "Puntos por evento personalizado 2", FCVAR_PLUGIN);

	// Registrar hooks de eventos personalizados
	// Ejemplo: HookEvent("map_transition", Event_CustomEvent1, EventHookMode_Pre);
}

/**
 * TEMPLATE: Evento personalizado 1
 * Describe aquí qué hace este evento
 */
public Action Event_CustomEvent1(Event event, const char[] name, bool dontBroadcast)
{
	// Obtener información del evento
	// int client = GetClientOfUserId(event.GetInt("userid"));

	// Validar cliente
	// if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	//	return Plugin_Continue;

	// Obtener reward
	// int reward = GetConVarInt(cvar_CurrencyCustomEvent1);

	// Otorgar currency
	// AwardCurrency(client, reward, "Evento personalizado 1");

	// Actualizar stats si lo necesita
	// CurrencyStats_AddEarnings(client, reward);

	return Plugin_Continue;
}

/**
 * TEMPLATE: Evento personalizado 2
 * Describe aquí qué hace este evento
 */
public Action Event_CustomEvent2(Event event, const char[] name, bool dontBroadcast)
{
	// Similar a Event_CustomEvent1
	// Implementar según necesidad

	return Plugin_Continue;
}

//==================================================
// INSTRUCCIONES PARA CREAR UN EVENTO PERSONALIZADO:
//==================================================
//
// 1. IDENTIFICA el evento L4D2 que quieres usar
//    Referencia: https://wiki.alliedmods.net/Left_4_Dead_2_Events
//
// 2. COPIA la estructura de arriba (Event_CustomEvent1)
//
// 3. REEMPLAZA:
//    - Event_CustomEvent1 con un nombre descriptivo
//    - "map_transition" con el evento real
//    - cvar_CurrencyCustomEvent1 con un nombre apropiado
//
// 4. IMPLEMENTA la lógica:
//    - Obtén el cliente/datos del evento
//    - Valida el cliente
//    - Obtén el reward del ConVar
//    - Llama a AwardCurrency()
//    - (Opcional) Actualiza estadísticas
//
// 5. PRUEBA en servidor de desarrollo
//
//==================================================
// EVENTOS DISPONIBLES EN L4D2:
//==================================================
//
// Supervivencia:
// - player_death              (Superviviente muere)
// - player_incapacitated      (Superviviente incapacitado)
// - player_now_it             (Jugador cegado)
// - player_no_longer_it       (Ceguera termina)
//
// Infectados:
// - infected_death            (Infectado común muere)
// - tank_killed               (Tank muere)
// - witch_killed              (Witch muere)
//
// Acciones:
// - heal_success              (Curación exitosa)
// - revive_success            (Revive exitoso)
// - tongue_pull_stopped       (Escape de Smoker)
// - pounce_stopped            (Escape de Hunter)
// - jockey_ride_end           (Bajada de Jockey)
// - charger_impact            (Impacto de Charger)
//
// Mapa:
// - map_transition            (Transición de mapa)
// - round_start               (Inicio de ronda)
// - survival_round_start      (Inicio ronda Survival)
//
// Armas/Items:
// - weapon_given              (Arma dada)
// - defibrillator_used        (Desfibrilador usado)
// - upgrade_pack_used         (Paquete de mejora)
//
//==================================================
