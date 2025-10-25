#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === ACID BATH ACTIVE ABILITY ===
// El ácido de Spitter cura en lugar de dañar
// Nivel: 9
// Duración: 60 segundos
// Cooldown: 5 minutos (300 segundos)
//==================================================

// --- ConVars ---
Handle cvar_AcidBath_RequiredLevel = INVALID_HANDLE;
Handle cvar_AcidBath_Duration = INVALID_HANDLE;
Handle cvar_AcidBath_Cooldown = INVALID_HANDLE;
Handle cvar_AcidBath_HealMultiplier = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bAcidBath_Active[MAXPLAYERS + 1];
int  g_iAcidBath_TimeRemaining[MAXPLAYERS + 1];
int  g_iAcidBath_Cooldown[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Acid Bath
 */
public void AcidBath_OnPluginStart()
{
	cvar_AcidBath_RequiredLevel = CreateConVar(
		"ability_acidbath_level",
		"9",
		"Nivel requerido para desbloquear Acid Bath",
		FCVAR_PLUGIN
	);

	cvar_AcidBath_Duration = CreateConVar(
		"ability_acidbath_duration",
		"60",
		"Duración de Acid Bath en segundos",
		FCVAR_PLUGIN
	);

	cvar_AcidBath_Cooldown = CreateConVar(
		"ability_acidbath_cooldown",
		"300",
		"Cooldown de Acid Bath en segundos",
		FCVAR_PLUGIN
	);

	cvar_AcidBath_HealMultiplier = CreateConVar(
		"ability_acidbath_heal",
		"1.0",
		"Multiplicador de curación del ácido",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void AcidBath_OnClientConnect(int client)
{
	g_bAcidBath_Active[client] = false;
	g_iAcidBath_TimeRemaining[client] = 0;
	g_iAcidBath_Cooldown[client] = 0;
}

/**
 * Limpia recursos al desconectar
 */
public void AcidBath_OnClientDisconnect(int client)
{
	AcidBath_Deactivate(client);
	g_iAcidBath_Cooldown[client] = 0;
}

/**
 * Actualiza timers cada segundo
 */
public void AcidBath_OnSecondTick(int client)
{
	// Reducir cooldown
	if (g_iAcidBath_Cooldown[client] > 0)
	{
		g_iAcidBath_Cooldown[client]--;
	}

	// Actualizar habilidad activa
	if (g_bAcidBath_Active[client])
	{
		g_iAcidBath_TimeRemaining[client]--;

		// Mantener night vision
		if (g_iAcidBath_TimeRemaining[client] > 0 && g_iAcidBath_TimeRemaining[client] <= 50)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
		}

		// Desactivar si se acabó el tiempo
		if (g_iAcidBath_TimeRemaining[client] <= 0)
		{
			AcidBath_Deactivate(client);
		}
	}
}

/**
 * Verifica si el jugador puede usar Acid Bath
 */
public bool AcidBath_CanUse(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_AcidBath_RequiredLevel);

	if (level < requiredLevel)
		return false;

	if (g_iAcidBath_Cooldown[client] > 0)
		return false;

	if (g_bAcidBath_Active[client])
		return false;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	return true;
}

/**
 * Activa Acid Bath
 */
public void AcidBath_Activate(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int duration = GetConVarInt(cvar_AcidBath_Duration);
	int cooldown = GetConVarInt(cvar_AcidBath_Cooldown);

	g_bAcidBath_Active[client] = true;
	g_iAcidBath_TimeRemaining[client] = duration;
	g_iAcidBath_Cooldown[client] = cooldown;

	// Activar night vision
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);

	PrintToChat(client, "\x04[Ability]\x01 Acid Bath Activated! (\x05%ds\x01)", duration);
}

/**
 * Desactiva Acid Bath
 */
public void AcidBath_Deactivate(int client)
{
	if (!g_bAcidBath_Active[client])
		return;

	g_bAcidBath_Active[client] = false;
	g_iAcidBath_TimeRemaining[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
		PrintToChat(client, "\x04[Ability]\x01 Acid Bath Deactivated");
	}
}

/**
 * Hook para convertir daño de ácido en curación
 */
public Action AcidBath_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bAcidBath_Active[victim])
		return Plugin_Continue;

	if (victim <= 0 || victim > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(victim))
		return Plugin_Continue;

	// Verificar si es daño de ácido de Spitter (insect_swarm)
	if (damagetype & DMG_RADIATION) // El ácido usa DMG_RADIATION en L4D2
	{
		// Convertir daño en curación
		float healAmount = damage * GetConVarFloat(cvar_AcidBath_HealMultiplier);

		int currentHealth = GetClientHealth(victim);
		int maxHealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth");
		int newHealth = currentHealth + RoundToFloor(healAmount);

		if (newHealth > maxHealth)
			newHealth = maxHealth;

		SetEntProp(victim, Prop_Data, "m_iHealth", newHealth);

		// Bloquear el daño
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/**
 * Obtiene si Acid Bath está activo
 */
public bool AcidBath_IsActive(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bAcidBath_Active[client];
}

/**
 * Obtiene el cooldown restante
 */
public int AcidBath_GetCooldown(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iAcidBath_Cooldown[client];
}

/**
 * Obtiene el tiempo restante de la habilidad
 */
public int AcidBath_GetTimeRemaining(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iAcidBath_TimeRemaining[client];
}
