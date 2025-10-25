
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif


Menu g_MainMenu;
Menu g_DeployablesMenu;
Menu g_InstantsMenu;
Menu g_LongActionsMenu;
Menu g_TeamBonusesMenu;
/// Main Menu Choices ///
#define BM_CHOICE_0_1 "BM_Instant"
#define BM_CHOICE_0_2 "BM_LongAction"
#define BM_CHOICE_0_3 "BM_Deployables"
#define BM_CHOICE_0_4 "BM_TeamBonuses"
/// Instant Choices ///
#define BM_CHOICE_1_1 "BM_Instant_ConvertHP"
#define BM_CHOICE_1_2 "BM_Instant_FireYell"
#define BM_CHOICE_1_3 "BM_Instant_PowerYell"
#define BM_CHOICE_1_4 "BM_Instant_LeapOfDesperation"
/// Long Action Choices ///
#define BM_CHOICE_2_1 "BM_LongAction_SurvSpeedUp"
/// Deployables Choices ///
#define BM_CHOICE_3_1 "BM_Deployables_Ammo_Pile"
#define BM_CHOICE_3_2 "BM_Deployables_UV_Light"
#define BM_CHOICE_3_3 "BM_Deployables_Healing_Station"
#define BM_CHOICE_3_4 "BM_Deployables_Ion_Cannon"
#define BM_CHOICE_3_5 "BM_Deployables_Defense_Grid"
/// Team Bonuses Choices ///
#define BM_CHOICE_4_1 "BM_TeamBonuses_TeamSpeedBoost"
#define BM_CHOICE_4_2 "BM_TeamBonuses_TeamHeal"

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
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
			if (StrEqual(info, BM_CHOICE_0_1))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Instants");
				g_InstantsMenu.Display(client, 20);
			}
			if (StrEqual(info, BM_CHOICE_0_2))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Long Action");
				g_LongActionsMenu.Display(client, 20);
			}
			if (StrEqual(info, BM_CHOICE_0_3))
			{
				PrintToChat(client, "\x05[Eclipse]\x01  Deployables Menu");
				g_DeployablesMenu.Display(client, 20);
			}
			if (StrEqual(info, BM_CHOICE_0_4))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Team Bonuses");
				TeamBonusesMenu(client);
				if (g_TeamBonusesMenu != null)
				{
					g_TeamBonusesMenu.Display(client, 20);
				}
			}
		}

		case MenuAction_Cancel:
		{
			PrintToChatAll("Client %d's menu was cancelled for reason %d", client, param2);
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public void InstantsMenu(int client)
{
	char text[64];
	char title[128];
	char baseText[40];

	// Create Submenu
	g_InstantsMenu = new Menu(MenuHandler_Instants, MENU_ACTIONS_ALL);
	char mainTitle[40];
	Format(mainTitle, sizeof(mainTitle), "%T", "Submenu Title", client);
	int playerPoints = g_iPlayerCurrency[client];
	Format(title, sizeof(title), "%s\nTus puntos: %d", mainTitle, playerPoints);
	g_InstantsMenu.SetTitle(title);

	// Add Submenu Items with costs
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_1, client);
	int cost1 = GetConVarInt(cvar_CostConvertHP);
	Format(text, sizeof(text), "%s (%d)", baseText, cost1);
	g_InstantsMenu.AddItem(BM_CHOICE_1_1, text);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_2, client);
	int cost2 = GetConVarInt(cvar_CostFireYell);
	Format(text, sizeof(text), "%s (%d)", baseText, cost2);
	g_InstantsMenu.AddItem(BM_CHOICE_1_2, text);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_3, client);
	int cost3 = GetConVarInt(cvar_CostPowerYell);
	Format(text, sizeof(text), "%s (%d)", baseText, cost3);
	g_InstantsMenu.AddItem(BM_CHOICE_1_3, text);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_4, client);
	int cost4 = GetConVarInt(cvar_CostLeap);
	Format(text, sizeof(text), "%s (%d)", baseText, cost4);
	g_InstantsMenu.AddItem(BM_CHOICE_1_4, text);

	g_InstantsMenu.ExitBackButton = true;
	g_InstantsMenu.ExitButton	  = true;
}

