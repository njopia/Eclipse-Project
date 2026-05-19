#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === CURRENCY EVENTS MODULE ===
// Vincula eventos del juego con el sistema de currency
//==================================================

// --- ConVars para configurar recompensas por eventos ---
Handle cvar_CurrencyCommonKill = INVALID_HANDLE;
Handle cvar_CurrencySpecialKill = INVALID_HANDLE;
Handle cvar_CurrencyTankKill = INVALID_HANDLE;
Handle cvar_CurrencyWitchKill = INVALID_HANDLE;
Handle cvar_CurrencyHeadshot = INVALID_HANDLE;
Handle cvar_CurrencyRevive = INVALID_HANDLE;
Handle cvar_CurrencyHeal = INVALID_HANDLE;
Handle cvar_CurrencyDefibrillator = INVALID_HANDLE;

/**
 * Inicializa el modulo de eventos de currency
 * Debe ser llamado desde OnPluginStart()
 */
public void CurrencyEvents_OnPluginStart()
{
	// Crear ConVars para recompensas por eventos
	cvar_CurrencyCommonKill = CreateConVar("currency_common_kill", "1", "Puntos por matar un infectado comun", FCVAR_PLUGIN);
	cvar_CurrencySpecialKill = CreateConVar("currency_special_kill", "5", "Puntos por matar un infectado especial", FCVAR_PLUGIN);
	cvar_CurrencyTankKill = CreateConVar("currency_tank_kill", "20", "Puntos por matar un Tank", FCVAR_PLUGIN);
	cvar_CurrencyWitchKill = CreateConVar("currency_witch_kill", "15", "Puntos por matar una Witch", FCVAR_PLUGIN);
	cvar_CurrencyHeadshot = CreateConVar("currency_headshot", "2", "Puntos bonus por headshot", FCVAR_PLUGIN);
	cvar_CurrencyRevive = CreateConVar("currency_revive", "3", "Puntos por revivir a un companero", FCVAR_PLUGIN);
	cvar_CurrencyHeal = CreateConVar("currency_heal", "1", "Puntos por curar a un companero", FCVAR_PLUGIN);
	cvar_CurrencyDefibrillator = CreateConVar("currency_defibrillator", "5", "Puntos por usar desfibrilador", FCVAR_PLUGIN);

	// Registrar hooks de eventos
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Pre);
	HookEvent("tank_killed", Event_TankKilled, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Pre);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Pre);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Pre);

	// L4D2 specific
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		HookEvent("defibrillator_used", Event_DefibUsed, EventHookMode_Pre);
	}

	// Inicializar modulo de eventos avanzados
	CurrencyAdvancedEvents_OnPluginStart();
}

/**
 * Evento: Player Death (cuando un survivor muere por un infectado)
 * Se otorgan puntos al infectado que lo mato
 */
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	// Validar que el atacante es un infectado
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 3)  // Team 3 = Infected
		return Plugin_Continue;

	// Nota: La mayoria de las muertes se registran como "player_death"
	// Los eventos especiales (tank_killed, witch_killed) se manejan por separado

	return Plugin_Continue;
}

/**
 * Evento: Infected Death (cuando muere un infectado comun)
 * Los survivors ganan puntos por matarlos
 */
public Action Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	// Validar que el atacante es un survivor
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int reward = GetConVarInt(cvar_CurrencyCommonKill);
	bool isHeadshot = event.GetBool("headshot", false);

	// Otorgar puntos base por matar infectado comun
	AwardCurrency(attacker, reward, "Matar infectado comun");
	CurrencyStats_AddCommonKill(attacker);

	// Bonus por headshot
	if (isHeadshot)
	{
		int headshotBonus = GetConVarInt(cvar_CurrencyHeadshot);
		AwardCurrency(attacker, headshotBonus, "Headshot");
		CurrencyStats_AddHeadshot(attacker);
	}

	return Plugin_Continue;
}

/**
 * Evento: Tank Killed
 * El que mata el tank gana puntos considerables
 */
public Action Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Solo survivors
		return Plugin_Continue;

	int reward = GetConVarInt(cvar_CurrencyTankKill);
	AwardCurrency(attacker, reward, "Matar Tank");

	return Plugin_Continue;
}

/**
 * Evento: Witch Killed
 * El que mata la witch gana puntos
 */
public Action Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Solo survivors
		return Plugin_Continue;

	int reward = GetConVarInt(cvar_CurrencyWitchKill);
	AwardCurrency(attacker, reward, "Matar Witch");

	return Plugin_Continue;
}

/**
 * Evento: Heal Success (cuando se cura a un companero con medkit)
 */
public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(event.GetInt("userid"));

	if (healer <= 0 || healer > MaxClients || !IsClientInGame(healer))
		return Plugin_Continue;

	if (GetClientTeam(healer) != 2)
		return Plugin_Continue;

	int reward = GetConVarInt(cvar_CurrencyHeal);
	AwardCurrency(healer, reward, "Curar companero");
	CurrencyStats_AddHeal(healer);

	return Plugin_Continue;
}

/**
 * Evento: Revive Success (cuando se revive a un companero caido)
 */
public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(event.GetInt("userid"));

	if (healer <= 0 || healer > MaxClients || !IsClientInGame(healer))
		return Plugin_Continue;

	if (GetClientTeam(healer) != 2)
		return Plugin_Continue;

	int reward = GetConVarInt(cvar_CurrencyRevive);
	AwardCurrency(healer, reward, "Revivir companero");
	CurrencyStats_AddRevival(healer);

	return Plugin_Continue;
}

/**
 * Evento: Defibrillator Used (L4D2 only)
 * Se otorgan puntos por usar desfibrilador
 */
public Action Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));

	if (userid <= 0 || userid > MaxClients || !IsClientInGame(userid))
		return Plugin_Continue;

	if (GetClientTeam(userid) != 2)
		return Plugin_Continue;

	int reward = GetConVarInt(cvar_CurrencyDefibrillator);
	AwardCurrency(userid, reward, "Usar desfibrilador");

	return Plugin_Continue;
}

/**
 * Stock function para otorgar currency con mensaje personalizado
 * (Usa la funcion AwardCurrency existente en buy-menu.module.sp)
 */
stock void CurrencyEvents_SetCommonReward(int amount)
{
	SetConVarInt(cvar_CurrencyCommonKill, amount);
}

stock void CurrencyEvents_SetSpecialReward(int amount)
{
	SetConVarInt(cvar_CurrencySpecialKill, amount);
}

stock void CurrencyEvents_SetTankReward(int amount)
{
	SetConVarInt(cvar_CurrencyTankKill, amount);
}

stock void CurrencyEvents_SetWitchReward(int amount)
{
	SetConVarInt(cvar_CurrencyWitchKill, amount);
}

stock int CurrencyEvents_GetCommonReward()
{
	return GetConVarInt(cvar_CurrencyCommonKill);
}

stock int CurrencyEvents_GetSpecialReward()
{
	return GetConVarInt(cvar_CurrencySpecialKill);
}

stock int CurrencyEvents_GetTankReward()
{
	return GetConVarInt(cvar_CurrencyTankKill);
}

stock int CurrencyEvents_GetWitchReward()
{
	return GetConVarInt(cvar_CurrencyWitchKill);
}
