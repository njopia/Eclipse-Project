/*
 * Auto Map Change Module
 * Adapted for Eclipse Management System
 */

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#define _MAPVOTE_MODULE_

//==================================================
// === AUTO MAP CHANGE MODULE ===
// Al terminar una finale (win o loss), elige un mapa
// aleatorio OFICIAL de la lista y cambia directamente.
// !custom (admin): menú con campañas custom para cambio manual.
//==================================================

#define FINALE_MAX_MAPS          16
#define FINALE_MAX_CUSTOM_MAPS   32
#define FINALE_VEHICLE_DELAY     10.0   // Delay tras finale_vehicle_leaving (survivors win)
#define FINALE_LOSS_DELAY         3.0   // Delay tras mission_lost (survivors lose)
#define FINALE_CHANGELEVEL_DELAY  7.0   // Tiempo entre anuncio y changelevel

static char g_MapVote_gameMode[64];
static bool g_MapVote_game_l4d2     = false;
static bool g_bWasFinaleStarted     = false;
static bool g_bFinaleChangePending  = false;
static char g_sNextMap[64];
static char g_sNextMapName[64];

// Official maps — used for auto-change after finale
static char g_sFinaleMapList[FINALE_MAX_MAPS][64];
static char g_sFinaleNameList[FINALE_MAX_MAPS][64];
static int  g_iFinaleMapCount = 0;

// Custom maps — used exclusively by !custom admin command
static char g_sCustomMapList[FINALE_MAX_CUSTOM_MAPS][64];
static char g_sCustomNameList[FINALE_MAX_CUSTOM_MAPS][64];
static int  g_iCustomMapCount = 0;

static Handle g_hFinaleCLTimer       = INVALID_HANDLE;
static Handle g_hFinaleAnnounceTimer = INVALID_HANDLE;

// ==================================================
// === LIFECYCLE ===
// ==================================================

public void MapVote_OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	g_MapVote_game_l4d2 = StrEqual(game_name, "left4dead2", false);

	HookEvent("finale_start",           MapVote_Event_FinaleStart,          EventHookMode_Post);
	HookEvent("finale_vehicle_leaving", MapVote_Event_FinaleVehicleLeaving, EventHookMode_Post);
	HookEvent("mission_lost",           MapVote_Event_MissionLost,          EventHookMode_Post);
}

public void MapVote_OnMapStart()
{
	ConVar hMode = FindConVar("mp_gamemode");
	if (hMode != null)
		hMode.GetString(g_MapVote_gameMode, sizeof(g_MapVote_gameMode));

	g_bWasFinaleStarted    = false;
	g_bFinaleChangePending = false;
	g_sNextMap[0]          = '\0';
	g_sNextMapName[0]      = '\0';

	if (g_hFinaleCLTimer       != INVALID_HANDLE) { KillTimer(g_hFinaleCLTimer);       g_hFinaleCLTimer       = INVALID_HANDLE; }
	if (g_hFinaleAnnounceTimer != INVALID_HANDLE) { KillTimer(g_hFinaleAnnounceTimer); g_hFinaleAnnounceTimer = INVALID_HANDLE; }

	FinaleMap_BuildList();
}

public void MapVote_OnClientPostAdminCheck(int client) {}

// ==================================================
// === FINALE DETECTION ===
// ==================================================

public Action MapVote_Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bWasFinaleStarted = true;
	return Plugin_Continue;
}

public Action MapVote_Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	FinaleMap_TriggerChange(FINALE_VEHICLE_DELAY);
	return Plugin_Continue;
}

public Action MapVote_Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bWasFinaleStarted)
		return Plugin_Continue;

	FinaleMap_TriggerChange(FINALE_LOSS_DELAY);
	return Plugin_Continue;
}

// ==================================================
// === AUTO CHANGE LOGIC ===
// ==================================================

static void FinaleMap_TriggerChange(float initialDelay)
{
	if (g_bFinaleChangePending || g_iFinaleMapCount == 0)
		return;

	g_bFinaleChangePending = true;

	int idx = GetRandomInt(0, g_iFinaleMapCount - 1);
	strcopy(g_sNextMap,     sizeof(g_sNextMap),     g_sFinaleMapList[idx]);
	strcopy(g_sNextMapName, sizeof(g_sNextMapName), g_sFinaleNameList[idx]);

	if (g_hFinaleAnnounceTimer != INVALID_HANDLE)
		KillTimer(g_hFinaleAnnounceTimer);

	g_hFinaleAnnounceTimer = CreateTimer(initialDelay, Timer_FinaleAnnounce);
}

public Action Timer_FinaleAnnounce(Handle timer)
{
	g_hFinaleAnnounceTimer = INVALID_HANDLE;

	PrintToChatAll("\x04[Eclipse]\x01 Próxima campaña: \x05%s\x01 — cambiando en \x04%.0f\x01 segundos.",
		g_sNextMapName, FINALE_CHANGELEVEL_DELAY);

	if (g_hFinaleCLTimer != INVALID_HANDLE)
		KillTimer(g_hFinaleCLTimer);

	g_hFinaleCLTimer = CreateTimer(FINALE_CHANGELEVEL_DELAY, Timer_FinaleChangeLevel);

	return Plugin_Stop;
}

