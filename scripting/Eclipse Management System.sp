#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

/////// DATABASE MANAGEMENT SYSTEM ///////////
#define EMS_MAIN_FILE	 // EMS_MAIN_FILE define main file as the current core
#define ADMIN_DB_NAME	"admins"
#define PLAYERS_DB_NAME "players"
#tryinclude "utils/database.utils.sp"
//////////////////////////////////////////////

/////// MENU TEST ///////////////////////////
#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"
#define CHOICE3 "#choice3"
#tryinclude "modules/buy-menu.module.sp"
//////////////////////////////////////////////

/////// SERVER MANAGEMENT UTILS ////////////
#tryinclude "utils/server-management.utils.sp"
//////////////////////////////////////////////

/////// PLUGIN VARIABLES ////////////////////

#define LOG_PATH "logs\\Eclipse_Management_System.log"
static char logfilepath[PLATFORM_MAX_PATH];
//////////////////////////////////////////////
public Plugin myinfo =
{
	name		= "Eclipse management system",
	author		= "Natan Jopia",
	description = "daabase management system module",
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

	if (checkDBFile(PLAYERS_DB_NAME))
	{
		doSqlConnection(PLAYERS_DB_NAME);
	}
	if (checkDBFile(ADMIN_DB_NAME))
	{
		doSqlConnection(ADMIN_DB_NAME);
	}
	buyMenuOnPluginStart();
	LoadTranslations("eclipse.phrases");
	RegConsoleCmd("buy", Cmd_Buy);
	RegAdminCmd("rp", Cmd_Reload_Plugins, ADMFLAG_ROOT);
	RegAdminCmd("rt", Cmd_Reload_Translations, ADMFLAG_ROOT);

	//CreateTimer(1.0, Timer_UpdateUVLight, _, TIMER_REPEAT);
}
