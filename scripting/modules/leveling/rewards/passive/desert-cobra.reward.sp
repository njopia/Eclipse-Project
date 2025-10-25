#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DESERT COBRA PASSIVE REWARD ===
// Reemplaza la pistola normal con Magnum al ser incapacitado
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_DesertCobra_RequiredLevel = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bDesertCobra_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Desert Cobra
 */
public void DesertCobra_OnPluginStart()
{
	cvar_DesertCobra_RequiredLevel = CreateConVar(
		"reward_desertcobra_level",
		"8",
		"Nivel requerido para desbloquear Desert Cobra (Magnum al incapacitar)",
		FCVAR_PLUGIN
	);

	// Hook para evento de incapacitación
	HookEvent("player_incapacitated", Event_DesertCobra_Incapacitated, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void DesertCobra_OnClientConnect(int client)
{
	g_bDesertCobra_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void DesertCobra_OnClientDisconnect(int client)
{
	g_bDesertCobra_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void DesertCobra_OnPlayerSpawn(int client, int level)
{
	if (DesertCobra_IsUnlocked(client, level))
	{
		g_bDesertCobra_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void DesertCobra_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_DesertCobra_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzó el nivel requerido
	if (level == requiredLevel)
	{
		g_bDesertCobra_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Desert Cobra\x01! (Magnum Pistol al incapacitar)");
	}
	else if (level > requiredLevel)
	{
		g_bDesertCobra_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool DesertCobra_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_DesertCobra_RequiredLevel);
}

/**
 * Evento: Player Incapacitated - Reemplaza pistola por Magnum
 */
public Action Event_DesertCobra_Incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2) // Solo survivors
		return Plugin_Continue;

	if (!g_bDesertCobra_Enabled[client])
		return Plugin_Continue;

	// Dar un pequeño delay para que el juego termine de incapacitar
	CreateTimer(0.1, Timer_DesertCobra_GiveMagnum, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/**
 * Timer: Otorga Magnum después de incapacitar
 */
public Action Timer_DesertCobra_GiveMagnum(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (GetClientTeam(client) != 2)
		return Plugin_Stop;

	// Obtener el arma secundaria (slot 1)
	int weapon = GetPlayerWeaponSlot(client, 1);

	if (weapon > 0 && IsValidEntity(weapon))
	{
		char classname[32];
		GetEdictClassname(weapon, classname, sizeof(classname));

		// Solo reemplazar si es una pistola normal
		if (StrEqual(classname, "weapon_pistol", false))
		{
			// Remover pistola actual
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");

			// Dar Magnum
			DesertCobra_GiveMagnum(client);

			PrintToChat(client, "\x04[Desert Cobra]\x01 Equipando Magnum Pistol");
		}
	}

	return Plugin_Stop;
}

/**
 * Otorga una Magnum al jugador
 */
stock void DesertCobra_GiveMagnum(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	// Dar Magnum usando CheatCommand
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give pistol_magnum");
	SetCommandFlags("give", flags);
}

/**
 * Obtiene si Desert Cobra está habilitado para un jugador
 */
public bool DesertCobra_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bDesertCobra_Enabled[client];
}
