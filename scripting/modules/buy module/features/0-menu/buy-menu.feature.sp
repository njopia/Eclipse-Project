#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

Menu g_MainMenu;
Menu g_InstantsMenu;
Menu g_TeamBonusesMenu;
Menu g_BombardmentsMenu;

/// Main Menu Choices ///
#define BM_CHOICE_0_1 "BM_Instant"
#define BM_CHOICE_0_2 "BM_LongAction"
#define BM_CHOICE_0_4 "BM_Bombardments"
#define BM_CHOICE_0_5 "BM_TeamBonuses"
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

	Format(text, sizeof(text), "%T", BM_CHOICE_0_4, client);
	g_MainMenu.AddItem(BM_CHOICE_0_4, text);

	Format(text, sizeof(text), "%T", BM_CHOICE_0_5, client);
	g_MainMenu.AddItem(BM_CHOICE_0_5, text);

	g_MainMenu.ExitButton = true;
	g_MainMenu.Display(client, 20);

	// Recrear submenus para mostrar timers actualizados
	InstantsMenu(client);
	BombardmentsMenu(client);
	TeamBonusesMenu(client);

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
		BuyIonCannon(client);
	}
	else if (StrEqual(info, BM_CHOICE_4_2))
	{
		if (playerLevel < 15)
		{
			_BM_PrintLevelError(client, 15, "Nuclear Strike");
			return 0;
		}
		BuyNuclearStrike(client);
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

// =============================================================================
// HELPERS INTERNOS
// =============================================================================

static void _BM_PrintLevelError(int client, int requiredLevel, const char[] itemName)
{
	char errorMsg[128];
	Format(errorMsg, sizeof(errorMsg), "%T", "Error_LevelRequired", client, requiredLevel, itemName);
	PrintToChat(client, "\x05[Eclipse]\x01 %s", errorMsg);
}

