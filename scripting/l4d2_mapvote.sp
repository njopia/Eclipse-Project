// Force strict semicolon mode
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION	"1.0.0"

char g_gameMode[64];
Handle g_mapMenu = null;

int AllowVote[MAXPLAYERS + 1];

int yes, no;
char mapname[255];

bool game_l4d2 = false;

public Plugin myinfo =
{
	name = "[L4D2] Campaign/Map Voter",
	author = "satannuts",
	description = "Allows voting by players to change campaign/map",
	version = PLUGIN_VERSION,
	url = "..."
}

public void OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}
	if (StrEqual(game_name, "left4dead2", false))
	{
		game_l4d2 = true;
	}

	// Load translations for Eclipse integration
	LoadTranslations("eclipse.phrases");

	CreateConVar("l4d_mapvote_version", PLUGIN_VERSION, "[L4D2] Campaign/Map Voter Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegAdminCmd("sm_cancelvote", Command_CancelVote, ADMFLAG_VOTE);
	RegConsoleCmd("sm_custom", Command_MapVote);
	AutoExecConfig(true, "l4d2_mapvote");

	yes = 0;
	no = 0;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidPlayer(i)) {
			AllowVote[i] = 1;
		}
	}
}

public void OnMapStart()
{
	ConVar currentGameMode = FindConVar("mp_gamemode");
	currentGameMode.GetString(g_gameMode, sizeof(g_gameMode));
	yes = 0;
	no = 0;
}

public void OnClientPutInServer(int client)
{
	// Code disabled by original author
	/*
	ConVar cvar = FindConVar("l4d_mapvote_announce_mode");
	if(cvar.IntValue != 0)
	{
		CreateTimer(50.0, Timer_WelcomeMessage, client);
	}
	*/
}

public Action Timer_WelcomeMessage(Handle timer, int client)
{
	// Code disabled by original author
	return Plugin_Continue;
	/*
	char announce[] = "\x01[CUSTOM] To call a vote to change map/campaign votes, Type: \x04!mapvote\x01 in chat.";
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		ConVar cvar = FindConVar("l4d_backpack_help_mode");
		switch (cvar.IntValue)
		{
			case 1:
			{
				PrintToChat(client, announce);
			}
			case 2:
			{
				PrintHintText(client, announce);
			}
			case 3:
			{
				PrintCenterText(client, announce);
			}
			default:
			{
				PrintToChat(client, announce);
			}
		}
	}
	return Plugin_Continue;
	*/
}

public Action Command_Say(int client, int args)
{
	// Code disabled by original author
	return Plugin_Continue;

	/*
	if(!client)
	{
		return Plugin_Continue;
	}

	char text[192];
	if(!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}

	int startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if(strcmp(text[startidx], "!mapvote", false) == 0)
	{
		DoMapVoteList(client);
	}

	return Plugin_Continue;
	*/
}

void DoMapVoteList(int client)
{
	if (!IsValidPlayer(client)) return;

	if (AllowVote[client] != 1) {
		PrintToChat(client, "\x04[MAPVOTE]\x01 %t", "MapVote_VoteLimit");
		return;
	}
	AllowVote[client] = 0;
	CreateTimer(120.0, SetAllowVote, client);

	g_mapMenu = BuildMapMenu(false);
	DisplayMenu(g_mapMenu, client, 60);
}

public Action SetAllowVote(Handle timer, int client)
{
	AllowVote[client] = 1;
	return Plugin_Continue;
}

public Action FinishVoteTimer(Handle timer, int client)
{
	if (yes > 0) FinishVote();
	return Plugin_Continue;
}

public int Handle_MapVoteList(Menu mapMenu, MenuAction action, int param1, int param2)
{
	// Change the map to the selected item.
	if(action == MenuAction_Select)
	{
		char map[64];
		GetMenuItem(mapMenu, param2, map, sizeof(map));
		Format(mapname, sizeof(mapname), "%s", map);

		if (yes > 0) {
			PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_InProgress");
			return 0;
		}
		CreateTimer(30.0, FinishVoteTimer, INVALID_HANDLE);
		yes = 1;
		no = 0;
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Started", GetName(param1), mapname);

		DoVoteMenu(param1);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete mapMenu;
	}
	return 0;
}

