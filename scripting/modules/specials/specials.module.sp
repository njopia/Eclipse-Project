#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SPECIALS MODULE ===
// Menu de habilidades especiales desbloqueables
// por nivel alto. No requieren currency.
//
// Niveles requeridos:
//   Shoulder Cannon: nivel 45
//   Jetpack:         nivel 49  (finale-only)
//   Hats:            nivel 50
//==================================================

#define _SPECIALS_MODULE_

#define SPEC_LVL_SHOULDERCANNON 45
#define SPEC_LVL_JETPACK        49
#define SPEC_LVL_HATS           50

#tryinclude "hats.module.sp"
#tryinclude "jetpack.module.sp"

// =============================================================================
// LIFECYCLE
// =============================================================================

void Specials_OnPluginStart()
{
#if defined _HATS_MODULE_
	Hats_OnPluginStart();
#endif
#if defined _JETPACK_MODULE_
	Jetpack_OnPluginStart();
#endif

	HookEvent("player_spawn", _Specials_Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", _Specials_Event_PlayerDeath, EventHookMode_Post);
}

public void _Specials_Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client))
		Specials_OnPlayerSpawn(client);
}

public void _Specials_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client))
		Specials_OnPlayerDeath(client);
}

void Specials_OnMapStart()
{
#if defined _HATS_MODULE_
	Hats_OnMapStart();
#endif
#if defined _JETPACK_MODULE_
	Jetpack_OnMapStart();
#endif
}

void Specials_OnClientCookiesCached(int client)
{
#if defined _HATS_MODULE_
	Hats_OnClientCookiesCached(client);
#endif
}

void Specials_OnPlayerSpawn(int client)
{
#if defined _HATS_MODULE_
	Hats_OnPlayerSpawn(client);
#endif
}

void Specials_OnPlayerDeath(int client)
{
#if defined _HATS_MODULE_
	Hats_OnPlayerDeath(client);
#endif
#if defined _JETPACK_MODULE_
	Jetpack_OnPlayerDeath(client);
#endif
}

void Specials_OnClientDisconnect(int client)
{
#if defined _HATS_MODULE_
	Hats_OnClientDisconnect(client);
#endif
#if defined _JETPACK_MODULE_
	Jetpack_OnClientDisconnect(client);
#endif
}

void Specials_OnPlayerRunCmd(int client, int buttons)
{
#if defined _JETPACK_MODULE_
	Jetpack_OnPlayerRunCmd(client, buttons);
#endif
}

// =============================================================================
// COMANDO !specials
// =============================================================================

public Action Cmd_Specials(int client, int args)
{
	if (!IsSurvivor(client))
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solo disponible para sobrevivientes.");
		return Plugin_Handled;
	}
	Specials_ShowMenu(client);
	return Plugin_Handled;
}

// =============================================================================
// MENU
// =============================================================================

void Specials_ShowMenu(int client)
{
	int playerLevel = Leveling_GetPlayerLevel(client);

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	Menu menu = new Menu(Specials_MenuHandler);
	menu.SetTitle("Especiales\n%s | Nivel %d\n=================", name, playerLevel);

	char text[64];

	// Shoulder Cannon
	if (playerLevel >= SPEC_LVL_SHOULDERCANNON)
		Format(text, sizeof(text), "Shoulder Cannon");
	else
		Format(text, sizeof(text), "Shoulder Cannon [Nivel %d]", SPEC_LVL_SHOULDERCANNON);
	menu.AddItem("sc", text, playerLevel >= SPEC_LVL_SHOULDERCANNON ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Jetpack
	if (playerLevel >= SPEC_LVL_JETPACK)
	{
		if (Jetpack_IsEquipped(client))
			Format(text, sizeof(text), "Jetpack [Equipado - %d cargas]", g_iJetpackCharges[client]);
		else
			Format(text, sizeof(text), "Jetpack");
		menu.AddItem("jp", text);
	}
	else
	{
		Format(text, sizeof(text), "Jetpack [Nivel %d]", SPEC_LVL_JETPACK);
		menu.AddItem("jp", text, ITEMDRAW_DISABLED);
	}

	// Hats
	if (playerLevel >= SPEC_LVL_HATS)
	{
		char sHatName[32];
		Hats_GetName(g_iSelectedHat[client], sHatName, sizeof(sHatName));
		Format(text, sizeof(text), "Hat: %s", sHatName);
		menu.AddItem("hats", text);
	}
	else
	{
		Format(text, sizeof(text), "Hats [Nivel %d]", SPEC_LVL_HATS);
		menu.AddItem("hats", text, ITEMDRAW_DISABLED);
	}

	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int Specials_MenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(item, info, sizeof(info));
		int playerLevel = Leveling_GetPlayerLevel(client);

		if (StrEqual(info, "sc"))
		{
			if (playerLevel < SPEC_LVL_SHOULDERCANNON)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para Shoulder Cannon.", SPEC_LVL_SHOULDERCANNON);
				return 0;
			}
			ShoulderCannon_ShowMenu(client);
		}
		else if (StrEqual(info, "jp"))
		{
			if (playerLevel < SPEC_LVL_JETPACK)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para el Jetpack.", SPEC_LVL_JETPACK);
				return 0;
			}
			if (Jetpack_IsEquipped(client))
			{
				Jetpack_Unequip(client);
				PrintToChat(client, "\x04[Eclipse]\x01 Jetpack desequipado.");
			}
			else
				Jetpack_Equip(client);
		}
		else if (StrEqual(info, "hats"))
		{
			if (playerLevel < SPEC_LVL_HATS)
			{
				PrintToChat(client, "\x04[Eclipse]\x01 Necesitas nivel \x05%d\x01 para Hats.", SPEC_LVL_HATS);
				return 0;
			}
			Hats_ShowMenu(client, 0);
		}
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}
