
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

Menu g_MainMenu;
Menu g_DeployablesMenu;
Menu g_InstantsMenu;
// Menu g_LongActionsMenu; // Removido - ahora usa ShowAbilitiesMenu()
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
/// Specials Choices ///
#define BM_CHOICE_6_1 "BM_Specials_ShoulderCannon"

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		/* case MenuAction_Start:
		{
			PrintToChatAll("Displaying menu");
		} */
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, BM_CHOICE_0_1))
			{
				// PrintToChat(client, "\x05[Eclipse]\x01 Instants");
				InstantsMenu(client);
				if (g_InstantsMenu != null)
				{
					g_InstantsMenu.Display(client, 20);
				}
			}
			if (StrEqual(info, BM_CHOICE_0_2))
			{
				// Abrir menú de Abilities en lugar de Long Actions
				ShowAbilitiesMenu(client);
			}
			if (StrEqual(info, BM_CHOICE_0_3))
			{
				// PrintToChat(client, "\x05[Eclipse]\x01  Deployables Menu");
				DeployablesMenu(client);
				if (g_DeployablesMenu != null)
				{
					g_DeployablesMenu.Display(client, 20);
				}
			}
			if (StrEqual(info, BM_CHOICE_0_4))
			{
				// PrintToChat(client, "\x05[Eclipse]\x01 Bombardments");
				BombardmentsMenu(client);
				if (g_BombardmentsMenu != null)
				{
					g_BombardmentsMenu.Display(client, 20);
				}
			}
			if (StrEqual(info, BM_CHOICE_0_5))
			{
				// PrintToChat(client, "\x05[Eclipse]\x01 Team Bonuses");
				TeamBonusesMenu(client);
				if (g_TeamBonusesMenu != null)
				{
					g_TeamBonusesMenu.Display(client, 20);
				}
			}
			if (StrEqual(info, BM_CHOICE_0_6))
			{
				// PrintToChat(client, "\x05[Eclipse]\x01 Specials");
				SpecialsMenu(client);
				if (g_SpecialsMenu != null)
				{
					g_SpecialsMenu.Display(client, 20);
				}
			}
		}

			/* case MenuAction_Cancel:
			{
				PrintToChatAll("Client %d's menu was cancelled for reason %d", client, param2);
			} */

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public void InstantsMenu(int client)
{
	g_InstantsMenu = new Menu(MenuHandler_Instants, MENU_ACTIONS_ALL);

	char text[40];
	char title[128];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName))
		Format(title, sizeof(title), "%T", "BM_Instant", client);
	int	 playerPoints = GetPlayerCurrency(client);
	int	 playerLevel  = Leveling_GetPlayerLevel(client);
	char fullTitle[256];
	char playerText[32], pointsText[32], levelText[32];
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle), "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================", title, playerText, playerName, pointsText, playerPoints, levelText, playerLevel);

	g_InstantsMenu.SetTitle(fullTitle, LANG_SERVER);

	char baseText[40];

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

// LongActionsMenu removida - reemplazada por ShowAbilitiesMenu() del sistema de Abilities

