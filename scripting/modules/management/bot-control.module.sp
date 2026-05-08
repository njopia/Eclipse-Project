#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === BOT CONTROL MODULE ===
// Mantiene exactamente 4 sobrevivientes en equipo 2
// (humanos + bots). Si hay menos de 4, agrega un bot.
// Si hay 4 o mas humanos, saca bots sobrantes.
//==================================================

#define _BOT_CONTROL_MODULE_

#define BOT_CONTROL_TEAM 2
#define BOT_CONTROL_MAX  4

Handle g_hCvarBotControl = INVALID_HANDLE;

void BotControl_OnPluginStart()
{
	g_hCvarBotControl = CreateConVar("bot_control", "1", "Mantener 4 sobrevivientes automaticamente (0=off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateTimer(2.0, BotControl_TimerCheck, _, TIMER_REPEAT);
}

void BotControl_OnMapStart()
{
	// Nothing — timer runs continuously
}

public Action BotControl_TimerCheck(Handle timer)
{
	if (!GetConVarBool(g_hCvarBotControl)) return Plugin_Continue;
	if (!IsServerProcessing()) return Plugin_Continue;

	int humans = 0;
	int bots   = 0;
	int firstBot = -1;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != BOT_CONTROL_TEAM) continue;

		if (IsFakeClient(i))
		{
			// Skip bots that a human is spectating (about to take over)
			int spectatorUID = GetEntProp(i, Prop_Send, "m_humanSpectatorUserID");
			if (spectatorUID != 0) continue;

			bots++;
			if (firstBot == -1) firstBot = i;
		}
		else
		{
			humans++;
		}
	}

	int total = humans + bots;

	if (total < BOT_CONTROL_MAX)
	{
		ServerCommand("sb_add");
	}
	else if (humans >= BOT_CONTROL_MAX && bots > 0 && firstBot != -1)
	{
		// Strip weapons before kicking to avoid drops cluttering the map
		BotControl_RemoveBotWeapons(firstBot);
		KickClient(firstBot);
	}

	return Plugin_Continue;
}

static void BotControl_RemoveBotWeapons(int client)
{
	for (int slot = 0; slot < 5; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (weapon != -1 && IsValidEntity(weapon))
			RemovePlayerItem(client, weapon);
	}
}
