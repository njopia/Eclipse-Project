#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#pragma newdecls required
#pragma semicolon 1
/////// DATABASE MANAGEMENT SYSTEM ///////////
#define EMS_MAIN_FILE	 // EMS_MAIN_FILE define main file as the current core
#define ADMIN_DB_NAME	"admins"
#define PLAYERS_DB_NAME "players"
#tryinclude "utils/database.utils.sp"
//////////////////////////////////////////////

/////// HELPERS /////////////////////////////
#tryinclude "helpers/commons.helpers.sp"
#tryinclude "helpers/entities.helpers.sp"
#tryinclude "helpers/commands.helpers.sp"
#tryinclude "helpers/sdks.helpers.sp"
#tryinclude "helpers/beacons.helpers.sp"
//////////////////////////////////////////////
#tryinclude "utils/includes/precache.inc"
/////// BUY MENU /////////////////////////////
#tryinclude "modules/buy module/buy-menu.module.sp"
//////////////////////////////////////////////

/////// CURRENCY EVENTS MODULE ///////////////
#tryinclude "modules/currency/currency-events.module.sp"
#tryinclude "modules/currency/currency-advanced-events.module.sp"
#tryinclude "modules/currency/currency-stats.module.sp"
//////////////////////////////////////////////

/////// SERVER MANAGEMENT UTILS ////////////
#tryinclude "utils/server-management.utils.sp"
//////////////////////////////////////////////

/////// LEVELING SYSTEM MODULE ///////////////
#define LEVELING_DB_NAME "players"  // Reutiliza la BD de players
#tryinclude "modules/leveling/leveling-system.module.sp"
#tryinclude "modules/leveling/leveling-xp-events.module.sp"
#tryinclude "modules/leveling/leveling-rewards.module.sp"
#tryinclude "modules/leveling/leveling-ui.module.sp"
#tryinclude "modules/leveling/leveling-info.module.sp"
//////////////////////////////////////////////

/////// GAME MODES MODULE ///////////////////
#tryinclude "modules/modes/bloodmoon.module.sp"
//////////////////////////////////////////////

#define LOG_PATH "logs\\Eclipse_Management_System.log"
static char logfilepath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= "Eclipse management system",
	author		= "Natan Jopia",
	description = "database management system module",
	version		= "1.0.0",
	url			= "https://gitlab.com/sourcepawn1/sm-win"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead2, Engine_Left4Dead:
			return APLRes_Success;
		default:
			return APLRes_Failure;
	}
}

public void OnPluginStart()
{
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), LOG_PATH);
	LogToFile(logfilepath, "|               PLUGIN START                |");

	HandleSdk();
	if (checkDBFile(PLAYERS_DB_NAME))
	{
		doSqlConnectionPlayers(PLAYERS_DB_NAME);  // Usar handle separado para players
	}
	if (checkDBFile(ADMIN_DB_NAME))
	{
		doSqlConnection(ADMIN_DB_NAME);  // Handle para admins
	}
	buyMenuOnPluginStart();
	AdminMoney_OnPluginStart();
	CurrencyEvents_OnPluginStart();

	// Inicializar sistema de leveling
	Leveling_OnPluginStart();
	LevelingXPEvents_OnPluginStart();
	LevelingRewards_OnPluginStart();
	LevelingUI_OnPluginStart();
	LevelingInfo_OnPluginStart();

	// Inicializar módulos de modos de juego
	Bloodmoon_OnPluginStart();

	RegConsoleCmd("buy", Cmd_Buy);
	RegConsoleCmd("sm_buy", Cmd_Buy);
	RegConsoleCmd("sm_givemoney", Command_GiveMoneySub);

	RegAdminCmd("rp", Cmd_Reload_Plugins, ADMFLAG_ROOT);
	RegAdminCmd("rt", Cmd_Reload_Translations, ADMFLAG_ROOT);
	g_cvarDebug = CreateConVar("sm_spawnammo_debug", "0", "Activa debug verboso (0/1).", 0, true, 0.0, true, 1.0);
	LoadTranslations("eclipse.phrases");
	PrecacheAll();
}

public void OnMapStart()
{
	LogToFile(logfilepath, "|               MAP START                   |");

	// Limpiar todos los timers de mapas anteriores
	CleanupAllTimers();

	DelegateBuyMenuModule();
	DefenseGrid_OnMapStart();
	Bloodmoon_OnMapStart();
#if defined _EMS_PRECACHE_MODULE_
	EMS_Precache_OnMapStart();
#endif
}

public void OnMapEnd()
{
	LogToFile(logfilepath, "|               MAP END                     |");

	// Limpiar todos los timers antes de cambiar de mapa
	CleanupAllTimers();
}

public void OnClientPutInServer(int client)
{
	// Hook de daño para habilidades activas (ahora en buy module)
	BuyMenu_OnClientPutInServer(client);

	// Hook de Bloodmoon
	Bloodmoon_OnClientPutInServer(client);

	// Inicializar UI de leveling
	LevelingUI_OnClientConnect(client);
}

public void OnClientPostAdminCheck(int client)
{
	// Cargar datos de leveling cuando el cliente se conecta
	Leveling_OnClientPostAdminCheck(client);

	// Inicializar Defense Grid
	DefenseGrid_OnClientConnect(client);

	// Inicializar Ion Cannon
	IonCannon_OnClientPutInServer(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Manejar doble salto del sistema de leveling
	LevelingRewards_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);

	// Manejar weapon fire para habilidades activas (Berserker swing speed)
	if (buttons & IN_ATTACK)
	{
		Berserker_OnWeaponSwing(client);
	}

	return Plugin_Continue;
}

public void PrecacheAll()
{
#if defined _EMS_PRECACHE_MODULE_
	EMS_Precache_Init();
	// (opcional) activar logs:
	//EMS_Precache_SetDebug(true);
#endif
}

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
 * Limpia todos los timers del sistema al cambiar de mapa
 * Esta función debe ser llamada en OnMapStart() y OnMapEnd()
 */
stock void CleanupAllTimers()
{
	LogToFile(logfilepath, "[CLEANUP] Iniciando limpieza de timers del sistema...");

	// Team Heal timers
	CleanupTeamHealTimers();

	// Team Speed Boost timers
	CleanupTeamSpeedBoostTimers();

	// Buy Menu timers (incluyendo timers de actualización dinámica)
	CleanupBuyMenuTimers();

	// Resetear estado de los jugadores
	ResetAllPlayersState();

	LogToFile(logfilepath, "[CLEANUP] Limpieza de timers completada");
}

/**
 * Limpia timers asociados al Buy Menu
 */
stock void CleanupBuyMenuTimers()
{
	LogToFile(logfilepath, "[CLEANUP] Limpiando Buy Menu timers...");
	// El TimerUpdate1 continúa en el nuevo mapa (TIMER_REPEAT)
	// No es necesario matarlo, simplemente continúa funcionando
}

/**
 * Resetea el estado de todos los jugadores (cooldowns, variables, etc.)
 */
stock void ResetAllPlayersState()
{
	LogToFile(logfilepath, "[CLEANUP] Reseteando estado de todos los jugadores...");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			// Resetear cooldowns de Team Heal
			ResetTeamHealCooldown(i);

			// Resetear cooldowns de Team Speed Boost
			ResetTeamSpeedBoostCooldown(i);
		}
	}
}
