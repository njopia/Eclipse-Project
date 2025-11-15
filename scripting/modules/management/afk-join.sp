#include <sourcemod>
#include <sdktools>

#tryinclude < left4dhooks>

Handle PanelTimer[MAXPLAYERS + 1];
Handle HintTimer[MAXPLAYERS + 1];

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2

ConVar g_hCvarSurvivorLimit;

public void Afk_Join_OnPluginStart()
{
	RegConsoleCmd("sm_afk", CmdAfk);
	RegConsoleCmd("sm_join", CmdJoin);

	g_hCvarSurvivorLimit = FindConVar("sv_maxplayers");
	if (!g_hCvarSurvivorLimit)
	{
		// En algunos servers no existe; usa 4 por defecto
		g_hCvarSurvivorLimit = CreateConVar("survivor_limit", "16", "Limite de sobrevivientes (fallback).", FCVAR_DONTRECORD);
	}
}

/* ===================== Comandos ===================== */
public Action CmdAfk(int client, int args)
{
	if (!IsPlayer(client)) return Plugin_Handled;

	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		char message[128];
		Format(message, sizeof(message), "%T", "AFK_AlreadySpectator", client);
		PrintToChat(client, "\x04[AFK]\x01 %s", message);
		return Plugin_Handled;
	}

	ToSpectator(client, true);
	PanelTimer[client] = CreateTimer(2.0, Timer_ShowPanel, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action CmdJoin(int client, int args)
{
	if (!IsPlayer(client)) return Plugin_Handled;
	if (GetClientTeam(client) == TEAM_SURVIVOR) return Plugin_Handled;
	// Muestra un panel con info y opciones rápidas
	afkShowMainMenu(client);
	return Plugin_Handled;
}

public Action Timer_ShowPanel(Handle timer, int client)
{
	// Create a global variable visible only in the local scope (this function).
	static int numPrinted = 0;

	if (numPrinted >= 5)
	{
		numPrinted = 0;
		return Plugin_Stop;
	}

	afkShowMainMenu(client);

	return Plugin_Continue;
}

/* ===================== Lógica ===================== */

void afkShowMainMenu(int client)
{
	// Detener hint mientras el menú está abierto
	StopHintTimer(client);

	int survTotal, survHumans, specs;
	CountTeams(survTotal, survHumans, specs);

	int maxSurv	  = GetMaxPlayers();
	int slotsDisp = maxSurv - survHumans;
	if (slotsDisp < 0) slotsDisp = 0;

	char  line[128];

	Panel p = new Panel();

	Format(line, sizeof(line), "Sobrevivientes: %d/%d  Espectadores: %d", survHumans, maxSurv, specs);
	p.SetTitle(line);

	Format(line, sizeof(line), "Slots disponibles: %d", slotsDisp);
	p.DrawText(line);
	p.DrawText("escribe !menu para abrir el menu del servidor");
	p.DrawText("escribe !servers para ver los demas servers disponibles");
	p.DrawText("Cuando aparezca un slot, ir al equipo:");

	p.CurrentKey = 1;
	p.DrawItem("Espectadores");
	p.CurrentKey = 2;
	p.DrawItem("Sobrevivientes");
	p.CurrentKey = 3;
	p.DrawItem("Cerrar");

	p.Send(client, PanelHandler, 15);
	delete p;
}

public int PanelHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action != MenuAction_Select || !IsPlayer(client)) return 0;

	switch (item)
	{
		case 1:	   // Espectadores
		{
			ToSpectator(client, false);
			// Iniciar hint permanente
			StartHintTimer(client);
		}
		case 2:	   // Sobrevivientes
		{
			// Detener hint si está activo
			StopHintTimer(client);
			TryJoinSurvivors(client);
		}
		case 3:	   // Cerrar
		{
			delete PanelTimer[client];
			// Iniciar hint permanente cuando cierra el panel
			StartHintTimer(client);
		}
	}
	return 0;
}

