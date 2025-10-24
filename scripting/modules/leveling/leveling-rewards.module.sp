#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING REWARDS MODULE ===
// Beneficios/Rewards según el nivel alcanzado
//==================================================

// --- ConVars para configurar rewards ---
Handle cvar_RewardDoubleJumpLevel = INVALID_HANDLE;
Handle cvar_RewardSpeedBoostLevel = INVALID_HANDLE;
Handle cvar_RewardSpeedBoostValue = INVALID_HANDLE;
Handle cvar_RewardHealthLevel = INVALID_HANDLE;
Handle cvar_RewardHealthValue = INVALID_HANDLE;
Handle cvar_RewardDamageReductionLevel = INVALID_HANDLE;

// --- Array para tracking de double jump por jugador ---
bool g_bPlayerDoubleJumpEnabled[MAXPLAYERS + 1];
int g_iPlayerJumpsUsed[MAXPLAYERS + 1];
bool g_bPlayerLastButtonJump[MAXPLAYERS + 1];  // Para detectar cuando se presiona el salto

/**
 * Inicializa el módulo de rewards
 * Debe ser llamado desde OnPluginStart()
 */
public void LevelingRewards_OnPluginStart()
{
	// Configurar en qué nivel se obtiene cada reward
	cvar_RewardDoubleJumpLevel = CreateConVar(
		"reward_double_jump_level",
		"1",
		"Nivel requerido para obtener doble salto",
		FCVAR_PLUGIN
	);

	cvar_RewardSpeedBoostLevel = CreateConVar(
		"reward_speed_boost_level",
		"2",
		"Nivel requerido para obtener +10% velocidad",
		FCVAR_PLUGIN
	);

	cvar_RewardSpeedBoostValue = CreateConVar(
		"reward_speed_boost_value",
		"1.1",
		"Multiplicador de velocidad (1.1 = +10%)",
		FCVAR_PLUGIN
	);

	cvar_RewardHealthLevel = CreateConVar(
		"reward_health_level",
		"3",
		"Nivel requerido para obtener +25 HP",
		FCVAR_PLUGIN
	);

	cvar_RewardHealthValue = CreateConVar(
		"reward_health_value",
		"25",
		"HP adicional a obtener",
		FCVAR_PLUGIN
	);

	cvar_RewardDamageReductionLevel = CreateConVar(
		"reward_damage_reduction_level",
		"4",
		"Nivel requerido para obtener resistencia a daño (placeholder)",
		FCVAR_PLUGIN
	);

	// Registrar hook para cuando el jugador spawn (aplicar rewards)
	HookEvent("player_spawn", Event_PlayerSpawn_Rewards, EventHookMode_Post);
}

/**
 * OnPlayerRunCmd - Se llama cada tick para detectar input del jugador
 * Usado para implementar el doble salto
 */
public Action LevelingRewards_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Solo procesar survivors
	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	// Solo procesar si el jugador tiene doble salto habilitado
	if (!g_bPlayerDoubleJumpEnabled[client])
		return Plugin_Continue;

	int flags = GetEntityFlags(client);

	// Si está en el suelo, resetear contador de saltos
	if (flags & FL_ONGROUND)
	{
		g_iPlayerJumpsUsed[client] = 0;
		g_bPlayerLastButtonJump[client] = false;
	}
	else  // Está en el aire
	{
		// Detectar cuando el jugador presiona SALTO (rising edge)
		bool isPressingJump = (buttons & IN_JUMP) != 0;

		if (isPressingJump && !g_bPlayerLastButtonJump[client])
		{
			// El jugador acaba de presionar salto
			g_iPlayerJumpsUsed[client]++;

			// Si es el segundo salto, aplicar impulso
			if (g_iPlayerJumpsUsed[client] == 2)
			{
				float velocity[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				velocity[2] = 300.0;  // Impulso vertical
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

				// Efecto de sonido (opcional, si quieres agregar feedback)
				// EmitSoundToAll("player/suit_sprint.wav", client);

				// Incrementar para evitar múltiples saltos
				g_iPlayerJumpsUsed[client]++;
			}
		}

		g_bPlayerLastButtonJump[client] = isPressingJump;
	}

	return Plugin_Continue;
}

/**
 * Aplica los rewards del nivel actual (con mensajes - llamado al subir de nivel)
 * @param client - ID del cliente
 * @param level - Nivel alcanzado
 */
public void LevelingRewards_ApplyRewards(int client, int level)
{
	LevelingRewards_ApplyRewardsInternal(client, level, true);
}

/**
 * Aplica los rewards del nivel actual silenciosamente (sin mensajes - llamado en spawn)
 * @param client - ID del cliente
 * @param level - Nivel alcanzado
 */
public void LevelingRewards_ApplyRewardsSilent(int client, int level)
{
	LevelingRewards_ApplyRewardsInternal(client, level, false);
}

/**
 * Función interna que aplica los rewards
 */
stock void LevelingRewards_ApplyRewardsInternal(int client, int level, bool showMessages)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	// Nivel 1: Doble salto
	if (level >= GetConVarInt(cvar_RewardDoubleJumpLevel))
	{
		g_bPlayerDoubleJumpEnabled[client] = true;
		if (showMessages)
			PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste el \x05Doble Salto\x01!");
	}

	// Nivel 2: +10% velocidad
	if (level >= GetConVarInt(cvar_RewardSpeedBoostLevel))
	{
		float speedBoost = GetConVarFloat(cvar_RewardSpeedBoostValue);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 250.0 * speedBoost);
		if (showMessages)
			PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05+10%% Velocidad\x01!");
	}

	// Nivel 3: +25 HP
	if (level >= GetConVarInt(cvar_RewardHealthLevel))
	{
		int healthBonus = GetConVarInt(cvar_RewardHealthValue);
		int currentHealth = GetClientHealth(client);
		SetEntityHealth(client, currentHealth + healthBonus);
		if (showMessages)
			PrintToChat(client, "\x04[REWARD]\x01 ¡Ganaste \x05+%d HP\x01!", healthBonus);
	}

	// Nivel 4+: Resistencia a daño (-5%)
	if (level >= GetConVarInt(cvar_RewardDamageReductionLevel))
	{
		if (showMessages)
			PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Resistencia a Daño (-5%%)\x01!");
	}
}

/**
 * Evento: Player Spawn (aplicar rewards al aparecer)
 */
public Action Event_PlayerSpawn_Rewards(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Resetear contador de saltos
	g_iPlayerJumpsUsed[client] = 0;

	// Aplicar rewards según nivel (sin mostrar mensajes en spawn)
	int playerLevel = Leveling_GetPlayerLevel(client);
	if (playerLevel > 0)
	{
		LevelingRewards_ApplyRewardsSilent(client, playerLevel);
	}

	// Mostrar UI de nivel/XP
	LevelingUI_ShowOnSpawn(client);

	return Plugin_Continue;
}

/**
 * Obtiene el status del doble salto
 */
public bool LevelingRewards_IsDoubleJumpEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bPlayerDoubleJumpEnabled[client];
}

/**
 * Resetear rewards al desconectar
 */
public void LevelingRewards_OnClientDisconnect(int client)
{
	g_bPlayerDoubleJumpEnabled[client] = false;
	g_iPlayerJumpsUsed[client] = 0;
	g_bPlayerLastButtonJump[client] = false;
}