void DoVoteMenu(int client)
{
	if (IsVoteInProgress())	{
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_AlreadyInProgress");
		return;
	}

	for (int i=1; i<=MaxClients; i++)
		if ( (IsValidPlayer(i)) && (i != client) )
			ShowVotePanel(i);
}

public int Handle_VoteMenu(Menu voteMenu, MenuAction action, int param1, int param2)
{
	if (voteMenu == null)	return 0;

	if (action == MenuAction_End) {
		delete voteMenu;
		return 0;
	}

	if (action != MenuAction_Select || (!IsValidPlayer(param1))) {
		return 0;
	}

	char Info[255];
	bool found = GetMenuItem(voteMenu, param2, Info, sizeof(Info));

	if (!found)	return 0;

	if (strcmp(Info, "yes", false) == 0)
	{
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_VotedYes", GetName(param1), yes, no);
		yes++;
	}
	else if (strcmp(Info, "no", false) == 0)
	{
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_VotedNo", GetName(param1), yes, no);
		no++;
	}

	if ( (yes+no) >= (GetTeamHumanCount(2) + GetTeamHumanCount(3)) )  {
		//ServerCommand("changelevel %s", mapname);
		FinishVote();
	}

	return 0;
}

char[] GetName(int client)
{
	char name[MAX_NAME_LENGTH];
	Format(name, sizeof(name), "noname");
	if ((client <= 0) || (client > MaxClients) || (!IsClientConnected(client))) return name;

	GetClientName(client, name, MAX_NAME_LENGTH);

	ReplaceString(name, sizeof(name), "<?php", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "\\", "");
	//ReplaceString(name, sizeof(name), "\"", "");
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), ";", "");
	ReplaceString(name, sizeof(name), "ґ", "");
	ReplaceString(name, sizeof(name), "`", "");

	return name;
}

bool IsValidPlayer(int client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;

	if (!IsClientInGame(client))
		return false;

	if (IsFakeClient(client))
		return false;

	return true;
}




stock int GetTeamHumanCount(int team)
{
	int humans = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if ( (IsValidPlayer(i)) && (GetClientTeam(i) == team) )  {
			humans++;
		}
	}

	return humans;
}

public Action Command_CancelVote(int client, int args)
{
	CancelVote();

	return Plugin_Handled;
}

public Action Command_MapVote(int client, int args)
{
	if (IsValidPlayer(client)) DoMapVoteList(client);

	//g_mapMenu = BuildMapMenu(true);
	//DisplayMenu(g_mapMenu, client, 60);

	return Plugin_Handled;
}

public int Handle_AdminMapMenu(Menu mapMenu, MenuAction action, int param1, int param2)
{
	// Change the map to the selected item.
	if(action == MenuAction_Select)
	{
		char map[64];
		GetMenuItem(mapMenu, param2, map, sizeof(map));
		ServerCommand("changelevel %s", map);
	}
	// If the menu was cancelled, choose a random map.
	else if (action == MenuAction_Cancel)
	{
		delete mapMenu;
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		delete mapMenu;
	}
	return 0;
}

