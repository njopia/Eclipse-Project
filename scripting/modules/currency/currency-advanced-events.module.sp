#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === CURRENCY ADVANCED EVENTS MODULE ===
// Maneja eventos mas complejos para otorgar currency
// Incluye: Saves, Incaps, Team events, etc.
//==================================================

// --- ConVars para eventos avanzados ---
Handle cvar_CurrencyIncapSave = INVALID_HANDLE;
Handle cvar_CurrencySmokerSave = INVALID_HANDLE;
Handle cvar_CurrencyHunterSave = INVALID_HANDLE;
Handle cvar_CurrencyChargerSave = INVALID_HANDLE;
Handle cvar_CurrencyJockeySave = INVALID_HANDLE;
Handle cvar_CurrencySpitterSave = INVALID_HANDLE;
Handle cvar_CurrencySurvivalRound = INVALID_HANDLE;

/**
 * Inicializa el modulo de eventos avanzados de currency
 * Debe ser llamado desde CurrencyEvents_OnPluginStart()
 */
public void CurrencyAdvancedEvents_OnPluginStart()
{
	// Crear ConVars para eventos avanzados
	cvar_CurrencyIncapSave = CreateConVar("currency_incap_save", "2", "Puntos por salvar a un jugador incapacitado", FCVAR_PLUGIN);
	cvar_CurrencySmokerSave = CreateConVar("currency_smoker_save", "3", "Puntos por liberarse de Smoker", FCVAR_PLUGIN);
	cvar_CurrencyHunterSave = CreateConVar("currency_hunter_save", "3", "Puntos por detener a Hunter", FCVAR_PLUGIN);
	cvar_CurrencyChargerSave = CreateConVar("currency_charger_save", "3", "Puntos por escapar de Charger", FCVAR_PLUGIN);
	cvar_CurrencyJockeySave = CreateConVar("currency_jockey_save", "3", "Puntos por bajarse del Jockey", FCVAR_PLUGIN);
	cvar_CurrencySpitterSave = CreateConVar("currency_spitter_save", "2", "Puntos por evitar Spitter", FCVAR_PLUGIN);
	cvar_CurrencySurvivalRound = CreateConVar("currency_survival_round", "10", "Puntos por completar ronda de Survival", FCVAR_PLUGIN);

	// Registrar hooks de eventos avanzados
	HookEvent("player_incapacitated", Event_PlayerIncapacitated, EventHookMode_Pre);
	HookEvent("tongue_pull_stopped", Event_SmokSave, EventHookMode_Pre);
	HookEvent("pounce_stopped", Event_HunterSave, EventHookMode_Pre);
	HookEvent("charger_impact", Event_ChargerImpact, EventHookMode_Pre);
	HookEvent("jockey_ride_end", Event_JockeySave, EventHookMode_Pre);

	// L4D2 specific
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		HookEvent("survival_round_start", Event_SurvivalStart, EventHookMode_Pre);
	}
}

/**
 * Evento: Player Incapacitated
 * Se otorgan puntos a quien saca a un companero de incapacitado
 */
public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	// Este evento solo registra el incap, los puntos se dan cuando alguien lo saca
	// Usamos tongue_pull_stopped, pounce_stopped, etc. para las recompensas
	return Plugin_Continue;
}

/**
 * Evento: Tongue Pull Stopped (Smoker saved)
 * Se otorgan puntos al que es salvado de Smoker
 */
public Action Event_SmokSave(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	if (GetClientTeam(victim) != 2)
		return Plugin_Continue;

	// Otorgar puntos al que fue salvado
	int reward = GetConVarInt(cvar_CurrencySmokerSave);
	AwardCurrency(victim, reward, "Escapar de Smoker");

	return Plugin_Continue;
}

/**
 * Evento: Pounce Stopped (Hunter saved)
 * Se otorgan puntos al que es salvado de Hunter
 */
public Action Event_HunterSave(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	if (GetClientTeam(victim) != 2)
		return Plugin_Continue;

	// Otorgar puntos al que fue salvado
	int reward = GetConVarInt(cvar_CurrencyHunterSave);
	AwardCurrency(victim, reward, "Escapar de Hunter");

	return Plugin_Continue;
}

/**
 * Evento: Charger Impact
 * Se otorgan puntos a quien golpea a un Charger o lo detiene
 */
public Action Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	// Este evento se dispara cuando Charger impacta
	// Los puntos se dan mejor en charger_carry_start si alguien lo salva

	return Plugin_Continue;
}

/**
 * Evento: Jockey Ride End
 * Se otorgan puntos al que es salvado del Jockey
 */
public Action Event_JockeySave(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	if (GetClientTeam(victim) != 2)
		return Plugin_Continue;

	// Otorgar puntos al que fue salvado
	int reward = GetConVarInt(cvar_CurrencyJockeySave);
	AwardCurrency(victim, reward, "Bajarse del Jockey");

	return Plugin_Continue;
}

/**
 * Evento: Survival Round Start (L4D2 only)
 * Se otorgan puntos al completar una ronda de Survival
 */
public Action Event_SurvivalStart(Event event, const char[] name, bool dontBroadcast)
{
	// Cuando inicia una ronda de Survival, todos los survivors vivos ganan puntos
	int reward = GetConVarInt(cvar_CurrencySurvivalRound);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			AwardCurrency(i, reward, "Completar ronda de Survival");
		}
	}

	return Plugin_Continue;
}

/**
 * Stock functions para configurar y obtener recompensas avanzadas
 */
stock void CurrencyAdvancedEvents_SetIncapSaveReward(int amount)
{
	SetConVarInt(cvar_CurrencyIncapSave, amount);
}

stock void CurrencyAdvancedEvents_SetSmokerSaveReward(int amount)
{
	SetConVarInt(cvar_CurrencySmokerSave, amount);
}

stock void CurrencyAdvancedEvents_SetHunterSaveReward(int amount)
{
	SetConVarInt(cvar_CurrencyHunterSave, amount);
}

stock void CurrencyAdvancedEvents_SetChargerSaveReward(int amount)
{
	SetConVarInt(cvar_CurrencyChargerSave, amount);
}

stock void CurrencyAdvancedEvents_SetJockeySaveReward(int amount)
{
	SetConVarInt(cvar_CurrencyJockeySave, amount);
}

stock void CurrencyAdvancedEvents_SetSpitterSaveReward(int amount)
{
	SetConVarInt(cvar_CurrencySpitterSave, amount);
}

stock int CurrencyAdvancedEvents_GetIncapSaveReward()
{
	return GetConVarInt(cvar_CurrencyIncapSave);
}

stock int CurrencyAdvancedEvents_GetSmokerSaveReward()
{
	return GetConVarInt(cvar_CurrencySmokerSave);
}

stock int CurrencyAdvancedEvents_GetHunterSaveReward()
{
	return GetConVarInt(cvar_CurrencyHunterSave);
}

stock int CurrencyAdvancedEvents_GetChargerSaveReward()
{
	return GetConVarInt(cvar_CurrencyChargerSave);
}

stock int CurrencyAdvancedEvents_GetJockeySaveReward()
{
	return GetConVarInt(cvar_CurrencyJockeySave);
}

stock int CurrencyAdvancedEvents_GetSpitterSaveReward()
{
	return GetConVarInt(cvar_CurrencySpitterSave);
}
