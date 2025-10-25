#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === HARD TO KILL PASSIVE REWARD ===
// Aumenta el HP cuando estás incapacitado
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_HardToKill_RequiredLevel = INVALID_HANDLE;
Handle cvar_HardToKill_IncapHP = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bHardToKill_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Hard to Kill
 */
public void HardToKill_OnPluginStart()
{
	cvar_HardToKill_RequiredLevel = CreateConVar(
		"reward_hardtokill_level",
		"17",
		"Nivel requerido para desbloquear Hard to Kill",
		FCVAR_PLUGIN
	);

	cvar_HardToKill_IncapHP = CreateConVar(
		"reward_hardtokill_incap_hp",
		"500",
		"HP al estar incapacitado (default: 300, con Hard to Kill: 500)",
		FCVAR_PLUGIN
	);

	// Hook para evento de incapacitación
	HookEvent("player_incapacitated_start", Event_HardToKill_IncapStart, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void HardToKill_OnClientConnect(int client)
{
	g_bHardToKill_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void HardToKill_OnClientDisconnect(int client)
{
	g_bHardToKill_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void HardToKill_OnPlayerSpawn(int client, int level)
{
	if (HardToKill_IsUnlocked(client, level))
	{
		g_bHardToKill_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void HardToKill_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_HardToKill_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzó el nivel requerido
	if (level == requiredLevel)
	{
		g_bHardToKill_Enabled[client] = true;
		int incapHP = GetConVarInt(cvar_HardToKill_IncapHP);
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Hard to Kill\x01! (HP de incapacitación aumentado a \x03%d\x01)", incapHP);
	}
	else if (level > requiredLevel)
	{
		g_bHardToKill_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool HardToKill_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_HardToKill_RequiredLevel);
}

/**
 * Evento: Player Incapacitated Start - Ajusta el HP de incapacitación
 */
public Action Event_HardToKill_IncapStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2) // Solo survivors
		return Plugin_Continue;

	// Ajustar el HP de incapacitación según el nivel
	HardToKill_UpdateIncapHealth(client);

	return Plugin_Continue;
}

/**
 * Actualiza el HP de incapacitación global
 */
stock void HardToKill_UpdateIncapHealth(int client)
{
	ConVar cvarIncapHealth = FindConVar("survivor_incap_health");
	if (cvarIncapHealth == INVALID_HANDLE)
		return;

	int targetHP;

	if (g_bHardToKill_Enabled[client])
	{
		targetHP = GetConVarInt(cvar_HardToKill_IncapHP);
	}
	else
	{
		targetHP = 300; // HP de incapacitación por defecto
	}

	// Solo actualizar si es diferente
	int currentHP = GetConVarInt(cvarIncapHealth);
	if (currentHP != targetHP)
	{
		SetConVarInt(cvarIncapHealth, targetHP);
	}
}

/**
 * Obtiene si Hard to Kill está habilitado para un jugador
 */
public bool HardToKill_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bHardToKill_Enabled[client];
}
