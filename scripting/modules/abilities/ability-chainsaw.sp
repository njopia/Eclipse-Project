//==================================================
// === CHAINSAW MASSACRE ABILITY (Level 25) ===
// Infinite ammo chainsaw with bonus XP per kill
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

#define CHAINSAW_BONUS_XP 10  // XP extra por cada kill con chainsaw

int g_iChainsaw_Kills[MAXPLAYERS + 1];
int g_iChainsaw_WeaponRef[MAXPLAYERS + 1];

/**
 * Activa Chainsaw Massacre
 */
bool Ability_ChainsawMassacre_Activate(int client)
{
	// Dar chainsaw
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give chainsaw");
	SetCommandFlags("give", flags);

	// Esperar un tick para obtener la referencia del arma
	CreateTimer(0.1, Timer_GetChainsawRef, GetClientUserId(client));

	// Reset de kills
	g_iChainsaw_Kills[client] = 0;

	// Efecto visual rojo sangre
	int clients[1];
	clients[0] = client;
	int color[4] = {200, 0, 0, 100};
	int duration = 60000;
	int flags_fade = 0x0001;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, 500);
		BfWriteShort(message, flags_fade);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}

	PrintToChat(client, "\x04[Chainsaw Massacre]\x01 Motosierra infinita! +%d XP por kill.", CHAINSAW_BONUS_XP);
	return true;
}

/**
 * Desactiva Chainsaw Massacre
 */
void Ability_ChainsawMassacre_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Mostrar estadísticas
	if (g_iChainsaw_Kills[client] > 0)
	{
		int totalXP = g_iChainsaw_Kills[client] * CHAINSAW_BONUS_XP;
		PrintToChat(client, "\x04[Chainsaw Massacre]\x01 Kills: \x03%d\x01 | XP Bonus: \x03+%d",
			g_iChainsaw_Kills[client], totalXP);
	}

	// Remover chainsaw
	int weapon = EntRefToEntIndex(g_iChainsaw_WeaponRef[client]);
	if (weapon != INVALID_ENT_REFERENCE && IsValidEntity(weapon))
	{
		char weaponName[64];
		GetEdictClassname(weapon, weaponName, sizeof(weaponName));
		if (StrContains(weaponName, "chainsaw") != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEntity(weapon);
		}
	}

	g_iChainsaw_WeaponRef[client] = 0;
	g_iChainsaw_Kills[client] = 0;

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
 * Timer: Obtener referencia del chainsaw
 */
public Action Timer_GetChainsawRef(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Stop;

	// Buscar chainsaw en el slot 1
	int weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon != -1)
	{
		char weaponName[64];
		GetEdictClassname(weapon, weaponName, sizeof(weaponName));
		if (StrContains(weaponName, "chainsaw") != -1)
		{
			g_iChainsaw_WeaponRef[client] = EntIndexToEntRef(weapon);

			// Hacer que el chainsaw tenga munición infinita
			CreateTimer(0.1, Timer_InfiniteChainsaw, GetClientUserId(client), TIMER_REPEAT);
		}
	}

	return Plugin_Stop;
}

/**
 * Timer: Mantener chainsaw con munición infinita
 */
public Action Timer_InfiniteChainsaw(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (!Abilities_IsActive(client, Ability_ChainsawMassacre))
		return Plugin_Stop;

	int weapon = EntRefToEntIndex(g_iChainsaw_WeaponRef[client]);
	if (weapon == INVALID_ENT_REFERENCE)
		return Plugin_Stop;

	// Mantener fuel infinito
	SetEntProp(weapon, Prop_Send, "m_iClip1", 30);

	return Plugin_Continue;
}

/**
 * Hook cuando mata un infectado con chainsaw
 */
public void ChainsawMassacre_OnInfectedKilled(int attacker, int victim, const char[] weapon)
{
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return;

	if (!Abilities_IsActive(attacker, Ability_ChainsawMassacre))
		return;

	// Verificar que sea con chainsaw
	if (StrContains(weapon, "chainsaw") == -1)
		return;

	// Incrementar contador
	g_iChainsaw_Kills[attacker]++;

	// Otorgar XP bonus
	Leveling_AwardXP(attacker, CHAINSAW_BONUS_XP, "Chainsaw Kill");

	// Feedback
	if (g_iChainsaw_Kills[attacker] % 5 == 0)  // Cada 5 kills
	{
		PrintHintText(attacker, "Chainsaw Kills: %d (+%d XP)", g_iChainsaw_Kills[attacker], g_iChainsaw_Kills[attacker] * CHAINSAW_BONUS_XP);
	}

	// Efecto visual en cada kill
	float victimPos[3];
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim))
	{
		GetClientAbsOrigin(victim, victimPos);
	}
	else if (IsValidEntity(victim))
	{
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
	}
	else
	{
		return;
	}

	TE_SetupBeamRingPoint(victimPos, 10.0, 150.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.3, 8.0, 0.0, {200, 0, 0, 255}, 10, 0);
	TE_SendToAll();
}
