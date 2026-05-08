#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === EXTREME CONDITIONING PASSIVE REWARD ===
// Aumenta la velocidad de movimiento del jugador
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_ExtremeConditioning_RequiredLevel = INVALID_HANDLE;
Handle cvar_ExtremeConditioning_SpeedMultiplier = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bExtremeConditioning_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Extreme Conditioning
 */
public void ExtremeConditioning_OnPluginStart()
{
	cvar_ExtremeConditioning_RequiredLevel = CreateConVar(
		"reward_extremeconditioning_level",
		"24",
		"Nivel requerido para desbloquear Extreme Conditioning (mayor velocidad)",
		FCVAR_PLUGIN
	);

	cvar_ExtremeConditioning_SpeedMultiplier = CreateConVar(
		"reward_extremeconditioning_speed",
		"1.25",
		"Multiplicador de velocidad (1.25 = +25% velocidad)",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void ExtremeConditioning_OnClientConnect(int client)
{
	g_bExtremeConditioning_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void ExtremeConditioning_OnClientDisconnect(int client)
{
	g_bExtremeConditioning_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void ExtremeConditioning_OnPlayerSpawn(int client, int level)
{
	if (ExtremeConditioning_IsUnlocked(client, level))
	{
		g_bExtremeConditioning_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void ExtremeConditioning_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_ExtremeConditioning_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzo el nivel requerido
	if (level == requiredLevel)
	{
		g_bExtremeConditioning_Enabled[client] = true;
		float multiplier = GetConVarFloat(cvar_ExtremeConditioning_SpeedMultiplier);
		int percentage = RoundToFloor((multiplier - 1.0) * 100.0);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Extreme Conditioning\x01! (Velocidad aumentada en \x03+%d%%\x01)", percentage);
	}
	else if (level > requiredLevel)
	{
		g_bExtremeConditioning_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool ExtremeConditioning_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_ExtremeConditioning_RequiredLevel);
}

/**
 * Procesa el movimiento del jugador cada tick
 * Esta funcion debe ser llamada desde OnPlayerRunCmd
 */
public Action ExtremeConditioning_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Solo survivors
	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	// Verificar si tiene Extreme Conditioning habilitado
	if (!g_bExtremeConditioning_Enabled[client])
		return Plugin_Continue;

	ExtremeConditioning_UpdateSpeed(client);

	return Plugin_Continue;
}

/**
 * Actualiza la velocidad del jugador
 */
stock void ExtremeConditioning_UpdateSpeed(int client)
{
	// IMPORTANTE: Speed Freak ability tiene prioridad sobre Extreme Conditioning
	if (Abilities_IsActive(client, Ability_SpeedFreak))
	{
		// Speed Freak maneja su propia velocidad (2.5x)
		return;
	}

	int flags = GetEntityFlags(client);
	float speedValue;
	float speedMultiplier = GetConVarFloat(cvar_ExtremeConditioning_SpeedMultiplier);

	// Verificar si esta saltando
	if (flags & IN_JUMP)
	{
		// En salto, velocidad ligeramente mayor
		speedValue = 1.15;
	}
	// Verificar si esta en el agua
	else if (flags & FL_INWATER)
	{
		// En agua, velocidad reducida
		bool hasAdrenaline = GetEntProp(client, Prop_Send, "m_bAdrenalineActive") > 0;

		if (hasAdrenaline)
		{
			speedValue = speedMultiplier;
		}
		else
		{
			speedValue = speedMultiplier * 0.8; // Mas lento en agua sin adrenalina
		}
	}
	else
	{
		// Velocidad normal mejorada
		speedValue = speedMultiplier;
	}

	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speedValue);
}

/**
 * Obtiene si Extreme Conditioning esta habilitado para un jugador
 */
public bool ExtremeConditioning_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bExtremeConditioning_Enabled[client];
}
