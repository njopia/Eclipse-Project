#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//////////////////////////////////////////
// TEAM BONUSES: Team Heal              //
//////////////////////////////////////////

// --- Defines ---
#define TEAM_HEAL_RADIUS 9999.0              // Radio infinito (todo el mapa)
#define GLOW_COLOR_LIME_GREEN RGB_TO_INT(50, 205, 50) // Verde lima
#define BOT_GLOW_BLINK_INTERVAL 0.5          // Intervalo de parpadeo (0.5s)

// --- Variables ---
static float g_fNextTeamHeal[MAXPLAYERS + 1];
static Handle g_hTeamHealTimer[MAXPLAYERS + 1];
static Handle g_hBotGlowBlinkTimer[MAXPLAYERS + 1];
static bool g_bBotGlowVisible[MAXPLAYERS + 1];
static int g_iMaxHealth[MAXPLAYERS + 1];

/**
 * Activa la habilidad Team Heal para un jugador.
 * Cura a todos los sobrevivientes con ticks de sanación hasta llegar al máximo.
 * Los bots survivors reciben glow verde lima parpadeante.
 *
 * @param client  Índice del jugador que activa la habilidad.
 */
stock void Activate_TeamHeal(int client)
{
	// 1. Verificar si es survivor
	if (!IsSurvivor(client))
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Solo los sobrevivientes pueden usar esta habilidad.");
		return;
	}

	// 2. Verificar cooldown
	float remainingTime = g_fNextTeamHeal[client] - GetGameTime();
	if (remainingTime > 0.0)
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Debes esperar \x04%.1f\x01 segundos.", remainingTime);
		return;
	}

	// 3. Efectos audiovisuales
	PlayTeamHealEffects(client);

	// 4. Curar a todos los sobrevivientes con ticks
	int survivorsHealed = HealAllSurvivors();

	// 5. Aplicar glow parpadeante a bots
	int botsGlowed = ApplyBotGlow();

	// 6. Feedback al jugador
	PrintToChat(client, "\x05[Eclipse]\x01 \x04Team Heal\x01 activado. Curando a \x04%d\x01 sobrevivientes (\x04%d\x01 bots).",
		survivorsHealed, botsGlowed);
	PrintToChatAll("\x05[Eclipse]\x01 \x04%N\x01 ha activado \x04Team Heal\x01. ¡Todos están siendo curados!", client);

	// 7. Establecer cooldown
	g_fNextTeamHeal[client] = GetGameTime() + CONFIG_TEAM_HEAL_COOLDOWN;
}

/**
 * Reproduce efectos de sonido y visuales para Team Heal
 */
static void PlayTeamHealEffects(int client)
{
	// Sonido de activación - usar comando de adrenaline
	EmitSoundToAll("player/adrenaline_inject.wav", client, SNDCHAN_VOICE);

	// Sonido adicional (victoria/activación)
	EmitSoundToAll("player/survivor/voice/gambler/battlecry01.wav", client, SNDCHAN_AUTO);

	// Obtener posición del cliente para la partícula
	float origin[3];
	GetClientAbsOrigin(client, origin);

	// Crear partícula de sanación
	CreateHealingParticle(origin);

	// Fade visual para todos (efecto de sanación)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			L4D_ScreenFade(i, 0, 255, 0, 100, 0.3, FADE_IN);
		}
	}

	// Aplicar efecto de adrenaline visual a todos (sin el tiempo de curación completo)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			// Usar L4D2_UseAdrenaline para efecto visual
			L4D2_UseAdrenaline(i, 3.0, false);
		}
	}
}

/**
 * Crea una partícula de sanación temporal
 */
static void CreateHealingParticle(const float origin[3])
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle == -1)
		return;

	// Usar partícula de sanación - luz verde brillante
	DispatchKeyValue(particle, "effect_name", "heal_sparkles");
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
 * Cura a todos los sobrevivientes con ticks hasta llegar al máximo
 * @return Número de sobrevivientes curados
 */
