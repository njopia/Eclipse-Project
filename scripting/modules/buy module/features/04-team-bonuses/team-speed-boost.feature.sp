#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//////////////////////////////////////////
// TEAM BONUSES: Team Speed Boost       //
//////////////////////////////////////////

// --- Defines ---
#define GLOW_COLOR_BLUE			  RGB_TO_INT(0, 100, 255)	 // Azul brillante
#define TSB_SPEED_BASE			  1.0						 // Velocidad base normal

// --- Variables ---
static float  g_fNextTeamSpeedBoost[MAXPLAYERS + 1];
static Handle g_hTeamSpeedBoostTimer[MAXPLAYERS + 1];
static float  g_fSpeedBoostEnd[MAXPLAYERS + 1];
static float  g_fOriginalLaggedMovement[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Team Speed Boost al cargar el mapa
 */
public void TeamSpeedBoost_OnMapStart()
{
	CleanupTeamSpeedBoostTimers();
	LogMessage("[TeamSpeedBoost] Timers and cooldowns reset on map start");
}

/**
 * Hook de inicio de ronda - Resetear cooldowns
 */
public void TeamSpeedBoost_OnRoundStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ResetTeamSpeedBoostCooldown(i);
		}
	}
	LogMessage("[TeamSpeedBoost] Cooldowns reset on round start");
}

/**
 * Hook cuando jugador entra al servidor - Resetear cooldowns
 */
public void TeamSpeedBoost_OnClientPutInServer(int client)
{
	ResetTeamSpeedBoostCooldown(client);
	g_hTeamSpeedBoostTimer[client] = INVALID_HANDLE;
	g_fSpeedBoostEnd[client] = 0.0;
	g_fOriginalLaggedMovement[client] = 0.0;
	LogMessage("[TeamSpeedBoost] Cooldown reset for client %d on connect", client);
}

/**
 * Activa la habilidad Team Speed Boost para un jugador.
 * Aumenta la velocidad de movimiento de todos los sobrevivientes 40% durante 5 minutos.
 *
 * @param client  Índice del jugador que activa la habilidad.
 */
stock void	  Activate_TeamSpeedBoost(int client)
{
	// Verificar si es survivor
	if (!IsSurvivor(client))
		return;

	// Verificar cooldown
	int remainingTime = RoundToNearest(g_fNextTeamSpeedBoost[client] - GetGameTime());
	if (remainingTime > 0.0)
		return;

	// Efectos audiovisuales
	PlayTeamSpeedBoostEffects(client);

	// Aplicar boost de velocidad a todos los sobrevivientes
	ApplySpeedBoost();

	// Aplicar glow azul a jugadores afectados
	ApplySpeedBoostGlow();

	// Mensaje de activación
	PrintToChatAll("\x05[Eclipse]\x01 \x04Team Speed Boost activado!");

	// Establecer cooldown
	g_fNextTeamSpeedBoost[client] = GetGameTime() + CONFIG_TEAM_SPEEDBOOST_COOLDOWN;
}

/**
 * Reproduce efectos de sonido y visuales para Team Speed Boost
 */
static void PlayTeamSpeedBoostEffects(int client)
{
	// Sonido de activación - usar comando de adrenaline
	EmitSoundToAll("player/adrenaline_inject.wav", client, SNDCHAN_VOICE);

	// Sonido adicional (activación rápida)
	EmitSoundToAll("player/survivor/voice/mechanic/battlecry01.wav", client, SNDCHAN_AUTO);

	// Obtener posición del cliente para la partícula
	float origin[3];
	GetClientAbsOrigin(client, origin);

	// Crear partícula de velocidad
	CreateSpeedParticle(origin);

	// Fade visual para todos los supervivientes vivos (jugadores y bots)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			L4D_ScreenFade(i, 0, 100, 255, 100, 0.3, FADE_IN);
		}
	}

	// Aplicar efecto de adrenaline visual a todos los supervivientes (incluyendo bots)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			// Usar L4D2_UseAdrenaline para efecto visual en jugadores y bots
			L4D2_UseAdrenaline(i, 3.0, false);
		}
	}
}

/**
 * Crea una partícula de velocidad temporal
 */
static void CreateSpeedParticle(const float origin[3])
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle == -1)
		return;

	// Usar partícula de velocidad - efecto de viento/energía
	DispatchKeyValue(particle, "effect_name", "steam_fumes");
	TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	// Auto-destruir después de 3 segundos
	SetVariantString("OnUser1 !self:Kill::3.0:-1");
	AcceptEntityInput(particle, "AddOutput");
	AcceptEntityInput(particle, "FireUser1");
}

/**
 * Aplica el boost de velocidad a todos los sobrevivientes (incluyendo bots)
 * @return Número de sobrevivientes afectados
 */
