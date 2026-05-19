#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING XP EVENTS MODULE ===
// Vincula eventos del juego con el sistema de XP
//==================================================

// --- ConVars para XP por diferentes eventos ---
Handle cvar_XPCommonKill = INVALID_HANDLE;
Handle cvar_XPSpecialKill = INVALID_HANDLE;
Handle cvar_XPTankKill = INVALID_HANDLE;
Handle cvar_XPWitchKill = INVALID_HANDLE;
Handle cvar_XPHeadshot = INVALID_HANDLE;
Handle cvar_XPRevive = INVALID_HANDLE;
Handle cvar_XPHeal = INVALID_HANDLE;
Handle cvar_XPDefibrillator = INVALID_HANDLE;

/**
 * Inicializa el modulo de eventos de XP
 * Debe ser llamado desde OnPluginStart() DESPUES de Leveling_OnPluginStart()
 */
public void LevelingXPEvents_OnPluginStart()
{
	// Crear ConVars para recompensas XP por eventos
	cvar_XPCommonKill = CreateConVar(
		"xp_common_kill",
		"5",
		"XP por matar un infectado comun",
		FCVAR_PLUGIN
	);

	cvar_XPSpecialKill = CreateConVar(
		"xp_special_kill",
		"15",
		"XP por matar un infectado especial",
		FCVAR_PLUGIN
	);

	cvar_XPTankKill = CreateConVar(
		"xp_tank_kill",
		"50",
		"XP por matar un Tank",
		FCVAR_PLUGIN
	);

	cvar_XPWitchKill = CreateConVar(
		"xp_witch_kill",
		"40",
		"XP por matar una Witch",
		FCVAR_PLUGIN
	);

	cvar_XPHeadshot = CreateConVar(
		"xp_headshot",
		"10",
		"XP bonus por headshot",
		FCVAR_PLUGIN
	);

	cvar_XPRevive = CreateConVar(
		"xp_revive",
		"20",
		"XP por revivir a un companero",
		FCVAR_PLUGIN
	);

	cvar_XPHeal = CreateConVar(
		"xp_heal",
		"5",
		"XP por curar a un companero",
		FCVAR_PLUGIN
	);

	cvar_XPDefibrillator = CreateConVar(
		"xp_defibrillator",
		"25",
		"XP por usar desfibrilador",
		FCVAR_PLUGIN
	);

	// Eventos adicionales con left4dhooks
	CreateConVar(
		"xp_protect_teammate",
		"10",
		"XP por proteger a un companero de un SI",
		FCVAR_PLUGIN
	);

	CreateConVar(
		"xp_complete_map",
		"100",
		"XP por completar un mapa (llegar al saferoom final)",
		FCVAR_PLUGIN
	);

	// Registrar hooks de eventos
	HookEvent("infected_death", Event_InfectedDeath_XP, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath_XP, EventHookMode_Pre);  // Para infectados especiales
	HookEvent("tank_killed", Event_TankKilled_XP, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchKilled_XP, EventHookMode_Pre);
	HookEvent("heal_success", Event_HealSuccess_XP, EventHookMode_Pre);
	HookEvent("revive_success", Event_ReviveSuccess_XP, EventHookMode_Pre);

	// L4D2 specific
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		HookEvent("defibrillator_used", Event_DefibUsed_XP, EventHookMode_Pre);
	}

	// Eventos adicionales left4dhooks
	HookEvent("player_left_safe_area", Event_LeftSafeArea_XP, EventHookMode_Post);
	HookEvent("finale_vehicle_leaving", Event_MapComplete_XP, EventHookMode_Post);
	HookEvent("map_transition", Event_MapComplete_XP, EventHookMode_Post);
}

/**
 * Evento: Infected Death
 * Los survivors ganan XP por matar infectados comunes
 */
public Action Event_InfectedDeath_XP(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int xp_reward = GetConVarInt(cvar_XPCommonKill);
	bool isHeadshot = event.GetBool("headshot", false);

	// Otorgar XP base
	Leveling_AwardXP(attacker, xp_reward, "Matar infectado comun");

	// Bonus por headshot
	if (isHeadshot)
	{
		int headshot_bonus = GetConVarInt(cvar_XPHeadshot);
		Leveling_AwardXP(attacker, headshot_bonus, "Headshot en infectado comun");
	}

	return Plugin_Continue;
}

/**
 * Evento: Player Death (para detectar infectados especiales muertos)
 * Los survivors ganan XP por matar infectados especiales (Hunter, Smoker, etc)
 */