// Function to Create Submenu
public void DeployablesMenu(int client)
{
	// Create Submenu
	g_DeployablesMenu = new Menu(MenuHandler_Deployables, MENU_ACTIONS_ALL);
	char baseText[64];
	char text[40];
	char title[128];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName))
		Format(title, sizeof(title), "%T", "BM_Deployables", client);
	int	 playerPoints = GetPlayerCurrency(client);
	int	 playerLevel  = Leveling_GetPlayerLevel(client);
	char fullTitle[256];
	char playerText[32], pointsText[32], levelText[32];
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle), "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================", title, playerText, playerName, pointsText, playerPoints, levelText, playerLevel);

	g_DeployablesMenu.SetTitle(fullTitle);

	// === DEPLOYABLES CON RESTRICCIONES DE NIVEL ===

	// Ammo Pile (Nivel 1)
	int requiredLevelAmmo = 1;
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_1, client);
	int costAmmo = GetConVarInt(cvar_CostAmmo);
	if (playerLevel >= requiredLevelAmmo)
	{
		Format(text, sizeof(text), "%s (%d)", baseText, costAmmo);
		g_DeployablesMenu.AddItem(BM_CHOICE_3_1, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelAmmo);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_ammo", text, ITEMDRAW_DEFAULT);
	}

	// UV Light (Nivel 3)
	int requiredLevelUV = 3;
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_2, client);
	int costUV = GetConVarInt(cvar_CostUVLight);
	if (playerLevel >= requiredLevelUV)
	{
		if (UVLightTimer[client] > 0)
		{
			Format(text, sizeof(text), "%s (%d) [%ds]", baseText, costUV, UVLightTimer[client]);
		}
		else
		{
			Format(text, sizeof(text), "%s (%d)", baseText, costUV);
		}
		g_DeployablesMenu.AddItem(BM_CHOICE_3_2, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelUV);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_uvlight", text, ITEMDRAW_DEFAULT);
	}

	// Healing Station (Nivel 5)
	int requiredLevelHS = 5;
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_3, client);
	int costHS = GetConVarInt(cvar_CostHealingStation);
	if (playerLevel >= requiredLevelHS)
	{
		if (HSTimer[client] > 0)
		{
			Format(text, sizeof(text), "%s (%d) [%ds]", baseText, costHS, HSTimer[client]);
		}
		else
		{
			Format(text, sizeof(text), "%s (%d)", baseText, costHS);
		}
		g_DeployablesMenu.AddItem(BM_CHOICE_3_3, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelHS);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_healingstation", text, ITEMDRAW_DEFAULT);
	}

	// Defense Grid (Level 10)
	int requiredLevelDG = 10;
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_3_4, client);
	int costDG = GetConVarInt(cvar_CostDefenseGrid);
	if (playerLevel >= requiredLevelDG)
	{
		int dgCooldown = DefenseGrid_GetCooldown(client);
		int dgTime	   = DefenseGrid_GetTimeRemaining(client);
		char activeText[32], readyText[32];
		Format(activeText, sizeof(activeText), "%T", "UI_Active", client);
		Format(readyText, sizeof(readyText), "%T", "UI_Ready", client);

		if (dgTime > 0)
		{
			Format(text, sizeof(text), "%s (%d) [%s: %ds]", baseText, costDG, activeText, dgTime);
		}
		else if (dgCooldown > 0)
		{
			Format(text, sizeof(text), "%s (%d) [CD: %ds]", baseText, costDG, dgCooldown);
		}
		else
		{
			Format(text, sizeof(text), "%s (%d) [%s]", baseText, costDG, readyText);
		}
		g_DeployablesMenu.AddItem(BM_CHOICE_3_4, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelDG);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_DeployablesMenu.AddItem("locked_defensegrid", text, ITEMDRAW_DEFAULT);
	}

	g_DeployablesMenu.ExitBackButton = true;
	g_DeployablesMenu.ExitButton	 = true;
}

// Function to Create Bombardments Submenu
public void BombardmentsMenu(int client)
{
	g_BombardmentsMenu = new Menu(MenuHandler_Bombardments, MENU_ACTIONS_ALL);
	char baseText[64];
	char text[40];
	char title[128];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName))
		Format(title, sizeof(title), "%T", "BM_Bombardments", client);
	int	 playerPoints = GetPlayerCurrency(client);
	int	 playerLevel  = Leveling_GetPlayerLevel(client);
	char fullTitle[256];
	char playerText[32], pointsText[32], levelText[32];
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle), "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================", title, playerText, playerName, pointsText, playerPoints, levelText, playerLevel);

	g_BombardmentsMenu.SetTitle(fullTitle);

	// === BOMBARDMENTS WITH LEVEL RESTRICTIONS ===

	// Ion Cannon (Level 7)
	int requiredLevelIC = 7;
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_4_1, client);
	int costIC = GetConVarInt(cvar_CostIonCannon);
	if (playerLevel >= requiredLevelIC)
	{
		char ionCannonInfo[128];
		GetIonCannonInfo(client, ionCannonInfo, sizeof(ionCannonInfo));
		Format(text, sizeof(text), "%s (%d) %s", baseText, costIC, ionCannonInfo);
		g_BombardmentsMenu.AddItem(BM_CHOICE_4_1, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelIC);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_BombardmentsMenu.AddItem("locked_ioncannon", text, ITEMDRAW_DEFAULT);
	}

	// Nuclear Strike (Level 15)
	int requiredLevelNS = 15;
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_4_2, client);
	int costNS = GetConVarInt(cvar_CostNuclearStrike);
	if (playerLevel >= requiredLevelNS)
	{
		char usedText[32], onePerMapText[32];
		Format(usedText, sizeof(usedText), "%T", "UI_Used", client);
		Format(onePerMapText, sizeof(onePerMapText), "%T", "UI_OnePerMap", client);

		if (NuclearStrike_HasUsedThisMap(client))
		{
			Format(text, sizeof(text), "%s (%d) [%s]", baseText, costNS, usedText);
		}
		else
		{
			Format(text, sizeof(text), "%s (%d) [%s]", baseText, costNS, onePerMapText);
		}
		g_BombardmentsMenu.AddItem(BM_CHOICE_4_2, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelNS);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_BombardmentsMenu.AddItem("locked_nuclearstrike", text, ITEMDRAW_DEFAULT);
	}

	g_BombardmentsMenu.ExitBackButton = true;
	g_BombardmentsMenu.ExitButton	  = true;
}