void ToSpectator(int client, bool verbose)
{
	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		if (verbose)
		{
			char message[128];
			Format(message, sizeof(message), "%T", "AFK_AlreadySpectator", client);
			PrintToChat(client, "\x04[AFK]\x01 %s", message);
		}
		return;
	}

	// Cambiar a espectador (matar si es necesario)
	ChangeClientTeam(client, TEAM_SPECTATOR);
	// En algunos casos ayuda emitir el comando del juego
	FakeClientCommand(client, "jointeam 1");
	afkShowMainMenu(client);

	char message[128];
	Format(message, sizeof(message), "%T", "AFK_MovedToSpectator", LANG_SERVER, client);
	PrintToChatAll("\x04[AFK]\x01 %s", message);
}

void TryJoinSurvivors(int client)
{
	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		char message[128];
		Format(message, sizeof(message), "%T", "Join_AlreadySurvivor", client);
		PrintToChat(client, "\x04[JOIN]\x01 %s", message);
		return;
	}

	int maxSurv = GetMaxSurvivors();
	int survTotal, survHumans, specs;
	CountTeams(survTotal, survHumans, specs);

	if (survHumans >= maxSurv)
	{
		char message[256];
		Format(message, sizeof(message), "%T", "Join_SurvivorsFull", client, survHumans, maxSurv);
		PrintToChat(client, "\x04[JOIN]\x01 %s", message);
		return;
	}

	LogMessage("[JOIN DEBUG] Client %d (team: %d) attempting to join survivors", client, GetClientTeam(client));

	// MÉTODO 1: Buscar un bot de sobreviviente y tomar su control
	int bot = FindSurvivorBot();
	LogMessage("[JOIN DEBUG] Survivor bot found: %d", bot);

	if (bot > 0)
	{
		LogMessage("[JOIN DEBUG] Using L4D_SetHumanSpec method");
		L4D_SetHumanSpec(bot, client);
		L4D_TakeOverBot(client);
	}
	else
	{
		// MÉTODO 3: No hay bot, intentar unión directa (puede fallar si servidor está configurado así)
		LogMessage("[JOIN DEBUG] No bot available. Attempting direct team join.");
		ChangeClientTeam(client, TEAM_SURVIVOR);
	}

	delete PanelTimer[client];
	// Verifica el resultado después de dar tiempo al proceso
	CreateTimer(0.7, PostJoinCheck, GetClientUserId(client));
}

// Timer para verificación final después del frame
public Action Timer_FinalCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsPlayer(client))
		return Plugin_Stop;

	// Si todavía no es sobreviviente, forzar con comando de consola
	if (GetClientTeam(client) != TEAM_SURVIVOR)
	{
		LogMessage("[JOIN DEBUG] Client %d still not survivor after frame. Forcing with console command.", client);
		ClientCommand(client, "jointeam 2");
	}

	return Plugin_Stop;
}

public Action PostJoinCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsPlayer(client))
		return Plugin_Stop;

	int currentTeam = GetClientTeam(client);
	LogMessage("[JOIN DEBUG] PostJoinCheck - Client %d is now in team %d (expected %d)", client, currentTeam, TEAM_SURVIVOR);

	if (currentTeam == TEAM_SURVIVOR)
	{
		// ÉXITO: El jugador logró unirse a sobrevivientes
		char message[128];
		Format(message, sizeof(message), "%T", "Join_JoinedSurvivors", LANG_SERVER, client);
		PrintToChatAll("\x04[JOIN]\x01 %s", message);
		delete PanelTimer[client];
		StopHintTimer(client);  // Detener hint al unirse exitosamente
	}
	else
	{
		// FALLO: Aún está en espectadores - último intento
		LogMessage("[JOIN DEBUG] FAILED - Client %d could not join survivors (still in team %d)", client, currentTeam);

		int bot = FindSurvivorBot();
		if (bot > 0)
		{
			LogMessage("[JOIN DEBUG] Last attempt: Found bot %d, killing it to free slot", bot);

			// Matar al bot para liberar el slot
			ForcePlayerSuicide(bot);

			// Forzar cambio de equipo
			ChangeClientTeam(client, TEAM_SURVIVOR);

			// Último intento con comando de consola
			ClientCommand(client, "jointeam 2");

			// Verificación final después de 0.5s
			CreateTimer(0.5, Timer_FinalVerification, userid);
		}
		else
		{
			// No hay bots disponibles
			char message[256];
			Format(message, sizeof(message), "%T", "Join_Failed", client);
			PrintToChat(client, "\x04[JOIN]\x01 %s", message);
			PrintToChat(client, "\x03[DEBUG]\x01 Team: %d | Expected: %d | No survivor bots available", currentTeam, TEAM_SURVIVOR);
			delete PanelTimer[client];
		}
	}
	return Plugin_Stop;
}

