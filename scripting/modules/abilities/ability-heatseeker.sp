//==================================================
// === HEAT SEEKER ABILITY (Level 27) ===
// Heat seeking grenade launcher shells + infinite ammo
// Press WALK to cycle target priorities
// Duration: 60 seconds
// Cooldown: 5 minutes
// Requirements: Must have Grenade Launcher
//==================================================

#define HEATSEEKER_SEARCH_RADIUS 2000.0

enum HeatSeekerTarget
{
	Target_SpecialInfected,
	Target_Tank,
	Target_Nearest
}

HeatSeekerTarget g_iHeatSeeker_Priority[MAXPLAYERS + 1];
Handle g_hHeatSeeker_AmmoTimer[MAXPLAYERS + 1];
int g_iHeatSeeker_WeaponRef[MAXPLAYERS + 1];

/**
 * Activa Heat Seeker
 */
bool Ability_HeatSeeker_Activate(int client)
{
	// Verificar que tenga Grenade Launcher
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == -1)
	{
		PrintToChat(client, "\x04[Heat Seeker]\x01 Necesitas un Grenade Launcher.");
		return false;
	}

	char weaponName[64];
	GetEdictClassname(weapon, weaponName, sizeof(weaponName));
	if (StrContains(weaponName, "grenade_launcher") == -1)
	{
		PrintToChat(client, "\x04[Heat Seeker]\x01 Necesitas un Grenade Launcher.");
		return false;
	}

	// Inicializar prioridad
	g_iHeatSeeker_Priority[client] = Target_SpecialInfected;
	g_iHeatSeeker_WeaponRef[client] = EntIndexToEntRef(weapon);

	// Iniciar timer de ammo infinita
	g_hHeatSeeker_AmmoTimer[client] = CreateTimer(0.1, Timer_HeatSeeker_Ammo, GetClientUserId(client), TIMER_REPEAT);

	// Efecto visual rojo brillante
	int clients[1];
	clients[0] = client;
	int color[4] = {255, 50, 50, 90};
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

	HeatSeeker_ShowPriority(client);

	PrintToChat(client, "\x04[Heat Seeker]\x01 Granadas teledirigidas! Usa WALK para cambiar prioridad.");
	return true;
}

/**
 * Desactiva Heat Seeker
 */
void Ability_HeatSeeker_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	// Detener timer
	if (g_hHeatSeeker_AmmoTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hHeatSeeker_AmmoTimer[client]);
		g_hHeatSeeker_AmmoTimer[client] = INVALID_HANDLE;
	}

	g_iHeatSeeker_WeaponRef[client] = 0;

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
 * Timer: Municion infinita
 */
public Action Timer_HeatSeeker_Ammo(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if (!Abilities_IsActive(client, Ability_HeatSeeker))
		return Plugin_Stop;

	int weapon = EntRefToEntIndex(g_iHeatSeeker_WeaponRef[client]);
	if (weapon == INVALID_ENT_REFERENCE)
		return Plugin_Stop;

	// Municion infinita
	SetEntProp(weapon, Prop_Send, "m_iClip1", 1);

	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammoType != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", 99, _, ammoType);
	}

	return Plugin_Continue;
}

/**
 * Cambia prioridad de target
 */
void HeatSeeker_CyclePriority(int client)
{
	if (!Abilities_IsActive(client, Ability_HeatSeeker))
		return;

	switch (g_iHeatSeeker_Priority[client])
	{
		case Target_SpecialInfected:
			g_iHeatSeeker_Priority[client] = Target_Tank;
		case Target_Tank:
			g_iHeatSeeker_Priority[client] = Target_Nearest;
		case Target_Nearest:
			g_iHeatSeeker_Priority[client] = Target_SpecialInfected;
	}

	HeatSeeker_ShowPriority(client);
	EmitSoundToClient(client, "buttons/blip1.wav");
}

/**
 * Muestra la prioridad actual
 */
void HeatSeeker_ShowPriority(int client)
{
	char priority[32];
	switch (g_iHeatSeeker_Priority[client])
	{
		case Target_SpecialInfected: strcopy(priority, sizeof(priority), "Infectados Especiales");
		case Target_Tank: strcopy(priority, sizeof(priority), "Tanks");
		case Target_Nearest: strcopy(priority, sizeof(priority), "Mas Cercano");
	}

	PrintHintText(client, "Prioridad: %s", priority);
}

/**
 * Busca el mejor target segun la prioridad
 */
int HeatSeeker_FindTarget(int client)
{
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);

	int bestTarget = -1;
	float bestDistance = HEATSEEKER_SEARCH_RADIUS;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");

			// Filtrar segun prioridad
			bool isValid = false;
			switch (g_iHeatSeeker_Priority[client])
			{
				case Target_SpecialInfected:
					isValid = (zombieClass >= 1 && zombieClass <= 6);  // Solo especiales, no tank
				case Target_Tank:
					isValid = (zombieClass == 8);  // Solo tank
				case Target_Nearest:
					isValid = (zombieClass >= 1 && zombieClass <= 8);  // Cualquiera
			}

			if (isValid)
			{
				float targetPos[3];
				GetClientAbsOrigin(i, targetPos);

				float distance = GetVectorDistance(clientPos, targetPos);
				if (distance < bestDistance)
				{
					bestDistance = distance;
					bestTarget = i;
				}
			}
		}
	}

	return bestTarget;
}

/**
 * Hook de teclas para Heat Seeker
 */
public Action HeatSeeker_OnPlayerRunCmd(int client, int &buttons)
{
	if (!Abilities_IsActive(client, Ability_HeatSeeker))
		return Plugin_Continue;

	static int lastButtons[MAXPLAYERS + 1];

	// WALK key para cambiar prioridad
	if ((buttons & IN_SPEED) && !(lastButtons[client] & IN_SPEED))
	{
		HeatSeeker_CyclePriority(client);
	}

	lastButtons[client] = buttons;
	return Plugin_Continue;
}

/**
 * Hook cuando se dispara una granada
 * Modifica la trayectoria para que vaya al target
 */
public void HeatSeeker_OnProjectile(int entity, int client)
{
	if (!Abilities_IsActive(client, Ability_HeatSeeker))
		return;

	int target = HeatSeeker_FindTarget(client);
	if (target == -1)
		return;

	// Obtener posiciones
	float projectilePos[3], targetPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", projectilePos);
	GetClientAbsOrigin(target, targetPos);

	// Calcular vector direccion
	float direction[3];
	SubtractVectors(targetPos, projectilePos, direction);
	NormalizeVector(direction, direction);

	// Escalar por velocidad
	ScaleVector(direction, 1000.0);  // Velocidad de la granada

	// Aplicar velocidad
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, direction);
}
