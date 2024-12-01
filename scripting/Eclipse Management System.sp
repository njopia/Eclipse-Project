#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

// DATABASE MANAGEMENT SYSTEM
#define EMS_MAIN_FILE	 // EMS_MAIN_FILE define main file as the current core
#define ADMIN_DB_NAME "admins"
#tryinclude "modules/db-utils.sp"

#pragma newdecls required
#pragma semicolon 1
public Plugin myinfo =
{
	name		= "Eclipse management system",
	author		= "Natan Jopia",
	description = "daabase management system module",
	version		= "1.0.0",
	url			= "https://gitlab.com/sourcepawn1/sm-win"
};

public void OnPluginStart()
{
	if (!doSqlConnection(ADMIN_DB_NAME))
	{
		SetFailState("Error en la conexion a la base de datos");
	}
}