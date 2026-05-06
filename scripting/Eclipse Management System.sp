#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <left4dhooks>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1

//==================================================
// === DATABASE MANAGEMENT SYSTEM ===
//==================================================
#define EMS_MAIN_FILE	 // EMS_MAIN_FILE define main file as the current core
#define ADMIN_DB_NAME	"admins"
#define PLAYERS_DB_NAME "players"
#define DB_HUD_MESSAGES PLAYERS_DB_NAME
#tryinclude "utils/database.utils.sp"

#define PLUGIN_VERSION "1.0.0"

//==================================================
// === HELPERS ===
//==================================================
#tryinclude "helpers/commons.helpers.sp"
#tryinclude "helpers/entities.helpers.sp"
#tryinclude "helpers/sdks.helpers.sp"
#tryinclude "helpers/beacons.helpers.sp"

//==================================================
// === PRECACHE UTILITIES ===
//==================================================
#tryinclude "utils/includes/precache.inc"

//==================================================
// === LEVELING SYSTEM MODULE ===
// IMPORTANTE: Se incluye ANTES del Buy Menu porque
// define g_bShoulderCannon_AutoEquip usado en shoulder-cannon.feature.sp
//==================================================
#define LEVELING_DB_NAME "players"	  // Reutiliza la BD de players
#tryinclude "modules/leveling/leveling-system.module.sp"
#tryinclude "modules/leveling/leveling-rewards.module.sp"
#tryinclude "modules/leveling/leveling-ui.module.sp"
#tryinclude "modules/leveling/leveling-info.module.sp"

//==================================================
// === ABILITIES SYSTEM MODULE ===
// Sistema de habilidades desbloqueables por nivel
// No requieren currency, se activan automáticamente
//==================================================
#tryinclude "modules/abilities/abilities-system.module.sp"
#tryinclude "modules/abilities/ability-detectzombie.sp"
#tryinclude "modules/abilities/ability-berserker.sp"
#tryinclude "modules/abilities/ability-acidbath.sp"
#tryinclude "modules/abilities/ability-lifestealer.sp"
#tryinclude "modules/abilities/ability-flameshield.sp"
#tryinclude "modules/abilities/ability-nightcrawler.sp"
#tryinclude "modules/abilities/ability-rapidfire.sp"
#tryinclude "modules/abilities/ability-chainsaw.sp"
#tryinclude "modules/abilities/ability-heatseeker.sp"
#tryinclude "modules/abilities/ability-speedfreak.sp"
#tryinclude "modules/abilities/ability-healingaura.sp"
#tryinclude "modules/abilities/ability-shouldercannon.sp"
#tryinclude "modules/abilities/ability-soulshield.sp"
#tryinclude "modules/abilities/ability-polymorph.sp"
#tryinclude "modules/abilities/ability-instagib.sp"

//==================================================
// === BUY MENU MODULE ===
//==================================================
#tryinclude "modules/buy module/buy-menu.module.sp"

//==================================================
// === CURRENCY STATS MODULE ===
// Mantener para estadísticas
//==================================================
#tryinclude "modules/currency/currency-stats.module.sp"

//==================================================
// === SERVER MANAGEMENT UTILITIES ===
//==================================================
#tryinclude "utils/server-management.utils.sp"

//==================================================
// === ECLIPSE POINTS UNIFIED MODULE ===
//==================================================
#include "modules/eclipse-points-unified.module.sp"

//==================================================
// === GAME MODES MODULE ===
//==================================================
#tryinclude "modules/modes/difficulty-orchestrator.module.sp"
#tryinclude "modules/modes/bloodmoon.module.sp"
#tryinclude "modules/modes/hell.module.sp"
#tryinclude "modules/modes/inferno.module.sp"
#tryinclude "modules/modes/cow-level.module.sp"

//==================================================
// === FRAGS SYSTEM MODULE ===
//==================================================
#include "modules/frags-system.module.sp"

//==================================================
// === PLAYERS LIST MODULE ===
//==================================================
#tryinclude "modules/players-list.module.sp"

//==================================================
// === SERVER MANAGEMENT SYSTEM CORE ===
//==================================================
#include "modules/management/afk-join.sp"
#tryinclude "modules/management/scripted-hud.module.sp"
#tryinclude "modules/management/lang.module.sp"
#tryinclude "modules/management/mapvote.module.sp"
#tryinclude "modules/management/admin-manager.sp"

