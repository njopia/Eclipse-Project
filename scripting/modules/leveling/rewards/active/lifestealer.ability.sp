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

// --- ConVars ---
Handle cvar_LifeStealer_RequiredLevel = INVALID_HANDLE;
Handle cvar_LifeStealer_Duration = INVALID_HANDLE;
Handle cvar_LifeStealer_Cooldown = INVALID_HANDLE;
Handle cvar_LifeStealer_HealPercent = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bLifeStealer_Active[MAXPLAYERS + 1];
int  g_iLifeStealer_TimeRemaining[MAXPLAYERS + 1];
int  g_iLifeStealer_Cooldown[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de LifeStealer
 */
public void LifeStealer_OnPluginStart()
{
	cvar_LifeStealer_RequiredLevel = CreateConVar(
		"ability_lifestealer_level",
		"12",
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

	cvar_LifeStealer_HealPercent = CreateConVar(
		"ability_lifestealer_heal",
		"0.15",
		"Porcentaje del daño que se convierte en curación (0.15 = 15%)",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void LifeStealer_OnClientConnect(int client)
{
	g_bLifeStealer_Active[client] = false;
	g_iLifeStealer_TimeRemaining[client] = 0;
	g_iLifeStealer_Cooldown[client] = 0;
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
		return false;

	if (g_iLifeStealer_Cooldown[client] > 0)
		return false;

	if (g_bLifeStealer_Active[client])
		return false;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

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

	// Activar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	PrintToChat(client, "\x04[Ability]\x01 LifeStealer Activated! (\x05%ds\x01)", duration);
}

/**
 * Desactiva LifeStealer
 */
public void LifeStealer_Deactivate(int client)
{
	if (!g_bLifeStealer_Active[client])
		return;

	g_bLifeStealer_Active[client] = false;
	g_iLifeStealer_TimeRemaining[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		PrintToChat(client, "\x04[Ability]\x01 LifeStealer Deactivated");
	}
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

	// Calcular curación
	float healPercent = GetConVarFloat(cvar_LifeStealer_HealPercent);
	int healAmount = RoundToFloor(damage * healPercent);

	if (healAmount <= 0)
		healAmount = 1;

	// Aplicar curación
	LifeStealer_StealLife(attacker, healAmount);

	// Efecto visual en el enemigo
	LifeStealer_CreateEffect(victim);
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

	if (newHealth > maxHealth)
		newHealth = maxHealth;

	SetEntProp(client, Prop_Data, "m_iHealth", newHealth);
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
