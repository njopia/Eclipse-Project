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
//////////////////////////////////////////////

/////// BUY MENU /////////////////////////////
#tryinclude "modules/buy module/buy-menu.module.sp"
//////////////////////////////////////////////

/////// SERVER MANAGEMENT UTILS ////////////
#tryinclude "utils/server-management.utils.sp"
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
		doSqlConnection(PLAYERS_DB_NAME);
	}
	if (checkDBFile(ADMIN_DB_NAME))
	{
		doSqlConnection(ADMIN_DB_NAME);
	}
	buyMenuOnPluginStart();
	RegConsoleCmd("buy", Cmd_Buy);
	RegConsoleCmd("sm_buy", Cmd_Buy);
	RegAdminCmd("rp", Cmd_Reload_Plugins, ADMFLAG_ROOT);
	RegAdminCmd("rt", Cmd_Reload_Translations, ADMFLAG_ROOT);
	LoadTranslations("eclipse.phrases");
}

public void OnMapStart()
{
	DelegateBuyMenuModule();
	PrintToServer("Current Game Mode: %d", CurrentGameMode());
}
