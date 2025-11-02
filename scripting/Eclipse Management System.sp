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

/////// CURRENCY STATS MODULE (mantener para estadísticas) ///
#tryinclude "modules/currency/currency-stats.module.sp"
//////////////////////////////////////////////

/////// SERVER MANAGEMENT UTILS ////////////
#tryinclude "utils/server-management.utils.sp"
//////////////////////////////////////////////

/////// LEVELING SYSTEM MODULE ///////////////
#define LEVELING_DB_NAME "players"	  // Reutiliza la BD de players
#tryinclude "modules/leveling/leveling-system.module.sp"
#tryinclude "modules/leveling/leveling-rewards.module.sp"
#tryinclude "modules/leveling/leveling-ui.module.sp"
#tryinclude "modules/leveling/leveling-info.module.sp"
//////////////////////////////////////////////

/////// ECLIPSE POINTS UNIFIED MODULE ///////////////
#include "modules/eclipse-points-unified.module.sp"
//////////////////////////////////////////////

/////// GAME MODES MODULE ///////////////////
#tryinclude "modules/modes/bloodmoon.module.sp"
//////////////////////////////////////////////

/////// FRAGS SYSTEM MODULE ///////////////////
#include "modules/frags-system.module.sp"
//////////////////////////////////////////////

/////// SERVER MANAGEMENT SYSTEM CORE /////////
#include "modules/management/afk-join.sp"

#define LOG_PATH "logs\\Eclipse_Management_System.log"
static char logfilepath[PLATFORM_MAX_PATH];

// Snow
ConVar		cvar_preciptype;
ConVar		cvar_density;
ConVar		cvar_color;
ConVar		cvar_render;
char		sMap[96];

public Plugin myinfo =
{
	name		= "Eclipse management system",
	author		= "Natan Jopia",
	description = "database management system module",
	version		= "1.0.0",
	url			= "https://gitlab.com/sourcepawn1/sm-win"
};

// Agregar esto después de la línea 66 (después de AskPluginLoad2)
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead2, Engine_Left4Dead:
		{
			// ===== CREAR NATIVES PARA OTROS PLUGINS =====
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
 * Native: Obtiene el nivel actual del jugador
 */
public int Native_GetPlayerLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetPlayerLevel(client);
}

/**
 * Native: Obtiene el XP actual del jugador en su nivel
 */
public int Native_GetPlayerCurrentXP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetPlayerCurrentXP(client);
}

/**
 * Native: Obtiene el XP total acumulado del jugador
 */
public int Native_GetPlayerTotalXP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetPlayerTotalXP(client);
}

/**
 * Native: Obtiene el XP requerido para el siguiente nivel
 */
public int Native_GetXPForNextLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetXPRequiredForNextLevel(client);
}

/**
 * Native: Obtiene el progreso en porcentaje (0-100)
 */
public int Native_GetLevelProgress(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return Leveling_GetLevelProgress(client);
}

/**
 * Native: Obtiene la moneda/puntos del jugador
 */
public int Native_GetPlayerCurrency(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return 0;

	return g_iPlayerCurrency[client];
}

