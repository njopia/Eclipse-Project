#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

Menu g_MainMenu;
Menu g_DeployablesMenu;
Menu g_InstantsMenu;
Menu g_TeamBonusesMenu;
Menu g_BombardmentsMenu;
Menu g_SpecialsMenu;

/// Main Menu Choices ///
#define BM_CHOICE_0_1 "BM_Instant"
#define BM_CHOICE_0_2 "BM_LongAction"
#define BM_CHOICE_0_3 "BM_Deployables"
#define BM_CHOICE_0_4 "BM_Bombardments"
#define BM_CHOICE_0_5 "BM_TeamBonuses"
#define BM_CHOICE_0_6 "BM_Specials"
#define BM_CHOICE_6_1 "BM_Specials_ShoulderCannon"
#define BM_CHOICE_6_2 "BM_Specials_ShoulderCannon_Config"
/// Instant Choices ///
#define BM_CHOICE_1_1 "BM_Instant_ConvertHP"
#define BM_CHOICE_1_2 "BM_Instant_FireYell"
#define BM_CHOICE_1_3 "BM_Instant_PowerYell"
#define BM_CHOICE_1_4 "BM_Instant_LeapOfDesperation"
/// Long Action Choices ///
#define BM_CHOICE_2_1 "BM_LongAction_SurvSpeedUp"
#define BM_CHOICE_2_2 "BM_Ability_Berserker"
#define BM_CHOICE_2_3 "BM_Ability_AcidBath"
#define BM_CHOICE_2_4 "BM_Ability_LifeStealer"
#define BM_CHOICE_2_5 "BM_Ability_SpeedFreak"
#define BM_CHOICE_2_6 "BM_Ability_ShoulderCannon"
/// Deployables Choices ///
#define BM_CHOICE_3_1 "BM_Deployables_Ammo_Pile"
#define BM_CHOICE_3_2 "BM_Deployables_UV_Light"
#define BM_CHOICE_3_3 "BM_Deployables_Healing_Station"
#define BM_CHOICE_3_4 "BM_Deployables_Defense_Grid"
/// Bombardments Choices ///
#define BM_CHOICE_4_1 "BM_Bombardments_Ion_Cannon"
#define BM_CHOICE_4_2 "BM_Bombardments_Nuclear_Strike"
/// Team Bonuses Choices ///
#define BM_CHOICE_5_1 "BM_TeamBonuses_TeamSpeedBoost"
#define BM_CHOICE_5_2 "BM_TeamBonuses_TeamHeal"

// =============================================================================
// HELPER — tiempo restante del Team Speed Boost para mostrar en el menu.
// El manager no expone el tiempo restante directamente, asi que mostramos
// si esta activo o en cooldown, que es lo que realmente importa en la UI.
// =============================================================================
static void _BM_GetSpeedBoostMenuText(int client, int cost, char[] out, int maxlen)
{
	char baseText[64];
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_5_1, client);

	if (SPD_HasLayer(client, SpeedLayer_TeamBoost))
	{
		// Activo — no tenemos tiempo exacto sin un timer propio, mostramos estado
		char activeText[32];
		Format(activeText, sizeof(activeText), "%T", "UI_Active", client);
		Format(out, maxlen, "%s (%d) [%s]", baseText, cost, activeText);
	}
	else
	{
		float cooldown = GetTeamSpeedBoostCooldown(client);
		if (cooldown > 0.0)
		{
			int cdSeconds = RoundToFloor(cooldown);
			Format(out, maxlen, "%s (%d) [CD: %ds]", baseText, cost, cdSeconds);
		}
		else
		{
			Format(out, maxlen, "%s (%d)", baseText, cost);
		}
	}
}

