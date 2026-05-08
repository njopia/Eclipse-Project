#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//////////////////////////////////////////
// TEAM BONUSES: Team Speed Boost       //
//////////////////////////////////////////

// --- Defines ---
#define GLOW_COLOR_BLUE RGB_TO_INT(0, 100, 255)

// --- Cooldown ---
static float  g_fNextTeamSpeedBoost[MAXPLAYERS + 1];
static Handle g_hGlowTimer = INVALID_HANDLE;

/**
 * Activa la habilidad Team Speed Boost para un jugador.
 * Aumenta la velocidad de todos los sobrevivientes un 40% durante CONFIG_TEAM_SPEEDBOOST_DURATION.
 *
 * @param client  Índice del jugador que activa la habilidad.
 */
stock void	 Activate_TeamSpeedBoost(int client)
{
	if (!IsSurvivor(client))
		return;

	int remainingTime = RoundToNearest(g_fNextTeamSpeedBoost[client] - GetGameTime());
	if (remainingTime > 0)
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Debes esperar \x04%d\x01 segundos.", remainingTime);
		return;
	}

	PlayTeamSpeedBoostEffects(client);

	// Aplicar boost a todo el equipo via speed manager
	SPD_ApplyToTeam(SpeedLayer_TeamBoost, CONFIG_TEAM_SPEEDBOOST_AMOUNT, CONFIG_TEAM_SPEEDBOOST_DURATION);

	ApplySpeedBoostGlow();

	if (g_hGlowTimer != INVALID_HANDLE)
		KillTimer(g_hGlowTimer);
	g_hGlowTimer = CreateTimer(CONFIG_TEAM_SPEEDBOOST_DURATION, _TeamSpeedBoost_GlowExpire, _, TIMER_FLAG_NO_MAPCHANGE);

	PrintToChatAll("\x05[Eclipse]\x01 \x04Team Speed Boost\x01 activado por \x04%.0f\x01 segundos!",
				   CONFIG_TEAM_SPEEDBOOST_DURATION);

	g_fNextTeamSpeedBoost[client] = GetGameTime() + CONFIG_TEAM_SPEEDBOOST_COOLDOWN;
}

/**
 * Reproduce efectos de sonido y visuales.
 */
static void PlayTeamSpeedBoostEffects(int client)
{
	EmitSoundToAll("player/adrenaline_inject.wav", client, SNDCHAN_VOICE);
	EmitSoundToAll("player/survivor/voice/mechanic/battlecry01.wav", client, SNDCHAN_AUTO);

	float origin[3];
	GetClientAbsOrigin(client, origin);
	FX_CreateParticleAtPos(origin, PARTICLE_ADRENALINE, 3.0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
			L4D_ScreenFade(i, 0, 100, 255, 100, 0.3, FADE_IN);
	}
}

/**
 * Aplica glow azul a todos los sobrevivientes.
 */
static void ApplySpeedBoostGlow()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsSurvivor(i) || !IsPlayerAlive(i))
			continue;

		SetEntProp(i, Prop_Send, "m_glowColorOverride", GLOW_COLOR_BLUE);
		SetEntProp(i, Prop_Send, "m_iGlowType", 2);
	}
}

/**
 * Remueve el glow de un cliente (llamar al expirar el boost si se desea).
 */
static void RemoveSpeedBoostGlow(int client)
{
	if (!IsClientInGame(client)) return;
	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
}

// =============================================================================
// API PÚBLICA
// =============================================================================

/**
 * Retorna true si el cliente tiene el Team Speed Boost activo.
 */
stock bool TeamSpeedBoost_IsActive(int client)
{
	return SPD_HasLayer(client, SpeedLayer_TeamBoost);
}

/**
 * Retorna el tiempo restante del boost activo (0.0 si no está activo).
 * Nota: el manager no expone el tiempo restante directamente,
 * así que lo calculamos desde el cooldown del cliente que lo activó.
 * Para un tracking exacto usa un timer propio si lo necesitas en la UI.
 */
stock float GetTeamSpeedBoostCooldown(int client)
{
	float remaining = g_fNextTeamSpeedBoost[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Resetea el cooldown (debugging / admin).
 */
stock void ResetTeamSpeedBoostCooldown(int client)
{
	g_fNextTeamSpeedBoost[client] = 0.0;
}

/**
 * Limpieza al desconectar cliente.
 */
stock void TeamSpeedBoost_OnClientDisconnect(int client)
{
	RemoveSpeedBoostGlow(client);
	SPD_OnClientDisconnect(client);
	g_fNextTeamSpeedBoost[client] = 0.0;
}

/**
 * Limpieza al cambiar de mapa.
 */
stock void CleanupTeamSpeedBoostTimers()
{
	if (g_hGlowTimer != INVALID_HANDLE)
	{
		KillTimer(g_hGlowTimer);
		g_hGlowTimer = INVALID_HANDLE;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		RemoveSpeedBoostGlow(i);
		g_fNextTeamSpeedBoost[i] = 0.0;
	}
	SPD_OnMapEnd();
}

public Action _TeamSpeedBoost_GlowExpire(Handle timer)
{
	g_hGlowTimer = INVALID_HANDLE;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			RemoveSpeedBoostGlow(i);
	}
	return Plugin_Stop;
}