static int HealAllSurvivors()
{
	int survivorsHealed = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i) || !IsPlayerAlive(i))
			continue;

		// Obtener salud actual y máxima
		int currentHealth = GetEntProp(i, Prop_Data, "m_iHealth");
		int maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");

		// Si no está al máximo, curar
		if (currentHealth < maxHealth)
		{
			// Cancelar timer anterior si existe
			if (g_hTeamHealTimer[i] != INVALID_HANDLE)
			{
				KillTimer(g_hTeamHealTimer[i]);
				g_hTeamHealTimer[i] = INVALID_HANDLE;
			}

			// Guardar el maxHealth para el timer
			g_iMaxHealth[i] = maxHealth;

			// Crear timer para curación gradual
			g_hTeamHealTimer[i] = CreateTimer(
				CONFIG_TEAM_HEAL_TICK_INTERVAL,
				Timer_HealTick,
				i,
				TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
			);

			survivorsHealed++;

			// Efecto visual individual (destello verde)
			int glowColor = GLOW_COLOR_LIME_GREEN;
			SetEntProp(i, Prop_Send, "m_glowColorOverride", glowColor);
			SetEntProp(i, Prop_Send, "m_iGlowType", 2);

			// Remover glow después de 5 segundos
			CreateTimer(5.0, Timer_RemoveGlow, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return survivorsHealed;
}

/**
 * Timer para aplicar sanación gradual a un jugador
 */
public Action Timer_HealTick(Handle timer, int client)
{
	int maxHealth = g_iMaxHealth[client];

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !IsSurvivor(client))
	{
		g_hTeamHealTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int currentHealth = GetEntProp(client, Prop_Data, "m_iHealth");

	// Si llegó al máximo, detener timer
	if (currentHealth >= maxHealth)
	{
		g_hTeamHealTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Curar con tick
	int newHealth = currentHealth + CONFIG_TEAM_HEAL_PER_TICK;
	if (newHealth > maxHealth)
	{
		newHealth = maxHealth;
	}

	SetEntProp(client, Prop_Data, "m_iHealth", newHealth);

	// Mostrar feedback periódico
	if (newHealth % 10 == 0)
	{
		PrintToChat(client, "\x05[Eclipse]\x01 Sanando... \x04%d\x01 / \x04%d\x01", newHealth, maxHealth);
	}

	// Si llegó al máximo después de curar, detener timer
	if (newHealth >= maxHealth)
	{
		g_hTeamHealTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

/**
 * Timer para remover el glow temporal
 */
public Action Timer_RemoveGlow(Handle timer, int client)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;

	int glowType = GetEntProp(client, Prop_Send, "m_iGlowType");
	if (glowType == 2)
	{
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	}

	return Plugin_Stop;
}

/**
 * Aplica glow verde lima parpadeante a todos los bots survivors
 * @return Número de bots con glow aplicado
 */
static int ApplyBotGlow()
{
	int botsGlowed = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i) || !IsPlayerAlive(i) || !IsFakeClient(i))
			continue;

		botsGlowed++;

		// Aplicar glow inicial
		SetEntProp(i, Prop_Send, "m_glowColorOverride", GLOW_COLOR_LIME_GREEN);
		SetEntProp(i, Prop_Send, "m_iGlowType", 2);

		// Marcar como visible inicialmente
		g_bBotGlowVisible[i] = true;

		// Cancelar timer anterior si existe
		if (g_hBotGlowBlinkTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hBotGlowBlinkTimer[i]);
		}

		// Crear timer para parpadeo
		g_hBotGlowBlinkTimer[i] = CreateTimer(
			BOT_GLOW_BLINK_INTERVAL,
			Timer_BotGlowBlink,
			i,
			TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
		);
	}

	// Detener parpadeo después de 10 segundos
	CreateTimer(10.0, Timer_StopBotGlow, _, TIMER_FLAG_NO_MAPCHANGE);

	return botsGlowed;
}

/**
 * Timer para hacer parpadear el glow de bots
 */
public Action Timer_BotGlowBlink(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || !IsSurvivor(client))
	{
		g_hBotGlowBlinkTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Alternar visibilidad
	if (g_bBotGlowVisible[client])
	{
		// Apagar glow
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		g_bBotGlowVisible[client] = false;
	}
	else
	{
		// Encender glow
		SetEntProp(client, Prop_Send, "m_glowColorOverride", GLOW_COLOR_LIME_GREEN);
		SetEntProp(client, Prop_Send, "m_iGlowType", 2);
		g_bBotGlowVisible[client] = true;
	}

	return Plugin_Continue;
}

/**
 * Timer para detener el parpadeo de bots
 */
public Action Timer_StopBotGlow(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hBotGlowBlinkTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hBotGlowBlinkTimer[i]);
			g_hBotGlowBlinkTimer[i] = INVALID_HANDLE;
		}

		// Remover glow final
		if (IsClientInGame(i) && IsSurvivor(i))
		{
			SetEntProp(i, Prop_Send, "m_iGlowType", 0);
		}
	}

	return Plugin_Stop;
}

/**
 * Resetea el cooldown (útil para debugging)
 */
stock void ResetTeamHealCooldown(int client)
{
	g_fNextTeamHeal[client] = 0.0;
}

/**
 * Obtiene el tiempo restante de cooldown
 */
stock float GetTeamHealCooldown(int client)
{
	float remaining = g_fNextTeamHeal[client] - GetGameTime();
	return (remaining > 0.0) ? remaining : 0.0;
}

/**
 * Limpieza al desconectar cliente
 */
stock void TeamHeal_OnClientDisconnect(int client)
{
	if (g_hTeamHealTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTeamHealTimer[client]);
		g_hTeamHealTimer[client] = INVALID_HANDLE;
	}

	if (g_hBotGlowBlinkTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hBotGlowBlinkTimer[client]);
		g_hBotGlowBlinkTimer[client] = INVALID_HANDLE;
	}

	g_fNextTeamHeal[client] = 0.0;
	g_bBotGlowVisible[client] = false;
}

/**
 * Limpieza de todos los timers de Team Heal al cambiar de mapa
 * Llamada por CleanupAllTimers() en Eclipse Management System.sp
 */
stock void CleanupTeamHealTimers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hTeamHealTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hTeamHealTimer[i]);
			g_hTeamHealTimer[i] = INVALID_HANDLE;
		}

		if (g_hBotGlowBlinkTimer[i] != INVALID_HANDLE)
		{
			KillTimer(g_hBotGlowBlinkTimer[i]);
			g_hBotGlowBlinkTimer[i] = INVALID_HANDLE;
		}

		g_fNextTeamHeal[i] = 0.0;
		g_bBotGlowVisible[i] = false;
	}
}
