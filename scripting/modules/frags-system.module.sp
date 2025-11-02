#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === FRAGS SYSTEM MODULE ===
// Sistema de frags y estadísticas de daño
//==================================================

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

/**
 * Inicializa el módulo de frags
 */
public void FragsSystem_OnPluginStart()
{
	// Comandos
	RegConsoleCmd("sm_frags", FragsSystem_Command_Frags, "Muestra panel de frags");

	// Eventos
	HookEvent("player_death", FragsSystem_Event_PlayerDeath);
	HookEvent("player_hurt", FragsSystem_Event_PlayerHurt);
	HookEvent("round_start", FragsSystem_Event_MapStart);

	// Reset para todos los clientes
	FragsSystem_ResetAllStats();
}

/**
 * Al cambiar de mapa
 */
public void FragsSystem_OnMapStart()
{
	FragsSystem_ResetAllStats();
}

/**
 * Cuando un cliente se conecta
 */
public void FragsSystem_OnClientPutInServer(int client)
{
	ShowInfo[client] = true;
}

/**
 * Reset de todas las estadísticas
 */
void FragsSystem_ResetAllStats()
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

	FragsSystem_ResetExClients();
	FragsSystem_UpdateFragsLine();
}

/**
 * Comando: sm_frags
 */
public Action FragsSystem_Command_Frags(int client, int args)
{
	FragsSystem_ShowFragsPanel(client);
	return Plugin_Handled;
}

/**
 * Evento: Player Death (infectados especiales)
 */
public void FragsSystem_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim	 = GetClientOfUserId(event.GetInt("userid"));

	if (!FragsSystem_IsValidClient(attacker))
		return;

	// Validar victim antes de acceder a su equipo
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return;

	if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
	{
		Frags[attacker]++;
		FragsSystem_UpdateFragsLine();

		// Obtener tipo de infectado y puntos ganados
		int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		int pointsGained = 0;
		bool isHeadshot = event.GetBool("headshot", false);

		// Calcular puntos según tipo (debe coincidir con eclipse-points-unified)
		if (zombieClass == 8) // Tank
			pointsGained = 200;
		else if (zombieClass >= 1 && zombieClass <= 7) // Especiales normales
			pointsGained = 50;

		// Agregar bonus por headshot si aplica
		if (isHeadshot)
			pointsGained += 3;

		// Usar función centralizada de buy-menu para mostrar el mensaje
		BuyMenu_PrintKillMessage(attacker, victim, Frags[attacker], FragsSystem_GetFragsPos(attacker), pointsGained);
	}
}

/**
 * Evento: Player Hurt (daño de infectados)
 */
public void FragsSystem_Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int damage	 = event.GetInt("dmg_health");

	if (!FragsSystem_IsValidClient(attacker) || !FragsSystem_IsValidClient(victim))
		return;

	if (GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2)
	{
		Dmg[attacker] += damage;

		if (SessionDmg[attacker] == 0)
		{
			LastDmg[attacker] = Dmg[attacker];
			CreateTimer(5.0, FragsSystem_Timer_CheckDamage, attacker);
		}

		SessionDmg[attacker] += damage;
	}
}

/**
 * Timer para verificar daño acumulado
 */
public Action FragsSystem_Timer_CheckDamage(Handle timer, any client)
{
	if (!FragsSystem_IsValidClient(client) || SessionDmg[client] == 0)
		return Plugin_Stop;

	if (LastDmg[client] == Dmg[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (FragsSystem_IsValidClient(i) && ShowInfo[i])
			{
				PrintToChat(i, "\x03[Pos: %d] \x04%N \x01causó \x05%d daño \x01(Total: \x03%d\x01)",
							FragsSystem_GetDmgPos(client), client, SessionDmg[client], Dmg[client]);
			}
		}

		SessionDmg[client] = 0;
		FragsSystem_UpdateFragsLine();
		return Plugin_Stop;
	}
	else
	{
		LastDmg[client] = Dmg[client];
		CreateTimer(5.0, FragsSystem_Timer_CheckDamage, client);
		return Plugin_Stop;
	}
}

/**
 * Mostrar panel de frags
 */