public Action Event_PlayerDeath_XP(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	// Validar que victima y atacante existan
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	// Verificar que la victima es infectado (Team 3) y el atacante es survivor (Team 2)
	if (GetClientTeam(victim) != 3 || GetClientTeam(attacker) != 2)
		return Plugin_Continue;

	// Obtener la clase de zombie
	int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

	// Verificar que NO es un Tank (Tank tiene su propio evento)
	if (zombieClass == 8 || zombieClass == 9)  // 8 = Tank, 9 = Tank en L4D1
		return Plugin_Continue;

	// Verificar que es un infectado especial valido (1-7)
	// 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger, 7=Witch
	if (zombieClass < 1 || zombieClass > 7)
		return Plugin_Continue;

	// Es un infectado especial (Smoker, Boomer, Hunter, Spitter, Jockey, Charger)
	int xp_reward = GetConVarInt(cvar_XPSpecialKill);
	bool isHeadshot = event.GetBool("headshot", false);

	// Otorgar XP base
	Leveling_AwardXP(attacker, xp_reward, "Matar infectado especial");

	// Bonus por headshot
	if (isHeadshot)
	{
		int headshot_bonus = GetConVarInt(cvar_XPHeadshot);
		Leveling_AwardXP(attacker, headshot_bonus, "Headshot en infectado especial");
	}

	return Plugin_Continue;
}

/**
 * Evento: Tank Killed
 * Los survivors ganan XP por matar un Tank
 */
public Action Event_TankKilled_XP(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int xp_reward = GetConVarInt(cvar_XPTankKill);
	Leveling_AwardXP(attacker, xp_reward, "Matar Tank");

	return Plugin_Continue;
}

/**
 * Evento: Witch Killed
 * Los survivors ganan XP por matar una Witch
 */
public Action Event_WitchKilled_XP(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int xp_reward = GetConVarInt(cvar_XPWitchKill);
	Leveling_AwardXP(attacker, xp_reward, "Matar Witch");

	return Plugin_Continue;
}

/**
 * Evento: Heal Success
 * Los survivors ganan XP por curar a un companero
 */
public Action Event_HealSuccess_XP(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(event.GetInt("userid"));

	if (healer <= 0 || healer > MaxClients || !IsClientInGame(healer) || IsFakeClient(healer))
		return Plugin_Continue;

	if (GetClientTeam(healer) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int xp_reward = GetConVarInt(cvar_XPHeal);
	Leveling_AwardXP(healer, xp_reward, "Curar companero");

	return Plugin_Continue;
}

/**
 * Evento: Revive Success
 * Los survivors ganan XP por revivir a un companero
 */
public Action Event_ReviveSuccess_XP(Event event, const char[] name, bool dontBroadcast)
{
	int reviver = GetClientOfUserId(event.GetInt("userid"));

	if (reviver <= 0 || reviver > MaxClients || !IsClientInGame(reviver) || IsFakeClient(reviver))
		return Plugin_Continue;

	if (GetClientTeam(reviver) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int xp_reward = GetConVarInt(cvar_XPRevive);
	Leveling_AwardXP(reviver, xp_reward, "Revivir companero");

	return Plugin_Continue;
}

/**
 * Evento: Defibrillator Used (L4D2 only)
 * Los survivors ganan XP por usar un desfibrilador
 */
public Action Event_DefibUsed_XP(Event event, const char[] name, bool dontBroadcast)
{
	int user = GetClientOfUserId(event.GetInt("userid"));

	if (user <= 0 || user > MaxClients || !IsClientInGame(user) || IsFakeClient(user))
		return Plugin_Continue;

	if (GetClientTeam(user) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	int xp_reward = GetConVarInt(cvar_XPDefibrillator);
	Leveling_AwardXP(user, xp_reward, "Usar desfibrilador");

	return Plugin_Continue;
}

/**
 * Evento: Player Left Safe Area
 * Marca que el mapa comenzo (para dar XP al completarlo)
 */
bool g_bXPMapStarted = false;

public Action Event_LeftSafeArea_XP(Event event, const char[] name, bool dontBroadcast)
{
	g_bXPMapStarted = true;
	return Plugin_Continue;
}

/**
 * Evento: Map Complete (finale_vehicle_leaving o map_transition)
 * Los survivors que completan el mapa ganan XP
 */
public Action Event_MapComplete_XP(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bXPMapStarted)
		return Plugin_Continue;

	Handle xpCompleteMap = FindConVar("xp_complete_map");
	if (xpCompleteMap == INVALID_HANDLE)
		return Plugin_Continue;

	int xp_reward = GetConVarInt(xpCompleteMap);

	// Otorgar XP a todos los survivors vivos
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			Leveling_AwardXP(i, xp_reward, "Completar mapa");
		}
	}

	g_bXPMapStarted = false;
	return Plugin_Continue;
}