// Verificación final después de todos los intentos
public Action Timer_FinalVerification(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsPlayer(client))
		return Plugin_Stop;

	int currentTeam = GetClientTeam(client);

	if (currentTeam == TEAM_SURVIVOR)
	{
		char message[128];
		Format(message, sizeof(message), "%T", "Join_JoinedSurvivors", LANG_SERVER, client);
		PrintToChatAll("\x04[JOIN]\x01 %s", message);
		LogMessage("[JOIN DEBUG] SUCCESS (final) - Client %d joined survivors", client);
		StopHintTimer(client);  // Detener hint al unirse exitosamente
	}
	else
	{
		char message[256];
		Format(message, sizeof(message), "%T", "Join_Failed", client);
		PrintToChat(client, "\x04[JOIN]\x01 %s", message);
		LogMessage("[JOIN DEBUG] ULTIMATE FAILURE - Client %d could not join (team: %d)", client, currentTeam);
		// Si falla definitivamente, reiniciar el hint para que sepa que puede reintentar
		StartHintTimer(client);
	}

	delete PanelTimer[client];
	return Plugin_Stop;
}

/* ===================== Utilidades ===================== */

bool IsPlayer(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

int GetMaxSurvivors()
{
	if (!g_hCvarSurvivorLimit) return 4;
	return g_hCvarSurvivorLimit.IntValue > 0 ? g_hCvarSurvivorLimit.IntValue : 4;
}

// Cuenta sobrevivientes (total y humanos) y espectadores.
void CountTeams(int &survTotal, int &survHumans, int &specs)
{
	survTotal  = 0;
	survHumans = 0;
	specs	   = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;

		int team = GetClientTeam(i);
		if (team == TEAM_SURVIVOR)
		{
			survTotal++;
			if (!IsFakeClient(i)) survHumans++;
		}
		else if (team == TEAM_SPECTATOR)
		{
			specs++;
		}
	}
}

int FindSurvivorBot()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsFakeClient(i)) continue;
		if (GetClientTeam(i) == TEAM_SURVIVOR)
			return i;
	}
	return 0;
}

public int GetMaxPlayers()
{
	ConVar cvMaxPlayers = FindConVar("sv_maxplayers");
	if (cvMaxPlayers == null)
	{
		LogError("No se pudo encontrar sv_maxplayers");
		return -1;
	}

	return cvMaxPlayers.IntValue;
}

/* ===================== Sistema de Hints ===================== */

// Inicia el timer de hint permanente
void StartHintTimer(int client)
{
	if (!IsPlayer(client))
		return;

	// Si ya está en sobrevivientes, no mostrar hint
	if (GetClientTeam(client) == TEAM_SURVIVOR)
		return;

	// Detener hint anterior si existe
	StopHintTimer(client);

	// Crear timer repetitivo que muestre el hint cada 5 segundos
	HintTimer[client] = CreateTimer(5.0, Timer_ShowHint, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	// Mostrar el hint inmediatamente también
	ShowRejoinHint(client);
}

// Detiene el timer de hint
void StopHintTimer(int client)
{
	if (HintTimer[client] != null)
	{
		KillTimer(HintTimer[client]);
		HintTimer[client] = null;
	}
}

// Timer que muestra el hint repetidamente
public Action Timer_ShowHint(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (!IsPlayer(client))
	{
		HintTimer[client] = null;
		return Plugin_Stop;
	}

	// Si el jugador ya no está en espectadores, detener el hint
	if (GetClientTeam(client) != TEAM_SPECTATOR)
	{
		HintTimer[client] = null;
		return Plugin_Stop;
	}

	ShowRejoinHint(client);
	return Plugin_Continue;
}

// Muestra el mensaje de hint traducido
void ShowRejoinHint(int client)
{
	char message[128];
	Format(message, sizeof(message), "%T", "Join_HintRejoin", client);
	PrintHintText(client, message);
}

// Hook de desconexión para limpiar timers
public void Afk_Join_OnClientDisconnect(int client)
{
	StopHintTimer(client);
	delete PanelTimer[client];
}