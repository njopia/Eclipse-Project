#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === PACK RAT PASSIVE REWARD ===
// Permite llevar más munición en todas las armas
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_PackRat_RequiredLevel = INVALID_HANDLE;
Handle cvar_PackRat_AmmoMultiplier = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bPackRat_Enabled[MAXPLAYERS + 1];

/**
 * Inicializa el módulo de Pack Rat
 */
public void PackRat_OnPluginStart()
{
	cvar_PackRat_RequiredLevel = CreateConVar(
		"reward_packrat_level",
		"6",
		"Nivel requerido para desbloquear Pack Rat (más capacidad de munición)",
		FCVAR_PLUGIN
	);

	cvar_PackRat_AmmoMultiplier = CreateConVar(
		"reward_packrat_ammo_multiplier",
		"1.25",
		"Multiplicador de capacidad de munición (1.25 = +25% munición)",
		FCVAR_PLUGIN
	);

	// Hook para cuando el jugador recoge munición
	// Nota: Se aplicará automáticamente cuando el jugador use ammo piles
}

/**
 * Resetea el estado al conectar
 */
public void PackRat_OnClientConnect(int client)
{
	g_bPackRat_Enabled[client] = false;
}

/**
 * Limpia recursos al desconectar
 */
public void PackRat_OnClientDisconnect(int client)
{
	g_bPackRat_Enabled[client] = false;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void PackRat_OnPlayerSpawn(int client, int level)
{
	if (PackRat_IsUnlocked(client, level))
	{
		g_bPackRat_Enabled[client] = true;
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void PackRat_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_PackRat_RequiredLevel);

	// Solo mostrar mensaje si justo alcanzó el nivel requerido
	if (level == requiredLevel)
	{
		g_bPackRat_Enabled[client] = true;
		float multiplier = GetConVarFloat(cvar_PackRat_AmmoMultiplier);
		int percentage = RoundToFloor((multiplier - 1.0) * 100.0);
		PrintToChat(client, "\x04[REWARD]\x01 ¡Desbloqueaste \x05Pack Rat\x01! (Puedes llevar \x03+%d%%\x01 más munición)", percentage);
	}
	else if (level > requiredLevel)
	{
		g_bPackRat_Enabled[client] = true;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool PackRat_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_PackRat_RequiredLevel);
}

/**
 * Aplica munición extra cuando el jugador recoge un ammo pile
 * Esta función debe ser llamada desde el evento de item_pickup o cuando se usa ammo pile
 */
public void PackRat_OnAmmoPickup(int client)
{
	if (!g_bPackRat_Enabled[client])
		return;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	PackRat_GiveExtraAmmo(client);
}

/**
 * Otorga munición extra basada en el arma primaria equipada
 */
stock void PackRat_GiveExtraAmmo(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 0); // Slot 0 = Arma primaria

	if (weapon <= 0 || !IsValidEntity(weapon))
		return;

	char classname[32];
	GetEdictClassname(weapon, classname, sizeof(classname));

	int offset = PackRat_GetWeaponAmmoOffset(weapon);
	if (offset <= 0 || offset == 24 || offset == 68)
		return;

	int currentAmmo = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + offset);
	int maxAmmo = PackRat_GetMaxAmmoForWeapon(classname);

	if (maxAmmo > 0 && currentAmmo < maxAmmo)
	{
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + offset, maxAmmo);
		PrintToChat(client, "\x04[Pack Rat]\x01 Almacenando munición extra");
	}
}

/**
 * Obtiene el offset de munición de un arma
 */
stock int PackRat_GetWeaponAmmoOffset(int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

	if (ammotype == -1)
		return 0;

	return ammotype * 4;
}

/**
 * Obtiene la cantidad máxima de munición para un arma con Pack Rat
 */
stock int PackRat_GetMaxAmmoForWeapon(const char[] classname)
{
	float multiplier = GetConVarFloat(cvar_PackRat_AmmoMultiplier);

	// Rifles (M16, SG552)
	if (StrEqual(classname, "weapon_rifle") || StrEqual(classname, "weapon_rifle_sg552"))
		return RoundFloat(360 * multiplier); // Base: 360, con Pack Rat: ~450

	// Desert Rifle
	if (StrEqual(classname, "weapon_rifle_desert"))
		return RoundFloat(360 * multiplier);

	// AK47
	if (StrEqual(classname, "weapon_rifle_ak47"))
		return RoundFloat(360 * multiplier);

	// SMGs (Uzi, Silenced, MP5)
	if (StrEqual(classname, "weapon_smg") || StrEqual(classname, "weapon_smg_silenced") ||
	    StrEqual(classname, "weapon_smg_mp5"))
		return RoundFloat(650 * multiplier); // Base: 650, con Pack Rat: ~812

	// Pump Shotguns
	if (StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome"))
		return RoundFloat(56 * multiplier); // Base: 56, con Pack Rat: ~70

	// Auto Shotguns
	if (StrEqual(classname, "weapon_autoshotgun") || StrEqual(classname, "weapon_shotgun_spas"))
		return RoundFloat(90 * multiplier); // Base: 90, con Pack Rat: ~112

	// Hunting Rifle
	if (StrEqual(classname, "weapon_hunting_rifle"))
		return RoundFloat(150 * multiplier); // Base: 150, con Pack Rat: ~187

	// Scout
	if (StrEqual(classname, "weapon_sniper_scout"))
		return RoundFloat(180 * multiplier); // Base: 180, con Pack Rat: ~225

	// Military Sniper
	if (StrEqual(classname, "weapon_sniper_military"))
		return RoundFloat(180 * multiplier);

	// AWP
	if (StrEqual(classname, "weapon_sniper_awp"))
		return RoundFloat(180 * multiplier);

	return 0; // Arma no reconocida o sin munición extra
}

/**
 * Obtiene si Pack Rat está habilitado para un jugador
 */
public bool PackRat_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bPackRat_Enabled[client];
}