public void LongActionsMenu(int client)
{
	char text[128];
	char title[128];
	char baseText[64];

	// Create Submenu
	g_LongActionsMenu = new Menu(MenuHandler_LongActions, MENU_ACTIONS_ALL);
	char mainTitle[40];
	Format(mainTitle, sizeof(mainTitle), "%T", "Submenu Title", client);
	int playerPoints = g_iPlayerCurrency[client];
	Format(title, sizeof(title), "%s\nTus puntos: %d", mainTitle, playerPoints);
	g_LongActionsMenu.SetTitle(title);

	// Add Survivor Speed Boost Item with remaining time and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_2_1, client);
	int cost = GetConVarInt(cvar_CostSurvSpeed);
	float speedBoostRemaining = GetSurvSpeedBoostRemaining(client);
	if (speedBoostRemaining > 0.0)
	{
		int seconds = RoundToFloor(speedBoostRemaining);
		Format(text, sizeof(text), "%s (%d) [Activo: %ds]", baseText, cost, seconds);
	}
	else
	{
		Format(text, sizeof(text), "%s (%d)", baseText, cost);
	}
	g_LongActionsMenu.AddItem(BM_CHOICE_2_1, text);

	g_LongActionsMenu.ExitBackButton = true;
	g_LongActionsMenu.ExitButton	 = true;
}
// Function to Create Submenu
public void DeployablesMenu(int client)
{
	char text[128];
	char title[128];
	char baseText[64];

	// Create Submenu
	g_DeployablesMenu = new Menu(MenuHandler_Deployables, MENU_ACTIONS_ALL);
	char mainTitle[40];
	Format(mainTitle, sizeof(mainTitle), "%T", "Submenu Title", client);
	int playerPoints = g_iPlayerCurrency[client];
	Format(title, sizeof(title), "%s\nTus puntos: %d", mainTitle, playerPoints);
	g_DeployablesMenu.SetTitle(title);

	// Add Ammo Pile Item with cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_1, client);
	int costAmmo = GetConVarInt(cvar_CostAmmo);
	Format(text, sizeof(text), "%s (%d)", baseText, costAmmo);
	g_DeployablesMenu.AddItem(BM_CHOICE_3_1, text);

	// Add UV Light Item with remaining time and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_2, client);
	int costUV = GetConVarInt(cvar_CostUVLight);
	if (UVLightTimer[client] > 0)
	{
		Format(text, sizeof(text), "%s (%d) [%ds]", baseText, costUV, UVLightTimer[client]);
	}
	else
	{
		Format(text, sizeof(text), "%s (%d)", baseText, costUV);
	}
	g_DeployablesMenu.AddItem(BM_CHOICE_3_2, text);

	// Add Healing Station Item with remaining time and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_3, client);
	int costHS = GetConVarInt(cvar_CostHealingStation);
	if (HSTimer[client] > 0)
	{
		Format(text, sizeof(text), "%s (%d) [%ds]", baseText, costHS, HSTimer[client]);
	}
	else
	{
		Format(text, sizeof(text), "%s (%d)", baseText, costHS);
	}
	g_DeployablesMenu.AddItem(BM_CHOICE_3_3, text);

	// Add Ion Cannon Item with remaining cooldown/charges info and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_4, client);
	int costIC = GetConVarInt(cvar_CostIonCannon);
	char ionCannonInfo[128];
	GetIonCannonInfo(client, ionCannonInfo, sizeof(ionCannonInfo));
	Format(text, sizeof(text), "%s (%d) %s", baseText, costIC, ionCannonInfo);
	g_DeployablesMenu.AddItem(BM_CHOICE_3_4, text);

	// Add Defense Grid Item with remaining time/cooldown and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_5, client);
	int costDG = GetConVarInt(cvar_CostDefenseGrid);
	int dgCooldown = DefenseGrid_GetCooldown(client);
	int dgTime = DefenseGrid_GetTimeRemaining(client);
	if (dgTime > 0)
	{
		Format(text, sizeof(text), "%s (%d) [Activo: %ds]", baseText, costDG, dgTime);
	}
	else if (dgCooldown > 0)
	{
		Format(text, sizeof(text), "%s (%d) [CD: %ds]", baseText, costDG, dgCooldown);
	}
	else
	{
		Format(text, sizeof(text), "%s (%d) [Listo]", baseText, costDG);
	}
	g_DeployablesMenu.AddItem(BM_CHOICE_3_5, text);

	g_DeployablesMenu.ExitBackButton = true;
	g_DeployablesMenu.ExitButton	 = true;
}

