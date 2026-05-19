#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING DEBUG MODULE ===
// Menu admin para probar y debuggear rewards pasivos
//==================================================

// --- ConVars ---
Handle cvar_Debug_Enabled = INVALID_HANDLE;

// --- Estado del debug ---
bool g_bDebug_ForceReward[MAXPLAYERS + 1][50]; // Array para forzar rewards (50 max rewards)
int g_iDebug_ForcedLevel[MAXPLAYERS + 1];      // Nivel forzado para testing

/**
 * Inicializa el modulo de debug
 */
public void LevelingDebug_OnPluginStart()
{
	cvar_Debug_Enabled = CreateConVar(
		"leveling_debug_enabled",
		"1",
		"Habilita el sistema de debug de leveling (1 = habilitado, 0 = deshabilitado)",
		FCVAR_PLUGIN
	);

	// Comando admin para abrir menu de debug
	RegAdminCmd("sm_rewardsdebug", Command_RewardsDebug, ADMFLAG_ROOT, "Abre el menu de debug de rewards");
	RegAdminCmd("sm_rdebug", Command_RewardsDebug, ADMFLAG_ROOT, "Abre el menu de debug de rewards");
	RegAdminCmd("sm_setlevel", Command_SetLevel, ADMFLAG_ROOT, "Establece el nivel de un jugador temporalmente");
}

/**
 * Resetea el estado al conectar
 */
public void LevelingDebug_OnClientConnect(int client)
{
	for (int i = 0; i < 50; i++)
	{
		g_bDebug_ForceReward[client][i] = false;
	}
	g_iDebug_ForcedLevel[client] = -1;
}

/**
 * Limpia recursos al desconectar
 */
public void LevelingDebug_OnClientDisconnect(int client)
{
	for (int i = 0; i < 50; i++)
	{
		g_bDebug_ForceReward[client][i] = false;
	}
	g_iDebug_ForcedLevel[client] = -1;
}

/**
 * Comando: Abre el menu de debug de rewards
 */
public Action Command_RewardsDebug(int client, int args)
{
	if (!GetConVarBool(cvar_Debug_Enabled))
	{
		ReplyToCommand(client, "[Debug] El sistema de debug esta deshabilitado.");
		return Plugin_Handled;
	}

	if (client == 0)
	{
		ReplyToCommand(client, "[Debug] Este comando solo puede ser usado in-game.");
		return Plugin_Handled;
	}

	ShowDebugMainMenu(client);
	return Plugin_Handled;
}

/**
 * Comando: Establece el nivel de un jugador
 */
public Action Command_SetLevel(int client, int args)
{
	if (!GetConVarBool(cvar_Debug_Enabled))
	{
		ReplyToCommand(client, "[Debug] El sistema de debug esta deshabilitado.");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		ReplyToCommand(client, "[Debug] Uso: sm_setlevel <jugador> <nivel>");
		return Plugin_Handled;
	}

	char targetName[MAX_NAME_LENGTH];
	GetCmdArg(1, targetName, sizeof(targetName));

	char levelArg[8];
	GetCmdArg(2, levelArg, sizeof(levelArg));
	int level = StringToInt(levelArg);

	int target = FindTarget(client, targetName, true, false);
	if (target == -1)
		return Plugin_Handled;

	g_iDebug_ForcedLevel[target] = level;

	ReplyToCommand(client, "[Debug] Nivel de %N establecido a %d (temporal para testing)", target, level);
	PrintToChat(target, "\x04[Debug]\x01 Tu nivel ha sido establecido a \x05%d\x01 por un admin (temporal)", level);

	return Plugin_Handled;
}

/**
 * Muestra el menu principal de debug
 */