// Function to Create Team Bonuses Submenu
public void TeamBonusesMenu(int client)
{
	g_TeamBonusesMenu = new Menu(MenuHandler_TeamBonuses, MENU_ACTIONS_ALL);
	char baseText[64];
	char text[40];
	char title[128];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName))
		Format(title, sizeof(title), "%T", "BM_TeamBonuses", client);
	int	 playerPoints = GetPlayerCurrency(client);
	int	 playerLevel  = Leveling_GetPlayerLevel(client);
	char fullTitle[256];
	char playerText[32], pointsText[32], levelText[32];
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle), "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================", title, playerText, playerName, pointsText, playerPoints, levelText, playerLevel);

	g_TeamBonusesMenu.SetTitle(fullTitle);

	// Add Team Speed Boost Item with remaining time and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_5_1, client);
	int	  costTSB			  = GetConVarInt(cvar_CostTeamSpeedBoost);
	float speedBoostRemaining = GetTeamSpeedBoostRemaining(client);
	char activeText[32];
	Format(activeText, sizeof(activeText), "%T", "UI_Active", client);

	if (speedBoostRemaining > 0.0)
	{
		int minutes = RoundToFloor(speedBoostRemaining / 60.0);
		int seconds = RoundToFloor(speedBoostRemaining - (minutes * 60));
		Format(text, sizeof(text), "%s (%d) [%s: %dm %ds]", baseText, costTSB, activeText, minutes, seconds);
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
	g_TeamBonusesMenu.AddItem(BM_CHOICE_5_1, text);

	// Add Team Heal Item with remaining cooldown and cost
	Format(baseText, sizeof(baseText), "%T", BM_CHOICE_5_2, client);
	int	  costTH		   = GetConVarInt(cvar_CostTeamHeal);
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
	g_TeamBonusesMenu.AddItem(BM_CHOICE_5_2, text);

	g_TeamBonusesMenu.ExitBackButton = true;
	g_TeamBonusesMenu.ExitButton	 = true;
}

public int MenuHandler_Bombardments(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		int playerLevel = Leveling_GetPlayerLevel(client);

		// Ion Cannon (Nivel 7)
		if (StrEqual(info, BM_CHOICE_4_1))
		{
			if (playerLevel < 7)
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, 7, "Ion Cannon");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
			int cost = GetConVarInt(cvar_CostIonCannon);
			if (PurchaseItem(client, cost, "Ion Cannon") && BuyIonCannon(client))
			{
				char successMsg[128];
				Format(successMsg, sizeof(successMsg), "%T", "Success_Deploying", client, "Ion Cannon");
				PrintToChat(client, "\x04[Bombardments]\x01 %s", successMsg);
			}
		}
		// Nuclear Strike (Nivel 15)
		else if (StrEqual(info, BM_CHOICE_4_2))
		{
			if (playerLevel < 15)
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, 15, "Nuclear Strike");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
			int cost = GetConVarInt(cvar_CostNuclearStrike);
			if (PurchaseItem(client, cost, "Nuclear Strike"))
				Activate_NuclearStrike(client);
		}
	}
	return 0;
}

