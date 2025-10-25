#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SURGEON PASSIVE REWARD ===
// Reduce el tiempo de uso de items de curación a la mitad
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_Surgeon_RequiredLevel = INVALID_HANDLE;
Handle cvar_Surgeon_HealDuration = INVALID_HANDLE;
Handle cvar_Surgeon_ReviveDuration = INVALID_HANDLE;
Handle cvar_Surgeon_DefibDuration = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bSurgeon_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Surgeon
 */
public void Surgeon_OnPluginStart()
{
	cvar_Surgeon_RequiredLevel = CreateConVar(
		"reward_surgeon_level",
		"22",
		"Nivel requerido para desbloquear Surgeon",
		FCVAR_PLUGIN
	);

	cvar_Surgeon_HealDuration = CreateConVar(
		"reward_surgeon_heal_duration",
		"2.5",
		"Duración de uso de botiquín con Surgeon (default: 5.0)",
		FCVAR_PLUGIN
	);

	cvar_Surgeon_ReviveDuration = CreateConVar(
		"reward_surgeon_revive_duration",
		"2.5",
		"Duración de revivir con Surgeon (default: 5.0)",
		FCVAR_PLUGIN
	);

	cvar_Surgeon_DefibDuration = CreateConVar(
		"reward_surgeon_defib_duration",
		"1.5",
		"Duración de usar desfibrilador con Surgeon (default: 3.0)",
		FCVAR_PLUGIN
	);

	// Hooks para eventos de curación
	HookEvent("heal_begin", Event_Surgeon_HealBegin, EventHookMode_Post);
	HookEvent("defibrillator_begin", Event_Surgeon_DefibBegin, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void Surgeon_OnClientConnect(int client)
{
	g_bSurgeon_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void Surgeon_OnClientDisconnect(int client)
{
	g_bSurgeon_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void Surgeon_OnPlayerSpawn(int client, int level)
{
	if (Surgeon_IsUnlocked(client, level))
	{
		g_bSurgeon_Enabled[client] = true;
		Surgeon_UpdateUseDurations();
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void Surgeon_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_Surgeon_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bSurgeon_Enabled[client] = true;
		Surgeon_UpdateUseDurations();
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Surgeon\x01! (Usas items de curación 2x más rápido)");
	}
	else if (level > requiredLevel)
	{
		g_bSurgeon_Enabled[client] = true;
		Surgeon_UpdateUseDurations();
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool Surgeon_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_Surgeon_RequiredLevel);
}

/**
 * Evento: Heal Begin - Muestra mensaje de Surgeon
 */
public Action Event_Surgeon_HealBegin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (g_bSurgeon_Enabled[client])
	{
		PrintToChat(client, "\x04[Surgeon]\x01 Tu habilidad te permite usar este item más rápido");
	}

	return Plugin_Continue;
}

/**
 * Evento: Defibrillator Begin - Muestra mensaje de Surgeon
 */
public Action Event_Surgeon_DefibBegin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (g_bSurgeon_Enabled[client])
	{
		PrintToChat(client, "\x04[Surgeon]\x01 Tu habilidad te permite usar este item más rápido");
	}

	return Plugin_Continue;
}

/**
 * Actualiza las duraciones de uso de items de curación
 */
stock void Surgeon_UpdateUseDurations()
{
	// Verificar si algún jugador tiene Surgeon habilitado
	bool anySurgeon = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			if (g_bSurgeon_Enabled[i])
			{
				anySurgeon = true;
				break;
			}
		}
	}

	// Ajustar ConVars según si hay algún Surgeon
	ConVar cvarHeal = FindConVar("first_aid_kit_use_duration");
	ConVar cvarRevive = FindConVar("survivor_revive_duration");
	ConVar cvarDefib = FindConVar("defibrillator_use_duration");

	if (anySurgeon)
	{
		SetConVarFloat(cvarHeal, GetConVarFloat(cvar_Surgeon_HealDuration));
		SetConVarFloat(cvarRevive, GetConVarFloat(cvar_Surgeon_ReviveDuration));
		SetConVarFloat(cvarDefib, GetConVarFloat(cvar_Surgeon_DefibDuration));
	}
	else
	{
		// Restaurar valores por defecto
		SetConVarFloat(cvarHeal, 5.0);
		SetConVarFloat(cvarRevive, 5.0);
		SetConVarFloat(cvarDefib, 3.0);
	}
}

/**
 * Obtiene si Surgeon está habilitado para un jugador
 */
public bool Surgeon_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSurgeon_Enabled[client];
}