// =============================================================================
// MENU PRINCIPAL
// =============================================================================
public Action Cmd_Buy(int client, int args)
{
	if (!IsSurvivor(client))
	{
		char errorMsg[128];
		Format(errorMsg, sizeof(errorMsg), "%T", "Error_OnlyForSurvivors", client);
		PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
		return Plugin_Handled;
	}

	g_MainMenu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);

	char text[40];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	int	 playerPoints = GetPlayerCurrency(client);
	int	 playerLevel  = Leveling_GetPlayerLevel(client);

	char fullTitle[256];
	char playerText[32], pointsText[32], levelText[32], title[128];
	Format(title, sizeof(title), "%T", "Menu Title", client);
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle),
		   "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================",
		   title, playerText, playerName, pointsText, playerPoints, levelText, playerLevel);

	g_MainMenu.SetTitle(fullTitle, LANG_SERVER);

	Format(text, sizeof(text), "%T", BM_CHOICE_0_1, client);
	g_MainMenu.AddItem(BM_CHOICE_0_1, text);

	if (playerLevel >= 3)
	{
		Format(text, sizeof(text), "%T", "Menu_Abilities", client);
		g_MainMenu.AddItem(BM_CHOICE_0_2, text);
	}

	Format(text, sizeof(text), "%T", BM_CHOICE_0_3, client);
	g_MainMenu.AddItem(BM_CHOICE_0_3, text);

	Format(text, sizeof(text), "%T", BM_CHOICE_0_4, client);
	g_MainMenu.AddItem(BM_CHOICE_0_4, text);

	Format(text, sizeof(text), "%T", BM_CHOICE_0_5, client);
	g_MainMenu.AddItem(BM_CHOICE_0_5, text);

	if (playerLevel >= 35)
	{
		Format(text, sizeof(text), "%T", "Menu_Specials", client);
		g_MainMenu.AddItem(BM_CHOICE_0_6, text);
	}

	g_MainMenu.ExitButton = true;
	g_MainMenu.Display(client, 20);

	// Recrear submenus para mostrar timers actualizados
	InstantsMenu(client);
	DeployablesMenu(client);
	BombardmentsMenu(client);
	TeamBonusesMenu(client);
	SpecialsMenu(client);

	return Plugin_Handled;
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, BM_CHOICE_0_1))
			{
				InstantsMenu(client);
				if (g_InstantsMenu != null)
					g_InstantsMenu.Display(client, 20);
			}
			else if (StrEqual(info, BM_CHOICE_0_2))
			{
				ShowAbilitiesMenu(client);
			}
			else if (StrEqual(info, BM_CHOICE_0_3))
			{
				DeployablesMenu(client);
				if (g_DeployablesMenu != null)
					g_DeployablesMenu.Display(client, 20);
			}
			else if (StrEqual(info, BM_CHOICE_0_4))
			{
				BombardmentsMenu(client);
				if (g_BombardmentsMenu != null)
					g_BombardmentsMenu.Display(client, 20);
			}
			else if (StrEqual(info, BM_CHOICE_0_5))
			{
				TeamBonusesMenu(client);
				if (g_TeamBonusesMenu != null)
					g_TeamBonusesMenu.Display(client, 20);
			}
			else if (StrEqual(info, BM_CHOICE_0_6))
			{
				SpecialsMenu(client);
				if (g_SpecialsMenu != null)
					g_SpecialsMenu.Display(client, 20);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

// =============================================================================
// SUBMENUS
// =============================================================================
public void InstantsMenu(int client)
{
	g_InstantsMenu = new Menu(MenuHandler_Instants, MENU_ACTIONS_ALL);

	char text[40], baseText[40], title[128], fullTitle[256];
	char playerName[MAX_NAME_LENGTH];
	char playerText[32], pointsText[32], levelText[32];
	GetClientName(client, playerName, sizeof(playerName));
	Format(title, sizeof(title), "%T", "BM_Instant", client);
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle),
		   "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================",
		   title, playerText, playerName, pointsText, GetPlayerCurrency(client), levelText, Leveling_GetPlayerLevel(client));
	g_InstantsMenu.SetTitle(fullTitle, LANG_SERVER);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_1, client);
	Format(text, sizeof(text), "%s (%d)", baseText, GetConVarInt(cvar_CostConvertHP));
	g_InstantsMenu.AddItem(BM_CHOICE_1_1, text);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_2, client);
	Format(text, sizeof(text), "%s (%d)", baseText, GetConVarInt(cvar_CostFireYell));
	g_InstantsMenu.AddItem(BM_CHOICE_1_2, text);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_3, client);
	Format(text, sizeof(text), "%s (%d)", baseText, GetConVarInt(cvar_CostPowerYell));
	g_InstantsMenu.AddItem(BM_CHOICE_1_3, text);

	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_1_4, client);
	Format(text, sizeof(text), "%s (%d)", baseText, GetConVarInt(cvar_CostLeap));
	g_InstantsMenu.AddItem(BM_CHOICE_1_4, text);

	g_InstantsMenu.ExitBackButton = true;
	g_InstantsMenu.ExitButton	  = true;
}