// Function to Create Team Bonuses Submenu
public void TeamBonusesMenu(int client)
{
	char text[128];
	char title[128];
	char baseText[64];

	// Create Submenu
	g_TeamBonusesMenu = new Menu(MenuHandler_TeamBonuses, MENU_ACTIONS_ALL);
	char mainTitle[40];
	Format(mainTitle, sizeof(mainTitle), "%T", "Submenu Title", client);
	int playerPoints = g_iPlayerCurrency[client];
	Format(title, sizeof(title), "%s\nTus puntos: %d", mainTitle, playerPoints);
	g_TeamBonusesMenu.SetTitle(title);

	// Add Team Speed Boost Item with remaining time and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_4_1, client);
	int costTSB = GetConVarInt(cvar_CostTeamSpeedBoost);
	float speedBoostRemaining = GetTeamSpeedBoostRemaining(client);
	if (speedBoostRemaining > 0.0)
	{
		int minutes = RoundToFloor(speedBoostRemaining / 60.0);
		int seconds = RoundToFloor(speedBoostRemaining - (minutes * 60));
		Format(text, sizeof(text), "%s (%d) [Activo: %dm %ds]", baseText, costTSB, minutes, seconds);
	}
	else
	{
		float speedBoostCooldown = GetTeamSpeedBoostCooldown(client);
		if (speedBoostCooldown > 0.0)
		{
			int cdSeconds = RoundToFloor(speedBoostCooldown);
			Format(text, sizeof(text), "%s (%d) [CD: %ds]", baseText, costTSB, cdSeconds);
		}
		else
		{
			Format(text, sizeof(text), "%s (%d)", baseText, costTSB);
		}
	}
	g_TeamBonusesMenu.AddItem(BM_CHOICE_4_1, text);

	// Add Team Heal Item with remaining cooldown and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_4_2, client);
	int costTH = GetConVarInt(cvar_CostTeamHeal);
	float teamHealCooldown = GetTeamHealCooldown(client);
	if (teamHealCooldown > 0.0)
	{
		int cdSeconds = RoundToFloor(teamHealCooldown);
		Format(text, sizeof(text), "%s (%d) [CD: %ds]", baseText, costTH, cdSeconds);
	}
	else
	{
		Format(text, sizeof(text), "%s (%d)", baseText, costTH);
	}
	g_TeamBonusesMenu.AddItem(BM_CHOICE_4_2, text);

	g_TeamBonusesMenu.ExitBackButton = true;
	g_TeamBonusesMenu.ExitButton	 = true;
}

public int MenuHandler_TeamBonuses(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_4_1))
		{
			int cost = GetConVarInt(cvar_CostTeamSpeedBoost);
			if (PurchaseItem(client, cost, "Team Speed Boost"))
				Activate_TeamSpeedBoost(client);
		}
		if (StrEqual(info, BM_CHOICE_4_2))
		{
			int cost = GetConVarInt(cvar_CostTeamHeal);
			if (PurchaseItem(client, cost, "Team Heal"))
				Activate_TeamHeal(client);
		}
	}
	return 0;
}

public int MenuHandler_Instants(Menu menu, MenuAction action, int client, int param)
{
	PrintToChatAll("action: %i", action);
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_1_1))
		{
			int cost = GetConVarInt(cvar_CostConvertHP);
			if (PurchaseItem(client, cost, "Convert HP"))
				ConvertHealth(client);
		}
		if (StrEqual(info, BM_CHOICE_1_2))
		{
			int cost = GetConVarInt(cvar_CostFireYell);
			if (PurchaseItem(client, cost, "Fire Yell"))
				Activate_FireYell(client);
		}
		else if (StrEqual(info, BM_CHOICE_1_3))
		{
			int cost = GetConVarInt(cvar_CostPowerYell);
			if (PurchaseItem(client, cost, "Power Yell"))
				Yell(client);
		}
		else if (StrEqual(info, BM_CHOICE_1_4))
		{
			int cost = GetConVarInt(cvar_CostLeap);
			if (PurchaseItem(client, cost, "Leap of Desperation"))
				Activate_LeapOfDesperation(client);
		}
	}
	return 0;
}