static int ApplySpeedBoost()
{
	int	  survivorsBoosted = 0;
	float currentTime	   = GetGameTime();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsSurvivor(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		// Cancelar timer anterior si existe
		if (g_hTeamSpeedBoostTimer[i] != INVALID_HANDLE)
			KillTimer(g_hTeamSpeedBoostTimer[i]);

		// Guardar tiempo de finalización (5 minutos desde ahora)
		g_fSpeedBoostEnd[i]		  = currentTime + CONFIG_TEAM_SPEEDBOOST_DURATION;

		// Crear timer para mantener el boost (funciona con jugadores reales y bots)
		g_hTeamSpeedBoostTimer[i] = CreateTimer(
			CONFIG_TEAM_SPEEDBOOST_TICK_INTERVAL,
			Timer_MaintainSpeedBoost,
			i,
			TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		// Aplicar boost inicial (se aplica a jugadores y bots por igual)
		ApplySpeedToClient(i);

		survivorsBoosted++;
	}

	return survivorsBoosted;
}

/**
 * Aplica la velocidad boost a un cliente específico
 */
static void ApplySpeedToClient(int client)
{
	if (!IsClientInGame(client))
		return;

	if (!IsPlayerAlive(client))
		return;

	// Si es la primera vez, guardar velocidad original
	if (g_fOriginalLaggedMovement[client] <= 0.0)
		g_fOriginalLaggedMovement[client] = TSB_SPEED_BASE;

	// Aplicar boost usando el multiplicador correcto (1.40 = 40% más)
	L4D_SetPlayerSpeed(client, CONFIG_TEAM_SPEEDBOOST_AMOUNT);
}

/**
 * Timer para mantener el boost de velocidad
 */
public Action Timer_MaintainSpeedBoost(Handle timer, int client)
{
	float currentTime = GetGameTime();

	if (!IsClientInGame(client))
	{
		g_hTeamSpeedBoostTimer[client] = INVALID_HANDLE;
		g_fSpeedBoostEnd[client]	   = 0.0;
		return Plugin_Stop;
	}

	if (!IsPlayerAlive(client))
	{
		g_hTeamSpeedBoostTimer[client] = INVALID_HANDLE;
		g_fSpeedBoostEnd[client]	   = 0.0;
		return Plugin_Stop;
	}

	if (!IsSurvivor(client))
	{
		g_hTeamSpeedBoostTimer[client] = INVALID_HANDLE;
		g_fSpeedBoostEnd[client]	   = 0.0;
		return Plugin_Stop;
	}

	// Verificar si el boost ha expirado
	if (currentTime >= g_fSpeedBoostEnd[client])
	{
		RemoveSpeedBoost(client);
		g_hTeamSpeedBoostTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Mantener el boost aplicado
	ApplySpeedToClient(client);

	return Plugin_Continue;
}

/**
 * Remueve el boost de velocidad de un cliente
 */
static void RemoveSpeedBoost(int client)
{
	if (!IsClientInGame(client))
		return;

	// Restaurar velocidad original
	L4D_SetPlayerSpeed(client, TSB_SPEED_BASE);

	// Remover glow
	SetEntProp(client, Prop_Send, "m_iGlowType", 0);

	// Mensaje de finalización
	if (IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05[Eclipse]\x01 \x04Team Speed Boost terminado!");
	}

	// Resetear variables
	g_fSpeedBoostEnd[client] = 0.0;
	g_fOriginalLaggedMovement[client] = 0.0;
}

/**
 * Aplica glow azul a todos los sobrevivientes afectados por el boost (incluyendo bots)
 */
static void ApplySpeedBoostGlow()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsSurvivor(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		// Aplicar glow azul a jugadores y bots
		SetEntProp(i, Prop_Send, "m_glowColorOverride", GLOW_COLOR_BLUE);
		SetEntProp(i, Prop_Send, "m_iGlowType", 2);
	}
}

/**
 * Resetea el cooldown (útil para debugging)
 */
stock void ResetTeamSpeedBoostCooldown(int client)
{
	g_fNextTeamSpeedBoost[client] = 0.0;
}

/**
 * Obtiene el tiempo restante de cooldown
 */
stock float GetTeamSpeedBoostCooldown(int client)
{
	float remaining = g_fNextTeamSpeedBoost[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Obtiene el tiempo restante del boost activo
 */
stock float GetTeamSpeedBoostRemaining(int client)
{
	if (g_fSpeedBoostEnd[client] <= 0.0)
		return 0.0;

	float remaining = g_fSpeedBoostEnd[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Limpieza al desconectar cliente
 */
stock void TeamSpeedBoost_OnClientDisconnect(int client)
{
	if (g_hTeamSpeedBoostTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTeamSpeedBoostTimer[client]);
		g_hTeamSpeedBoostTimer[client] = INVALID_HANDLE;
	}

	g_fNextTeamSpeedBoost[client] = 0.0;
	g_fSpeedBoostEnd[client]	  = 0.0;
	g_fOriginalLaggedMovement[client]	  = 0.0;
}

/**
 * Limpieza de todos los timers de Team Speed Boost al cambiar de mapa
 * Llamada por CleanupAllTimers() en Eclipse Management System.sp
 */
stock void CleanupTeamSpeedBoostTimers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hTeamSpeedBoostTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hTeamSpeedBoostTimer[i]);
			g_hTeamSpeedBoostTimer[i] = INVALID_HANDLE;
		}

		g_fNextTeamSpeedBoost[i] = 0.0;
		g_fSpeedBoostEnd[i] = 0.0;
		g_fOriginalLaggedMovement[i] = 0.0;
	}
}
