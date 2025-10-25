#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === MASTER AT ARMS PASSIVE REWARD ===
// Duplica el daño de armas melee (100 -> 200)
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_MasterAtArms_RequiredLevel = INVALID_HANDLE;
Handle cvar_MasterAtArms_MeleeDamage = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bMasterAtArms_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Master at Arms
 */
public void MasterAtArms_OnPluginStart()
{
	cvar_MasterAtArms_RequiredLevel = CreateConVar(
		"reward_masteratarms_level",
		"32",
		"Nivel requerido para desbloquear Master at Arms",
		FCVAR_PLUGIN
	);

	cvar_MasterAtArms_MeleeDamage = CreateConVar(
		"reward_masteratarms_damage",
		"200.0",
		"Daño de melee con Master at Arms (default: 100.0)",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void MasterAtArms_OnClientConnect(int client)
{
	g_bMasterAtArms_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void MasterAtArms_OnClientDisconnect(int client)
{
	g_bMasterAtArms_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void MasterAtArms_OnPlayerSpawn(int client, int level)
{
	if (MasterAtArms_IsUnlocked(client, level))
	{
		g_bMasterAtArms_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void MasterAtArms_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_MasterAtArms_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bMasterAtArms_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Master at Arms\x01! (Daño melee duplicado)");
	}
	else if (level > requiredLevel)
	{
		g_bMasterAtArms_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool MasterAtArms_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_MasterAtArms_RequiredLevel);
}

/**
 * Obtiene el daño melee modificado para el jugador
 * Debe ser llamado desde el hook OnTakeDamage
 */
public float MasterAtArms_GetMeleeDamage(int client)
{
	if (g_bMasterAtArms_Enabled[client])
	{
		return GetConVarFloat(cvar_MasterAtArms_MeleeDamage);
	}

	return 100.0; // Daño melee por defecto
}

/**
 * Obtiene si Master at Arms está habilitado para un jugador
 */
public bool MasterAtArms_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bMasterAtArms_Enabled[client];
}
