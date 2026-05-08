#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SELF REVIVE PASSIVE REWARD ===
// Permite auto-revivirse cuando esta incapacitado usando la tecla [USE]
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_SelfRevive_RequiredLevel = INVALID_HANDLE;
Handle cvar_SelfRevive_Duration = INVALID_HANDLE;
Handle cvar_SelfRevive_BonusHP = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bSelfRevive_Enabled[MAXPLAYERS + 1];
bool g_bSelfRevive_InProgress[MAXPLAYERS + 1];
float g_fSelfRevive_StartTime[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Self Revive
 */
public void SelfRevive_OnPluginStart()
{
	cvar_SelfRevive_RequiredLevel = CreateConVar(
		"reward_selfrevive_level",
		"11",
		"Nivel requerido para desbloquear Self Revive",
		FCVAR_PLUGIN
	);

	cvar_SelfRevive_Duration = CreateConVar(
		"reward_selfrevive_duration",
		"2.5",
		"Duracion del auto-revive en segundos",
		FCVAR_PLUGIN
	);

	cvar_SelfRevive_BonusHP = CreateConVar(
		"reward_selfrevive_bonus_hp",
		"30",
		"HP bonus al revivir si tiene Medic (nivel 4+)",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void SelfRevive_OnClientConnect(int client)
{
	g_bSelfRevive_Enabled[client] = false;
	g_bSelfRevive_InProgress[client] = false;
	g_fSelfRevive_StartTime[client] = 0.0;
}

/**
 * Limpia recursos al desconectar
 */
public void SelfRevive_OnClientDisconnect(int client)
{
	g_bSelfRevive_Enabled[client] = false;
	g_bSelfRevive_InProgress[client] = false;
	g_fSelfRevive_StartTime[client] = 0.0;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void SelfRevive_OnPlayerSpawn(int client, int level)
{
	if (SelfRevive_IsUnlocked(client, level))
	{
		g_bSelfRevive_Enabled[client] = true;
	}

	// Resetear estado de progreso
	g_bSelfRevive_InProgress[client] = false;
	g_fSelfRevive_StartTime[client] = 0.0;
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void SelfRevive_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_SelfRevive_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bSelfRevive_Enabled[client] = true;
		float duration = GetConVarFloat(cvar_SelfRevive_Duration);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Self Revive\x01! (Auto-revive en %.1fs con tecla USE)", duration);
	}
	else if (level > requiredLevel)
	{
		g_bSelfRevive_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool SelfRevive_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_SelfRevive_RequiredLevel);
}

/**
 * Proceso de self revive - debe ser llamado en OnPlayerRunCmd o similar
 * Retorna true si esta en proceso de revive
 */
public bool SelfRevive_Process(int client, int buttons)
{
	if (!g_bSelfRevive_Enabled[client])
		return false;

	if (!IsPlayerAlive(client))
		return false;

	// Verificar si esta incapacitado y no esta siendo sostenido por infectado
	if (!SelfRevive_IsIncapacitated(client) || SelfRevive_IsHeld(client))
	{
		if (g_bSelfRevive_InProgress[client])
		{
			g_bSelfRevive_InProgress[client] = false;
			g_fSelfRevive_StartTime[client] = 0.0;
		}
		return false;
	}

	// Verificar si alguien mas lo esta reviviendo
	int reviver = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
	if (reviver > 0 && reviver != client)
	{
		if (g_bSelfRevive_InProgress[client])
		{
			g_bSelfRevive_InProgress[client] = false;
			g_fSelfRevive_StartTime[client] = 0.0;
		}
		return false;
	}

	float currentTime = GetEngineTime();
	float duration = GetConVarFloat(cvar_SelfRevive_Duration);

	// Iniciar proceso si presiona USE
	if (buttons & IN_USE)
	{
		if (!g_bSelfRevive_InProgress[client] && reviver <= 0)
		{
			g_bSelfRevive_InProgress[client] = true;
			g_fSelfRevive_StartTime[client] = currentTime;
			SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
			PrintToChat(client, "\x04[Self Revive]\x01 Using Skill...");
		}
		else if (g_bSelfRevive_InProgress[client] && (currentTime - g_fSelfRevive_StartTime[client]) >= duration && reviver == client)
		{
			// Completar revive
			SelfRevive_Complete(client);
			g_bSelfRevive_InProgress[client] = false;
			g_fSelfRevive_StartTime[client] = 0.0;
		}
		return true;
	}
	else
	{
		// Cancelar si suelta USE
		if (g_bSelfRevive_InProgress[client])
		{
			g_bSelfRevive_InProgress[client] = false;
			g_fSelfRevive_StartTime[client] = 0.0;
			SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
		}
	}

	return false;
}

/**
 * Completa el self revive
 */
stock void SelfRevive_Complete(int client)
{
	// Revivir al jugador (esto requiere SDKCall configurado en el main)
	// Por ahora usaremos el metodo basico
	SelfRevive_RevivePlayer(client);

	// Bonus HP si tiene Medic (nivel 4+)
	// Esto se puede verificar desde el modulo principal
	// Por ahora aplicamos bonus HP basico
	int bonusHP = GetConVarInt(cvar_SelfRevive_BonusHP);
	SelfRevive_GiveHealth(client, bonusHP, false);

	PrintToChat(client, "\x04[Self Revive]\x01 Successfully revived!");
}

/**
 * Revive al jugador
 */
stock void SelfRevive_RevivePlayer(int client)
{
	// Nota: Esto requiere el SDKCall L4D2_ReviveSurvivor configurado en el main
	// Por ahora usaremos un metodo alternativo
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
}

/**
 * Otorga salud al jugador
 */
stock void SelfRevive_GiveHealth(int client, int amount, bool temp)
{
	int currentHP = GetClientHealth(client);
	int maxHP = GetEntProp(client, Prop_Data, "m_iMaxHealth");

	if (temp)
	{
		// Salud temporal
		float tempHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", tempHP + float(amount));
	}
	else
	{
		// Salud permanente
		int newHP = currentHP + amount;
		if (newHP > maxHP)
			newHP = maxHP;

		SetEntityHealth(client, newHP);
	}
}

/**
 * Verifica si el jugador esta incapacitado
 */
stock bool SelfRevive_IsIncapacitated(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1;
}

/**
 * Verifica si el jugador esta siendo sostenido por un infectado
 */
stock bool SelfRevive_IsHeld(int client)
{
	// Verificar si esta agarrado por Smoker, Hunter, Jockey, Charger
	if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;

	return false;
}

/**
 * Obtiene si Self Revive esta habilitado para un jugador
 */
public bool SelfRevive_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSelfRevive_Enabled[client];
}

/**
 * Obtiene si el jugador esta en proceso de self revive
 */
public bool SelfRevive_IsInProgress(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSelfRevive_InProgress[client];
}
