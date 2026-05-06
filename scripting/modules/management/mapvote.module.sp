/*
 * Map Vote Module - Campaign/Map voting system
 * Original author: satannuts
 * Adapted for Eclipse Management System
 */

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#define _MAPVOTE_MODULE_

//==================================================
// === MAP VOTE MODULE ===
// Allows players to vote for map/campaign changes
//==================================================

char g_MapVote_gameMode[64];
Handle g_MapVote_mapMenu = null;

int g_MapVote_AllowVote[MAXPLAYERS + 1];
int g_MapVote_yes, g_MapVote_no;
char g_MapVote_mapname[255];

bool g_MapVote_game_l4d2 = false;

/**
 * Initialize map vote module
 */
public void MapVote_OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead2", false))
	{
		g_MapVote_game_l4d2 = true;
	}

	g_MapVote_yes = 0;
	g_MapVote_no = 0;

	for (int i = 1; i <= MaxClients; i++) {
		if (MapVote_IsValidPlayer(i)) {
			g_MapVote_AllowVote[i] = 1;
		}
	}
}

/**
 * Called on map start
 */
public void MapVote_OnMapStart()
{
	ConVar currentGameMode = FindConVar("mp_gamemode");
	currentGameMode.GetString(g_MapVote_gameMode, sizeof(g_MapVote_gameMode));
	g_MapVote_yes = 0;
	g_MapVote_no = 0;
}

/**
 * Called when client is post admin checked
 */
public void MapVote_OnClientPostAdminCheck(int client)
{
	g_MapVote_AllowVote[client] = 1;
}

/**
 * Command: sm_custom
 * Opens the map vote menu
 */
public Action MapVote_Command_MapVote(int client, int args)
{
	if (MapVote_IsValidPlayer(client)) MapVote_DoMapVoteList(client);
	return Plugin_Handled;
}

/**
 * Command: sm_cancelvote
 * Cancels the current vote
 */
public Action MapVote_Command_CancelVote(int client, int args)
{
	CancelVote();
	return Plugin_Handled;
}

/**
 * Display map vote list to client
 */
void MapVote_DoMapVoteList(int client)
{
	if (!MapVote_IsValidPlayer(client)) return;

	if (g_MapVote_AllowVote[client] != 1) {
		PrintToChat(client, "\x04[MAPVOTE]\x01 %t", "MapVote_VoteLimit");
		return;
	}
	g_MapVote_AllowVote[client] = 0;
	CreateTimer(120.0, MapVote_SetAllowVote, client);

	g_MapVote_mapMenu = MapVote_BuildMapMenu(false);
	DisplayMenu(g_MapVote_mapMenu, client, 60);
}

/**
 * Timer to reset vote permission
 */
public Action MapVote_SetAllowVote(Handle timer, int client)
{
	g_MapVote_AllowVote[client] = 1;
	return Plugin_Continue;
}

/**
 * Timer to finish vote
 */
public Action MapVote_FinishVoteTimer(Handle timer, int client)
{
	if (g_MapVote_yes > 0) MapVote_FinishVote();
	return Plugin_Continue;
}

/**
 * Menu handler for map selection
 */
public int MapVote_Handle_MapVoteList(Menu mapMenu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char map[64];
		GetMenuItem(mapMenu, param2, map, sizeof(map));
		Format(g_MapVote_mapname, sizeof(g_MapVote_mapname), "%s", map);

		if (g_MapVote_yes > 0) {
			PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_InProgress");
			return 0;
		}
		CreateTimer(30.0, MapVote_FinishVoteTimer, INVALID_HANDLE);
		g_MapVote_yes = 1;
		g_MapVote_no = 0;
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Started", MapVote_GetName(param1), g_MapVote_mapname);

		MapVote_DoVoteMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete mapMenu;
	}
	return 0;
}

/**
 * Start vote menu
 */
void MapVote_DoVoteMenu(int client)
{
	if (IsVoteInProgress())	{
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_AlreadyInProgress");
		return;
	}

	for (int i=1; i<=MaxClients; i++)
		if ( (MapVote_IsValidPlayer(i)) && (i != client) )
			MapVote_ShowVotePanel(i);
}

/**
 * Finish vote and change map if successful
 */
void MapVote_FinishVote()
{
	PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Finished", g_MapVote_yes, g_MapVote_no);
	if (g_MapVote_yes > g_MapVote_no) {
		PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Changing", g_MapVote_mapname);
		g_MapVote_yes = 0;
		g_MapVote_no = 0;
		ServerCommand("changelevel %s", g_MapVote_mapname);
	}
	else PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_Failed");
}

/**
 * Show vote panel to client
 */
