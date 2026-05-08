#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === DAMAGE REDUCTION PASSIVE REWARD ===
// Reduce el dano recibido por el jugador
//==================================================

// --- ConVars ---
Handle cvar_DamageReduction_RequiredLevel = INVALID_HANDLE;
Handle cvar_DamageReduction_Percentage = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bDamageReduction_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Damage Reduction
 */
public void DamageReduction_OnPluginStart()
{
	cvar_DamageReduction_RequiredLevel = CreateConVar(
		"reward_damage_reduction_level",
		"9",
		"Nivel requerido para desbloquear reduccion de dano",
		FCVAR_PLUGIN
	);

	cvar_DamageReduction_Percentage = CreateConVar(
		"reward_damage_reduction_value",
		"0.05",
		"Porcentaje de reduccion de dano (0.05 = 5%, 0.10 = 10%)",
		FCVAR_PLUGIN
	);

	// Hook para modificar el dano recibido
	HookEvent("player_hurt", Event_PlayerHurt_DamageReduction, EventHookMode_Pre);
}

/**
 * Resetea el estado al conectar
 */
public void DamageReduction_OnClientConnect(int client)
{
	g_bDamageReduction_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void DamageReduction_OnClientDisconnect(int client)
{
	g_bDamageReduction_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void DamageReduction_OnPlayerSpawn(int client, int level)
{
	if (DamageReduction_IsUnlocked(client, level))
	{
		g_bDamageReduction_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void DamageReduction_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_DamageReduction_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzo el nivel requerido
	if (level == requiredLevel)
	{
		g_bDamageReduction_Enabled[client] = true;

		float reductionValue = GetConVarFloat(cvar_DamageReduction_Percentage);
		int percentage = RoundToFloor(reductionValue * 100.0);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Resistencia a Dano (-%d%%)\x01!", percentage);
	}
	else if (level > requiredLevel)
	{
		g_bDamageReduction_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool DamageReduction_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_DamageReduction_RequiredLevel);
}

/**
 * Evento: Player Hurt - Reduce el dano recibido
 * NOTA: Este evento es informativo, el dano ya fue aplicado.
 * Para implementar reduccion de dano real, se necesita usar OnTakeDamage hook.
 * Este codigo es un placeholder que muestra la estructura.
 */
public Action Event_PlayerHurt_DamageReduction(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	// TODO: Implementar reduccion de dano real usando SDKHooks_TakeDamage
	// Este hook requiere SDKHooks y debe interceptar el dano ANTES de aplicarlo

	return Plugin_Continue;
}

/**
 * Obtiene si la reduccion de dano esta habilitada para un jugador
 */
public bool DamageReduction_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bDamageReduction_Enabled[client];
}

/**
 * Calcula el dano reducido para un jugador
 * @param client - ID del cliente
 * @param damage - Dano original
 * @return Dano despues de aplicar la reduccion
 */
public float DamageReduction_CalculateDamage(int client, float damage)
{
	if (!g_bDamageReduction_Enabled[client])
		return damage;

	float reductionPercentage = GetConVarFloat(cvar_DamageReduction_Percentage);
	return damage * (1.0 - reductionPercentage);
}
