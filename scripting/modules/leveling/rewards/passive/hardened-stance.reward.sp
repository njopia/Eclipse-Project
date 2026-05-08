#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === HARDENED STANCE PASSIVE REWARD ===
// Elimina el efecto de stagger causado por witch
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_HardenedStance_RequiredLevel = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bHardenedStance_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Hardened Stance
 */
public void HardenedStance_OnPluginStart()
{
	cvar_HardenedStance_RequiredLevel = CreateConVar(
		"reward_hardenedstance_level",
		"35",
		"Nivel requerido para desbloquear Hardened Stance",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void HardenedStance_OnClientConnect(int client)
{
	g_bHardenedStance_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void HardenedStance_OnClientDisconnect(int client)
{
	g_bHardenedStance_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void HardenedStance_OnPlayerSpawn(int client, int level)
{
	if (HardenedStance_IsUnlocked(client, level))
	{
		g_bHardenedStance_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void HardenedStance_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_HardenedStance_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bHardenedStance_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Hardened Stance\x01! (Sin stagger de witch)");
	}
	else if (level > requiredLevel)
	{
		g_bHardenedStance_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool HardenedStance_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_HardenedStance_RequiredLevel);
}

/**
 * Verifica si el jugador puede resistir stagger de witch
 * Debe ser llamado desde L4D2_OnStagger forward
 */
public bool HardenedStance_CanResistStagger(int client)
{
	return g_bHardenedStance_Enabled[client];
}

/**
 * Obtiene si Hardened Stance esta habilitado para un jugador
 */
public bool HardenedStance_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bHardenedStance_Enabled[client];
}
