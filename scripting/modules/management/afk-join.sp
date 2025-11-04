#include <sourcemod>
#include <sdktools>

#tryinclude < left4dhooks>

Handle PanelTimer[MAXPLAYERS + 1];

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
	ShowMainMenu(client);
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

	ShowMainMenu(client);

	return Plugin_Continue;
}

/* ===================== Lógica ===================== */

void ShowMainMenu(int client)
{
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
		}
		case 2:	   // Sobrevivientes
		{
			TryJoinSurvivors(client);
		}
		case 3:	   // Cerrar
		{
			delete PanelTimer[client];
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
	ShowMainMenu(client);

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

	// Si hay bot disponible intenta tomarlo (Left4DHooks) o haz fallback a jointeam 2
	bool taken = false;

	// Busca un bot de sobreviviente
	int	 bot   = FindSurvivorBot();
	if (bot > 0)
	{
		// PrintToChatAll("Taking over bot %d", bot);
		taken = L4D_TakeOverBot(client);
	}

	if (!taken)
	{
		// Fallback general del juego
		FakeClientCommand(client, "jointeam 2");
	}
	delete PanelTimer[client];
	// Verifica tras un frame
	CreateTimer(0.2, PostJoinCheck, GetClientUserId(client));
}

public Action PostJoinCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsPlayer(client)) return Plugin_Stop;

	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		char message[128];
		Format(message, sizeof(message), "%T", "Join_JoinedSurvivors", LANG_SERVER, client);
		PrintToChatAll("\x04[JOIN]\x01 %s", message);
	}
	else
	{
		char message[256];
		Format(message, sizeof(message), "%T", "Join_Failed", client);
		PrintToChat(client, "\x04[JOIN]\x01 %s", message);
	}
	// PrintToChatAll("client team: %d", GetClientTeam(client));
	// PrintToChatAll("TEAM_SURVIVOR: %d", TEAM_SURVIVOR);
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