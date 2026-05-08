#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
#define _MAIN_MENU_MODULE_

//==================================================
// === MAIN MENU MODULE ===
// Menu principal que unifica el acceso a todas las funcionalidades
// Similar al sistema del backup Master_3_46
//==================================================

/**
 * Inicializa el modulo de Main Menu
 */
public void MainMenu_OnPluginStart()
{
	// Comandos ahora registrados centralizadamente en commands.helpers.sp
}

/**
 * Comando: !menu / menu
 * Abre el menu principal con acceso a todas las funcionalidades
 */
public Action Command_MainMenu(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Handled;

	if (IsFakeClient(client))
		return Plugin_Handled;

	ShowMainMenu(client);
	return Plugin_Handled;
}

/**
 * Muestra el menu principal al jugador
 */
void ShowMainMenu(int client)
{
	Menu menu = new Menu(MainMenu_Handler);

	// Obtener informacion del jugador
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	int level = Leveling_GetPlayerLevel(client);
	int currentXP = Leveling_GetPlayerCurrentXP(client);
	int currency = GetPlayerCurrency(client);

	// Titulo del menu con informacion del jugador
	char title[256];
	SetGlobalTransTarget(client);
	Format(title, sizeof(title), "%t", "MainMenu_Title", playerName, level, currentXP, Leveling_GetXPRequiredForNextLevel(client), currency);
	menu.SetTitle(title);

	// === OPCIONES PRINCIPALES (siempre disponibles) ===
	char text[128];
	Format(text, sizeof(text), "%T", "MainMenu_Shop", client);
	menu.AddItem("buy", text);

	Format(text, sizeof(text), "%T", "MainMenu_LevelXP", client);
	menu.AddItem("level", text);

	Format(text, sizeof(text), "%T", "MainMenu_Rewards", client);
	menu.AddItem("rewards", text);

	Format(text, sizeof(text), "%T", "MainMenu_Abilities", client);
	menu.AddItem("abilities", text);
	menu.AddItem("", "", ITEMDRAW_SPACER);

	// === INFORMACION & ESTADISTICAS ===
	Format(text, sizeof(text), "%T", "MainMenu_FragsPanel", client);
	menu.AddItem("frags", text);

	Format(text, sizeof(text), "%T", "MainMenu_PlayersList", client);
	menu.AddItem("players", text);
	menu.AddItem("", "", ITEMDRAW_SPACER);

	// === OPCIONES DE SERVIDOR ===
	Format(text, sizeof(text), "%T", "MainMenu_MapVote", client);
	menu.AddItem("mapvote", text);

	Format(text, sizeof(text), "%T", "MainMenu_Language", client);
	menu.AddItem("language", text);
	menu.AddItem("", "", ITEMDRAW_SPACER);

	// === ACCIONES DE EQUIPO ===
	if (GetClientTeam(client) == 2)
	{
		Format(text, sizeof(text), "%T", "MainMenu_AlreadyInSurvivors", client);
		menu.AddItem("join", text);
	}
	else
	{
		Format(text, sizeof(text), "%T", "MainMenu_JoinSurvivors", client);
		menu.AddItem("join", text);
	}

	Format(text, sizeof(text), "%T", "MainMenu_GoSpectator", client);
	menu.AddItem("afk", text);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu principal
 */
public int MainMenu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, "buy"))
			{
				// Abrir buy menu
				FakeClientCommand(client, "sm_buy");
			}
			else if (StrEqual(info, "level"))
			{
				// Mostrar informacion de nivel
				FakeClientCommand(client, "sm_level");
				// Reabrir menu despues de mostrar info
				CreateTimer(0.1, Timer_ReopenMenu, GetClientUserId(client));
			}
			else if (StrEqual(info, "rewards"))
			{
				// Mostrar rewards activos directamente
				ShowActiveRewardsMenuWithBackButton(client);
			}
			else if (StrEqual(info, "abilities"))
			{
				// Abrir menu de abilities
				FakeClientCommand(client, "sm_abilities");
			}
			else if (StrEqual(info, "frags"))
			{
				// Abrir panel de frags
				FakeClientCommand(client, "sm_frags");
			}
			else if (StrEqual(info, "players"))
			{
				// Mostrar lista de jugadores
				FakeClientCommand(client, "sm_players");
			}
			else if (StrEqual(info, "mapvote"))
			{
				// Abrir votacion de mapas
				FakeClientCommand(client, "sm_custom");
			}
			else if (StrEqual(info, "language"))
			{
				// Abrir menu de idiomas
				FakeClientCommand(client, "sm_lang");
			}
			else if (StrEqual(info, "join"))
			{
				// Unirse a survivors
				FakeClientCommand(client, "sm_join");
				CreateTimer(0.5, Timer_ReopenMenu, GetClientUserId(client));
			}
			else if (StrEqual(info, "afk"))
			{
				// Ir a espectadores
				FakeClientCommand(client, "sm_afk");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/**
 * Timer: Reabrir el menu principal
 * Se usa despues de comandos que muestran informacion en chat
 */
public Action Timer_ReopenMenu(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client > 0 && IsClientInGame(client))
	{
		ShowMainMenu(client);
	}

	return Plugin_Stop;
}

