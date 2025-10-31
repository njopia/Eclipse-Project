#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LIFESTEALER ACTIVE ABILITY ===
// Cura una porción del daño infligido
// Nivel: 12
// Duración: 60 segundos
// Cooldown: 5 minutos (300 segundos)
//==================================================

// --- Particles & Sounds ---
#define PARTICLE_BLOOD_DRAIN "blood_advisor_pierce_spray"
#define PARTICLE_HEAL_PULSE "healing_aura_pulse"
#define SOUND_LIFESTEAL "player/survivor/voice/gambler/painrelieftirstaid01.wav"
#define SOUND_HEARTBEAT "player/heartbeatloop.wav"

// --- HP por tipo de enemigo ---
#define LIFESTEAL_HP_COMMON     1    // HP por infectado común
#define LIFESTEAL_HP_SPECIAL    5    // HP por infectado especial
#define LIFESTEAL_HP_WITCH      50   // HP por Witch
#define LIFESTEAL_HP_TANK       100  // HP por Tank

// --- ConVars ---
Handle cvar_LifeStealer_RequiredLevel = INVALID_HANDLE;
Handle cvar_LifeStealer_Duration = INVALID_HANDLE;
Handle cvar_LifeStealer_Cooldown = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bLifeStealer_Active[MAXPLAYERS + 1];
int  g_iLifeStealer_TimeRemaining[MAXPLAYERS + 1];
int  g_iLifeStealer_Cooldown[MAXPLAYERS + 1];
int  g_iLifeStealer_TotalHealed[MAXPLAYERS + 1];  // Total de vida robada en esta activación
Handle g_hLifeStealer_HeartbeatSound[MAXPLAYERS + 1];  // Handle del sonido de latidos

/**
 * Inicializa el módulo de LifeStealer
 */
public void LifeStealer_OnPluginStart()
{
	cvar_LifeStealer_RequiredLevel = CreateConVar(
		"ability_lifestealer_level",
		"1",
		"Nivel requerido para desbloquear LifeStealer",
		FCVAR_PLUGIN
	);

	cvar_LifeStealer_Duration = CreateConVar(
		"ability_lifestealer_duration",
		"60",
		"Duración de LifeStealer en segundos",
		FCVAR_PLUGIN
	);

	cvar_LifeStealer_Cooldown = CreateConVar(
		"ability_lifestealer_cooldown",
		"300",
		"Cooldown de LifeStealer en segundos",
		FCVAR_PLUGIN
	);

	// Precache sounds
	PrecacheSound(SOUND_LIFESTEAL, true);
	PrecacheSound(SOUND_HEARTBEAT, true);
}

/**
 * Resetea el estado al conectar
 */
public void LifeStealer_OnClientConnect(int client)
{
	g_bLifeStealer_Active[client] = false;
	g_iLifeStealer_TimeRemaining[client] = 0;
	g_iLifeStealer_Cooldown[client] = 0;
	g_iLifeStealer_TotalHealed[client] = 0;
	g_hLifeStealer_HeartbeatSound[client] = INVALID_HANDLE;
}

/**
 * Limpia recursos al desconectar
 */
public void LifeStealer_OnClientDisconnect(int client)
{
	LifeStealer_Deactivate(client);
	g_iLifeStealer_Cooldown[client] = 0;
}

/**
 * Actualiza timers cada segundo
 */
public void LifeStealer_OnSecondTick(int client)
{
	// Reducir cooldown
	if (g_iLifeStealer_Cooldown[client] > 0)
	{
		g_iLifeStealer_Cooldown[client]--;
	}

	// Actualizar habilidad activa
	if (g_bLifeStealer_Active[client])
	{
		g_iLifeStealer_TimeRemaining[client]--;

		// Mantener night vision
		if (g_iLifeStealer_TimeRemaining[client] > 0 && g_iLifeStealer_TimeRemaining[client] <= 50)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
		}

		// Desactivar si se acabó el tiempo
		if (g_iLifeStealer_TimeRemaining[client] <= 0)
		{
			LifeStealer_Deactivate(client);
		}
	}
}