public void OnPluginStart()
{
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), LOG_PATH);
	LogToFile(logfilepath, "|               PLUGIN START                |");

	HandleSdk();
	if (checkDBFile(PLAYERS_DB_NAME))
	{
		doSqlConnectionPlayers(PLAYERS_DB_NAME);	// Usar handle separado para players
	}
	if (checkDBFile(ADMIN_DB_NAME))
	{
		doSqlConnection(ADMIN_DB_NAME);	   // Handle para admins
	}
	buyMenuOnPluginStart();
	AdminMoney_OnPluginStart();

	// Inicializar sistema de leveling (DEBE ir ANTES del sistema de puntos unificado)
	Leveling_OnPluginStart();
	LevelingRewards_OnPluginStart();
	LevelingUI_OnPluginStart();
	LevelingInfo_OnPluginStart();

	// ===== SISTEMA UNIFICADO DE PUNTOS =====
	EclipsePointsUnified_OnPluginStart();

	// Inicializar módulos de modos de juego
	Bloodmoon_OnPluginStart();

	// Inicializar sistema de frags
	FragsSystem_OnPluginStart();

	// ===== SISTEMA DE GESTIÓN DEL SERVIDOR =====
	Afk_Join_OnPluginStart();

	RegConsoleCmd("buy", Cmd_Buy);
	RegConsoleCmd("sm_buy", Cmd_Buy);
	RegConsoleCmd("sm_givemoney", Command_GiveMoneySub);

	RegAdminCmd("rp", Cmd_Reload_Plugins, ADMFLAG_ROOT);
	RegAdminCmd("rt", Cmd_Reload_Translations, ADMFLAG_ROOT);
	g_cvarDebug = CreateConVar("sm_spawnammo_debug", "0", "Activa debug verboso (0/1).", 0, true, 0.0, true, 1.0);
	LoadTranslations("eclipse.phrases");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	cvar_preciptype = CreateConVar("snow_type", "3", "Type of the precipitation (https://developer.valvesoftware.com/wiki/Func_precipitation)");
	cvar_density	= CreateConVar("snow_density", "75", "Density of the precipitation");
	cvar_color		= CreateConVar("snow_color", "255 255 255", "Color of the precipitation");
	cvar_render		= CreateConVar("snow_renderamt", "5", "Render of the precipitation");
	PrecacheAll();
}

public void OnMapStart()
{
	LogToFile(logfilepath, "|               MAP START                   |");

	// Limpiar todos los timers de mapas anteriores
	CleanupAllTimers();

	// Reset tracking flags del sistema de puntos unificado
	EclipsePointsUnified_OnMapStart();

	// Reset frags system
	FragsSystem_OnMapStart();

	DelegateBuyMenuModule();
	DefenseGrid_OnMapStart();
	Bloodmoon_OnMapStart();
	NuclearStrike_OnMapStart();
#if defined _EMS_PRECACHE_MODULE_
	EMS_Precache_OnMapStart();
#endif
	GetCurrentMap(sMap, 64);
	Format(sMap, sizeof(sMap), "maps/%s.bsp", sMap);
	PrecacheModel(sMap, true);
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

	// Inicializar frags system
	FragsSystem_OnClientPutInServer(client);
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
	// EMS_Precache_SetDebug(true);
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

	// Nuclear Strike timers
	CleanupNuclearStrikeTimers();

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

// Snowing
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, CreateSnowFall);
}

public Action CreateSnowFall(Handle timer)
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "func_precipitation")) != -1)
		AcceptEntityInput(iEnt, "Kill");

	iEnt = CreateEntityByName("func_precipitation");

	if (iEnt != -1)
	{
		char  preciptype[5], density[5], color[16], render[5];
		float vMins[3], vMax[3], vBuff[3];

		cvar_preciptype.GetString(preciptype, sizeof(preciptype));
		cvar_density.GetString(density, sizeof(density));
		cvar_color.GetString(color, sizeof(color));
		cvar_render.GetString(render, sizeof(render));

		DispatchKeyValue(iEnt, "model", sMap);
		DispatchKeyValue(iEnt, "preciptype", preciptype);
		DispatchKeyValue(iEnt, "renderamt", render);
		DispatchKeyValue(iEnt, "density", density);
		DispatchKeyValue(iEnt, "rendercolor", color);

		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMax);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);

		SetEntPropVector(iEnt, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", vMax);

		vBuff[0] = vMins[0] + vMax[0];
		vBuff[1] = vMins[1] + vMax[1];
		vBuff[2] = vMins[2] + vMax[2];

		TeleportEntity(iEnt, vBuff, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
	}
	return Plugin_Continue;
}