#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === MEDIC PASSIVE REWARD ===
// Otorga bonus de salud al usar items de curacion
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_Medic_RequiredLevel = INVALID_HANDLE;
Handle cvar_Medic_PillsBonus = INVALID_HANDLE;
Handle cvar_Medic_AdrenalineBonus = INVALID_HANDLE;
Handle cvar_Medic_FirstAidBonus = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bMedic_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Medic
 */
public void Medic_OnPluginStart()
{
	cvar_Medic_RequiredLevel = CreateConVar(
		"reward_medic_level",
		"4",
		"Nivel requerido para desbloquear Medic (bonus de curacion)",
		FCVAR_PLUGIN
	);

	cvar_Medic_PillsBonus = CreateConVar(
		"reward_medic_pills_bonus",
		"50",
		"HP adicional al usar pastillas (Pills)",
		FCVAR_PLUGIN
	);

	cvar_Medic_AdrenalineBonus = CreateConVar(
		"reward_medic_adrenaline_bonus",
		"25",
		"HP adicional al usar adrenalina",
		FCVAR_PLUGIN
	);

	cvar_Medic_FirstAidBonus = CreateConVar(
		"reward_medic_firstaid_bonus",
		"200",
		"HP adicional al usar botiquin (First Aid Kit)",
		FCVAR_PLUGIN
	);

	// Hooks para eventos de curacion
	HookEvent("pills_used", Event_Medic_PillsUsed, EventHookMode_Post);
	HookEvent("adrenaline_used", Event_Medic_AdrenalineUsed, EventHookMode_Post);
	HookEvent("heal_success", Event_Medic_HealSuccess, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void Medic_OnClientConnect(int client)
{
	g_bMedic_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void Medic_OnClientDisconnect(int client)
{
	g_bMedic_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void Medic_OnPlayerSpawn(int client, int level)
{
	if (Medic_IsUnlocked(client, level))
	{
		g_bMedic_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void Medic_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_Medic_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzo el nivel requerido
	if (level == requiredLevel)
	{
		g_bMedic_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Medic\x01! (Bonus de salud al usar items de curacion)");
	}
	else if (level > requiredLevel)
	{
		g_bMedic_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool Medic_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_Medic_RequiredLevel);
}

/**
 * Evento: Pills Used - Otorga HP adicional al usar pastillas
 */
public Action Event_Medic_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2) // Solo survivors
		return Plugin_Continue;

	if (!g_bMedic_Enabled[client])
		return Plugin_Continue;

	int bonusHP = GetConVarInt(cvar_Medic_PillsBonus);
	Medic_GiveHealth(client, bonusHP, false);
	PrintToChat(client, "\x04[Medic]\x01 Recibiendo bonus de salud: \x03+%d HP\x01", bonusHP);

	return Plugin_Continue;
}

/**
 * Evento: Adrenaline Used - Otorga HP adicional al usar adrenalina
 */
public Action Event_Medic_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2) // Solo survivors
		return Plugin_Continue;

	if (!g_bMedic_Enabled[client])
		return Plugin_Continue;

	int bonusHP = GetConVarInt(cvar_Medic_AdrenalineBonus);
	Medic_GiveHealth(client, bonusHP, false);
	PrintToChat(client, "\x04[Medic]\x01 Recibiendo bonus de salud: \x03+%d HP\x01", bonusHP);

	return Plugin_Continue;
}

/**
 * Evento: Heal Success - Otorga HP adicional al usar botiquin
 */
public Action Event_Medic_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int target = GetClientOfUserId(event.GetInt("subject"));

	if (client <= 0 || target <= 0 || !IsClientInGame(client) || !IsClientInGame(target))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2 || GetClientTeam(target) != 2) // Solo survivors
		return Plugin_Continue;

	if (IsFakeClient(client))
		return Plugin_Continue;

	// Aplicar bonus al target si el cliente tiene Medic
	if (g_bMedic_Enabled[client])
	{
		int bonusHP = GetConVarInt(cvar_Medic_FirstAidBonus);
		Medic_GiveHealth(target, bonusHP, true);

		if (client == target)
		{
			PrintToChat(client, "\x04[Medic]\x01 Recibiendo bonus de salud: \x03+%d HP\x01", bonusHP);
		}
		else
		{
			PrintToChat(client, "\x04[Medic]\x01 Otorgaste bonus de salud a %N: \x03+%d HP\x01", target, bonusHP);
		}
	}

	return Plugin_Continue;
}

/**
 * Otorga salud al jugador
 * @param client - ID del cliente
 * @param amount - Cantidad de HP a otorgar
 * @param permanent - Si es salud permanente (true) o temporal (false)
 */
stock void Medic_GiveHealth(int client, int amount, bool permanent)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int currentHealth = GetClientHealth(client);
	int newHealth = currentHealth + amount;

	// Limitar a un maximo razonable
	if (newHealth > 500)
		newHealth = 500;

	if (permanent)
	{
		// Salud permanente
		SetEntityHealth(client, newHealth);
	}
	else
	{
		// Salud temporal (healthBuffer es float, no int)
		float currentTemp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", currentTemp + float(amount));
	}
}

/**
 * Obtiene si Medic esta habilitado para un jugador
 */
public bool Medic_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bMedic_Enabled[client];
}