/**
 * Verifica si el jugador puede usar LifeStealer
 */
public bool LifeStealer_CanUse(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_LifeStealer_RequiredLevel);

	if (level < requiredLevel)
	{
		PrintToChat(client, "\x05[DEBUG LifeStealer]\x01 Nivel insuficiente: %d/%d", level, requiredLevel);
		return false;
	}

	if (g_iLifeStealer_Cooldown[client] > 0)
	{
		PrintToChat(client, "\x05[DEBUG LifeStealer]\x01 Cooldown activo: %ds", g_iLifeStealer_Cooldown[client]);
		return false;
	}

	if (g_bLifeStealer_Active[client])
	{
		PrintToChat(client, "\x05[DEBUG LifeStealer]\x01 Ya está activo");
		return false;
	}

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		PrintToChat(client, "\x05[DEBUG LifeStealer]\x01 No estás en juego o no estás vivo");
		return false;
	}

	PrintToChat(client, "\x04[DEBUG LifeStealer]\x01 Todos los requisitos cumplidos!");
	return true;
}

/**
 * Activa LifeStealer
 */
public void LifeStealer_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int duration = GetConVarInt(cvar_LifeStealer_Duration);
	int cooldown = GetConVarInt(cvar_LifeStealer_Cooldown);

	g_bLifeStealer_Active[client] = true;
	g_iLifeStealer_TimeRemaining[client] = duration;
	g_iLifeStealer_Cooldown[client] = cooldown;
	g_iLifeStealer_TotalHealed[client] = 0;

	// Activar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	// Iniciar sonido de latidos del corazón (loop)
	EmitSoundToClient(client, SOUND_HEARTBEAT, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);

	// Efecto visual de activación (aura roja)
	LifeStealer_CreateActivationEffect(client);

	PrintToChat(client, "\x04[ABILITY ACTIVATED]\x01 LifeStealer - Duration: %ds", duration);
	PrintToChat(client, "\x04[Eclipse]\x01 HP robado: Común:\x05+1\x01 | Especial:\x05+5\x01 | Witch:\x05+50\x01 | Tank:\x05+100\x01");
}

/**
 * Desactiva LifeStealer
 */
public void LifeStealer_Deactivate(int client)
{
	if (!g_bLifeStealer_Active[client])
		return;

	int totalHealed = g_iLifeStealer_TotalHealed[client];

	g_bLifeStealer_Active[client] = false;
	g_iLifeStealer_TimeRemaining[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);

		// Detener sonido de latidos
		StopSound(client, SNDCHAN_AUTO, SOUND_HEARTBEAT);

		PrintToChat(client, "\x04[Eclipse]\x01 LifeStealer desactivado - Total curado: \x05%d HP\x01", totalHealed);
	}

	g_iLifeStealer_TotalHealed[client] = 0;
}

/**
 * Hook para robar vida al hacer daño
 */
public void LifeStealer_OnDamageDealt(int attacker, int victim, float damage)
{
	if (!g_bLifeStealer_Active[attacker])
		return;

	if (attacker <= 0 || attacker > MaxClients)
		return;

	if (!IsClientInGame(attacker) || !IsPlayerAlive(attacker))
		return;

	// Determinar tipo de enemigo y HP a robar
	int healAmount = LifeStealer_GetHPByEnemyType(victim);

	if (healAmount <= 0)
		return;

	// Acumular vida total robada
	g_iLifeStealer_TotalHealed[attacker] += healAmount;

	// Aplicar curación
	LifeStealer_StealLife(attacker, healAmount);

	// Efectos visuales y de sonido
	LifeStealer_CreateDrainEffect(victim, attacker);
	LifeStealer_CreateEffect(victim);

	// Mostrar en pantalla con código de color (hint text)
	char victimType[32];
	LifeStealer_GetEnemyTypeName(victim, victimType, sizeof(victimType));
	PrintHintText(attacker, "❤ LifeStealer: +%d HP (%s)\nTotal: %d HP", healAmount, victimType, g_iLifeStealer_TotalHealed[attacker]);
}