public void DeployablesMenu(int client)
{
	g_DeployablesMenu = new Menu(MenuHandler_Deployables, MENU_ACTIONS_ALL);

	char text[40], baseText[64], title[128], fullTitle[256];
	char playerName[MAX_NAME_LENGTH];
	char playerText[32], pointsText[32], levelText[32];
	GetClientName(client, playerName, sizeof(playerName));
	int playerLevel = Leveling_GetPlayerLevel(client);
	Format(title, sizeof(title), "%T", "BM_Deployables", client);
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle),
		   "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================",
		   title, playerText, playerName, pointsText, GetPlayerCurrency(client), levelText, playerLevel);
	g_DeployablesMenu.SetTitle(fullTitle);

	// Ammo Pile (Nivel 1)
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_1, client);
	if (playerLevel >= 1)
	{
		Format(text, sizeof(text), "%s (%d)", baseText, GetConVarInt(cvar_CostAmmo));
		g_DeployablesMenu.AddItem(BM_CHOICE_3_1, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 1);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_ammo", text, ITEMDRAW_DEFAULT);
	}

	// UV Light (Nivel 3)
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_2, client);
	if (playerLevel >= 3)
	{
		int costUV = GetConVarInt(cvar_CostUVLight);
		if (UVLightTimer[client] > 0)
			Format(text, sizeof(text), "%s (%d) [%ds]", baseText, costUV, UVLightTimer[client]);
		else
			Format(text, sizeof(text), "%s (%d)", baseText, costUV);
		g_DeployablesMenu.AddItem(BM_CHOICE_3_2, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 3);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_uvlight", text, ITEMDRAW_DEFAULT);
	}

	// Healing Station (Nivel 5)
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_3, client);
	if (playerLevel >= 5)
	{
		int costHS = GetConVarInt(cvar_CostHealingStation);
		if (HSTimer[client] > 0)
			Format(text, sizeof(text), "%s (%d) [%ds]", baseText, costHS, HSTimer[client]);
		else
			Format(text, sizeof(text), "%s (%d)", baseText, costHS);
		g_DeployablesMenu.AddItem(BM_CHOICE_3_3, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 5);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_healingstation", text, ITEMDRAW_DEFAULT);
	}

	// Defense Grid (Nivel 10)
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_4, client);
	if (playerLevel >= 10)
	{
		int	 dgCooldown = DefenseGrid_GetCooldown(client);
		int	 dgTime		= DefenseGrid_GetTimeRemaining(client);
		int	 costDG		= GetConVarInt(cvar_CostDefenseGrid);
		char activeText[32], readyText[32];
		Format(activeText, sizeof(activeText), "%T", "UI_Active", client);
		Format(readyText, sizeof(readyText), "%T", "UI_Ready", client);

		if (dgTime > 0)
			Format(text, sizeof(text), "%s (%d) [%s: %ds]", baseText, costDG, activeText, dgTime);
		else if (dgCooldown > 0)
			Format(text, sizeof(text), "%s (%d) [CD: %ds]", baseText, costDG, dgCooldown);
		else
			Format(text, sizeof(text), "%s (%d) [%s]", baseText, costDG, readyText);
		g_DeployablesMenu.AddItem(BM_CHOICE_3_4, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 10);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_defensegrid", text, ITEMDRAW_DEFAULT);
	}

	g_DeployablesMenu.ExitBackButton = true;
	g_DeployablesMenu.ExitButton	 = true;
}