void MapVote_ShowVotePanel(int client)
{
	Panel VoteMapPanel = new Panel();

	char text[255];

	Format(text, sizeof(text), "%T", "MapVote_ChangeMapQuestion", client, g_MapVote_mapname);
	VoteMapPanel.SetTitle(text);

	Format(text, sizeof(text), "%T", "MapVote_Yes", client);
	VoteMapPanel.DrawItem(text);

	Format(text, sizeof(text), "%T", "MapVote_No", client);
	VoteMapPanel.DrawItem(text);

	VoteMapPanel.Send(client, MapVote_VoteMapPanelHandler, 60);
	delete VoteMapPanel;
}

/**
 * Panel handler for vote responses
 */
public int MapVote_VoteMapPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if  (!MapVote_IsValidPlayer(param1)) return 0;

	if ((param2 == 1) || (param2 == 2)) {

		if (param2 == 1) {
			g_MapVote_yes++;
			PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_VotedYes", MapVote_GetName(param1), g_MapVote_yes, g_MapVote_no);
		}
		else if (param2 == 2) {
			g_MapVote_no++;
			PrintToChatAll("\x04[MAPVOTE]\x01 %t", "MapVote_VotedNo", MapVote_GetName(param1), g_MapVote_yes, g_MapVote_no);
		}

		if ( g_MapVote_yes+g_MapVote_no >= MapVote_GetTeamHumanCount(2)+MapVote_GetTeamHumanCount(3) ) {
			MapVote_FinishVote();
		}
	}
	else MapVote_ShowVotePanel(param1);

	return 0;
}

/**
 * Build map menu based on game mode
 */
Menu MapVote_BuildMapMenu(bool adminMode = false)
{
	#pragma unused adminMode
	Menu mapMenu = new Menu(MapVote_Handle_MapVoteList);

	char title[128];
	Format(title, sizeof(title), "%T", "MapVote_ChooseMap", LANG_SERVER);
	mapMenu.SetTitle(title);
	mapMenu.ExitButton = false;

	if(g_MapVote_game_l4d2)
	{
		if(strcmp(g_MapVote_gameMode, "coop", false) == 0)
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
		else if(strcmp(g_MapVote_gameMode, "realism", false) == 0)
		{
			// Official Campaigns only
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
		else if(strcmp(g_MapVote_gameMode, "versus", false) == 0)
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
		else if(strcmp(g_MapVote_gameMode, "teamversus", false) == 0)
		{
			// Official Campaigns only
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
		else if(strcmp(g_MapVote_gameMode, "survival", false) == 0)
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
		else if(strcmp(g_MapVote_gameMode, "scavenge", false) == 0)
		{
			mapMenu.AddItem("c1m4_atrium", "Atrium");
			mapMenu.AddItem("c2m1_highway", "Highway");
			mapMenu.AddItem("c3m1_plankcountry", "Plank Country");
			mapMenu.AddItem("c4m1_milltown_a", "Mill Town 1");
			mapMenu.AddItem("c4m2_sugarmill_a", "Sugar Mill 1");
			mapMenu.AddItem("c5m2_park", "Park");
		}
		else if(strcmp(g_MapVote_gameMode, "teamscavenge", false) == 0)
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
			// Default: All campaigns
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
		// L4D1 maps
		if(strcmp(g_MapVote_gameMode, "coop", false) == 0)
		{
			mapMenu.AddItem("l4d_hospital01_apartment", "Mercy Hospital");
			mapMenu.AddItem("l4d_garage01_alleys", "Crash Course");
			mapMenu.AddItem("l4d_smalltown01_caves", "Death Toll");
			mapMenu.AddItem("l4d_airport01_greenhouse", "Dead Air");
			mapMenu.AddItem("l4d_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(g_MapVote_gameMode, "versus", false) == 0)
		{
			mapMenu.AddItem("l4d_vs_hospital01_apartment", "Mercy Hospital");
			mapMenu.AddItem("l4d_garage01_alleys", "Crash Course");
			mapMenu.AddItem("l4d_vs_smalltown01_caves", "Death Toll");
			mapMenu.AddItem("l4d_vs_airport01_greenhouse", "Dead Air");
			mapMenu.AddItem("l4d_vs_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(g_MapVote_gameMode, "survival", false) == 0)
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
 * Get sanitized player name
 */
char[] MapVote_GetName(int client)
{
	char name[MAX_NAME_LENGTH];
	Format(name, sizeof(name), "noname");
	if ((client <= 0) || (client > MaxClients) || (!IsClientConnected(client))) return name;

	GetClientName(client, name, MAX_NAME_LENGTH);

	// Sanitize name
	ReplaceString(name, sizeof(name), "<?php", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "\\", "");
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), ";", "");
	ReplaceString(name, sizeof(name), "ґ", "");
	ReplaceString(name, sizeof(name), "`", "");

	return name;
}

/**
 * Check if client is a valid player
 */
bool MapVote_IsValidPlayer(int client)
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

/**
 * Get human player count for a team
 */
stock int MapVote_GetTeamHumanCount(int team)
{
	int humans = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if ( (MapVote_IsValidPlayer(i)) && (GetClientTeam(i) == team) )  {
			humans++;
		}
	}

	return humans;
}