//==================================================
// === MAIN MENU MODULE ===
//==================================================
#tryinclude "modules/main-menu.module.sp"

//==================================================
// === COMMANDS REGISTRATION ===
//==================================================
#tryinclude "helpers/commands.helpers.sp"

//==================================================
// === GLOBAL VARIABLES ===
//==================================================

// Logging
#define LOG_PATH "logs\\Eclipse_Management_System.log"
static char logfilepath[PLATFORM_MAX_PATH];

// Snow system
ConVar		cvar_preciptype;
ConVar		cvar_density;
ConVar		cvar_color;
ConVar		cvar_render;
char		sMap[96];

// Dynamic hostname
#define UPDATE_INTERVAL 5.0					// Seconds between updates
#define BASE_HOSTNAME	"[US-EAST] Coop"	// Base server name
Handle g_hTimer = INVALID_HANDLE;

//==================================================
// === PLUGIN INFO ===
//==================================================
public Plugin myinfo =
{
	name		= "Eclipse management system",
	author		= "Natan Jopia",
	description = "database management system module",
	version		= PLUGIN_VERSION,
	url			= "https://gitlab.com/sourcepawn1/sm-win"
};

//==================================================
// === PLUGIN LIBRARY & NATIVES ===
//==================================================

/**
 * Called before plugin starts
 * Creates natives for other plugins to access Eclipse system data
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead2, Engine_Left4Dead:
		{
			// Create natives for other plugins
			CreateNative("EMS_GetPlayerLevel", Native_GetPlayerLevel);
			CreateNative("EMS_GetPlayerCurrentXP", Native_GetPlayerCurrentXP);
			CreateNative("EMS_GetPlayerTotalXP", Native_GetPlayerTotalXP);
			CreateNative("EMS_GetXPForNextLevel", Native_GetXPForNextLevel);
			CreateNative("EMS_GetLevelProgress", Native_GetLevelProgress);
			CreateNative("EMS_GetPlayerCurrency", Native_GetPlayerCurrency);

			RegPluginLibrary("eclipse_ms");

			return APLRes_Success;
		}
		default:
			return APLRes_Failure;
	}
}

//==================================================
// === NATIVES IMPLEMENTATION ===
//==================================================

/**
 * Native: Get player's current level
 * @param client Client index
 * @return Current level of the player
 */
public int Native_GetPlayerLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetPlayerLevel(client);
}

/**
 * Native: Get player's current XP in their level
 * @param client Client index
 * @return Current XP in the current level
 */
public int Native_GetPlayerCurrentXP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetPlayerCurrentXP(client);
}

/**
 * Native: Get player's total accumulated XP
 * @param client Client index
 * @return Total XP accumulated
 */
public int Native_GetPlayerTotalXP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetPlayerTotalXP(client);
}

/**
 * Native: Get XP required for next level
 * @param client Client index
 * @return XP required for next level
 */
public int Native_GetXPForNextLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetXPRequiredForNextLevel(client);
}

/**
 * Native: Get level progress as percentage (0-100)
 * @param client Client index
 * @return Progress percentage
 */
public int Native_GetLevelProgress(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetLevelProgress(client);
}

/**
 * Native: Get player's currency/points
 * NOTA: Currency persiste durante la sesión (se mantiene entre mapas, se resetea al desconectar)
 * @param client Client index
 * @return Player's currency amount (session-persistent, not saved in DB)
 */
public int Native_GetPlayerCurrency(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return 0;

	// Currency persiste durante la sesión
	return GetPlayerCurrency(client);
}

//==================================================
// === PLUGIN LIFECYCLE ===
//==================================================

/**
 * Called when the plugin starts
 * Initializes all modules and systems
 */
