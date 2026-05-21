#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#define _RESPAWN_SYSTEM_MODULE_

//==================================================
// === RESPAWN SYSTEM MODULE ===
// Al morir un survivor, muestra un countdown de N segundos
// y lo respawnea cerca del grupo al finalizar.
//==================================================

#define RESPAWN_HINT_INTERVAL  5.0   // Actualiza el hint cada 5s
#define RESPAWN_TELEPORT_DELAY 0.2   // Delay tras L4D_RespawnPlayer antes de teleportar

ConVar g_hRespawnDelay;

Handle g_hRespawnTimer[MAXPLAYERS + 1];
int    g_iRespawnCountdown[MAXPLAYERS + 1];
bool   g_bAwaitingRespawn[MAXPLAYERS + 1];

/**
 * Inicializa el módulo
 */
public void RespawnSystem_OnPluginStart()
{
	g_hRespawnDelay = CreateConVar(
		"respawn_delay",
		"60",
		"Segundos de espera antes de respawnear a un survivor muerto (0 = desactivado)",
		FCVAR_PLUGIN
	);

	HookEvent("player_death",       RespawnSystem_OnPlayerDeath, EventHookMode_Post);
	HookEvent("round_end",          RespawnSystem_OnRoundEnd,    EventHookMode_PostNoCopy);
	HookEvent("player_spawn",       RespawnSystem_OnPlayerSpawn, EventHookMode_Post);
}

/**
 * Limpia todos los timers al cambiar de mapa
 */
public void RespawnSystem_OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		RespawnSystem_CancelTimer(i);
}

/**
 * Limpia el timer al desconectar
 */
public void RespawnSystem_OnClientDisconnect(int client)
{
	RespawnSystem_CancelTimer(client);
}

/**
 * Si el jugador spawnea (desfibrilador, etc.) antes del timer, cancela el countdown
 */
public Action RespawnSystem_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && g_bAwaitingRespawn[client])
		RespawnSystem_CancelTimer(client);

	return Plugin_Continue;
}

/**
 * Cancela todos los timers activos al finalizar la ronda
 */
public Action RespawnSystem_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		RespawnSystem_CancelTimer(i);

	return Plugin_Continue;
}

/**
 * Evento: player_death
 * Solo actúa sobre survivors humanos muertos
 */
public Action RespawnSystem_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != 2)
		return Plugin_Continue;

	int delay = g_hRespawnDelay.IntValue;
	if (delay <= 0)
		return Plugin_Continue;

	// Cancelar timer previo si existía
	RespawnSystem_CancelTimer(client);

	g_iRespawnCountdown[client] = delay;
	g_bAwaitingRespawn[client]  = true;

	// Mostrar primer hint inmediatamente
	RespawnSystem_ShowHint(client);

	// Timer repeat: actualiza el hint cada RESPAWN_HINT_INTERVAL segundos
	g_hRespawnTimer[client] = CreateTimer(
		RESPAWN_HINT_INTERVAL,
		Timer_RespawnCountdown,
		GetClientUserId(client),
		TIMER_REPEAT
	);

	return Plugin_Continue;
}

/**
 * Timer: decrementa el countdown y actualiza el hint.
 * Al llegar a 0, ejecuta el respawn.
 */
public Action Timer_RespawnCountdown(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		RespawnSystem_CancelTimerByUserId(userid);
		return Plugin_Stop;
	}

	// Si el jugador ya está vivo (lo revivieron con defib), cancelar
	if (IsPlayerAlive(client))
	{
		RespawnSystem_CancelTimer(client);
		return Plugin_Stop;
	}

	g_iRespawnCountdown[client] -= RoundToNearest(RESPAWN_HINT_INTERVAL);

	if (g_iRespawnCountdown[client] <= 0)
	{
		// Tiempo cumplido — respawnear
		g_hRespawnTimer[client]    = INVALID_HANDLE;
		g_bAwaitingRespawn[client] = false;
		RespawnSystem_Execute(client);
		return Plugin_Stop;
	}

	// Actualizar hint con tiempo restante
	RespawnSystem_ShowHint(client);
	return Plugin_Continue;
}

/**
 * Muestra el hint de countdown al jugador muerto
 */
void RespawnSystem_ShowHint(int client)
{
	if (!IsClientInGame(client) || IsPlayerAlive(client))
		return;

	// Obtener la frase traducida (contiene %d como placeholder del número)
	// y aplicar el número directamente a través de PrintHintText.
	char fmt[256];
	Format(fmt, sizeof(fmt), "%T", "Respawn_Hint", client);
	PrintHintText(client, fmt, g_iRespawnCountdown[client]);
}

/**
 * Ejecuta el respawn y teleporta al jugador cerca del grupo
 */
void RespawnSystem_Execute(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	// Notificar al jugador
	char msg[256];
	Format(msg, sizeof(msg), "%T", "Respawn_Spawning", client);
	PrintHintText(client, "%s", msg);

	// Respawnear via left4dhooks
	L4D_RespawnPlayer(client);

	// Teleportar cerca del grupo después de un tick
	CreateTimer(RESPAWN_TELEPORT_DELAY, Timer_TeleportToGroup, GetClientUserId(client));
}

/**
 * Timer: teleporta al jugador recién spawneado al centroide del grupo
 */
public Action Timer_TeleportToGroup(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	// Buscar todos los survivors vivos (excluyendo al recién spawneado)
	float groupOrigin[3];
	int   aliveCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i))
			continue;
		if (GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		float pos[3];
		GetClientAbsOrigin(i, pos);
		groupOrigin[0] += pos[0];
		groupOrigin[1] += pos[1];
		groupOrigin[2] += pos[2];
		aliveCount++;
	}

	if (aliveCount == 0)
	{
		// No hay teammates vivos — el spawn por defecto de L4D_RespawnPlayer es suficiente
		return Plugin_Stop;
	}

	// Calcular centroide del grupo
	groupOrigin[0] /= float(aliveCount);
	groupOrigin[1] /= float(aliveCount);
	groupOrigin[2] /= float(aliveCount);

	// Offset aleatorio pequeño para no aparecer encima de alguien
	groupOrigin[0] += GetRandomFloat(-60.0, 60.0);
	groupOrigin[1] += GetRandomFloat(-60.0, 60.0);

	TeleportEntity(client, groupOrigin, NULL_VECTOR, NULL_VECTOR);

	// Notificar al resto
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || i == client)
			continue;

		char action[200];
		Format(action, sizeof(action), "%T", "Respawn_Notification", i);
		PrintToChat(i, "\x04[Eclipse]\x01 \x05%s\x01 %s", playerName, action);
	}

	return Plugin_Stop;
}

/**
 * Cancela el timer de respawn de un cliente
 */
void RespawnSystem_CancelTimer(int client)
{
	if (g_hRespawnTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hRespawnTimer[client]);
		g_hRespawnTimer[client] = INVALID_HANDLE;
	}
	g_bAwaitingRespawn[client]  = false;
	g_iRespawnCountdown[client] = 0;
}

void RespawnSystem_CancelTimerByUserId(int userid)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hRespawnTimer[i] != INVALID_HANDLE
			&& IsClientInGame(i)
			&& GetClientUserId(i) == userid)
		{
			RespawnSystem_CancelTimer(i);
			return;
		}
	}
}