/**
 * Roba vida del enemigo y cura al atacante
 */
stock void LifeStealer_StealLife(int client, int healAmount)
{
	if (!IsClientInGame(client))
		return;

	// Si está incapacitado, intentar revivir
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		int health = GetClientHealth(client);
		int tempHealth = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_healthBuffer"));
		int totalHealth = health + tempHealth;

		if (totalHealth + healAmount >= 30)
		{
			// Añadir vida temporal para ayudar a levantarse
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(healAmount));
			return;
		}
	}

	// Curar normalmente
	int currentHealth = GetClientHealth(client);
	int maxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	int newHealth = currentHealth + healAmount;

	// Calcular HP real ganado (puede estar en el máximo)
	int actualHealAmount = healAmount;
	if (newHealth > maxHealth)
	{
		actualHealAmount = maxHealth - currentHealth;
		newHealth = maxHealth;
	}

	SetEntProp(client, Prop_Data, "m_iHealth", newHealth);

	// Efecto de curación en el jugador
	LifeStealer_CreateHealEffect(client);

	// Sonido de robo de vida (100% probabilidad, pero más bajo volumen)
	EmitSoundToClient(client, SOUND_LIFESTEAL, SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);

	// Feedback por chat mostrando HP ganado
	if (actualHealAmount > 0)
	{
		PrintToChat(client, "\x04[LifeStealer]\x01 +\x05%d HP\x01 robado (Total: \x05%d HP\x01)", actualHealAmount, g_iLifeStealer_TotalHealed[client]);
	}
}

/**
 * Crea efecto visual en el enemigo (glow rojo temporal)
 */