Menu BuildMapMenu(bool adminMode = false)
{
	Menu mapMenu;

	if(adminMode)
	{
		mapMenu = new Menu(Handle_AdminMapMenu);
	}
	else
	{
		mapMenu = new Menu(Handle_MapVoteList);
	}
	
	char title[128];
	Format(title, sizeof(title), "%T", "MapVote_ChooseMap", LANG_SERVER);
	mapMenu.SetTitle(title);
	mapMenu.ExitButton = false;

	if(game_l4d2)
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
			// Official Campaigns
			mapMenu.AddItem("c1m1_hotel", "Dead Center");
			mapMenu.AddItem("c2m1_highway", "Dark Carnival");
			mapMenu.AddItem("c3m1_plankcountry", "Swamp Fever");
			mapMenu.AddItem("c4m1_milltown_a", "Hard Rain");
			mapMenu.AddItem("c5m1_waterfront", "The Parish");
			mapMenu.AddItem("c6m1_riverbank", "The Passing");
			mapMenu.AddItem("c7m1_docks", "The Sacrifice");
			mapMenu.AddItem("c8m1_apartment", "No Mercy");
			mapMenu.AddItem("c9m1_alleys", "Crash Course");
			mapMenu.AddItem("c10m1_caves", "Death Toll");
			mapMenu.AddItem("c11m1_greenhouse", "Dead Air");
			mapMenu.AddItem("c12m1_hilltop", "Blood Harvest");
			mapMenu.AddItem("c13m1_alpinecreek", "Cold Stream");
			mapMenu.AddItem("c14m1_junkyard", "The Last Stand");

			// Custom Campaigns
			mapMenu.AddItem("cbm1_lake", "BloodProof");
			mapMenu.AddItem("l4d2_bts01_forest", "Back to School");
			mapMenu.AddItem("bdp_bunker01", "Buried Deep");
			mapMenu.AddItem("cwm1_intro", "Carried Off");
			mapMenu.AddItem("l4d2_daybreak01_hotel", "Day Break");
			mapMenu.AddItem("deathrow01_streets", "Death Row");
			mapMenu.AddItem("dm1_suburbs", "Devil Mountain");
			mapMenu.AddItem("dprm1_milltown_a", "Downpour");
			mapMenu.AddItem("gb_prologue", "Ghostbusters Project");
			mapMenu.AddItem("l4d_grave_city", "Grave Outdoors");
			mapMenu.AddItem("l4d2_diescraper1_apartment_361", "Diescraper");
			mapMenu.AddItem("map_part1", "Left 4 Invasion");
			mapMenu.AddItem("l4d_lastnight01_arrival", "Last Night");
			mapMenu.AddItem("l4d_mic2_trapmentd", "MIC2");
			mapMenu.AddItem("l4d2_stadium1_apartment", "Suicide Blitz 2");
			mapMenu.AddItem("l4d2_timemachine_01", "Time Machine");
		}
		else if(strcmp(g_gameMode, "realism", false) == 0)
		{
			// Official Campaigns
			mapMenu.AddItem("c1m1_hotel", "Dead Center");
			mapMenu.AddItem("c2m1_highway", "Dark Carnival");
			mapMenu.AddItem("c3m1_plankcountry", "Swamp Fever");
			mapMenu.AddItem("c4m1_milltown_a", "Hard Rain");
			mapMenu.AddItem("c5m1_waterfront", "The Parish");
			mapMenu.AddItem("c6m1_riverbank", "The Passing");
			mapMenu.AddItem("c7m1_docks", "The Sacrifice");
			mapMenu.AddItem("c8m1_apartment", "No Mercy");
			mapMenu.AddItem("c9m1_alleys", "Crash Course");
			mapMenu.AddItem("c10m1_caves", "Death Toll");
			mapMenu.AddItem("c11m1_greenhouse", "Dead Air");
			mapMenu.AddItem("c12m1_hilltop", "Blood Harvest");
			mapMenu.AddItem("c13m1_alpinecreek", "Cold Stream");
			mapMenu.AddItem("c14m1_junkyard", "The Last Stand");
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)
		{
			// Official Campaigns
			mapMenu.AddItem("c1m1_hotel", "Dead Center");
			mapMenu.AddItem("c2m1_highway", "Dark Carnival");
			mapMenu.AddItem("c3m1_plankcountry", "Swamp Fever");
			mapMenu.AddItem("c4m1_milltown_a", "Hard Rain");
			mapMenu.AddItem("c5m1_waterfront", "The Parish");
			mapMenu.AddItem("c6m1_riverbank", "The Passing");
			mapMenu.AddItem("c7m1_docks", "The Sacrifice");
			mapMenu.AddItem("c8m1_apartment", "No Mercy");
			mapMenu.AddItem("c9m1_alleys", "Crash Course");
			mapMenu.AddItem("c10m1_caves", "Death Toll");
			mapMenu.AddItem("c11m1_greenhouse", "Dead Air");
			mapMenu.AddItem("c12m1_hilltop", "Blood Harvest");
			mapMenu.AddItem("c13m1_alpinecreek", "Cold Stream");
			mapMenu.AddItem("c14m1_junkyard", "The Last Stand");

			// Custom Campaigns
			mapMenu.AddItem("cbm1_lake", "BloodProof");
			mapMenu.AddItem("l4d2_bts01_forest", "Back to School");
			mapMenu.AddItem("bdp_bunker01", "Buried Deep");
			mapMenu.AddItem("cwm1_intro", "Carried Off");
			mapMenu.AddItem("l4d2_daybreak01_hotel", "Day Break");
			mapMenu.AddItem("deathrow01_streets", "Death Row");
			mapMenu.AddItem("dm1_suburbs", "Devil Mountain");
			mapMenu.AddItem("dprm1_milltown_a", "Downpour");
			mapMenu.AddItem("gb_prologue", "Ghostbusters Project");
			mapMenu.AddItem("l4d_grave_city", "Grave Outdoors");
			mapMenu.AddItem("l4d2_diescraper1_apartment_361", "Diescraper");
			mapMenu.AddItem("map_part1", "Left 4 Invasion");
			mapMenu.AddItem("l4d_lastnight01_arrival", "Last Night");
			mapMenu.AddItem("l4d_mic2_trapmentd", "MIC2");
			mapMenu.AddItem("l4d2_stadium1_apartment", "Suicide Blitz 2");
			mapMenu.AddItem("l4d2_timemachine_01", "Time Machine");
		}
		else if(strcmp(g_gameMode, "teamversus", false) == 0)
		{
			// Official Campaigns
			mapMenu.AddItem("c1m1_hotel", "Dead Center");
			mapMenu.AddItem("c2m1_highway", "Dark Carnival");
			mapMenu.AddItem("c3m1_plankcountry", "Swamp Fever");
			mapMenu.AddItem("c4m1_milltown_a", "Hard Rain");
			mapMenu.AddItem("c5m1_waterfront", "The Parish");
			mapMenu.AddItem("c6m1_riverbank", "The Passing");
			mapMenu.AddItem("c7m1_docks", "The Sacrifice");
			mapMenu.AddItem("c8m1_apartment", "No Mercy");
			mapMenu.AddItem("c9m1_alleys", "Crash Course");
			mapMenu.AddItem("c10m1_caves", "Death Toll");
			mapMenu.AddItem("c11m1_greenhouse", "Dead Air");
			mapMenu.AddItem("c12m1_hilltop", "Blood Harvest");
			mapMenu.AddItem("c13m1_alpinecreek", "Cold Stream");
			mapMenu.AddItem("c14m1_junkyard", "The Last Stand");
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)
		{
			mapMenu.AddItem("c1m4_atrium", "Atrium");
			mapMenu.AddItem("c2m1_highway", "Highway");
			mapMenu.AddItem("c2m4_barns", "Barns");
			mapMenu.AddItem("c2m5_concert", "Concert");
			mapMenu.AddItem("c3m1_plankcountry", "Plank Country");
			mapMenu.AddItem("c3m4_plantation", "Plantation");
			mapMenu.AddItem("c4m1_milltown_a", "Mill Town 1");
			mapMenu.AddItem("c4m2_sugarmill_a", "Sugar Mill 1");
			mapMenu.AddItem("c5m2_park", "Park");
			mapMenu.AddItem("c5m5_bridge ", "Bridge");
		}
		else if(strcmp(g_gameMode, "scavenge", false) == 0)
		{
			mapMenu.AddItem("c1m4_atrium", "Atrium");
			mapMenu.AddItem("c2m1_highway", "Highway");
			mapMenu.AddItem("c3m1_plankcountry", "Plank Country");
			mapMenu.AddItem("c4m1_milltown_a", "Mill Town 1");
			mapMenu.AddItem("c4m2_sugarmill_a", "Sugar Mill 1");
			mapMenu.AddItem("c5m2_park", "Park");
		}
		else if(strcmp(g_gameMode, "teamscavenge", false) == 0)
		{
			mapMenu.AddItem("c1m4_atrium", "Atrium");
			mapMenu.AddItem("c2m1_highway", "Highway");
			mapMenu.AddItem("c3m1_plankcountry", "Plank Country");
			mapMenu.AddItem("c4m1_milltown_a", "Mill Town 1");
			mapMenu.AddItem("c4m2_sugarmill_a", "Sugar Mill 1");
			mapMenu.AddItem("c5m2_park", "Park");
		}
		else
		{
			// Official Campaigns
			mapMenu.AddItem("c1m1_hotel", "Dead Center");
			mapMenu.AddItem("c2m1_highway", "Dark Carnival");
			mapMenu.AddItem("c3m1_plankcountry", "Swamp Fever");
			mapMenu.AddItem("c4m1_milltown_a", "Hard Rain");
			mapMenu.AddItem("c5m1_waterfront", "The Parish");
			mapMenu.AddItem("c6m1_riverbank", "The Passing");
			mapMenu.AddItem("c7m1_docks", "The Sacrifice");
			mapMenu.AddItem("c8m1_apartment", "No Mercy");
			mapMenu.AddItem("c9m1_alleys", "Crash Course");
			mapMenu.AddItem("c10m1_caves", "Death Toll");
			mapMenu.AddItem("c11m1_greenhouse", "Dead Air");
			mapMenu.AddItem("c12m1_hilltop", "Blood Harvest");
			mapMenu.AddItem("c13m1_alpinecreek", "Cold Stream");
			mapMenu.AddItem("c14m1_junkyard", "The Last Stand");

			// Custom Campaigns
			mapMenu.AddItem("cbm1_lake", "BloodProof");
			mapMenu.AddItem("l4d2_bts01_forest", "Back to School");
			mapMenu.AddItem("bdp_bunker01", "Buried Deep");
			mapMenu.AddItem("cwm1_intro", "Carried Off");
			mapMenu.AddItem("l4d2_daybreak01_hotel", "Day Break");
			mapMenu.AddItem("deathrow01_streets", "Death Row");
			mapMenu.AddItem("dm1_suburbs", "Devil Mountain");
			mapMenu.AddItem("dprm1_milltown_a", "Downpour");
			mapMenu.AddItem("gb_prologue", "Ghostbusters Project");
			mapMenu.AddItem("l4d_grave_city", "Grave Outdoors");
			mapMenu.AddItem("l4d2_diescraper1_apartment_361", "Diescraper");
			mapMenu.AddItem("map_part1", "Left 4 Invasion");
			mapMenu.AddItem("l4d_lastnight01_arrival", "Last Night");
			mapMenu.AddItem("l4d_mic2_trapmentd", "MIC2");
			mapMenu.AddItem("l4d2_stadium1_apartment", "Suicide Blitz 2");
			mapMenu.AddItem("l4d2_timemachine_01", "Time Machine");
		}
	}
	else
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
			mapMenu.AddItem("l4d_hospital01_apartment", "Mercy Hospital");
			mapMenu.AddItem("l4d_garage01_alleys", "Crash Course");
			mapMenu.AddItem("l4d_smalltown01_caves", "Death Toll");
			mapMenu.AddItem("l4d_airport01_greenhouse", "Dead Air");
			mapMenu.AddItem("l4d_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)
		{
			mapMenu.AddItem("l4d_vs_hospital01_apartment", "Mercy Hospital");
			mapMenu.AddItem("l4d_garage01_alleys", "Crash Course");
			mapMenu.AddItem("l4d_vs_smalltown01_caves", "Death Toll");
			mapMenu.AddItem("l4d_vs_airport01_greenhouse", "Dead Air");
			mapMenu.AddItem("l4d_vs_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)
		{
			mapMenu.AddItem("l4d_hospital02_subway", "Generator Room");
			mapMenu.AddItem("l4d_hospital03_sewers", "Gas Station");
			mapMenu.AddItem("l4d_hospital04_interior", "Hospital");
			mapMenu.AddItem("l4d_vs_hospital05_rooftop", "Rooftop");
			mapMenu.AddItem("l4d_garage01_alleys", "Bridge (crashcourse)");
			mapMenu.AddItem("l4d_garage02_lots", "Truck Depot");
			mapMenu.AddItem("l4d_smalltown02_drainage", "Drains");
			mapMenu.AddItem("l4d_smalltown03_ranchhouse", "Church");
			mapMenu.AddItem("l4d_smalltown04_mainstreet", "Street");
			mapMenu.AddItem("l4d_vs_smalltown05_houseboat", "Boathouse");
			mapMenu.AddItem("l4d_airport02_offices", "Crane");
			mapMenu.AddItem("l4d_airport03_garage", "Construction Site");
			mapMenu.AddItem("l4d_airport04_terminal", "Terminal");
			mapMenu.AddItem("l4d_vs_airport05_runway", "Runway");
			mapMenu.AddItem("l4d_farm02_traintunnel", "Warehouse");
			mapMenu.AddItem("l4d_farm03_bridge", "Bridge (bloodharvest)");
			mapMenu.AddItem("l4d_vs_farm05_cornfield", "Farmhouse");
			mapMenu.AddItem("l4d_sv_lighthouse", "Lighthouse");
		}
	}

	return mapMenu;
}
/**
*public OnMapEnd()
*{
*	if (g_mapMenu != INVALID_HANDLE)
*	{
*		CloseHandle(g_mapMenu);
*		g_mapMenu = INVALID_HANDLE;
*	}
*	
*	if (g_gameModeMenu != INVALID_HANDLE)
*	{
*		CloseHandle(g_gameModeMenu);
*		g_gameModeMenu = INVALID_HANDLE;
*	}
*}
*/

void FinishVote()
{
	PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Finished", yes, no);
	if (yes > no) {
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Changing", mapname);
		yes = 0;
		no = 0;
		ServerCommand("changelevel %s", mapname);
	}
	else PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Failed");
}

void ShowVotePanel(int client)
{
	Panel VoteMapPanel = new Panel();

	char text[255];

	Format(text, sizeof(text), "%T", "MapVote_ChangeMapQuestion", client, mapname);
	VoteMapPanel.SetTitle(text);

	Format(text, sizeof(text), "%T", "MapVote_Yes", client);
	VoteMapPanel.DrawItem(text);

	Format(text, sizeof(text), "%T", "MapVote_No", client);
	VoteMapPanel.DrawItem(text);

	VoteMapPanel.Send(client, VoteMapPanelHandler, 60);
	delete VoteMapPanel;
}	

public int VoteMapPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if  (!IsValidPlayer(param1)) return 0;

	if ((param2 == 1) || (param2 == 2)) {

		if (param2 == 1) {
			yes++;
			PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_VotedYes", GetName(param1), yes, no);
		}
		else if (param2 == 2) {
			no++;
			PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_VotedNo", GetName(param1), yes, no);
		}


		if ( yes+no >= GetTeamHumanCount(2)+GetTeamHumanCount(3) ) {
			FinishVote();
		}
	}
	else ShowVotePanel(param1);

	return 0;
}

public void OnClientPostAdminCheck(int client)
{
	AllowVote[client] = 1;
}