void FragsSystem_ShowFragsPanel(int client)
{
	Panel panel = new Panel();

	panel.SetTitle("Estadísticas Actuales:");

	panel.DrawText("Frags Survivors:");

	char text[128];
	for (int i = 1; i <= FragsSystem_GetTeamPlayerCount(2); i++)
	{
		if (FragsSystem_IsValidClient(FragsLine[i]) && GetClientTeam(FragsLine[i]) == 2)
		{
			Format(text, sizeof(text), "%d. %N - Frags: %d", i, FragsLine[i], Frags[FragsLine[i]]);
			panel.DrawText(text);
		}
	}

	panel.DrawText(" ");
	panel.DrawText("Daño Infected:");

	for (int i = 1; i <= FragsSystem_GetTeamPlayerCount(3); i++)
	{
		if (FragsSystem_IsValidClient(DmgLine[i]) && GetClientTeam(DmgLine[i]) == 3)
		{
			Format(text, sizeof(text), "%d. %N - Daño: %d", i, DmgLine[i], Dmg[DmgLine[i]]);
			panel.DrawText(text);
		}
	}

	panel.DrawItem("Cerrar");

	panel.Send(client, FragsSystem_PanelHandler_Frags, 20);
	delete panel;
}

/**
 * Handler del panel
 */
public int FragsSystem_PanelHandler_Frags(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

/**
 * Actualizar líneas de frags y daño
 */
void FragsSystem_UpdateFragsLine()
{
	FragsSystem_ResetExClients();

	for (int i = 1; i <= FragsSystem_GetTeamPlayerCount(2); i++)
		FragsLine[i] = FragsSystem_GetMaxFragsClient();

	FragsSystem_ResetExClients();

	for (int i = 1; i <= FragsSystem_GetTeamPlayerCount(3); i++)
		DmgLine[i] = FragsSystem_GetMaxDamageClient();
}

/**
 * Obtener cliente con más frags
 */
int FragsSystem_GetMaxFragsClient()
{
	int maxFrags  = 0;
	int maxClient = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (FragsSystem_IsValidClient(i) && GetClientTeam(i) == 2 && Frags[i] >= maxFrags && !FragsSystem_IsExClient(i))
		{
			maxClient = i;
			maxFrags  = Frags[i];
		}
	}

	FragsSystem_AddExClient(maxClient);
	return maxClient;
}

/**
 * Obtener cliente con más daño
 */
int FragsSystem_GetMaxDamageClient()
{
	int maxDmg	  = 0;
	int maxClient = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (FragsSystem_IsValidClient(i) && GetClientTeam(i) == 3 && Dmg[i] >= maxDmg && !FragsSystem_IsExClient(i))
		{
			maxClient = i;
			maxDmg	  = Dmg[i];
		}
	}

	FragsSystem_AddExClient(maxClient);
	return maxClient;
}

/**
 * Utilidades para ExClients
 */
void FragsSystem_ResetExClients()
{
	ExClientsCount = 0;
}

void FragsSystem_AddExClient(int client)
{
	ExClients[ExClientsCount++] = client;
}

bool FragsSystem_IsExClient(int client)
{
	for (int i = 0; i < ExClientsCount; i++)
		if (ExClients[i] == client)
			return true;
	return false;
}

/**
 * Obtener posición en frags
 */
int FragsSystem_GetFragsPos(int client)
{
	for (int i = 1; i <= FragsSystem_GetTeamPlayerCount(2); i++)
		if (FragsLine[i] == client)
			return i;
	return 0;
}

/**
 * Obtener posición en daño
 */
int FragsSystem_GetDmgPos(int client)
{
	for (int i = 1; i <= FragsSystem_GetTeamPlayerCount(3); i++)
		if (DmgLine[i] == client)
			return i;
	return 0;
}

/**
 * Contar jugadores en un equipo
 */
int FragsSystem_GetTeamPlayerCount(int team)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (FragsSystem_IsValidClient(i) && GetClientTeam(i) == team)
			count++;
	return count;
}

/**
 * Validar cliente
 */
bool FragsSystem_IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!IsClientConnected(client)) return false;

	return true;
}

/**
 * Evento: Map Start
 */
public void FragsSystem_Event_MapStart(Event event, const char[] name, bool dontBroadcast)
{
	FragsSystem_ResetAllStats();
	PrintToServer("[frags] Estadísticas reseteadas: cambio de mapa detectado.");
}
