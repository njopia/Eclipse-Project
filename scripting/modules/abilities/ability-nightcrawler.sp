//==================================================
// === NIGHTCRAWLER ABILITY (Level 18) ===
// Teleportation between survivors
// Press WALK key to cycle between targets
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

int g_iNightcrawler_CurrentTarget[MAXPLAYERS + 1];
int g_iNightcrawler_SurvivorList[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iNightcrawler_SurvivorCount[MAXPLAYERS + 1];

/**
 * Activa Nightcrawler
 */
bool Ability_Nightcrawler_Activate(int client)
{
	// Construir lista de survivors disponibles
	Nightcrawler_BuildSurvivorList(client);

	if (g_iNightcrawler_SurvivorCount[client] == 0)
	{
		PrintToChat(client, "\x04[Nightcrawler]\x01 No hay otros survivors disponibles para teletransporte.");
		return false;
	}

	g_iNightcrawler_CurrentTarget[client] = 0;

	// Efecto visual púrpura
	int clients[1];
	clients[0] = client;
	int color[4] = {128, 0, 255, 100};
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

	// Mostrar target actual
	Nightcrawler_ShowCurrentTarget(client);

	PrintToChat(client, "\x04[Nightcrawler]\x01 ¡Teletransporte activado! Usa WALK (Shift) para cambiar destino, USE (E) para teletransportarte.");
	return true;
}

/**
 * Desactiva Nightcrawler
 */
void Ability_Nightcrawler_Deactivate(int client)
{
	if (!IsClientInGame(client))
		return;

	g_iNightcrawler_CurrentTarget[client] = 0;
	g_iNightcrawler_SurvivorCount[client] = 0;

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
 * Construye lista de survivors disponibles
 */
void Nightcrawler_BuildSurvivorList(int client)
{
	g_iNightcrawler_SurvivorCount[client] = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			g_iNightcrawler_SurvivorList[client][g_iNightcrawler_SurvivorCount[client]] = i;
			g_iNightcrawler_SurvivorCount[client]++;
		}
	}
}

/**
 * Muestra el target actual
 */
void Nightcrawler_ShowCurrentTarget(int client)
{
	if (g_iNightcrawler_SurvivorCount[client] == 0)
		return;

	int target = g_iNightcrawler_SurvivorList[client][g_iNightcrawler_CurrentTarget[client]];
	if (target > 0 && IsClientInGame(target))
	{
		char targetName[MAX_NAME_LENGTH];
		GetClientName(target, targetName, sizeof(targetName));
		PrintHintText(client, "Destino: %s [%d/%d]", targetName, g_iNightcrawler_CurrentTarget[client] + 1, g_iNightcrawler_SurvivorCount[client]);
	}
}

/**
 * Cambia al siguiente target
 */
void Nightcrawler_CycleTarget(int client)
{
	if (!Abilities_IsActive(client, Ability_Nightcrawler))
		return;

	if (g_iNightcrawler_SurvivorCount[client] == 0)
		return;

	g_iNightcrawler_CurrentTarget[client]++;
	if (g_iNightcrawler_CurrentTarget[client] >= g_iNightcrawler_SurvivorCount[client])
	{
		g_iNightcrawler_CurrentTarget[client] = 0;
	}

	Nightcrawler_ShowCurrentTarget(client);

	// Efecto de sonido
	EmitSoundToClient(client, "buttons/blip1.wav");
}

/**
 * Ejecuta el teletransporte
 */
void Nightcrawler_Teleport(int client)
{
	if (!Abilities_IsActive(client, Ability_Nightcrawler))
		return;

	if (g_iNightcrawler_SurvivorCount[client] == 0)
		return;

	int target = g_iNightcrawler_SurvivorList[client][g_iNightcrawler_CurrentTarget[client]];
	if (target <= 0 || !IsClientInGame(target) || !IsPlayerAlive(target))
	{
		// Reconstruir lista si el target murió
		Nightcrawler_BuildSurvivorList(client);
		return;
	}

	// Obtener posición del target
	float targetPos[3], targetAng[3];
	GetClientAbsOrigin(target, targetPos);
	GetClientAbsAngles(target, targetAng);

	// Offset para no spawnear encima
	targetPos[0] += 50.0;
	targetPos[1] += 50.0;

	// Efecto visual antes de teleport
	TE_SetupBeamRingPoint(targetPos, 10.0, 300.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.5, 10.0, 0.0, {128, 0, 255, 255}, 10, 0);
	TE_SendToAll();

	// Teletransportar
	TeleportEntity(client, targetPos, targetAng, NULL_VECTOR);

	// Efecto visual después de teleport
	TE_SetupBeamRingPoint(targetPos, 10.0, 300.0, PrecacheModel("materials/sprites/laserbeam.vmt"), PrecacheModel("materials/sprites/halo01.vmt"), 0, 15, 0.5, 10.0, 0.0, {128, 0, 255, 255}, 10, 0);
	TE_SendToAll();

	// Efecto de sonido
	EmitSoundToAll("ambient/atmosphere/terrain_rumble1.wav", client);

	char targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));
	PrintToChat(client, "\x04[Nightcrawler]\x01 Teletransportado a \x03%s\x01!", targetName);
}

/**
 * Hook de teclas para Nightcrawler
 */
public Action Nightcrawler_OnPlayerRunCmd(int client, int &buttons)
{
	if (!Abilities_IsActive(client, Ability_Nightcrawler))
		return Plugin_Continue;

	static int lastButtons[MAXPLAYERS + 1];

	// WALK key para cambiar target
	if ((buttons & IN_SPEED) && !(lastButtons[client] & IN_SPEED))
	{
		Nightcrawler_CycleTarget(client);
	}

	// USE key para teletransportarse
	if ((buttons & IN_USE) && !(lastButtons[client] & IN_USE))
	{
		Nightcrawler_Teleport(client);
	}

	lastButtons[client] = buttons;
	return Plugin_Continue;
}