/**
 * Muestra el menu de rewards activos con boton de retorno al menu principal
 */
void ShowActiveRewardsMenuWithBackButton(int client)
{
	int level = Leveling_GetPlayerLevel(client);

	Menu menu = new Menu(ActiveRewards_MainMenuHandler);

	char title[128];
	SetGlobalTransTarget(client);
	Format(title, sizeof(title), "%t", "MainMenu_ActiveRewardsTitle", level);
	menu.SetTitle(title);

	int count = 0;

	// Lista de rewards con sus niveles requeridos
	if (level >= 1)
	{
		menu.AddItem("1", "Double Jump (Lvl 1)");
		count++;
	}
	if (level >= 2)
	{
		menu.AddItem("2", "Acrobatics (Lvl 2)");
		count++;
	}
	if (level >= 3)
	{
		menu.AddItem("3", "Health Bonus +25 HP (Lvl 3)");
		count++;
	}
	if (level >= 4)
	{
		menu.AddItem("4", "Medic (Lvl 4)");
		count++;
	}
	if (level >= 6)
	{
		menu.AddItem("6", "Pack Rat +25% Ammo (Lvl 6)");
		count++;
	}
	if (level >= 8)
	{
		menu.AddItem("8", "Desert Cobra (Lvl 8)");
		count++;
	}
	if (level >= 9)
	{
		menu.AddItem("9", "Damage Reduction -5% (Lvl 9)");
		count++;
	}
	if (level >= 10)
	{
		menu.AddItem("10", "Gene Mutations I +100 HP (Lvl 10)");
		count++;
	}
	if (level >= 11)
	{
		menu.AddItem("11", "Self Revive (Lvl 11)");
		count++;
	}
	if (level >= 13)
	{
		menu.AddItem("13", "Sleight of Hand 2x Reload (Lvl 13)");
		count++;
	}
	if (level >= 15)
	{
		menu.AddItem("15", "Knife (Lvl 15)");
		count++;
	}
	if (level >= 17)
	{
		menu.AddItem("17", "Hard to Kill 500 HP (Lvl 17)");
		count++;
	}
	if (level >= 19)
	{
		menu.AddItem("19", "Arms Dealer 40 Items (Lvl 19)");
		count++;
	}
	if (level >= 20)
	{
		menu.AddItem("20", "Gene Mutations II +200 HP (Lvl 20)");
		count++;
	}
	if (level >= 22)
	{
		menu.AddItem("22", "Surgeon -50% Heal Time (Lvl 22)");
		count++;
	}
	if (level >= 24)
	{
		menu.AddItem("24", "Extreme Conditioning +25% Speed (Lvl 24)");
		count++;
	}
	if (level >= 26)
	{
		menu.AddItem("26", "BullsEye (Lvl 26)");
		count++;
	}
	if (level >= 29)
	{
		menu.AddItem("29", "Size Matters (Lvl 29)");
		count++;
	}
	if (level >= 30)
	{
		menu.AddItem("30", "Gene Mutations III +300 HP (Lvl 30)");
		count++;
	}
	if (level >= 32)
	{
		menu.AddItem("32", "Master at Arms 2x Melee (Lvl 32)");
		count++;
	}
	if (level >= 35)
	{
		menu.AddItem("35", "Hardened Stance (Lvl 35)");
		count++;
	}
	if (level >= 38)
	{
		menu.AddItem("38", "Critical Hit 10% (Lvl 38)");
		count++;
	}
	if (level >= 40)
	{
		menu.AddItem("40", "Gene Mutations IV +400 HP (Lvl 40)");
		count++;
	}
	if (level >= 41)
	{
		menu.AddItem("41", "Commando (Lvl 41)");
		count++;
	}
	if (level >= 44)
	{
		menu.AddItem("44", "Second Chance (Lvl 44)");
		count++;
	}
	if (level >= 47)
	{
		menu.AddItem("47", "Laser Rounds (Lvl 47)");
		count++;
	}

	if (count == 0)
	{
		char noRewardsText[64];
		Format(noRewardsText, sizeof(noRewardsText), "%T", "MainMenu_NoRewardsYet", client);
		menu.AddItem("none", noRewardsText, ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu de rewards activos desde el menu principal
 */
public int ActiveRewards_MainMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));

		if (!StrEqual(info, "none"))
		{
			int rewardLevel = StringToInt(info);
			ShowRewardDetailPanel(client, rewardLevel);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		// Volver al menu principal
		ShowMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra un panel con informacion detallada del reward
 */
void ShowRewardDetailPanel(int client, int rewardLevel)
{
	char rewardName[64];
	char rewardDesc[512];
	GetRewardDetailedInfo(rewardLevel, rewardName, sizeof(rewardName), rewardDesc, sizeof(rewardDesc));

	Panel panel = new Panel();

	char titleText[64];
	SetGlobalTransTarget(client);
	Format(titleText, sizeof(titleText), "%t", "Menu_RewardInformation");
	panel.SetTitle(titleText);

	panel.DrawText("=======================");

	char text[128];
	Format(text, sizeof(text), "%T", "Menu_RewardLabel", client, rewardName);
	panel.DrawText(text);

	panel.DrawText("=======================");
	panel.DrawText(" ");
	panel.DrawText(rewardDesc);
	panel.DrawText(" ");
	panel.DrawText("=======================");

	char backText[32];
	Format(backText, sizeof(backText), "%T", "Menu_BackButton", client);
	panel.DrawItem(backText);
	panel.Send(client, RewardDetailPanelHandler, 40);

	delete panel;
}

/**
 * Handler del panel de detalles del reward
 */
public int RewardDetailPanelHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		// Volver al menu de rewards activos
		ShowActiveRewardsMenuWithBackButton(client);
	}

	return 0;
}