public int MenuHandler_TeamBonuses(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_5_1))
		{
			int cost = GetConVarInt(cvar_CostTeamSpeedBoost);
			if (PurchaseItem(client, cost, "Team Speed Boost"))
				Activate_TeamSpeedBoost(client);
		}
		if (StrEqual(info, BM_CHOICE_5_2))
		{
			int cost = GetConVarInt(cvar_CostTeamHeal);
			if (PurchaseItem(client, cost, "Team Heal"))
				Activate_TeamHeal(client);
		}
	}
	return 0;
}

// Function to Create Specials Submenu
public void SpecialsMenu(int client)
{
	g_SpecialsMenu = new Menu(MenuHandler_Specials, MENU_ACTIONS_ALL);
	char baseText[64];
	char text[128];
	char title[128];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName))
		Format(title, sizeof(title), "Specials");
	int	 playerLevel  = Leveling_GetPlayerLevel(client);
	char fullTitle[256];
	char playerText[32], levelText[32];
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle), "%s \n================= \n %s: %s \n %s: %d \n=================", title, playerText, playerName, levelText, playerLevel);

	g_SpecialsMenu.SetTitle(fullTitle);

	// Shoulder Cannon (Level 35) - Equipable permanente
	int requiredLevelSC = 35;
	Format(baseText, sizeof(baseText), "Shoulder Cannon");
	if (playerLevel >= requiredLevelSC)
	{
		// Verificar si está equipado
		bool isEquipped = (g_iShoulderCannon_Entity[client] > 0 && IsValidEntity(g_iShoulderCannon_Entity[client]));

		if (isEquipped)
		{
			Format(text, sizeof(text), "%s [EQUIPPED]", baseText);
		}
		else
		{
			Format(text, sizeof(text), "%s [NOT EQUIPPED]", baseText);
		}
		g_SpecialsMenu.AddItem(BM_CHOICE_6_1, text);
	}
	else
	{
		char lockedText[64];
		Format(lockedText, sizeof(lockedText), "%T", "UI_Locked", client, requiredLevelSC);
		Format(text, sizeof(text), "%s %s", baseText, lockedText);
		g_SpecialsMenu.AddItem("locked_shouldercannon", text, ITEMDRAW_DEFAULT);
	}

	g_SpecialsMenu.ExitBackButton = true;
	g_SpecialsMenu.ExitButton	 = true;
}

public int MenuHandler_Specials(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		int playerLevel = Leveling_GetPlayerLevel(client);

		// Shoulder Cannon (Level 35)
		if (StrEqual(info, BM_CHOICE_6_1))
		{
			if (playerLevel < 35)
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Necesitas nivel 35 para usar Shoulder Cannon");
				return 0;
			}

			// Verificar si está equipado
			bool isEquipped = (g_iShoulderCannon_Entity[client] > 0 && IsValidEntity(g_iShoulderCannon_Entity[client]));

			if (isEquipped)
			{
				// Desequipar
				ShoulderCannon_Unequip(client);
				PrintToChat(client, "\x04[Specials]\x01 Shoulder Cannon desequipado");
			}
			else
			{
				// Equipar
				ShoulderCannon_Equip(client);
				PrintToChat(client, "\x04[Specials]\x01 Shoulder Cannon equipado");
			}

			// Reabrir menú
			SpecialsMenu(client);
			if (g_SpecialsMenu != null)
			{
				g_SpecialsMenu.Display(client, 20);
			}
		}
	}
	return 0;
}