public void OnPluginStart()
{
	// Initialize logging
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), LOG_PATH);
	LogToFile(logfilepath, "|               PLUGIN START                |");

	// Initialize SDK hooks
	// HandleSdk();

	// Initialize database connections
	if (checkDBFile(PLAYERS_DB_NAME))
	{
		doSqlConnectionPlayers(PLAYERS_DB_NAME);	// Separate handle for players
	}
	if (checkDBFile(ADMIN_DB_NAME))
	{
		doSqlConnection(ADMIN_DB_NAME);	   // Handle for admins
	}
	if (checkDBFile(DB_HUD_MESSAGES))
	{
		doSqlConnection(DB_HUD_MESSAGES);	 // Handle for HUD messages
	}

	// Initialize buy menu
	buyMenuOnPluginStart();
	AdminMoney_OnPluginStart();

	// Initialize leveling system (MUST be BEFORE unified points system)
	Leveling_OnPluginStart();
	LevelingRewards_OnPluginStart();
	LevelingUI_OnPluginStart();
	LevelingInfo_OnPluginStart();

	// Initialize abilities system (AFTER leveling system)
	Abilities_OnPluginStart();

	// Initialize unified points system
	EclipsePointsUnified_OnPluginStart();

	// Initialize game mode orchestrator (MUST be before individual modes)
	DifficultyOrchestrator_OnPluginStart();

	// Initialize game mode modules
	Bloodmoon_OnPluginStart();
	Hell_OnPluginStart();
	Inferno_OnPluginStart();
	CowLevel_OnPluginStart();

	// Initialize frags system
	FragsSystem_OnPluginStart();

	// Initialize players list system
	PlayersList_OnPluginStart();

	// Initialize server management system
	Afk_Join_OnPluginStart();
	AdminManager_OnPluginStart();

	// Initialize HUD system
#if defined _SCRIPTED_HUD_MODULE_
	ScriptedHUD_OnPluginStart();
#endif

	// Initialize language system
	Language_OnPluginStart();

	// Initialize map vote system
#if defined _MAPVOTE_MODULE_
	MapVote_OnPluginStart();
#endif

	// Initialize main menu
	MainMenu_OnPluginStart();

	// Centralized Command Registration
	RegisterEMSCommands();

	// Load translations
	LoadTranslations("eclipse.phrases");

	// Hook events
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	// Snow system ConVars
	cvar_preciptype = CreateConVar("snow_type", "3", "Type of the precipitation (https://developer.valvesoftware.com/wiki/Func_precipitation)");
	cvar_density	= CreateConVar("snow_density", "75", "Density of the precipitation");
	cvar_color		= CreateConVar("snow_color", "255 255 255", "Color of the precipitation");
	cvar_render		= CreateConVar("snow_renderamt", "5", "Render of the precipitation");

	// Precache all resources
	PrecacheAll();

	// Initialize dynamic hostname timer
	if (g_hTimer != INVALID_HANDLE)
		CloseHandle(g_hTimer);
	g_hTimer = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHostname, _, TIMER_REPEAT);
}

/**
 * Called when map starts
 * Initializes map-specific systems and resets states
 */
public void OnMapStart()
{
	LogToFile(logfilepath, "|               MAP START                   |");

	// Clean up all timers from previous map
	CleanupAllTimers();

	// CRITICAL: Force cleanup any residual fog controllers
	ForceCleanupAllFogControllers();

	// Reset unified points system tracking flags
	EclipsePointsUnified_OnMapStart();

	// Reset abilities system
	Abilities_OnMapStart();

	// Reset frags system
	FragsSystem_OnMapStart();

	// Reset map vote system
#if defined _MAPVOTE_MODULE_
	MapVote_OnMapStart();
#endif

	// Initialize buy menu modules
	DelegateBuyMenuModule();
	DefenseGrid_OnMapStart();

	// Initialize difficulty orchestrator (MUST be before individual modes)
	DifficultyOrchestrator_OnMapStart();

	Bloodmoon_OnMapStart();
	Hell_OnMapStart();
	Inferno_OnMapStart();
	CowLevel_OnMapStart();
	NuclearStrike_OnMapStart();

	// Initialize HUD
#if defined _SCRIPTED_HUD_MODULE_
	ScriptedHUD_OnMapStart();
#endif

	// Precache resources
#if defined _EMS_PRECACHE_MODULE_
	EMS_Precache_OnMapStart();
#endif

	// Precache current map
	GetCurrentMap(sMap, 64);
	Format(sMap, sizeof(sMap), "maps/%s.bsp", sMap);
	PrecacheModel(sMap, true);

	// Initialize leveling system
	Leveling_OnMapStart();
}

/**
 * Called when map ends
 * Cleanup before map change
 */