public int MenuHandler_LongActions(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_2_1))
		{
			PrintToChatAll("Activating Speed Boost for client %d", client);
			int cost = GetConVarInt(cvar_CostSurvSpeed);
			if (PurchaseItem(client, cost, "Survivor Speed Boost"))
				Surv_SpeedBoost(client);
		}
	}
	return 0;
}

public int MenuHandler_Deployables(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_3_1))
		{
			int cost = GetConVarInt(cvar_CostAmmo);
			if (PurchaseItem(client, cost, "Ammo Pile"))
			{
				SpawnAmmoByName(client, "pile");
				PrintToChat(client, "\x04[Deployables]\x01 Deploying Ammo Pile");
			}
		}
		else
		if (StrEqual(info, BM_CHOICE_3_2))
		{
			if (UVLightTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					int cost = GetConVarInt(cvar_CostUVLight);
					if (PurchaseItem(client, cost, "UV Light"))
					{
						SpawnUVLight(client);
						UpdateUVLight(client);
						PrintToChat(client, "\x04[Deployables]\x01 Deploying UV Light");
					}
				}
				else
				{
					PrintToChat(client, "\x05[Eclipse]\x01 You must be on the ground to spawn a UV Light.");
				}
			}
			else
			{
				PrintToChat(client, "\x05[Eclipse]\x01 You have to wait %i seconds to use this again.", UVLightTimer[client]);
			}
		}
		else if (StrEqual(info, BM_CHOICE_3_3)) {
			if (HSTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					int cost = GetConVarInt(cvar_CostHealingStation);
					if (PurchaseItem(client, cost, "Healing Station"))
					{
						SpawnHealingStation(client);
						PrintToChat(client, "\x04[Deployables]\x01 Deploying Healing Station");
					}
				}
				else
				{
					PrintToChat(client, "\x05[Eclipse]\x01 You must be on the ground to spawn a Healing Station.");
				}
			}
			else
			{
				PrintToChat(client, "\x05[Eclipse]\x01 You have to wait %i seconds to use this again.", HSTimer[client]);
			}
		}
		else if (StrEqual(info, BM_CHOICE_3_4))
		{
			int cost = GetConVarInt(cvar_CostIonCannon);
			if (PurchaseItem(client, cost, "Ion Cannon") && BuyIonCannon(client))
			{
				PrintToChat(client, "\x04[Deployables]\x01 Deploying Ion Cannon");
			}
		}
		else if (StrEqual(info, BM_CHOICE_3_5))
		{
			int cost = GetConVarInt(cvar_CostDefenseGrid);
			if (PurchaseItem(client, cost, "Defense Grid"))
			{
				DefenseGrid_Deploy(client);
			}
		}
	}
	return 0;
}

public Action Cmd_Buy(int client, int args)
{
	char text[40];
	char title[128];
	g_MainMenu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Menu Title", client);

	// Agregar "Tus puntos" al título principal
	int playerPoints = g_iPlayerCurrency[client];
	char fullTitle[256];
	Format(fullTitle, sizeof(fullTitle), "%s\nTus puntos: %d", title, playerPoints);
	g_MainMenu.SetTitle(fullTitle, LANG_SERVER);

	Format(text, sizeof(text), "%T", BM_CHOICE_0_1, client);
	g_MainMenu.AddItem(BM_CHOICE_0_1, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_2, client);
	g_MainMenu.AddItem(BM_CHOICE_0_2, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_3, client);
	g_MainMenu.AddItem(BM_CHOICE_0_3, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_4, client);
	g_MainMenu.AddItem(BM_CHOICE_0_4, text);
	g_MainMenu.ExitButton = true;
	g_MainMenu.Display(client, 20);

	// Recreate all submenus to show current timers
	InstantsMenu(client);
	LongActionsMenu(client);
	DeployablesMenu(client);
	TeamBonusesMenu(client);

	return Plugin_Handled;
}