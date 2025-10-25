#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === HEALTH BONUS PASSIVE REWARD ===
// Otorga HP adicional al jugador
//==================================================

// --- ConVars ---
Handle cvar_HealthBonus_RequiredLevel = INVALID_HANDLE;
Handle cvar_HealthBonus_BonusAmount = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bHealthBonus_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Health Bonus
 */
public void HealthBonus_OnPluginStart()
{
	cvar_HealthBonus_RequiredLevel = CreateConVar(
		"reward_health_level",
		"3",
		"Nivel requerido para desbloquear bonus de HP",
		FCVAR_PLUGIN
	);

	cvar_HealthBonus_BonusAmount = CreateConVar(
		"reward_health_value",
		"25",
		"Cantidad de HP adicional otorgado",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void HealthBonus_OnClientConnect(int client)
{
	g_bHealthBonus_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void HealthBonus_OnClientDisconnect(int client)
{
	g_bHealthBonus_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void HealthBonus_OnPlayerSpawn(int client, int level)
{
	if (HealthBonus_IsUnlocked(client, level))
	{
		g_bHealthBonus_Enabled[client] = true;
		HealthBonus_ApplyHealth(client);
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void HealthBonus_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_HealthBonus_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzó el nivel requerido
	if (level == requiredLevel)
	{
		g_bHealthBonus_Enabled[client] = true;
		HealthBonus_ApplyHealth(client);

		int bonusAmount = GetConVarInt(cvar_HealthBonus_BonusAmount);
		PrintToChat(client, "\x04[REWARD]\x01 ¡Ganaste \x05+%d HP\x01!", bonusAmount);
	}
	else if (level > requiredLevel)
	{
		g_bHealthBonus_Enabled[client] = true;
		HealthBonus_ApplyHealth(client);
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool HealthBonus_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_HealthBonus_RequiredLevel);
}

/**
 * Aplica el bonus de HP
 */
stock void HealthBonus_ApplyHealth(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int bonusAmount = GetConVarInt(cvar_HealthBonus_BonusAmount);
	int currentHealth = GetClientHealth(client);
	SetEntityHealth(client, currentHealth + bonusAmount);
}

/**
 * Obtiene si el health bonus está habilitado para un jugador
 */
public bool HealthBonus_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bHealthBonus_Enabled[client];
}