public void BombardmentsMenu(int client)
{
	g_BombardmentsMenu = new Menu(MenuHandler_Bombardments, MENU_ACTIONS_ALL);

	char text[40], baseText[64], title[128], fullTitle[256];
	char playerName[MAX_NAME_LENGTH];
	char playerText[32], pointsText[32], levelText[32];
	GetClientName(client, playerName, sizeof(playerName));
	int playerLevel = Leveling_GetPlayerLevel(client);
	Format(title, sizeof(title), "%T", "BM_Bombardments", client);
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle),
		   "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================",
		   title, playerText, playerName, pointsText, GetPlayerCurrency(client), levelText, playerLevel);
	g_BombardmentsMenu.SetTitle(fullTitle);

	// Ion Cannon (Nivel 7)
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_4_1, client);
	if (playerLevel >= 7)
	{
		char ionCannonInfo[128];
		GetIonCannonInfo(client, ionCannonInfo, sizeof(ionCannonInfo));
		Format(text, sizeof(text), "%s (%d) %s", baseText, GetConVarInt(cvar_CostIonCannon), ionCannonInfo);
		g_BombardmentsMenu.AddItem(BM_CHOICE_4_1, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 7);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_BombardmentsMenu.AddItem("locked_ioncannon", text, ITEMDRAW_DEFAULT);
	}

	// Nuclear Strike (Nivel 15)
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_4_2, client);
	if (playerLevel >= 15)
	{
		char usedText[32], onePerMapText[32];
		Format(usedText, sizeof(usedText), "%T", "UI_Used", client);
		Format(onePerMapText, sizeof(onePerMapText), "%T", "UI_OnePerMap", client);
		int costNS = GetConVarInt(cvar_CostNuclearStrike);
		if (NuclearStrike_HasUsedThisMap(client))
			Format(text, sizeof(text), "%s (%d) [%s]", baseText, costNS, usedText);
		else
			Format(text, sizeof(text), "%s (%d) [%s]", baseText, costNS, onePerMapText);
		g_BombardmentsMenu.AddItem(BM_CHOICE_4_2, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 15);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_BombardmentsMenu.AddItem("locked_nuclearstrike", text, ITEMDRAW_DEFAULT);
	}

	g_BombardmentsMenu.ExitBackButton = true;
	g_BombardmentsMenu.ExitButton	  = true;
}

public void TeamBonusesMenu(int client)
{
	g_TeamBonusesMenu = new Menu(MenuHandler_TeamBonuses, MENU_ACTIONS_ALL);

	char text[128], baseText[64], title[128], fullTitle[256];
	char playerName[MAX_NAME_LENGTH];
	char playerText[32], pointsText[32], levelText[32];
	GetClientName(client, playerName, sizeof(playerName));
	Format(title, sizeof(title), "%T", "BM_TeamBonuses", client);
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle),
		   "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================",
		   title, playerText, playerName, pointsText, GetPlayerCurrency(client), levelText, Leveling_GetPlayerLevel(client));
	g_TeamBonusesMenu.SetTitle(fullTitle);

	// Team Speed Boost — usa helper del manager
	int costTSB = GetConVarInt(cvar_CostTeamSpeedBoost);
	_BM_GetSpeedBoostMenuText(client, costTSB, text, sizeof(text));
	g_TeamBonusesMenu.AddItem(BM_CHOICE_5_1, text);

	// Team Heal
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_5_2, client);
	int	  costTH	   = GetConVarInt(cvar_CostTeamHeal);
	float healCooldown = GetTeamHealCooldown(client);
	if (healCooldown > 0.0)
		Format(text, sizeof(text), "%s (%d) [CD: %ds]", baseText, costTH, RoundToFloor(healCooldown));
	else
		Format(text, sizeof(text), "%s (%d)", baseText, costTH);
	g_TeamBonusesMenu.AddItem(BM_CHOICE_5_2, text);

	g_TeamBonusesMenu.ExitBackButton = true;
	g_TeamBonusesMenu.ExitButton	 = true;
}

