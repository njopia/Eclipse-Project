/*
 * Players List Module - Shows connected players with their levels and admin status
 * Command: !players
 */

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === PLAYERS LIST MODULE ===
// Panel que muestra jugadores conectados, niveles y estado de admin
//==================================================

// ConVars
Handle cvar_PlayersList_Enabled = INVALID_HANDLE;

/**
 * Inicializa el modulo de lista de jugadores
 */
public void PlayersList_OnPluginStart()
{
	cvar_PlayersList_Enabled = CreateConVar(
		"players_list_enabled",
		"1",
		"Habilita el comando !players (1 = habilitado, 0 = deshabilitado)",
		FCVAR_PLUGIN
	);

	// Registrar comandos
	RegConsoleCmd("sm_players", Command_ShowPlayers, "Muestra lista de jugadores conectados");
	RegConsoleCmd("sm_playerlist", Command_ShowPlayers, "Muestra lista de jugadores conectados");
	RegConsoleCmd("sm_who", Command_ShowPlayers, "Muestra lista de jugadores conectados");
}

/**
 * Comando: Muestra el panel de jugadores
 */
public Action Command_ShowPlayers(int client, int args)
{
	if (!GetConVarBool(cvar_PlayersList_Enabled))
	{
		ReplyToCommand(client, "[Players] El sistema de lista de jugadores esta deshabilitado.");
		return Plugin_Handled;
	}

	if (client == 0)
	{
		ReplyToCommand(client, "[Players] Este comando solo puede ser usado in-game.");
		return Plugin_Handled;
	}

	ShowPlayersPanel(client);
	return Plugin_Handled;
}

/**
 * Structure to store player information
 */
enum struct PlayerInfo
{
	int clientIndex;
	char name[MAX_NAME_LENGTH];
	int level;
	bool isAdmin;
	int team;
}

/**
 * Shows the panel with connected players
 */
void ShowPlayersPanel(int client)
{
	Panel panel = new Panel();

	char title[128];
	int playerCount = GetConnectedPlayersCount();

	Format(title, sizeof(title), "%T", "PlayersList_Title", client, playerCount);
	panel.SetTitle(title);

	panel.DrawText(" ");

	char header[128];
	Format(header, sizeof(header), "%T", "PlayersList_Header", client);
	panel.DrawText(header);
	panel.DrawText("━━━━━━━━━━━━━━━━━━━━━━━━━━━");

	// Create array to store player information
	ArrayList playerList = new ArrayList(sizeof(PlayerInfo));

	// Collect information from all players
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		PlayerInfo pInfo;
		pInfo.clientIndex = i;
		GetClientName(i, pInfo.name, sizeof(pInfo.name));
		pInfo.level = Leveling_GetPlayerLevel(i);
		pInfo.isAdmin = CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true);
		pInfo.team = GetClientTeam(i);

		playerList.PushArray(pInfo);
	}

	// Sort players by level (highest to lowest)
	SortPlayersByLevel(playerList);

	// Display sorted players
	for (int i = 0; i < playerList.Length; i++)
	{
		PlayerInfo pInfo;
		playerList.GetArray(i, pInfo);

		char playerInfo[256];
		char playerName[MAX_NAME_LENGTH];
		strcopy(playerName, sizeof(playerName), pInfo.name);

		// Limit name to 20 characters for better formatting
		if (strlen(playerName) > 20)
		{
			playerName[17] = '.';
			playerName[18] = '.';
			playerName[19] = '.';
			playerName[20] = '\0';
		}

		// Get team name with translation
		char teamName[32];
		switch (pInfo.team)
		{
			case 2: Format(teamName, sizeof(teamName), "%T", "PlayersList_Survivor", client);
			case 1: Format(teamName, sizeof(teamName), "%T", "PlayersList_Spectator", client);
			default: strcopy(teamName, sizeof(teamName), "Unknown");
		}

		// Format player information
		char adminText[16];
		if (pInfo.isAdmin)
		{
			Format(adminText, sizeof(adminText), "%T", "PlayersList_Admin", client);
			Format(playerInfo, sizeof(playerInfo), "★ %s | Lvl %d | %s", playerName, pInfo.level, adminText);
		}
		else
		{
			Format(playerInfo, sizeof(playerInfo), "- %s | Lvl %d | %s", playerName, pInfo.level, teamName);
		}

		panel.DrawText(playerInfo);
	}

	delete playerList;

	panel.DrawText(" ");

	char closeText[32];
	Format(closeText, sizeof(closeText), "%T", "UI_Close", client);
	panel.DrawItem(closeText);

	panel.Send(client, PanelHandler_PlayersList, MENU_TIME_FOREVER);
	delete panel;
}

/**
 * Sorts players by level (highest to lowest)
 */
void SortPlayersByLevel(ArrayList playerList)
{
	int length = playerList.Length;

	// Simple bubble sort (sufficient for typical player count)
	for (int i = 0; i < length - 1; i++)
	{
		for (int j = 0; j < length - i - 1; j++)
		{
			PlayerInfo pInfo1, pInfo2;
			playerList.GetArray(j, pInfo1);
			playerList.GetArray(j + 1, pInfo2);

			// Sort by level descending
			if (pInfo1.level < pInfo2.level)
			{
				// Swap
				playerList.SetArray(j, pInfo2);
				playerList.SetArray(j + 1, pInfo1);
			}
		}
	}
}

/**
 * Panel handler
 */
public int PanelHandler_PlayersList(Menu menu, MenuAction action, int param1, int param2)
{
	// No special handling needed
	return 0;
}

/**
 * Gets the count of connected players (excluding bots)
 */
int GetConnectedPlayersCount()
{
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			count++;
		}
	}

	return count;
}

/**
 * Checks if the module is enabled
 */
public bool PlayersList_IsEnabled()
{
	return GetConVarBool(cvar_PlayersList_Enabled);
}