void ShowDebugMainMenu(int client)
{
	Menu menu = new Menu(DebugMainMenu_Handler);
	menu.SetTitle("=== Rewards Debug Menu ===\nSelecciona una categoria:");

	menu.AddItem("passive", "Rewards Pasivos");
	menu.AddItem("active", "Rewards Activos (WIP)");
	menu.AddItem("level", "Gestion de Nivel");
	menu.AddItem("reset", "Reset Todo");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu principal
 */
public int DebugMainMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "passive"))
		{
			ShowPassiveRewardsMenu(client);
		}
		else if (StrEqual(info, "active"))
		{
			PrintToChat(client, "\x04[Debug]\x01 Rewards activos aun no implementados.");
			ShowDebugMainMenu(client);
		}
		else if (StrEqual(info, "level"))
		{
			ShowLevelManagementMenu(client);
		}
		else if (StrEqual(info, "reset"))
		{
			ResetAllDebugForClient(client);
			PrintToChat(client, "\x04[Debug]\x01 Todos los rewards de debug han sido reseteados.");
			ShowDebugMainMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra el menu de rewards pasivos
 */
void ShowPassiveRewardsMenu(int client)
{
	Menu menu = new Menu(PassiveRewardsMenu_Handler);
	menu.SetTitle("=== Passive Rewards Debug ===\nNivel actual: %d", GetClientLevel(client));

	// Lista de todos los rewards pasivos
	menu.AddItem("1", "Double Jump (Lvl 1)");
	menu.AddItem("2", "Acrobatics (Lvl 2)");
	menu.AddItem("3", "Health Bonus (Lvl 3)");
	menu.AddItem("4", "Medic (Lvl 4)");
	menu.AddItem("6", "Pack Rat (Lvl 6)");
	menu.AddItem("8", "Desert Cobra (Lvl 8)");
	menu.AddItem("9", "Damage Reduction (Lvl 9)");
	menu.AddItem("10", "Gene Mutations I (Lvl 10)");
	menu.AddItem("11", "Self Revive (Lvl 11)");
	menu.AddItem("13", "Sleight of Hand (Lvl 13)");
	menu.AddItem("15", "Knife (Lvl 15)");
	menu.AddItem("17", "Hard to Kill (Lvl 17)");
	menu.AddItem("19", "Arms Dealer (Lvl 19)");
	menu.AddItem("20", "Gene Mutations II (Lvl 20)");
	menu.AddItem("22", "Surgeon (Lvl 22)");
	menu.AddItem("24", "Extreme Conditioning (Lvl 24)");
	menu.AddItem("26", "BullsEye (Lvl 26)");
	menu.AddItem("29", "Size Matters (Lvl 29)");
	menu.AddItem("30", "Gene Mutations III (Lvl 30)");
	menu.AddItem("32", "Master at Arms (Lvl 32)");
	menu.AddItem("35", "Hardened Stance (Lvl 35)");
	menu.AddItem("38", "Critical Hit (Lvl 38)");
	menu.AddItem("40", "Gene Mutations IV (Lvl 40)");
	menu.AddItem("41", "Commando (Lvl 41)");
	menu.AddItem("44", "Second Chance (Lvl 44)");
	menu.AddItem("47", "Laser Rounds (Lvl 47)");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu de rewards pasivos
 */
public int PassiveRewardsMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		int level = StringToInt(info);

		ShowRewardActionMenu(client, level);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowDebugMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra el menu de accion para un reward especifico
 */
void ShowRewardActionMenu(int client, int rewardLevel)
{
	Menu menu = new Menu(RewardActionMenu_Handler);

	char title[128];
	Format(title, sizeof(title), "=== Reward Nivel %d ===\nQue deseas hacer?", rewardLevel);
	menu.SetTitle(title);

	char levelStr[8];
	IntToString(rewardLevel, levelStr, sizeof(levelStr));

	char activateInfo[16], testInfo[16];
	Format(activateInfo, sizeof(activateInfo), "activate_%d", rewardLevel);
	Format(testInfo, sizeof(testInfo), "test_%d", rewardLevel);

	menu.AddItem(activateInfo, "Activar este reward");
	menu.AddItem(testInfo, "Establecer nivel temporal");
	menu.AddItem("back", "← Volver");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu de accion
 */
public int RewardActionMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "back"))
		{
			ShowPassiveRewardsMenu(client);
		}
		else if (StrContains(info, "activate_") == 0)
		{
			char levelStr[8];
			strcopy(levelStr, sizeof(levelStr), info[9]);
			int level = StringToInt(levelStr);

			// Aplicar el reward inmediatamente
			LevelingRewards_ApplyRewards(client, level);
			PrintToChat(client, "\x04[Debug]\x01 Reward de nivel %d activado.", level);

			ShowPassiveRewardsMenu(client);
		}
		else if (StrContains(info, "test_") == 0)
		{
			char levelStr[8];
			strcopy(levelStr, sizeof(levelStr), info[5]);
			int level = StringToInt(levelStr);

			g_iDebug_ForcedLevel[client] = level;
			LevelingRewards_ApplyRewardsSilent(client, level);
			PrintToChat(client, "\x04[Debug]\x01 Nivel temporal establecido a %d. Rewards aplicados.", level);

			ShowPassiveRewardsMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra el menu de gestion de nivel
 */
void ShowLevelManagementMenu(int client)
{
	Menu menu = new Menu(LevelManagementMenu_Handler);

	int currentLevel = GetClientLevel(client);
	char title[128];
	Format(title, sizeof(title), "=== Gestion de Nivel ===\nNivel actual: %d", currentLevel);
	menu.SetTitle(title);

	menu.AddItem("set_1", "Nivel 1");
	menu.AddItem("set_10", "Nivel 10");
	menu.AddItem("set_20", "Nivel 20");
	menu.AddItem("set_30", "Nivel 30");
	menu.AddItem("set_40", "Nivel 40");
	menu.AddItem("set_50", "Nivel 50");
	menu.AddItem("set_custom", "Nivel personalizado...");
	menu.AddItem("reset", "Reset nivel (eliminar override)");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menu de gestion de nivel
 */
public int LevelManagementMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "reset"))
		{
			g_iDebug_ForcedLevel[client] = -1;
			PrintToChat(client, "\x04[Debug]\x01 Override de nivel eliminado. Usando nivel real del sistema.");
			ShowLevelManagementMenu(client);
		}
		else if (StrContains(info, "set_") == 0)
		{
			char levelStr[8];
			strcopy(levelStr, sizeof(levelStr), info[4]);
			int level = StringToInt(levelStr);

			g_iDebug_ForcedLevel[client] = level;
			LevelingRewards_ApplyRewardsSilent(client, level);
			PrintToChat(client, "\x04[Debug]\x01 Nivel temporal establecido a %d.", level);
			ShowLevelManagementMenu(client);
		}
		else if (StrEqual(info, "set_custom"))
		{
			PrintToChat(client, "\x04[Debug]\x01 Usa el comando: \x05sm_setlevel <nombre> <nivel>");
			ShowLevelManagementMenu(client);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowDebugMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Resetea todos los overrides de debug para un cliente
 */
void ResetAllDebugForClient(int client)
{
	for (int i = 0; i < 50; i++)
	{
		g_bDebug_ForceReward[client][i] = false;
	}
	g_iDebug_ForcedLevel[client] = -1;
}

/**
 * Obtiene el nivel del cliente (con override de debug si existe)
 */
int GetClientLevel(int client)
{
	if (g_iDebug_ForcedLevel[client] >= 0)
		return g_iDebug_ForcedLevel[client];

	return Leveling_GetPlayerLevel(client);
}

/**
 * Obtiene si el debug esta habilitado
 */
public bool LevelingDebug_IsEnabled()
{
	return GetConVarBool(cvar_Debug_Enabled);
}

/**
 * Obtiene el nivel override de debug (si existe)
 */
public int LevelingDebug_GetForcedLevel(int client)
{
	if (client <= 0 || client > MaxClients)
		return -1;

	return g_iDebug_ForcedLevel[client];
}