public void SpecialsMenu(int client)
{
	g_SpecialsMenu = new Menu(MenuHandler_Specials, MENU_ACTIONS_ALL);

	char text[128], baseText[64], title[128], fullTitle[256];
	char playerName[MAX_NAME_LENGTH];
	char playerText[32], levelText[32];
	GetClientName(client, playerName, sizeof(playerName));
	int playerLevel = Leveling_GetPlayerLevel(client);
	SetGlobalTransTarget(client);
	Format(title, sizeof(title), "%t", "Menu_Specials");
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle),
		   "%s \n================= \n %s: %s \n %s: %d \n=================",
		   title, playerText, playerName, levelText, playerLevel);
	g_SpecialsMenu.SetTitle(fullTitle);

	// Shoulder Cannon (Nivel 35)
	Format(baseText, sizeof(baseText), "%T", "BM_Ability_ShoulderCannon", client);
	if (playerLevel >= 35)
	{
		g_SpecialsMenu.AddItem(BM_CHOICE_6_1, baseText);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, 35);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_SpecialsMenu.AddItem("locked_shouldercannon", text, ITEMDRAW_DISABLED);
	}

	g_SpecialsMenu.ExitBackButton = true;
	g_SpecialsMenu.ExitButton	  = true;
}

// =============================================================================
// HANDLERS DE SELECCION
// =============================================================================
public int MenuHandler_Instants(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, BM_CHOICE_1_1))
		{
			if (PurchaseItem(client, GetConVarInt(cvar_CostConvertHP), "Convert HP"))
				ConvertHealth(client);
		}
		else if (StrEqual(info, BM_CHOICE_1_2))
		{
			if (PurchaseItem(client, GetConVarInt(cvar_CostFireYell), "Fire Yell"))
				Activate_FireYell(client);
		}
		else if (StrEqual(info, BM_CHOICE_1_3))
		{
			if (PurchaseItem(client, GetConVarInt(cvar_CostPowerYell), "Power Yell"))
				Yell(client);
		}
		else if (StrEqual(info, BM_CHOICE_1_4))
		{
			if (PurchaseItem(client, GetConVarInt(cvar_CostLeap), "Leap of Desperation"))
				Activate_LeapOfDesperation(client);
		}
	}
	return 0;
}

public int MenuHandler_Deployables(Menu menu, MenuAction action, int client, int param)
{
	if (action != MenuAction_Select) return 0;

	char info[32];
	menu.GetItem(param, info, sizeof(info));
	int playerLevel = Leveling_GetPlayerLevel(client);

	if (StrEqual(info, BM_CHOICE_3_1))
	{
		if (playerLevel < 1)
		{
			_BM_PrintLevelError(client, 1, "Ammo Pile");
			return 0;
		}
		if (!AmmoPile_IsReady(client, AMMO_PILE))
		{
			PrintToChat(client, "\x05[Eclipse]\x01 Ammo Pile aun en cooldown.");
			return 0;
		}
		if (PurchaseItem(client, GetConVarInt(cvar_CostAmmo), "Ammo Pile"))
		{
			SpawnAmmoByName(client, "pile");
			_BM_PrintDeploySuccess(client, "Ammo Pile");
		}
	}
	else if (StrEqual(info, BM_CHOICE_3_2))
	{
		if (playerLevel < 3)
		{
			_BM_PrintLevelError(client, 3, "UV Light");
			return 0;
		}
		if (UVLightTimer[client] > 0)
		{
			char errorMsg[128];
			Format(errorMsg, sizeof(errorMsg), "%T", "Error_WaitSeconds", client, UVLightTimer[client]);
			PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
			return 0;
		}
		if (!(GetEntityFlags(client) & FL_ONGROUND))
		{
			_BM_PrintGroundError(client);
			return 0;
		}
		if (PurchaseItem(client, GetConVarInt(cvar_CostUVLight), "UV Light"))
		{
			SpawnUVLight(client);
			UpdateUVLight(client);
			_BM_PrintDeploySuccess(client, "UV Light");
		}
	}
	else if (StrEqual(info, BM_CHOICE_3_3))
	{
		if (playerLevel < 5)
		{
			_BM_PrintLevelError(client, 5, "Healing Station");
			return 0;
		}
		if (HSTimer[client] > 0)
		{
			char errorMsg[128];
			Format(errorMsg, sizeof(errorMsg), "%T", "Error_WaitSeconds", client, HSTimer[client]);
			PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
			return 0;
		}
		if (!(GetEntityFlags(client) & FL_ONGROUND))
		{
			_BM_PrintGroundError(client);
			return 0;
		}
		if (PurchaseItem(client, GetConVarInt(cvar_CostHealingStation), "Healing Station"))
		{
			SpawnHealingStation(client);
			_BM_PrintDeploySuccess(client, "Healing Station");
		}
	}
	else if (StrEqual(info, BM_CHOICE_3_4))
	{
		if (playerLevel < 10)
		{
			_BM_PrintLevelError(client, 10, "Defense Grid");
			return 0;
		}
		if (!DefenseGrid_CanDeploy(client)) return 0;
		if (PurchaseItem(client, GetConVarInt(cvar_CostDefenseGrid), "Defense Grid"))
			DefenseGrid_Deploy(client);
	}

	return 0;
}

