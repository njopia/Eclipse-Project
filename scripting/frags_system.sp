#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define MAXPLAYERS_PLUS1 (MAXPLAYERS + 1)

int	 Frags[MAXPLAYERS_PLUS1];
int	 FragsLine[MAXPLAYERS_PLUS1];
int	 Dmg[MAXPLAYERS_PLUS1];
int	 LastDmg[MAXPLAYERS_PLUS1];
int	 SessionDmg[MAXPLAYERS_PLUS1];
int	 DmgLine[MAXPLAYERS_PLUS1];

int	 ExClients[MAXPLAYERS_PLUS1];
int	 ExClientsCount = 0;

bool ShowInfo[MAXPLAYERS_PLUS1];

public Plugin myinfo =
{
	name		= "Frags System",
	author		= "Natan 'Xtreme' P",
	description = "Sistema de frags y estadísticas para L4D2",
	version		= "1.0",
	url			= "https://xtreme-infection.com"


}

public void
	OnPluginStart()
{
	// Comandos
	RegConsoleCmd("sm_frags", Command_Frags, "Muestra panel de frags");

	// Eventos
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", Event_MapStart);	 // <-- añadido: resetea frags al cambiar mapa

	// Reset para todos los clientes
	ResetAllStats();
}

public void OnClientPutInServer(int client)
{
	ShowInfo[client] = true;
}

void ResetAllStats()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Frags[i]	  = 0;
		FragsLine[i]  = 0;
		Dmg[i]		  = 0;
		LastDmg[i]	  = 0;
		SessionDmg[i] = 0;
		DmgLine[i]	  = 0;
		ShowInfo[i]	  = true;
	}
}

public Action Command_Frags(int client, int args)
{
	ShowFragsPanel(client);
	return Plugin_Handled;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// PrintToChatAll("Debug: Evento player_death activado.");
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim	 = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(attacker))
		return;
	if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
	{
		Frags[attacker]++;
		UpdateFragsLine();

		for (int i = 1; i <= MaxClients; i++)
		{
			// DEBUG: log en consola para cada candidato
			PrintToServer("[frags] loop i=%d valid=%d show=%d team=%d",
						  i, IsValidClient(i) ? 1 : 0, ShowInfo[i] ? 1 : 0,
						  IsValidClient(i) ? GetClientTeam(i) : -1);

			if (IsValidClient(i) && ShowInfo[i])
			{
				PrintToChatAll("\x04[Eclipse] \x03%N \x01mató a \x04%N \x05- \x04Frags: \x03%d - \x04Top: \x03%d.", attacker, victim, Frags[attacker], GetFragsPos(attacker));
			}
			else
			{
				PrintToServer("[frags] no enviado a %d (condición no cumplida)", i);
			}
		}
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int damage	 = event.GetInt("dmg_health");

	if (!IsValidClient(attacker) || !IsValidClient(victim))
		return;

	if (GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2)
	{
		Dmg[attacker] += damage;

		if (SessionDmg[attacker] == 0)
		{
			LastDmg[attacker] = Dmg[attacker];
			CreateTimer(5.0, Timer_CheckDamage, attacker);
		}

		SessionDmg[attacker] += damage;
	}
}

public Action Timer_CheckDamage(Handle timer, any client)
{
	if (!IsValidClient(client) || SessionDmg[client] == 0)
		return Plugin_Stop;

	if (LastDmg[client] == Dmg[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && ShowInfo[i])
			{
				PrintToChat(i, "\x03[Pos: %d] \x04%N \x01causó \x05%d daño \x01(Total: \x03%d\x01)",
							GetDmgPos(client), client, SessionDmg[client], Dmg[client]);
			}
		}

		SessionDmg[client] = 0;
		UpdateFragsLine();

		// One-shot timer — detener
		return Plugin_Stop;
	}
	else
	{
		LastDmg[client] = Dmg[client];
		CreateTimer(5.0, Timer_CheckDamage, client);

		// Detener el timer actual, la comprobación continuará en el nuevo timer creado
		return Plugin_Stop;
	}
}

void ShowFragsPanel(int client)
{
	Panel panel = new Panel();

	panel.SetTitle("Estadísticas Actuales:");

	panel.DrawText("Frags Survivors:");

	char text[128];
	for (int i = 1; i <= GetTeamPlayerCount(2); i++)
	{
		if (IsValidClient(FragsLine[i]) && GetClientTeam(FragsLine[i]) == 2)
		{
			Format(text, sizeof(text), "%d. %N - Frags: %d", i, FragsLine[i], Frags[FragsLine[i]]);
			panel.DrawText(text);
		}
	}

	panel.DrawText(" ");
	panel.DrawText("Daño Infected:");

	for (int i = 1; i <= GetTeamPlayerCount(3); i++)
	{
		if (IsValidClient(DmgLine[i]) && GetClientTeam(DmgLine[i]) == 3)
		{
			Format(text, sizeof(text), "%d. %N - Daño: %d", i, DmgLine[i], Dmg[DmgLine[i]]);
			panel.DrawText(text);
		}
	}

	panel.DrawItem("Cerrar");

	panel.Send(client, PanelHandler_Frags, 20);
	delete panel;
}

public int PanelHandler_Frags(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

void UpdateFragsLine()
{
	ResetExClients();

	for (int i = 1; i <= GetTeamPlayerCount(2); i++)
		FragsLine[i] = GetMaxFragsClient();

	ResetExClients();

	for (int i = 1; i <= GetTeamPlayerCount(3); i++)
		DmgLine[i] = GetMaxDamageClient();
}

int GetMaxFragsClient()
{
	int maxFrags  = 0;
	int maxClient = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2 && Frags[i] >= maxFrags && !IsExClient(i))
		{
			maxClient = i;
			maxFrags  = Frags[i];
		}
	}

	AddExClient(maxClient);
	return maxClient;
}

int GetMaxDamageClient()
{
	int maxDmg	  = 0;
	int maxClient = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3 && Dmg[i] >= maxDmg && !IsExClient(i))
		{
			maxClient = i;
			maxDmg	  = Dmg[i];
		}
	}

	AddExClient(maxClient);
	return maxClient;
}

void ResetExClients()
{
	ExClientsCount = 0;
}

void AddExClient(int client)
{
	ExClients[ExClientsCount++] = client;
}

bool IsExClient(int client)
{
	for (int i = 0; i < ExClientsCount; i++)
		if (ExClients[i] == client)
			return true;
	return false;
}

int GetFragsPos(int client)
{
	for (int i = 1; i <= GetTeamPlayerCount(2); i++)
		if (FragsLine[i] == client)
			return i;
	return 0;
}

int GetDmgPos(int client)
{
	for (int i = 1; i <= GetTeamPlayerCount(3); i++)
		if (DmgLine[i] == client)
			return i;
	return 0;
}

int GetTeamPlayerCount(int team)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && GetClientTeam(i) == team)
			count++;
	return count;
}

/* bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client));
} */
bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!IsClientConnected(client)) return false;

	return true;
}

public void Event_MapStart(Event event, const char[] name, bool dontBroadcast)
{
	// Resetea todas las estadísticas relevantes al inicio de un nuevo mapa
	for (int i = 1; i <= MaxClients; i++)
	{
		Frags[i]	  = 0;
		FragsLine[i]  = 0;
		Dmg[i]		  = 0;
		LastDmg[i]	  = 0;
		SessionDmg[i] = 0;
		DmgLine[i]	  = 0;
		ShowInfo[i]	  = true;
	}

	ResetExClients();
	UpdateFragsLine();

	PrintToServer("[frags] Estadísticas reseteadas: cambio de mapa detectado.");
}