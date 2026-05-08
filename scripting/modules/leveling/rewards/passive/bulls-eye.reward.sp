#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === BULLSEYE PASSIVE REWARD ===
// Equipa laser sight gratis en armas primarias
// Based on Master_3_46 implementation
//==================================================

// --- ConVars ---
Handle cvar_BullsEye_RequiredLevel = INVALID_HANDLE;

// --- Estado del jugador ---
bool g_bBullsEye_Enabled[MAXPLAYERS + 1];
int g_iBullsEye_UseDelay[MAXPLAYERS + 1];

/**
 * Inicializa el modulo de BullsEye
 */
public void BullsEye_OnPluginStart()
{
	cvar_BullsEye_RequiredLevel = CreateConVar(
		"reward_bullseye_level",
		"26",
		"Nivel requerido para desbloquear BullsEye",
		FCVAR_PLUGIN
	);

	// Hook para evento de usar items
	HookEvent("player_use", Event_BullsEye_PlayerUse, EventHookMode_Post);
}

/**
 * Resetea el estado al conectar
 */
public void BullsEye_OnClientConnect(int client)
{
	g_bBullsEye_Enabled[client] = false;
	g_iBullsEye_UseDelay[client] = 0;
}

/**
 * Limpia recursos al desconectar
 */
public void BullsEye_OnClientDisconnect(int client)
{
	g_bBullsEye_Enabled[client] = false;
	g_iBullsEye_UseDelay[client] = 0;
}

/**
 * Aplica el reward al spawn (silencioso)
 */
public void BullsEye_OnPlayerSpawn(int client, int level)
{
	if (BullsEye_IsUnlocked(client, level))
	{
		g_bBullsEye_Enabled[client] = true;
		g_iBullsEye_UseDelay[client] = 0;

		// Aplicar laser sight en spawn si ya tiene arma primaria
		BullsEye_EquipLaserSight(client, false);
	}
}

/**
 * Aplica el reward al subir de nivel (con mensaje)
 */
public void BullsEye_OnLevelUp(int client, int level)
{
	int requiredLevel = GetConVarInt(cvar_BullsEye_RequiredLevel);

	if (level == requiredLevel)
	{
		g_bBullsEye_Enabled[client] = true;
		g_iBullsEye_UseDelay[client] = 0;
		BullsEye_EquipLaserSight(client, false);
		PrintToChat(client, "\x04[REWARD]\x01 Desbloqueaste \x05BullsEye\x01! (Laser sight gratis en armas primarias)");
	}
	else if (level > requiredLevel)
	{
		g_bBullsEye_Enabled[client] = true;
		g_iBullsEye_UseDelay[client] = 0;
	}
}

/**
 * Verifica si el jugador tiene el reward desbloqueado
 */
public bool BullsEye_IsUnlocked(int client, int level)
{
	return level >= GetConVarInt(cvar_BullsEye_RequiredLevel);
}

/**
 * Evento: Player Use - Equipa laser sight al recoger armas
 */
public Action Event_BullsEye_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (!g_bBullsEye_Enabled[client])
		return Plugin_Continue;

	// Obtener el item usado
	char classname[64];
	GetEventString(event, "item", classname, sizeof(classname));

	// Verificar si es un arma (no melee)
	if (StrContains(classname, "weapon_", false) != -1 && StrContains(classname, "melee", false) == -1)
	{
		BullsEye_EquipLaserSight(client, true);
	}

	return Plugin_Continue;
}

/**
 * Equipa laser sight al arma primaria
 */
stock void BullsEye_EquipLaserSight(int client, bool showMessage)
{
	if (g_iBullsEye_UseDelay[client] != 0)
		return;

	int weapon = GetPlayerWeaponSlot(client, 0); // Slot 0 = Primary weapon
	if (weapon <= 0)
		return;

	int upgradeBit = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

	// UpgradeBit values:
	// 0 = No upgrade
	// 1 = Incendiary ammo
	// 2 = Explosive ammo
	// 4 = Laser sight
	// 5 = Incendiary + Laser
	// 6 = Explosive + Laser

	// Si ya tiene laser sight (4, 5, 6), no hacer nada
	if (upgradeBit == 4 || upgradeBit == 5 || upgradeBit == 6)
		return;

	// Aplicar laser sight
	int newUpgradeBit;
	if (upgradeBit == 1)
		newUpgradeBit = 5; // Incendiary + Laser
	else if (upgradeBit == 2)
		newUpgradeBit = 6; // Explosive + Laser
	else
		newUpgradeBit = 4; // Solo Laser

	SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", newUpgradeBit);

	if (showMessage)
	{
		PrintToChat(client, "\x04[BullsEye]\x01 Laser Sight Equipped");
	}

	g_iBullsEye_UseDelay[client] = 1;
	CreateTimer(1.0, Timer_BullsEye_ResetDelay, GetClientUserId(client));
}

/**
 * Timer: Resetea el delay de uso
 */
public Action Timer_BullsEye_ResetDelay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		g_iBullsEye_UseDelay[client] = 0;
	}
	return Plugin_Stop;
}

/**
 * Obtiene si BullsEye esta habilitado para un jugador
 */
public bool BullsEye_IsEnabled(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return g_bBullsEye_Enabled[client];
}