public void OnMapEnd()
{
	LogToFile(logfilepath, "|               MAP END                     |");

	// CRITICAL: Force cleanup all fog controllers before map change
	ForceCleanupAllFogControllers();

	// Cleanup game modes
	Bloodmoon_OnMapEnd();
	Hell_OnMapEnd();
	Inferno_OnMapEnd();
	CowLevel_OnMapEnd();

	// Cleanup HUD
#if defined _SCRIPTED_HUD_MODULE_
	ScriptedHUD_OnMapEnd();
#endif

	// Cleanup leveling system
	Leveling_OnMapEnd();

	// Clean up all timers before map change
	CleanupAllTimers();
}

/**
 * Called when configs are executed
 * Initialize configuration-dependent systems
 */
public void OnConfigsExecuted()
{
	// Initialize HUD configurations
#if defined _SCRIPTED_HUD_MODULE_
	ScriptedHUD_OnConfigsExecuted();
#endif

	// Initialize leveling configurations
	Leveling_OnConfigsExecuted();
}

/**
 * Called when client connects to server
 * Initialize client-specific systems
 */
public void OnClientPutInServer(int client)
{
	// Hook damage for active abilities (in buy module)
	BuyMenu_OnClientPutInServer(client);

	// Initialize Shoulder Cannon defaults
	ShoulderCannon_InitializeDefaults(client);

	// Hook for Bloodmoon
	Bloodmoon_OnClientPutInServer(client);
	Hell_OnClientPutInServer(client);
	Inferno_OnClientPutInServer(client);

	// Hook for Cow Level
	CowLevel_OnClientPutInServer(client);

	// Initialize leveling UI
	LevelingUI_OnClientConnect(client);

	// Initialize frags system
	FragsSystem_OnClientPutInServer(client);
}

/**
 * Called after client is admin checked
 * Load client data from database
 */
public void OnClientPostAdminCheck(int client)
{
	// Load leveling data when client connects
	Leveling_OnClientPostAdminCheck(client);

	// Initialize Defense Grid
	DefenseGrid_OnClientConnect(client);

	// Initialize Ion Cannon
	IonCannon_OnClientPutInServer(client);

	// Apply language preferences
	Language_OnClientPostAdminCheck(client);

	// Initialize map vote system
#if defined _MAPVOTE_MODULE_
	MapVote_OnClientPostAdminCheck(client);
#endif

	// Initialize Trophy System
	Leveling_OnClientPostAdminCheck(client);
}

/**
 * Called when client cookies are cached
 * Load client preferences
 */
public void OnClientCookiesCached(int client)
{
	// Load language preferences from cookies
	Language_OnClientCookiesCached(client);
}

/**
 * Called on every player command
 * Handle player actions like double jump and abilities
 */
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Handle double jump from leveling system
	LevelingRewards_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);

	// Handle ability-specific controls
	Nightcrawler_OnPlayerRunCmd(client, buttons);
	HeatSeeker_OnPlayerRunCmd(client, buttons);

	return Plugin_Continue;
}

/**
 * Precache all resources
 */
public void PrecacheAll()
{
#if defined _EMS_PRECACHE_MODULE_
	EMS_Precache_Init();
	// (optional) enable logs:
	// EMS_Precache_SetDebug(true);
#endif
}

/**
 * Called when plugin unloads
 * Cleanup resources
 */
public void OnPluginEnd()
{
	Leveling_OnPluginEnd();
}

/**
 * Command: Reload precache
 * Admin command to reload all precached resources
 */
public Action EMS_CmdPrecacheReload(int client, int args)
{
#if defined _EMS_PRECACHE_MODULE_
	EMS_Precache_DoAll();
	if (client > 0) PrintToChat(client, "[EMS] Precache recargado.");
#endif
	return Plugin_Handled;
}

//==================================================
// === CENTRALIZED TIMER CLEANUP SYSTEM ===
//==================================================

/**
 * Cleans up all system timers when changing maps
 * This function should be called in OnMapStart() and OnMapEnd()
 */
stock void CleanupAllTimers()
{
	LogToFile(logfilepath, "[CLEANUP] Iniciando limpieza de timers del sistema...");

	// Clean up Team Heal timers
	CleanupTeamHealTimers();

	// Clean up Team Speed Boost timers
	CleanupTeamSpeedBoostTimers();

	// Clean up Nuclear Strike timers
	CleanupNuclearStrikeTimers();

	// Clean up Buy Menu timers (including dynamic update timers)
	CleanupBuyMenuTimers();

	// Reset all players state
	ResetAllPlayersState();

	LogToFile(logfilepath, "[CLEANUP] Limpieza de timers completada");
}

