#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === GENE MUTATIONS PASSIVE REWARD ===
// Aumenta HP máximo y otorga regeneración de salud
// Based on Master_3_46 implementation
// Niveles: 10 (+100HP, +1 regen), 20 (+200HP, +2 regen), 30 (+300HP, +3 regen), 40 (+400HP, +4 regen)
//==================================================

// --- ConVars ---
Handle cvar_GeneMutations_Level1 = INVALID_HANDLE;
Handle cvar_GeneMutations_Level2 = INVALID_HANDLE;
Handle cvar_GeneMutations_Level3 = INVALID_HANDLE;
Handle cvar_GeneMutations_Level4 = INVALID_HANDLE;
Handle cvar_GeneMutations_BonusHP1 = INVALID_HANDLE;
Handle cvar_GeneMutations_BonusHP2 = INVALID_HANDLE;
Handle cvar_GeneMutations_BonusHP3 = INVALID_HANDLE;
Handle cvar_GeneMutations_BonusHP4 = INVALID_HANDLE;

// --- Estado del jugador ---
int g_iGeneMutations_Level[MAXPLAYERS + 1]; // 0 = sin, 1-4 = nivel de mutación

/**
 * Inicializa el módulo de Gene Mutations
 */
public void GeneMutations_OnPluginStart()
{
	cvar_GeneMutations_Level1 = CreateConVar(
		"reward_genemutations1_level",
		"10",
		"Nivel requerido para Gene Mutations I",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_Level2 = CreateConVar(
		"reward_genemutations2_level",
		"20",
		"Nivel requerido para Gene Mutations II",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_Level3 = CreateConVar(
		"reward_genemutations3_level",
		"30",
		"Nivel requerido para Gene Mutations III",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_Level4 = CreateConVar(
		"reward_genemutations4_level",
		"40",
		"Nivel requerido para Gene Mutations IV",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_BonusHP1 = CreateConVar(
		"reward_genemutations1_hp",
		"100",
		"HP adicional de Gene Mutations I",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_BonusHP2 = CreateConVar(
		"reward_genemutations2_hp",
		"200",
		"HP adicional de Gene Mutations II",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_BonusHP3 = CreateConVar(
		"reward_genemutations3_hp",
		"300",
		"HP adicional de Gene Mutations III",
		FCVAR_PLUGIN
	);

	cvar_GeneMutations_BonusHP4 = CreateConVar(
		"reward_genemutations4_hp",
		"400",
		"HP adicional de Gene Mutations IV",
		FCVAR_PLUGIN
	);

	// Crear timer de regeneración (cada 5 segundos)
	CreateTimer(5.0, Timer_GeneMutations_Regeneration, _, TIMER_REPEAT);
}

/**
 * Resetea el estado al conectar
 */
public void GeneMutations_OnClientConnect(int client)
{
	g_iGeneMutations_Level[client] = 0;
}

/**
 * Limpia recursos al desconectar
 */
public void GeneMutations_OnClientDisconnect(int client)
{
	g_iGeneMutations_Level[client] = 0;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void GeneMutations_OnPlayerSpawn(int client, int level)
{
	int mutationLevel = GeneMutations_GetMutationLevel(level);
	g_iGeneMutations_Level[client] = mutationLevel;

	if (mutationLevel > 0)
	{
		GeneMutations_ApplyHealthBonus(client, mutationLevel);
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void GeneMutations_OnLevelUp(int client, int level)
{
	int oldMutationLevel = g_iGeneMutations_Level[client];
	int newMutationLevel = GeneMutations_GetMutationLevel(level);

	// Solo mostrar mensaje si alcanzó un nuevo nivel de mutación
	if (newMutationLevel > oldMutationLevel)
	{
		g_iGeneMutations_Level[client] = newMutationLevel;
		GeneMutations_ApplyHealthBonus(client, newMutationLevel);

		char mutationName[32];
		int bonusHP = GeneMutations_GetBonusHP(newMutationLevel);

		switch (newMutationLevel)
		{
			case 1: mutationName = "Gene Mutations";
			case 2: mutationName = "Gene Mutations II";
			case 3: mutationName = "Gene Mutations III";
			case 4: mutationName = "Gene Mutations IV";
		}

		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05%s\x01! (+%d HP máximo y regeneración +%d HP/5s)", mutationName, bonusHP, newMutationLevel);
	}
	else
	{
		g_iGeneMutations_Level[client] = newMutationLevel;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool GeneMutations_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_GeneMutations_Level1);
}

/**
 * Obtiene el nivel de mutación según el nivel del jugador
 */
stock int GeneMutations_GetMutationLevel(int playerLevel)
{
	if (playerLevel >= GetConVarInt(cvar_GeneMutations_Level4))
		return 4;
	if (playerLevel >= GetConVarInt(cvar_GeneMutations_Level3))
		return 3;
	if (playerLevel >= GetConVarInt(cvar_GeneMutations_Level2))
		return 2;
	if (playerLevel >= GetConVarInt(cvar_GeneMutations_Level1))
		return 1;

	return 0;
}

/**
 * Obtiene el bonus de HP según el nivel de mutación
 */
stock int GeneMutations_GetBonusHP(int mutationLevel)
{
	switch (mutationLevel)
	{
		case 1: return GetConVarInt(cvar_GeneMutations_BonusHP1);
		case 2: return GetConVarInt(cvar_GeneMutations_BonusHP2);
		case 3: return GetConVarInt(cvar_GeneMutations_BonusHP3);
		case 4: return GetConVarInt(cvar_GeneMutations_BonusHP4);
	}
	return 0;
}

/**
 * Aplica el bonus de HP al jugador
 */
stock void GeneMutations_ApplyHealthBonus(int client, int mutationLevel)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int bonusHP = GeneMutations_GetBonusHP(mutationLevel);
	if (bonusHP > 0)
	{
		int currentHealth = GetClientHealth(client);
		int newHealth = currentHealth + bonusHP;

		// Aplicar el bonus
		SetEntityHealth(client, newHealth);
	}
}

/**
 * Timer: Regeneración de salud
 */
public Action Timer_GeneMutations_Regeneration(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
			continue;

		if (GetClientTeam(client) != 2) // Solo survivors
			continue;

		// Verificar si está incapacitado o siendo sujetado
		if (GeneMutations_IsPlayerIncapacitated(client) || GeneMutations_IsPlayerHeld(client))
			continue;

		int mutationLevel = g_iGeneMutations_Level[client];
		if (mutationLevel > 0)
		{
			GeneMutations_RegenerateHealth(client, mutationLevel);
		}
	}

	return Plugin_Continue;
}

/**
 * Regenera HP del jugador
 */
stock void GeneMutations_RegenerateHealth(int client, int mutationLevel)
{
	int currentHealth = GetClientHealth(client);
	int currentTemp = RoundToFloor(GeneMutations_GetTempHealth(client));
	int totalHealth = currentHealth + currentTemp;

	// Calcular HP máximo
	int maxHealth = 100 + GeneMutations_GetBonusHP(mutationLevel);

	// Si ya está al máximo, no regenerar
	if (totalHealth >= maxHealth)
		return;

	// Regenerar según el nivel de mutación
	int regenAmount = mutationLevel;

	// Aplicar regeneración como salud temporal
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntProp(client, Prop_Send, "m_healthBuffer", currentTemp + regenAmount);
}

/**
 * Obtiene la salud temporal del jugador
 */
stock float GeneMutations_GetTempHealth(int client)
{
	float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float tempTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float gameTime = GetGameTime();

	if (tempTime > 0.0)
	{
		float timeSince = gameTime - tempTime;
		tempHealth -= timeSince * 0.27; // Decay rate de L4D2

		if (tempHealth < 0.0)
			tempHealth = 0.0;
	}

	return tempHealth;
}

/**
 * Verifica si el jugador está incapacitado
 */
stock bool GeneMutations_IsPlayerIncapacitated(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0;
}

/**
 * Verifica si el jugador está siendo sujetado por un infectado
 */
stock bool GeneMutations_IsPlayerHeld(int client)
{
	// Verificar smoker, hunter, jockey, charger
	if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;

	return false;
}

/**
 * Obtiene el nivel de mutación del jugador
 */
public int GeneMutations_GetLevel(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iGeneMutations_Level[client];
}