public int MenuHandler_Bombardments(Menu menu, MenuAction action, int client, int param)
{
	if (action != MenuAction_Select) return 0;

	char info[32];
	menu.GetItem(param, info, sizeof(info));
	int playerLevel = Leveling_GetPlayerLevel(client);

	if (StrEqual(info, BM_CHOICE_4_1))
	{
		if (playerLevel < 7)
		{
			_BM_PrintLevelError(client, 7, "Ion Cannon");
			return 0;
		}
		if (PurchaseItem(client, GetConVarInt(cvar_CostIonCannon), "Ion Cannon") && BuyIonCannon(client))
			_BM_PrintDeploySuccess(client, "Ion Cannon");
	}
	else if (StrEqual(info, BM_CHOICE_4_2))
	{
		if (playerLevel < 15)
		{
			_BM_PrintLevelError(client, 15, "Nuclear Strike");
			return 0;
		}
		if (PurchaseItem(client, GetConVarInt(cvar_CostNuclearStrike), "Nuclear Strike"))
			Activate_NuclearStrike(client);
	}

	return 0;
}

public int MenuHandler_TeamBonuses(Menu menu, MenuAction action, int client, int param)
{
	if (action != MenuAction_Select) return 0;

	char info[32];
	menu.GetItem(param, info, sizeof(info));

	if (StrEqual(info, BM_CHOICE_5_1))
	{
		if (PurchaseItem(client, GetConVarInt(cvar_CostTeamSpeedBoost), "Team Speed Boost"))
			Activate_TeamSpeedBoost(client);
	}
	else if (StrEqual(info, BM_CHOICE_5_2))
	{
		if (PurchaseItem(client, GetConVarInt(cvar_CostTeamHeal), "Team Heal"))
			Activate_TeamHeal(client);
	}

	return 0;
}

public int MenuHandler_Specials(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, BM_CHOICE_6_1))
		{
			if (Leveling_GetPlayerLevel(client) < 35)
			{
				SetGlobalTransTarget(client);
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%t", "Error_NeedLevel35ShoulderCannon");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
			ShoulderCannon_ShowMenu(client);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		Cmd_Buy(client, 0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

// =============================================================================
// HELPERS INTERNOS
// =============================================================================

static void _BM_PrintLevelError(int client, int requiredLevel, const char[] itemName)
{
	char errorMsg[128];
	Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, requiredLevel, itemName);
	PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
}

static void _BM_PrintGroundError(int client)
{
	char errorMsg[128];
	Format(errorMsg, sizeof(errorMsg), "%T", "Error_MustBeOnGround", client);
	PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
}

static void _BM_PrintDeploySuccess(int client, const char[] itemName)
{
	char successMsg[128];
	Format(successMsg, sizeof(successMsg), "%T", "Success_Deploying", client, itemName);
	PrintToChat(client, "\x04[Deployables]\x01 %s", successMsg);
}