/**
 * Cleans up timers associated with Buy Menu
 */
stock void CleanupBuyMenuTimers()
{
	LogToFile(logfilepath, "[CLEANUP] Limpiando Buy Menu timers...");
	// TimerUpdate1 continues in the new map (TIMER_REPEAT)
	// No need to kill it, it simply continues running
}

/**
 * Resets all players state (cooldowns, variables, etc.)
 */
stock void ResetPlayerCooldowns(int client)
{
	ResetTeamHealCooldown(client);
	ResetTeamSpeedBoostCooldown(client);
	ResetFireYellCooldown(client);
	ResetPowerYellCooldown(client);
	DefenseGrid_ResetCooldown(client);
	IonCannon_ResetCooldown(client);
	AmmoPile_ResetCooldown(client);
}

stock void ResetAllPlayersState()
{
	LogToFile(logfilepath, "[CLEANUP] Reseteando estado de todos los jugadores...");
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			ResetPlayerCooldowns(i);
	LogToFile(logfilepath, "[CLEANUP] Reseteo de cooldowns completado");
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
        ResetPlayerCooldowns(client);
}

//==================================================
// === EMERGENCY FADE PURGE SYSTEM ===
//==================================================

/**
 * Emergency command to purge all screen fades
 * Fixes white screen overlay issues caused by persistent fades
 */
public Action Cmd_ClearFade(int client, int args)
{
	// FFADE_PURGE ya está definido en difficulty-orchestrator.module.sp
	// Purgar fades de todos los jugadores
	int affectedPlayers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		Handle hFade = StartMessageOne("Fade", i);
		if (hFade != null)
		{
			BfWriteShort(hFade, 0);				 // duration
			BfWriteShort(hFade, 0);				 // hold time
			BfWriteShort(hFade, FFADE_PURGE);	 // flags
			BfWriteByte(hFade, 0);				 // r
			BfWriteByte(hFade, 0);				 // g
			BfWriteByte(hFade, 0);				 // b
			BfWriteByte(hFade, 0);				 // alpha
			EndMessage();
			affectedPlayers++;
		}
	}

	// Mensaje de confirmación
	if (client > 0)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Screen fades purgados para \x05%d\x01 jugadores", affectedPlayers);
	}

	PrintToServer("[Eclipse] Screen fades purgados por admin. Jugadores afectados: %d", affectedPlayers);
	LogToFile(logfilepath, "[FADE PURGE] Admin %N purgó screen fades. Jugadores: %d", client > 0 ? client : 0, affectedPlayers);

	return Plugin_Handled;
}

/**
 * Emergency command to remove all fog controllers
 * Fixes white screen caused by fog configuration issues
 */
public Action Cmd_ClearFog(int client, int args)
{
	int removedCount = 0;
	int entity		 = -1;

	// Find and remove all env_fog_controller entities
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "TurnOff");
			AcceptEntityInput(entity, "Kill");
			removedCount++;
		}
	}

	// Also try to find and remove fog_volume entities
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
			removedCount++;
		}
	}

	// Reset light style to normal
	SetLightStyle(0, "m");

	// Mensaje de confirmación
	if (client > 0)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Fog controllers eliminados: \x05%d\x01. Light style restaurado.", removedCount);
	}

	PrintToServer("[Eclipse] Fog controllers eliminados por admin. Total: %d", removedCount);
	LogToFile(logfilepath, "[FOG CLEAR] Admin %N eliminó %d fog controllers", client > 0 ? client : 0, removedCount);

	return Plugin_Handled;
}

/**
 * Combined emergency command to fix white screen
 * Clears both fades and fog controllers
 */
