#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SIZE MATTERS PASSIVE REWARD ===
// Permite refill de M60 y Grenade Launcher en ammo piles
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_SizeMatters_RequiredLevel = INVALID_HANDLE;
Handle cvar_SizeMatters_M60Ammo = INVALID_HANDLE;
Handle cvar_SizeMatters_GLAmmo = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bSizeMatters_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Size Matters
 */
public void SizeMatters_OnPluginStart()
{
	cvar_SizeMatters_RequiredLevel = CreateConVar(
		"reward_sizematters_level",
		"29",
		"Nivel requerido para desbloquear Size Matters",
		FCVAR_PLUGIN
	);

	cvar_SizeMatters_M60Ammo = CreateConVar(
		"reward_sizematters_m60",
		"150",
		"Munición del cargador M60 en ammo pile",
		FCVAR_PLUGIN
	);

	cvar_SizeMatters_GLAmmo = CreateConVar(
		"reward_sizematters_gl",
		"30",
		"Munición del Grenade Launcher en ammo pile",
		FCVAR_PLUGIN
	);

	// Hook para evento de ammo pile
	HookEvent("ammo_pickup", Event_SizeMatters_AmmoPickup, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void SizeMatters_OnClientConnect(int client)
{
	g_bSizeMatters_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void SizeMatters_OnClientDisconnect(int client)
{
	g_bSizeMatters_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void SizeMatters_OnPlayerSpawn(int client, int level)
{
	if (SizeMatters_IsUnlocked(client, level))
	{
		g_bSizeMatters_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void SizeMatters_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_SizeMatters_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bSizeMatters_Enabled[client] = true;
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Size Matters\x01! (Refill M60 y Grenade Launcher en ammo piles)");
	}
	else if (level > requiredLevel)
	{
		g_bSizeMatters_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool SizeMatters_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_SizeMatters_RequiredLevel);
}

/**
 * Evento: Ammo Pickup - Recarga armas pesadas
 */
public Action Event_SizeMatters_AmmoPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (!g_bSizeMatters_Enabled[client])
		return Plugin_Continue;

	SizeMatters_RefillHeavyWeapons(client);

	return Plugin_Continue;
}

/**
 * Recarga M60 y Grenade Launcher
 */
stock void SizeMatters_RefillHeavyWeapons(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon <= 0)
		return;

	char weaponName[64];
	GetEdictClassname(weapon, weaponName, sizeof(weaponName));

	// M60
	if (StrEqual(weaponName, "weapon_rifle_m60", false))
	{
		int maxAmmo = GetConVarInt(cvar_SizeMatters_M60Ammo);
		int currentAmmo = GetEntProp(weapon, Prop_Send, "m_iClip1");

		if (currentAmmo < maxAmmo)
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", maxAmmo);
			PrintToChat(client, "\x04[Size Matters]\x01 Heavy Weapon Ammo Collected");
		}
	}
	// Grenade Launcher
	else if (StrEqual(weaponName, "weapon_grenade_launcher", false))
	{
		int maxAmmo = GetConVarInt(cvar_SizeMatters_GLAmmo);
		int offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		int currentAmmo = GetEntData(client, offset + 68); // Offset 68 es para GL

		if (currentAmmo < maxAmmo)
		{
			SetEntData(client, offset + 68, maxAmmo);
			PrintToChat(client, "\x04[Size Matters]\x01 Heavy Weapon Ammo Collected");
		}
	}
}

/**
 * Obtiene si Size Matters está habilitado para un jugador
 */
public bool SizeMatters_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bSizeMatters_Enabled[client];
}
