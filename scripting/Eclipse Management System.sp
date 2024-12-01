#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

/////// DATABASE MANAGEMENT SYSTEM ///////////
#define EMS_MAIN_FILE	 // EMS_MAIN_FILE define main file as the current core
#define ADMIN_DB_NAME "admins"
#tryinclude "modules/db-utils.sp"
//////////////////////////////////////////////

/////// MENU TEST ///////////////////////////
#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"
#define CHOICE3 "#choice3"
//////////////////////////////////////////////

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
	if (!doSqlConnection(ADMIN_DB_NAME))
	{
		SetFailState("Error en la conexion a la base de datos");
	}
	LoadTranslations("eclipse.phrases");
	RegConsoleCmd("buy", Cmd_Buy);
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToChatAll("Displaying menu");
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, CHOICE3))
			{
				PrintToChatAll("Client %d somehow selected %s despite it being disabled", param1, info);
			}
			else
			{
				PrintToChatAll("Client %d selected %s", param1, info);
			}
		}

		case MenuAction_Cancel:
		{
			PrintToChatAll("Client %d's menu was cancelled for reason %d", param1, param2);
		}

		case MenuAction_End:
		{
			delete menu;
		}

		case MenuAction_DrawItem:
		{
			int	 style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);

			if (StrEqual(info, CHOICE3))
			{
				return ITEMDRAW_DISABLED;
			}
			else
			{
				return style;
			}
		}
	}

	return 0;
}

public Action Cmd_Buy(int client, int args)
{
	char   text[40];
	char title[40];
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Menu Title", client);
	menu.SetTitle(title, LANG_SERVER);
	Format(text, sizeof(text), "%T", "Choice 1", client);
	menu.AddItem(CHOICE1, text);
	Format(text, sizeof(text), "%T", "Choice 2", client);
	menu.AddItem(CHOICE2, text);
	Format(text, sizeof(text), "%T", "Choice 3", client);
	menu.AddItem(CHOICE3, text);
	menu.ExitButton = true;
	menu.Display(client, 20);

	return Plugin_Handled;
}