#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SLEIGHT OF HAND PASSIVE REWARD ===
// Aumenta la velocidad de recarga de armas
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_SleightOfHand_RequiredLevel = INVALID_HANDLE;
Handle cvar_SleightOfHand_ReloadRate = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bSleightOfHand_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Sleight of Hand
 */
public void SleightOfHand_OnPluginStart()
{
	cvar_SleightOfHand_RequiredLevel = CreateConVar(
		"reward_sleightofhand_level",
		"13",
		"Nivel requerido para desbloquear Sleight of Hand (recarga rápida)",
		FCVAR_PLUGIN
	);

	cvar_SleightOfHand_ReloadRate = CreateConVar(
		"reward_sleightofhand_reload_rate",
		"0.5",
		"Multiplicador de velocidad de recarga (0.5 = mitad del tiempo, 0.25 = 4x más rápido)",
		FCVAR_PLUGIN
	);

	// Hook para evento de recarga
	HookEvent("weapon_reload", Event_SleightOfHand_Reload, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void SleightOfHand_OnClientConnect(int client)
{
	g_bSleightOfHand_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void SleightOfHand_OnClientDisconnect(int client)
{
	g_bSleightOfHand_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void SleightOfHand_OnPlayerSpawn(int client, int level)
{
	if (SleightOfHand_IsUnlocked(client, level))
	{
		g_bSleightOfHand_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void SleightOfHand_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_SleightOfHand_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzó el nivel requerido
	if (level == requiredLevel)
	{
		g_bSleightOfHand_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Sleight of Hand\x01! (Recarga más rápida)");
	}
	else if (level > requiredLevel)
	{
		g_bSleightOfHand_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool SleightOfHand_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_SleightOfHand_RequiredLevel);
}

/**
 * Evento: Weapon Reload - Aumenta la velocidad de recarga
 */
public Action Event_SleightOfHand_Reload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2) // Solo survivors
		return Plugin_Continue;

	if (!g_bSleightOfHand_Enabled[client])
		return Plugin_Continue;

	SleightOfHand_UpdateReload(client);

	return Plugin_Continue;
}

/**
 * Aplica el multiplicador de recarga al arma activa
 */
stock void SleightOfHand_UpdateReload(int client)
{
	// Obtener arma activa
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (weapon <= 0 || !IsValidEntity(weapon))
		return;

	char classname[32];
	GetEdictClassname(weapon, classname, sizeof(classname));

	float reloadRate = GetConVarFloat(cvar_SleightOfHand_ReloadRate);

	// Para shotguns, el sistema es diferente (recarga por shell)
	// Para otras armas, usamos el playback rate
	if (StrContains(classname, "shotgun", false) == -1)
	{
		// No es shotgun, aplicar playback rate directo
		SleightOfHand_SetReloadRate(weapon, reloadRate);
	}
	else
	{
		// Es shotgun, necesita manejo especial
		if (StrContains(classname, "autoshotgun", false) != -1 ||
		    StrContains(classname, "shotgun_spas", false) != -1)
		{
			// Auto shotgun - recarga por magazine completo
			SleightOfHand_SetReloadRate(weapon, reloadRate);
		}
		else
		{
			// Pump shotgun - recarga shell por shell
			SleightOfHand_SetReloadRate(weapon, reloadRate);
		}
	}
}

/**
 * Establece la velocidad de recarga de un arma
 */
stock void SleightOfHand_SetReloadRate(int weapon, float rate)
{
	if (!IsValidEntity(weapon))
		return;

	// Establecer el playback rate (velocidad de animación)
	// Valores menores = más rápido (0.5 = mitad del tiempo)
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 1.0 / rate);

	// Ajustar el tiempo de recarga
	float gameTime = GetGameTime();
	float nextAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");

	if (nextAttack > gameTime)
	{
		float timeLeft = nextAttack - gameTime;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime + (timeLeft * rate));
	}
}

/**
 * Obtiene si Sleight of Hand está habilitado para un jugador
 */
public bool SleightOfHand_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSleightOfHand_Enabled[client];
}
