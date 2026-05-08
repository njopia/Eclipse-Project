#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === CRITICAL HIT PASSIVE REWARD ===
// 10% de probabilidad de hacer 1.5x-3.0x dano
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_CriticalHit_RequiredLevel = INVALID_HANDLE;
Handle cvar_CriticalHit_Chance = INVALID_HANDLE;
Handle cvar_CriticalHit_MinMultiplier = INVALID_HANDLE;
Handle cvar_CriticalHit_MaxMultiplier = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bCriticalHit_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Critical Hit
 */
public void CriticalHit_OnPluginStart()
{
	cvar_CriticalHit_RequiredLevel = CreateConVar(
		"reward_criticalhit_level",
		"38",
		"Nivel requerido para desbloquear Critical Hit",
		FCVAR_PLUGIN
	);

	cvar_CriticalHit_Chance = CreateConVar(
		"reward_criticalhit_chance",
		"10",
		"Probabilidad de critical hit (1-100)",
		FCVAR_PLUGIN
	);

	cvar_CriticalHit_MinMultiplier = CreateConVar(
		"reward_criticalhit_min_multiplier",
		"1.5",
		"Multiplicador minimo de dano critico",
		FCVAR_PLUGIN
	);

	cvar_CriticalHit_MaxMultiplier = CreateConVar(
		"reward_criticalhit_max_multiplier",
		"3.0",
		"Multiplicador maximo de dano critico",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void CriticalHit_OnClientConnect(int client)
{
	g_bCriticalHit_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void CriticalHit_OnClientDisconnect(int client)
{
	g_bCriticalHit_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void CriticalHit_OnPlayerSpawn(int client, int level)
{
	if (CriticalHit_IsUnlocked(client, level))
	{
		g_bCriticalHit_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void CriticalHit_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_CriticalHit_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bCriticalHit_Enabled[client] = true;
		int chance = GetConVarInt(cvar_CriticalHit_Chance);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Critical Hit!\x01 (%d%% de probabilidad de dano critico)", chance);
	}
	else if (level > requiredLevel)
	{
		g_bCriticalHit_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool CriticalHit_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_CriticalHit_RequiredLevel);
}

/**
 * Intenta aplicar critical hit
 * Retorna el nuevo dano si es critico, 0.0 si no
 * Debe ser llamado desde OnTakeDamage
 */
public float CriticalHit_TryApply(int attacker, float damage)
{
	if (!g_bCriticalHit_Enabled[attacker])
		return 0.0;

	int chance = GetConVarInt(cvar_CriticalHit_Chance);
	int random = GetRandomInt(1, 100);

	if (random <= chance)
	{
		float minMultiplier = GetConVarFloat(cvar_CriticalHit_MinMultiplier);
		float maxMultiplier = GetConVarFloat(cvar_CriticalHit_MaxMultiplier);
		float multiplier = GetRandomFloat(minMultiplier, maxMultiplier);

		float newDamage = damage * multiplier;

		// Mostrar mensaje de critical hit
		PrintToChat(attacker, "\x01[\x04Critical Hit!\x01] [\x04%d\x01 Damage]", RoundFloat(newDamage));

		return newDamage;
	}

	return 0.0;
}

/**
 * Obtiene si Critical Hit esta habilitado para un jugador
 */
public bool CriticalHit_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bCriticalHit_Enabled[client];
}
