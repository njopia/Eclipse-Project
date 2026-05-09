#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING RESET MODULE ===
// Permite a jugadores nivel 50 resetear su nivel
// a un punto de partida elegido (0/10/20/30/40).
//==================================================

#define RESET_MAX_LEVEL 50

// Almacena nivel elegido hasta confirmar
int g_iResetTargetLevel[MAXPLAYERS + 1];

public void LevelingReset_OnPluginStart()
{
	RegConsoleCmd("sm_resetlevel", Cmd_ResetLevel, "Resetea tu nivel (solo nivel 50)");
	RegConsoleCmd("resetlevel",    Cmd_ResetLevel, "Resetea tu nivel (solo nivel 50)");
}

// =============================================================================
// COMANDO PRINCIPAL
// =============================================================================

public Action Cmd_ResetLevel(int client, int args)
{
	if (client <= 0) return Plugin_Handled;

	if (g_iPlayerLevel[client] < RESET_MAX_LEVEL)
	{
		PrintToChat(client, "\x04[Eclipse]\x01 Solo puedes resetear tu nivel cuando alcances el nivel \x05%d\x01.", RESET_MAX_LEVEL);
		return Plugin_Handled;
	}

	LevelingReset_ShowMenu(client);
	return Plugin_Handled;
}

// =============================================================================
// MENU: ELEGIR NIVEL DESTINO
// =============================================================================

void LevelingReset_ShowMenu(int client)
{
	Menu menu = new Menu(LevelingReset_MenuHandler);
	menu.SetTitle("Reset de Nivel\nElige a qué nivel quieres volver:");

	menu.AddItem("0",  "Nivel 0  (inicio completo)");
	menu.AddItem("10", "Nivel 10");
	menu.AddItem("20", "Nivel 20");
	menu.AddItem("30", "Nivel 30");
	menu.AddItem("40", "Nivel 40");

	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int LevelingReset_MenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(item, info, sizeof(info));
		g_iResetTargetLevel[client] = StringToInt(info);
		LevelingReset_ShowConfirm(client);
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

// =============================================================================
// MENU: CONFIRMACION
// =============================================================================

void LevelingReset_ShowConfirm(int client)
{
	int target = g_iResetTargetLevel[client];

	Menu menu = new Menu(LevelingReset_ConfirmHandler);
	menu.SetTitle("¿Confirmar reset?\nBajarás de nivel %d → %d\nTu XP se reiniciará a 0.", RESET_MAX_LEVEL, target);

	menu.AddItem("yes", "Sí, confirmar reset");
	menu.AddItem("no",  "No, cancelar");

	menu.ExitButton = false;
	menu.Display(client, 15);
}

public int LevelingReset_ConfirmHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(item, info, sizeof(info));

		if (StrEqual(info, "yes"))
			LevelingReset_Execute(client, g_iResetTargetLevel[client]);
		else
			PrintToChat(client, "\x04[Eclipse]\x01 Reset cancelado.");
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

// =============================================================================
// EJECUCION
// =============================================================================

void LevelingReset_Execute(int client, int targetLevel)
{
	int oldLevel = g_iPlayerLevel[client];

	g_iPlayerLevel[client]    = targetLevel;
	g_iPlayerXP[client]       = 0;
	g_iTotalPlayerXP[client]  = 0;

	Leveling_UpdatePlayerDatabase(client);

	// Strip passive reward flags immediately — they are cached on spawn and won't
	// update on their own until the next round. Re-applying with the new level
	// sets every flag to false for rewards above targetLevel.
	if (IsPlayerAlive(client))
		LevelingRewards_ApplyRewardsSilent(client, targetLevel);

	PrintToChat(client, "\x04[Eclipse]\x01 Tu nivel ha sido reseteado de \x05%d\x01 a \x05%d\x01. ¡Buena suerte!",
		oldLevel, targetLevel);

	PrintToChatAll("\x04[Eclipse]\x01 \x05%N\x01 ha reseteado su nivel de \x05%d\x01 a \x05%d\x01.",
		client, oldLevel, targetLevel);

	LogMessage("[LevelReset] %N reset nivel %d -> %d", client, oldLevel, targetLevel);
}
