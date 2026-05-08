#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === COMMANDO PASSIVE REWARD ===
// Permite recargar M60 con cartucho extendido de 300 balas en ammo piles
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_Commando_RequiredLevel = INVALID_HANDLE;
Handle cvar_Commando_ExtendedCartridge = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bCommando_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de Commando
 */
public void Commando_OnPluginStart()
{
	cvar_Commando_RequiredLevel = CreateConVar(
		"reward_commando_level",
		"41",
		"Nivel requerido para desbloquear Commando",
		FCVAR_PLUGIN
	);

	cvar_Commando_ExtendedCartridge = CreateConVar(
		"reward_commando_cartridge",
		"300",
		"Capacidad del cartucho extendido para M60",
		FCVAR_PLUGIN
	);
}

/**
 * Resetea el estado al conectar
 */
public void Commando_OnClientConnect(int client)
{
	g_bCommando_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void Commando_OnClientDisconnect(int client)
{
	g_bCommando_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void Commando_OnPlayerSpawn(int client, int level)
{
	if (Commando_IsUnlocked(client, level))
	{
		g_bCommando_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void Commando_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_Commando_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bCommando_Enabled[client] = true;
		int cartridge = GetConVarInt(cvar_Commando_ExtendedCartridge);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05Commando\x01! (Recarga M60 con cartucho de %d balas en ammo piles)", cartridge);
	}
	else if (level > requiredLevel)
	{
		g_bCommando_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool Commando_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_Commando_RequiredLevel);
}

/**
 * Recarga el M60 con cartucho extendido
 * Debe ser llamado cuando el jugador intenta usar un ammo pile
 */
public void Commando_ReloadM60(int client)
{
	if (!g_bCommando_Enabled[client])
		return;

	// Verificar si tiene M60
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon <= 0)
		return;

	char weaponName[64];
	GetEdictClassname(weapon, weaponName, sizeof(weaponName));

	if (!StrEqual(weaponName, "weapon_rifle_m60", false))
		return;

	// Obtener municion actual
	int offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	int currentAmmo = GetEntData(client, offset + 24); // Offset 24 es para M60

	int maxCartridge = GetConVarInt(cvar_Commando_ExtendedCartridge);

	if (currentAmmo < maxCartridge)
	{
		SetEntData(client, offset + 24, maxCartridge);
		PrintToChat(client, "\x04[Commando]\x01 Using Extended Cartridge Capacity");
	}
}

/**
 * Obtiene si Commando esta habilitado para un jugador
 */
public bool Commando_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bCommando_Enabled[client];
}