public Action Cmd_FixWhiteScreen(int client, int args)
{
	PrintToServer("[Eclipse] EMERGENCY FIX: Fixing white screen...");

	if (client > 0)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Aplicando solución de emergencia para pantalla blanca...");
	}

	// Step 1: Clear all fades
	int affectedPlayers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		Handle hFade = StartMessageOne("Fade", i);
		if (hFade != null)
		{
			BfWriteShort(hFade, 0);
			BfWriteShort(hFade, 0);
			BfWriteShort(hFade, FFADE_PURGE);
			BfWriteByte(hFade, 0);
			BfWriteByte(hFade, 0);
			BfWriteByte(hFade, 0);
			BfWriteByte(hFade, 0);
			EndMessage();
			affectedPlayers++;
		}
	}

	// Step 2: Remove all fog controllers
	int removedFog = 0;
	int entity	   = -1;
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "TurnOff");
			AcceptEntityInput(entity, "Kill");
			removedFog++;
		}
	}

	entity = -1;
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
			removedFog++;
		}
	}

	// Step 3: Reset light style
	SetLightStyle(0, "m");

	// Results
	if (client > 0)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solución aplicada:");
		PrintToChat(client, " \x05→\x01 Screen fades purgados: \x05%d\x01 jugadores", affectedPlayers);
		PrintToChat(client, " \x05→\x01 Fog controllers eliminados: \x05%d", removedFog);
		PrintToChat(client, " \x05→\x01 Light style restaurado a normal");
	}

	PrintToServer("[Eclipse] WHITE SCREEN FIX COMPLETE - Fades: %d players, Fog: %d entities", affectedPlayers, removedFog);
	LogToFile(logfilepath, "[WHITE SCREEN FIX] Admin %N - Fades: %d, Fog: %d", client > 0 ? client : 0, affectedPlayers, removedFog);

	return Plugin_Handled;
}

/**
 * Force cleanup all fog controllers
 * Called on map start/end to prevent fog controller accumulation
 */
void ForceCleanupAllFogControllers()
{
	int removedCount = 0;
	int entity		 = -1;

	// Remove all env_fog_controller entities
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "TurnOff");
			AcceptEntityInput(entity, "Kill");
			removedCount++;
		}
	}

	// Remove all fog_volume entities
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
			removedCount++;
		}
	}

	if (removedCount > 0)
	{
		LogToFile(logfilepath, "[FOG CLEANUP] Removed %d residual fog controllers", removedCount);
		SetLightStyle(0, "m");	  // Reset light style
	}
}

//==================================================
// === SNOW SYSTEM ===
//==================================================

/**
 * Event: Round Start
 * Triggers snow creation
 */
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, CreateSnowFall);
}

/**
 * Creates snowfall effect on the map
 * @return Plugin_Continue
 */
public Action CreateSnowFall(Handle timer)
{
	// Remove any existing precipitation entities
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "func_precipitation")) != -1)
		AcceptEntityInput(iEnt, "Kill");

	// Create new precipitation entity
	iEnt = CreateEntityByName("func_precipitation");

	if (iEnt != -1)
	{
		char  preciptype[5], density[5], color[16], render[5];
		float vMins[3], vMax[3], vBuff[3];

		// Get ConVar values
		cvar_preciptype.GetString(preciptype, sizeof(preciptype));
		cvar_density.GetString(density, sizeof(density));
		cvar_color.GetString(color, sizeof(color));
		cvar_render.GetString(render, sizeof(render));

		// Set entity properties
		DispatchKeyValue(iEnt, "model", sMap);
		DispatchKeyValue(iEnt, "preciptype", preciptype);
		DispatchKeyValue(iEnt, "renderamt", render);
		DispatchKeyValue(iEnt, "density", density);
		DispatchKeyValue(iEnt, "rendercolor", color);

		// Set world bounds
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMax);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);

		SetEntPropVector(iEnt, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", vMax);

		// Calculate center position
		vBuff[0] = vMins[0] + vMax[0];
		vBuff[1] = vMins[1] + vMax[1];
		vBuff[2] = vMins[2] + vMax[2];

		// Spawn entity
		TeleportEntity(iEnt, vBuff, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
	}
	return Plugin_Continue;
}

//==================================================
// === DYNAMIC HOSTNAME SYSTEM ===
//==================================================

/**
 * Timer: Update dynamic hostname
 * Updates server hostname with current player count
 * @return Plugin_Continue
 */
public Action Timer_UpdateHostname(Handle timer)
{
	int maxplayers = GetMaxHumanPlayers();
	int humans	   = 0;

	// Count human players
	for (int i = 1; i <= maxplayers; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i))
			continue;
		else
			humans++;
	}

	// Update hostname with player count
	char newHostname[128];
	Format(newHostname, sizeof(newHostname), "%s [%d/%d] - Eclipse BETA Release", BASE_HOSTNAME, humans, maxplayers);
	SetConVarString(FindConVar("hostname"), newHostname);

	return Plugin_Continue;
}
