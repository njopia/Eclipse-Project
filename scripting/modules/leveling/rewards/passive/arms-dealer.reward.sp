#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === ARMS DEALER PASSIVE REWARD ===
// Expande la mochila para llevar hasta 40 items (armas y melee) en vez de 9
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_ArmsDealer_RequiredLevel = INVALID_HANDLE;
Handle cvar_ArmsDealer_BackpackSize = INVALID_HANDLE;
Handle cvar_ArmsDealer_DefaultSize = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bArmsDealer_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Arms Dealer
 */
public void ArmsDealer_OnPluginStart()
{
	cvar_ArmsDealer_RequiredLevel = CreateConVar(
		"reward_armsdealer_level",
		"19",
		"Nivel requerido para desbloquear Arms Dealer",
		FCVAR_PLUGIN
	);

	cvar_ArmsDealer_BackpackSize = CreateConVar(
		"reward_armsdealer_backpack_size",
		"40",
		"Tamano de la mochila con Arms Dealer",
		FCVAR_PLUGIN
	);

	cvar_ArmsDealer_DefaultSize = CreateConVar(
		"reward_armsdealer_default_size",
		"9",
		"Tamano de la mochila sin Arms Dealer",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void ArmsDealer_OnClientConnect(int client)
{
	g_bArmsDealer_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void ArmsDealer_OnClientDisconnect(int client)
{
	g_bArmsDealer_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void ArmsDealer_OnPlayerSpawn(int client, int level)
{
	if (ArmsDealer_IsUnlocked(client, level))
	{
		g_bArmsDealer_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void ArmsDealer_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_ArmsDealer_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bArmsDealer_Enabled[client] = true;
		int backpackSize = GetConVarInt(cvar_ArmsDealer_BackpackSize);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Arms Dealer\x01! (Mochila expandida a %d items)", backpackSize);
	}
	else if (level > requiredLevel)
	{
		g_bArmsDealer_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool ArmsDealer_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_ArmsDealer_RequiredLevel);
}

/**
 * Obtiene el tamano de la mochila para el jugador
 */
public int ArmsDealer_GetBackpackSize(int client)
{
	if (g_bArmsDealer_Enabled[client])
	{
		return GetConVarInt(cvar_ArmsDealer_BackpackSize);
	}

	return GetConVarInt(cvar_ArmsDealer_DefaultSize);
}

/**
 * Obtiene si Arms Dealer esta habilitado para un jugador
 */
public bool ArmsDealer_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bArmsDealer_Enabled[client];
}
