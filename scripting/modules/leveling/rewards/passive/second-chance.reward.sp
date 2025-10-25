#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SECOND CHANCE PASSIVE REWARD ===
// Auto-revive una vez por ronda después de morir
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_SecondChance_RequiredLevel = INVALID_HANDLE;
Handle cvar_SecondChance_ReviveDelay = INVALID_HANDLE;
Handle cvar_SecondChance_InvulnTime = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bSecondChance_Enabled[MAXPLAYERS + 1];
bool g_bSecondChance_Used[MAXPLAYERS + 1];
int g_iSecondChance_InvulnTimer[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Second Chance
 */
public void SecondChance_OnPluginStart()
{
	cvar_SecondChance_RequiredLevel = CreateConVar(
		"reward_secondchance_level",
		"44",
		"Nivel requerido para desbloquear Second Chance",
		FCVAR_PLUGIN
	);

	cvar_SecondChance_ReviveDelay = CreateConVar(
		"reward_secondchance_delay",
		"3.0",
		"Segundos antes de auto-revivir",
		FCVAR_PLUGIN
	);

	cvar_SecondChance_InvulnTime = CreateConVar(
		"reward_secondchance_invuln",
		"4",
		"Segundos de invulnerabilidad después de revivir",
		FCVAR_PLUGIN
	);

	// Hook para evento de muerte
	HookEvent("player_death", Event_SecondChance_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_SecondChance_RoundStart, EventHookMode_PostNoCopy);
}

/**
 * Resetea el estado al conectar
 */
public void SecondChance_OnClientConnect(int client)
{
	g_bSecondChance_Enabled[client] = false;
	g_bSecondChance_Used[client] = false;
	g_iSecondChance_InvulnTimer[client] = 0;
}

/**
 * Limpia recursos al desconectar
 */
public void SecondChance_OnClientDisconnect(int client)
{
	g_bSecondChance_Enabled[client] = false;
	g_bSecondChance_Used[client] = false;
	g_iSecondChance_InvulnTimer[client] = 0;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void SecondChance_OnPlayerSpawn(int client, int level)
{
	if (SecondChance_IsUnlocked(client, level))
	{
		g_bSecondChance_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void SecondChance_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_SecondChance_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bSecondChance_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Second Chance\x01! (Auto-revive una vez por ronda)");
	}
	else if (level > requiredLevel)
	{
		g_bSecondChance_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool SecondChance_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_SecondChance_RequiredLevel);
}

/**
 * Evento: Player Death - Activa Second Chance
 */
public Action Event_SecondChance_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (!g_bSecondChance_Enabled[client])
		return Plugin_Continue;

	if (g_bSecondChance_Used[client])
		return Plugin_Continue;

	// Activar Second Chance
	float delay = GetConVarFloat(cvar_SecondChance_ReviveDelay);
	CreateTimer(delay, Timer_SecondChance_Revive, GetClientUserId(client));

	return Plugin_Continue;
}

/**
 * Evento: Round Start - Resetea el uso de Second Chance
 */
public Action Event_SecondChance_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bSecondChance_Used[i] = false;
		g_iSecondChance_InvulnTimer[i] = 0;
	}
	return Plugin_Continue;
}

/**
 * Timer: Revive al jugador
 */
public Action Timer_SecondChance_Revive(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Stop;

	if (IsPlayerAlive(client))
		return Plugin_Stop;

	// Encontrar un superviviente vivo para spawnear cerca
	int target = SecondChance_FindClosestSurvivor(client);
	if (target > 0 && IsClientInGame(target))
	{
		float origin[3], angles[3];
		GetClientAbsOrigin(target, origin);
		GetClientAbsAngles(target, angles);

		// Respawn
		SDKCall_L4D2_RespawnPlayer(client);
		TeleportEntity(client, origin, angles, NULL_VECTOR);
	}
	else
	{
		// Respawn en spawn original
		SDKCall_L4D2_RespawnPlayer(client);
	}

	PrintToChat(client, "\x04[Second Chance]\x01 You have been brought back from the dead.");

	g_bSecondChance_Used[client] = true;
	g_iSecondChance_InvulnTimer[client] = GetConVarInt(cvar_SecondChance_InvulnTime);

	return Plugin_Stop;
}

/**
 * Encuentra el superviviente vivo más cercano a una posición
 */
stock int SecondChance_FindClosestSurvivor(int client)
{
	float clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	int closestClient = -1;
	float closestDistance = 0.0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client)
			continue;

		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != 2)
			continue;

		float targetOrigin[3];
		GetClientAbsOrigin(i, targetOrigin);
		float distance = GetVectorDistance(clientOrigin, targetOrigin);

		if (closestClient == -1 || distance < closestDistance)
		{
			closestClient = i;
			closestDistance = distance;
		}
	}

	return closestClient;
}

/**
 * Respawn wrapper (requiere SDKCall setup en main)
 */
stock void SDKCall_L4D2_RespawnPlayer(int client)
{
	// Nota: Esta función asume que el SDKCall para L4D2_Respawn
	// está configurado en el archivo principal
	// Por ahora usaremos el comando cheat como fallback
	int flags = GetCommandFlags("sb_takecontrol");
	SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "sb_takecontrol");
	SetCommandFlags("sb_takecontrol", flags);
}

/**
 * Obtiene si el jugador está en tiempo de invulnerabilidad
 */
public bool SecondChance_IsInvulnerable(int client)
{
	return g_iSecondChance_InvulnTimer[client] > 0;
}

/**
 * Decrementa el timer de invulnerabilidad (llamar cada segundo)
 */
public void SecondChance_OnSecondTick(int client)
{
	if (g_iSecondChance_InvulnTimer[client] > 0)
	{
		PrintToChat(client, "\x04[Second Chance]\x01 Invincibility will fade in %d seconds.", g_iSecondChance_InvulnTimer[client]);
		g_iSecondChance_InvulnTimer[client]--;
	}
}

/**
 * Obtiene si Second Chance está habilitado para un jugador
 */
public bool SecondChance_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSecondChance_Enabled[client];
}

/**
 * Obtiene si el jugador ya usó Second Chance en esta ronda
 */
public bool SecondChance_WasUsed(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSecondChance_Used[client];
}