stock void LifeStealer_CreateEffect(int victim)
{
	if (victim <= 0)
		return;

	// Solo aplicar a entidades válidas
	if (victim > MaxClients)
	{
		if (!IsValidEntity(victim))
			return;
	}
	else
	{
		if (!IsClientInGame(victim))
			return;
	}

	// Glow rojo temporal
	int glowColor = (102 << 0) | (0 << 8) | (0 << 16); // RGB: 102, 0, 0
	SetEntProp(victim, Prop_Send, "m_glowColorOverride", glowColor);
	SetEntProp(victim, Prop_Send, "m_iGlowType", 3);

	// Remover glow después de 0.5 segundos
	CreateTimer(0.5, Timer_LifeStealer_RemoveGlow, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer para remover el glow
 */
public Action Timer_LifeStealer_RemoveGlow(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		int glowColor = (255 << 0) | (255 << 8) | (255 << 16); // RGB: 255, 255, 255 (blanco)
		SetEntProp(client, Prop_Send, "m_glowColorOverride", glowColor);
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	}
	return Plugin_Stop;
}

/**
 * Obtiene si LifeStealer está activo
 */
public bool LifeStealer_IsActive(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bLifeStealer_Active[client];
}

/**
 * Obtiene el cooldown restante
 */
public int LifeStealer_GetCooldown(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iLifeStealer_Cooldown[client];
}

/**
 * Obtiene el tiempo restante de la habilidad
 */
public int LifeStealer_GetTimeRemaining(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iLifeStealer_TimeRemaining[client];
}

/**
 * Crea efecto de activación (aura roja)
 */
stock void LifeStealer_CreateActivationEffect(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	// Crear partícula de sangre alrededor del jugador
	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		float Origin[3];
		GetClientAbsOrigin(client, Origin);
		Origin[2] += 50.0;

		DispatchKeyValue(particle, "effect_name", "blood_impact_red_01");
		DispatchKeyValueVector(particle, "origin", Origin);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		SetVariantString("OnUser1 !self:Kill::2.0:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

/**
 * Crea efecto de drenaje de sangre del enemigo al jugador
 */
stock void LifeStealer_CreateDrainEffect(int victim, int attacker)
{
	if (victim <= 0 || !IsValidEntity(victim))
		return;

	if (!IsClientInGame(attacker))
		return;

	float victimPos[3], attackerPos[3];

	// Obtener posiciones
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim))
		GetClientAbsOrigin(victim, victimPos);
	else
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);

	GetClientAbsOrigin(attacker, attackerPos);

	victimPos[2] += 40.0;
	attackerPos[2] += 50.0;

	// Crear partícula de sangre en la víctima
	int particle = CreateEntityByName("info_particle_system");
	if (particle > 0 && IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", PARTICLE_BLOOD_DRAIN);
		DispatchKeyValueVector(particle, "origin", victimPos);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		SetVariantString("OnUser1 !self:Kill::0.5:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

/**
 * Crea efecto de curación en el jugador
 */
stock void LifeStealer_CreateHealEffect(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	// Breve flash verde en la pantalla
	int clients[1];
	clients[0] = client;

	int color[4] = {50, 255, 50, 30};  // Verde claro semi-transparente
	int duration = 200;  // 200ms
	int holdtime = 100;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, 0x0001);  // FADE IN
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}
}

/**
 * Determina cuánto HP robar según el tipo de enemigo
 */
stock int LifeStealer_GetHPByEnemyType(int victim)
{
	// Si es un jugador (infectado especial o Tank)
	if (victim > 0 && victim <= MaxClients)
	{
		if (!IsClientInGame(victim))
			return 0;

		// Verificar si es Tank
		if (IsTank(victim))
			return LIFESTEAL_HP_TANK;  // +100 HP por Tank

		// Es infectado especial (Smoker, Hunter, Jockey, etc.)
		return LIFESTEAL_HP_SPECIAL;  // +5 HP por especial
	}
	// Si es una entidad (infectado común o Witch)
	else if (victim > MaxClients && IsValidEntity(victim))
	{
		char classname[32];
		GetEntityClassname(victim, classname, sizeof(classname));

		// Verificar si es Witch
		if (StrEqual(classname, "witch", false))
			return LIFESTEAL_HP_WITCH;  // +50 HP por Witch

		// Verificar si es infectado común
		if (StrEqual(classname, "infected", false))
			return LIFESTEAL_HP_COMMON;  // +1 HP por común
	}

	return 0;  // No es un enemigo válido
}

/**
 * Obtiene el nombre del tipo de enemigo para mostrar en pantalla
 */
stock void LifeStealer_GetEnemyTypeName(int victim, char[] buffer, int maxlen)
{
	// Si es un jugador (infectado especial o Tank)
	if (victim > 0 && victim <= MaxClients)
	{
		if (!IsClientInGame(victim))
		{
			Format(buffer, maxlen, "Desconocido");
			return;
		}

		// Verificar si es Tank
		if (IsTank(victim))
		{
			Format(buffer, maxlen, "Tank");
			return;
		}

		// Es infectado especial - obtener clase
		char classname[32];
		GetEntityNetClass(victim, classname, sizeof(classname));
		Format(buffer, maxlen, "%s", classname);
		return;
	}
	// Si es una entidad (infectado común o Witch)
	else if (victim > MaxClients && IsValidEntity(victim))
	{
		char classname[32];
		GetEntityClassname(victim, classname, sizeof(classname));

		if (StrEqual(classname, "witch", false))
			Format(buffer, maxlen, "Witch");
		else if (StrEqual(classname, "infected", false))
			Format(buffer, maxlen, "Común");
		else
			Format(buffer, maxlen, "%s", classname);
		return;
	}

	Format(buffer, maxlen, "Desconocido");
}