public int MenuHandler_Instants(Menu menu, MenuAction action, int client, int param)
{
	// PrintToChatAll("action: %i", action);
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

// MenuHandler_LongActions removido - reemplazado por ShowAbilitiesMenu()

public int MenuHandler_Deployables(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		int playerLevel = Leveling_GetPlayerLevel(client);

		// Ammo Pile (Nivel 1)
		if (StrEqual(info, BM_CHOICE_3_1))
		{
			PrintToChatAll("Player level: %d", playerLevel);
			if (playerLevel < 1)
			{
				PrintToChatAll("Player level: %d", playerLevel);
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, 1, "Ammo Pile");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
			int cost = GetConVarInt(cvar_CostAmmo);
			if (PurchaseItem(client, cost, "Ammo Pile"))
			{
				SpawnAmmoByName(client, "pile");
				char successMsg[128];
				Format(successMsg, sizeof(successMsg), "%T", "Success_Deploying", client, "Ammo Pile");
				PrintToChat(client, "\x04[Deployables]\x01 %s", successMsg);
			}
		}
		// UV Light (Nivel 3)
		else if (StrEqual(info, BM_CHOICE_3_2))
		{
			if (playerLevel < 3)
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, 3, "UV Light");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
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
						char successMsg[128];
						Format(successMsg, sizeof(successMsg), "%T", "Success_Deploying", client, "UV Light");
						PrintToChat(client, "\x04[Deployables]\x01 %s", successMsg);
					}
				}
				else
				{
					char errorMsg[128];
					Format(errorMsg, sizeof(errorMsg), "%T", "Error_MustBeOnGround", client);
					PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				}
			}
			else
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_WaitSeconds", client, UVLightTimer[client]);
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
			}
		}
		// Healing Station (Nivel 5)
		else if (StrEqual(info, BM_CHOICE_3_3))
		{
			if (playerLevel < 5)
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, 5, "Healing Station");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
			if (HSTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					int cost = GetConVarInt(cvar_CostHealingStation);
					if (PurchaseItem(client, cost, "Healing Station"))
					{
						SpawnHealingStation(client);
						char successMsg[128];
						Format(successMsg, sizeof(successMsg), "%T", "Success_Deploying", client, "Healing Station");
						PrintToChat(client, "\x04[Deployables]\x01 %s", successMsg);
					}
				}
				else
				{
					char errorMsg[128];
					Format(errorMsg, sizeof(errorMsg), "%T", "Error_MustBeOnGround", client);
					PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				}
			}
			else
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_WaitSeconds", client, HSTimer[client]);
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
			}
		}
		// Defense Grid (Nivel 10)
		else if (StrEqual(info, BM_CHOICE_3_4))
		{
			if (playerLevel < 10)
			{
				char errorMsg[128];
				Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, 10, "Defense Grid");
				PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
				return 0;
			}
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
	if (IsSurvivor(client) == false)
	{
		char errorMsg[128];
		Format(errorMsg, sizeof(errorMsg), "%T", "Error_OnlyForSurvivors", client);
		PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
		return Plugin_Handled;
	}
	g_MainMenu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	char text[40];
	char title[128];
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName))
		Format(title, sizeof(title), "%T", "Menu Title", client);
	// Add player points and level to main title
	int	 playerPoints = GetPlayerCurrency(client);
	int	 playerLevel  = Leveling_GetPlayerLevel(client);
	char fullTitle[256];
	char playerText[32], pointsText[32], levelText[32];
	Format(playerText, sizeof(playerText), "%T", "UI_Player", client);
	Format(pointsText, sizeof(pointsText), "%T", "UI_Points", client);
	Format(levelText, sizeof(levelText), "%T", "UI_Level", client);
	Format(fullTitle, sizeof(fullTitle), "%s \n================= \n %s: %s \n %s: %d \n %s: %d \n=================", title, playerText, playerName, pointsText, playerPoints, levelText, playerLevel);
	g_MainMenu.SetTitle(fullTitle, LANG_SERVER);

	Format(text, sizeof(text), "%T", BM_CHOICE_0_1, client);
	g_MainMenu.AddItem(BM_CHOICE_0_1, text);
	// Abilities - Only show if player has level 3 or higher
	if (playerLevel >= 3)
	{
		Format(text, sizeof(text), "Abilities");
		g_MainMenu.AddItem(BM_CHOICE_0_2, text);
	}
	Format(text, sizeof(text), "%T", BM_CHOICE_0_3, client);
	g_MainMenu.AddItem(BM_CHOICE_0_3, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_4, client);
	g_MainMenu.AddItem(BM_CHOICE_0_4, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_5, client);
	g_MainMenu.AddItem(BM_CHOICE_0_5, text);
	// Specials - Only show if player has level 35 or higher
	if (playerLevel >= 35)
	{
		Format(text, sizeof(text), "Specials");
		g_MainMenu.AddItem(BM_CHOICE_0_6, text);
	}
	g_MainMenu.ExitButton = true;
	g_MainMenu.Display(client, 20);

	// Recreate all submenus to show current timers
	InstantsMenu(client);
	// LongActionsMenu removido - ahora usa ShowAbilitiesMenu() directamente
	DeployablesMenu(client);
	BombardmentsMenu(client);
	TeamBonusesMenu(client);
	SpecialsMenu(client);

	return Plugin_Handled;
}