/**
 * Obtiene informacion detallada de un reward (basado en backup)
 */
void GetRewardDetailedInfo(int level, char[] name, int nameLen, char[] description, int descLen)
{
	switch (level)
	{
		case 1:
		{
			strcopy(name, nameLen, "Double Jump");
			strcopy(description, descLen, "This skill enables a secondary jump while airborne.\nIdeal for reaching elevated positions or evading attacks.\nDuration: Constant Effect\nLevel Unlocked: 1");
		}
		case 2:
		{
			strcopy(name, nameLen, "Acrobatics");
			strcopy(description, descLen, "Increases jump height and reduces fall damage by 50%.\nPerfect for vertical mobility.\nDuration: Constant Effect\nLevel Unlocked: 2");
		}
		case 3:
		{
			strcopy(name, nameLen, "Health Bonus");
			strcopy(description, descLen, "Grants +25 additional HP upon spawning.\nEnhanced survivability from the start.\nDuration: Constant Effect\nLevel Unlocked: 3");
		}
		case 4:
		{
			strcopy(name, nameLen, "Medic");
			strcopy(description, descLen, "Bonus HP from healing items:\n• Pills: +50 HP\n• Adrenaline: +25 HP\n• First Aid: +200 HP\nDuration: Constant Effect\nLevel Unlocked: 4");
		}
		case 6:
		{
			strcopy(name, nameLen, "Pack Rat");
			strcopy(description, descLen, "Allows you to carry +25% more ammo.\nMore bullets = more shooting time.\nDuration: Constant Effect\nLevel Unlocked: 6");
		}
		case 8:
		{
			strcopy(name, nameLen, "Desert Cobra");
			strcopy(description, descLen, "Replaces your Pistol with a Magnum when incapacitated.\nHigher damage for critical situations.\nDuration: Constant Effect\nLevel Unlocked: 8");
		}
		case 9:
		{
			strcopy(name, nameLen, "Damage Reduction");
			strcopy(description, descLen, "Reduces damage received by 5%.\nIncreased resistance to enemy attacks.\nDuration: Constant Effect\nLevel Unlocked: 9");
		}
		case 10:
		{
			strcopy(name, nameLen, "Gene Mutations I");
			strcopy(description, descLen, "+100 maximum HP\nRegeneration: +1 HP every 5 seconds\nFirst genetic upgrade.\nDuration: Constant Effect\nLevel Unlocked: 10");
		}
		case 11:
		{
			strcopy(name, nameLen, "Self Revive");
			strcopy(description, descLen, "Auto-revive using USE key when incapacitated.\nDuration: 2.5 seconds\nYou don't need anyone's help!\nLevel Unlocked: 11");
		}
		case 13:
		{
			strcopy(name, nameLen, "Sleight of Hand");
			strcopy(description, descLen, "Doubles weapon reload speed.\nLess time reloading = more time shooting.\nDuration: Constant Effect\nLevel Unlocked: 13");
		}
		case 15:
		{
			strcopy(name, nameLen, "Knife");
			strcopy(description, descLen, "Stab special infected when captured.\nUse the USE key during 1.5s to attempt escape.\nDuration: Constant Effect\nLevel Unlocked: 15");
		}
		case 17:
		{
			strcopy(name, nameLen, "Hard to Kill");
			strcopy(description, descLen, "Incapacitation HP increased from 300 to 500.\nHarder to die when down.\nDuration: Constant Effect\nLevel Unlocked: 17");
		}
		case 19:
		{
			strcopy(name, nameLen, "Arms Dealer");
			strcopy(description, descLen, "Expands your backpack from 9 to 40 items.\nCarry all the arsenal you need!\nDuration: Constant Effect\nLevel Unlocked: 19");
		}
		case 20:
		{
			strcopy(name, nameLen, "Gene Mutations II");
			strcopy(description, descLen, "+200 maximum HP (total: +300)\nRegeneration: +2 HP every 5 seconds\nSecond genetic upgrade.\nDuration: Constant Effect\nLevel Unlocked: 20");
		}
		case 22:
		{
			strcopy(name, nameLen, "Surgeon");
			strcopy(description, descLen, "Reduces healing item application time by 50%.\nFaster healing = greater survival.\nDuration: Constant Effect\nLevel Unlocked: 22");
		}
		case 24:
		{
			strcopy(name, nameLen, "Extreme Conditioning");
			strcopy(description, descLen, "Increases movement speed by 25%.\nRun faster than the infected!\nDuration: Constant Effect\nLevel Unlocked: 24");
		}
		case 26:
		{
			strcopy(name, nameLen, "BullsEye");
			strcopy(description, descLen, "Equips free laser sight on all primary weapons.\nBetter accuracy without spending upgrade points.\nDuration: Constant Effect\nLevel Unlocked: 26");
		}
		case 29:
		{
			strcopy(name, nameLen, "Size Matters");
			strcopy(description, descLen, "Reload M60 and Grenade Launcher at ammo piles.\nHeavy weapons always ready for action.\nDuration: Constant Effect\nLevel Unlocked: 29");
		}
		case 30:
		{
			strcopy(name, nameLen, "Gene Mutations III");
			strcopy(description, descLen, "+300 maximum HP (total: +600)\nRegeneration: +3 HP every 5 seconds\nThird genetic upgrade.\nDuration: Constant Effect\nLevel Unlocked: 30");
		}
		case 32:
		{
			strcopy(name, nameLen, "Master at Arms");
			strcopy(description, descLen, "Doubles melee weapon damage.\nDamage: 100 → 200\nDestroy infected in melee combat!\nDuration: Constant Effect\nLevel Unlocked: 32");
		}
		case 35:
		{
			strcopy(name, nameLen, "Hardened Stance");
			strcopy(description, descLen, "Removes the 'witch stagger' effect.\nWalk near witches without being pushed.\nDuration: Constant Effect\nLevel Unlocked: 35");
		}
		case 38:
		{
			strcopy(name, nameLen, "Critical Hit");
			strcopy(description, descLen, "10% chance to deal critical damage.\nMultiplier: 1.5x - 3.0x damage\nDevastating hits!\nDuration: Constant Effect\nLevel Unlocked: 38");
		}
		case 40:
		{
			strcopy(name, nameLen, "Gene Mutations IV");
			strcopy(description, descLen, "+400 maximum HP (total: +1000)\nRegeneration: +4 HP every 5 seconds\nMaximum genetic upgrade.\nDuration: Constant Effect\nLevel Unlocked: 40");
		}
		case 41:
		{
			strcopy(name, nameLen, "Commando");
			strcopy(description, descLen, "Allows M60 reload at ammo piles.\nExtended magazine of 300 rounds\nNever run out of ammo!\nDuration: Constant Effect\nLevel Unlocked: 41");
		}
		case 44:
		{
			strcopy(name, nameLen, "Second Chance");
			strcopy(description, descLen, "Automatic auto-revive once per round.\nReturn to life after dying\nA second chance!\nDuration: Constant Effect\nLevel Unlocked: 44");
		}
		case 47:
		{
			strcopy(name, nameLen, "Laser Rounds");
			strcopy(description, descLen, "Laser ammunition for rifles and SMGs.\nIncreased damage + incineration effect\nMaximum firepower!\nDuration: Constant Effect\nLevel Unlocked: 47");
		}
		default:
		{
			strcopy(name, nameLen, "Unknown Reward");
			strcopy(description, descLen, "No information available.");
		}
	}
}