public Action Timer_FinaleChangeLevel(Handle timer)
{
	g_hFinaleCLTimer = INVALID_HANDLE;
	ServerCommand("changelevel %s", g_sNextMap);
	return Plugin_Stop;
}

// ==================================================
// === MAP LISTS ===
// ==================================================

static void FinaleMap_AddOfficial(const char[] mapname, const char[] displayname)
{
	if (g_iFinaleMapCount >= FINALE_MAX_MAPS)
		return;
	strcopy(g_sFinaleMapList[g_iFinaleMapCount],  64, mapname);
	strcopy(g_sFinaleNameList[g_iFinaleMapCount], 64, displayname);
	g_iFinaleMapCount++;
}

static void FinaleMap_AddCustom(const char[] mapname, const char[] displayname)
{
	if (g_iCustomMapCount >= FINALE_MAX_CUSTOM_MAPS)
		return;
	strcopy(g_sCustomMapList[g_iCustomMapCount],  64, mapname);
	strcopy(g_sCustomNameList[g_iCustomMapCount], 64, displayname);
	g_iCustomMapCount++;
}

static void FinaleMap_BuildList()
{
	g_iFinaleMapCount = 0;
	g_iCustomMapCount = 0;

	if (g_MapVote_game_l4d2)
	{
		// --- Official L4D2 Campaigns (auto-change pool) ---
		FinaleMap_AddOfficial("c1m1_hotel",              "Dead Center");
		FinaleMap_AddOfficial("c2m1_highway",            "Dark Carnival");
		FinaleMap_AddOfficial("c3m1_plankcountry",       "Swamp Fever");
		FinaleMap_AddOfficial("c4m1_milltown_a",         "Hard Rain");
		FinaleMap_AddOfficial("c5m1_waterfront",         "The Parish");
		FinaleMap_AddOfficial("c6m1_riverbank",          "The Passing");
		FinaleMap_AddOfficial("c7m1_docks",              "The Sacrifice");
		FinaleMap_AddOfficial("c13m1_alpinecreek",       "Cold Stream");
		FinaleMap_AddOfficial("c14m1_junkyard",          "The Last Stand");

		// --- Custom Campaigns (!custom command only) ---
		FinaleMap_AddCustom("cbm1_lake",               "BloodProof");
		FinaleMap_AddCustom("l4d2_bts01_forest",       "Back to School");
		FinaleMap_AddCustom("bdp_bunker01",            "Buried Deep");
		FinaleMap_AddCustom("cwm1_intro",              "Carried Off");
		FinaleMap_AddCustom("l4d2_daybreak01_hotel",   "Day Break");
		FinaleMap_AddCustom("deathrow01_streets",      "Death Row");
		FinaleMap_AddCustom("dm1_suburbs",             "Devil Mountain");
		FinaleMap_AddCustom("dprm1_milltown_a",        "Downpour");
		FinaleMap_AddCustom("l4d_grave_city",          "Grave Outdoors");
		FinaleMap_AddCustom("l4d2_stadium1_apartment", "Suicide Blitz 2");
		FinaleMap_AddCustom("l4d_lastnight01_arrival", "Last Night");
		FinaleMap_AddCustom("l4d2_timemachine_01",     "Time Machine");
	}
	else
	{
		// --- Official L4D1 Campaigns (auto-change pool) ---
		FinaleMap_AddOfficial("l4d_hospital01_apartment", "Mercy Hospital");
		FinaleMap_AddOfficial("l4d_garage01_alleys",      "Crash Course");
		FinaleMap_AddOfficial("l4d_smalltown01_caves",    "Death Toll");
		FinaleMap_AddOfficial("l4d_airport01_greenhouse", "Dead Air");
		FinaleMap_AddOfficial("l4d_farm01_hilltop",       "Blood Harvest");
	}
}

// ==================================================
// === ADMIN COMMAND (!custom — custom maps only) ===
// ==================================================

public Action MapVote_Cmd_AdminMapChange(int client, int args)
{
	Menu menu = new Menu(MapVote_AdminMenuHandler);
	menu.SetTitle("Cambiar a Campaña Custom");
	menu.ExitButton = true;

	for (int i = 0; i < g_iCustomMapCount; i++)
	{
		char itemInfo[8];
		IntToString(i, itemInfo, sizeof(itemInfo));
		menu.AddItem(itemInfo, g_sCustomNameList[i]);
	}

	menu.Display(client, 60);
	return Plugin_Handled;
}

public int MapVote_AdminMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		int idx = StringToInt(info);

		if (idx < 0 || idx >= g_iCustomMapCount)
			return 0;

		PrintToChatAll("\x04[Eclipse]\x01 Admin cambia a: \x05%s\x01", g_sCustomNameList[idx]);
		ServerCommand("changelevel %s", g_sCustomMapList[idx]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}
