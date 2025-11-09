//==================================================
// === RAPID FIRE ABILITY (Level 23) ===
// Increases M16 firing rate and auto-resupply ammo
// Duration: 60 seconds
// Cooldown: 5 minutes
// Requirements: Must have M16 Assault Rifle
//==================================================

#define RAPID_FIRE_MULTIPLIER 0.3  // Delay entre disparos reducido a 30%

Handle g_hRapidFire_AmmoTimer[MAXPLAYERS + 1];
int g_iRapidFire_WeaponRef[MAXPLAYERS + 1];

/**
 * Activa Rapid Fire
 */
bool Ability_RapidFire_Activate(int client)
{
	// Verificar que tenga M16
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == -1)
	{
		PrintToChat(client, "\x04[Rapid Fire]\x01 Necesitas un M16 Assault Rifle.");
		return false;
	}

	char weaponName[64];
	GetEdictClassname(weapon, weaponName, sizeof(weaponName));
	if (StrContains(weaponName, "rifle") == -1 && StrContains(weaponName, "m16") == -1)
	{
		PrintToChat(client, "\x04[Rapid Fire]\x01 Necesitas un M16 Assault Rifle.");
		return false;
	}

	// Guardar referencia del arma
	g_iRapidFire_WeaponRef[client] = EntIndexToEntRef(weapon);

	// Modificar rate of fire
	RapidFire_ModifyWeapon(client, weapon);

	// Iniciar timer de auto-resupply
	g_hRapidFire_AmmoTimer[client] = CreateTimer(0.1, Timer_RapidFire_Ammo, GetClientUserId(client), TIMER_REPEAT);

	// Efecto visual amarillo brillante
	int clients[1];
	clients[0] = client;
	int color[4] = {255, 255, 0, 80};
	int duration = 60000;
	int flags = 0x0001;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, 500);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Rapid Fire]\x01 ¡M16 a máxima cadencia! Munición auto-resupply.");
	return true;
}

/**
 * Desactiva Rapid Fire
 */
void Ability_RapidFire_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Detener timer de ammo
	if (g_hRapidFire_AmmoTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hRapidFire_AmmoTimer[client]);
		g_hRapidFire_AmmoTimer[client] = INVALID_HANDLE;
	}

	// Restaurar arma original
	int weapon = EntRefToEntIndex(g_iRapidFire_WeaponRef[client]);
	if (weapon != INVALID_ENT_REFERENCE)
	{
		RapidFire_RestoreWeapon(weapon);
	}

	g_iRapidFire_WeaponRef[client] = 0;

	// Limpiar efecto visual
	int clients[1];
	clients[0] = client;
	int color[4] = {0, 0, 0, 0};

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, 500);
		BfWriteShort(message, 500);
		BfWriteShort(message, 0x0002);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}
}

/**
 * Modifica el arma para Rapid Fire
 */
void RapidFire_ModifyWeapon(int client, int weapon)
{
	// Modificar el delay entre disparos (m_flNextPrimaryAttack)
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 3.0);  // Velocidad de animación 3x

	// Dar munición completa
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammoType != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", 999, _, ammoType);
	}

	// Clip completo
	SetEntProp(weapon, Prop_Send, "m_iClip1", 50);
}

/**
 * Restaura el arma a valores normales
 */
void RapidFire_RestoreWeapon(int weapon)
{
	if (!IsValidEntity(weapon))
		return;

	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 1.0);
}

/**
 * Timer: Auto-resupply de munición
 */
public Action Timer_RapidFire_Ammo(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (!Abilities_IsActive(client, Ability_RapidFire))
		return Plugin_Stop;

	int weapon = EntRefToEntIndex(g_iRapidFire_WeaponRef[client]);
	if (weapon == INVALID_ENT_REFERENCE)
		return Plugin_Stop;

	// Mantener clip lleno
	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	if (clip < 50)
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", 50);
	}

	// Mantener ammo de reserva lleno
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammoType != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", 999, _, ammoType);
	}

	// Acelerar la siguiente acción
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + (0.1 * RAPID_FIRE_MULTIPLIER));

	return Plugin_Continue;
}
