/*
 * Admin Money Menu - Feature for admins to give money to players
 * Allows admins to select a player (excluding bots) and give them money using SetPlayerCurrency
 */

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

// Convars
Handle cvar_AdminMoneyEnabled = INVALID_HANDLE;

// Global variable to store target player for admin
int g_iAdminMoneyTarget[MAXPLAYERS + 1];

// Initialize admin money system
public void AdminMoney_OnPluginStart()
{
	cvar_AdminMoneyEnabled = CreateConVar("admin_money_enabled", "1", "Enable admin money menu? (0 = disabled, 1 = enabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Register the admin command
	RegConsoleCmd("sm_givemoney", Command_GiveMoney, "Admin command to open money menu");
	RegConsoleCmd("sm_money", Command_GiveMoney, "Admin command to open money menu");
}

/**
 * Command: sm_givemoney / sm_money
 * Opens a menu for admins to select a player and give them money
 */
public Action Command_GiveMoney(int client, int args)
{
	// Check if feature is enabled
	if (!GetConVarBool(cvar_AdminMoneyEnabled))
	{
		PrintToChat(client, "[Admin] El sistema de dinero para admins está deshabilitado");
		return Plugin_Handled;
	}

	// Check if client is valid and in game
	if (client <= 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	// Check if client has admin flag
	if (!CheckCommandAccess(client, "sm_givemoney", ADMFLAG_GENERIC, true))
	{
		PrintToChat(client, "[Admin] No tienes permisos para usar este comando");
		return Plugin_Handled;
	}

	// Open player selection menu
	ShowPlayerSelectionMenu(client);

	return Plugin_Handled;
}

/**
 * Show menu to select a player
 */
void ShowPlayerSelectionMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SelectPlayer);
	menu.SetTitle("Selecciona un jugador para darle dinero");

	// Add all connected survivors (excluding bots)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsSurvivor(i) && !IsFakeClient(i))
		{
			char sUserID[16];
			char sPlayerName[MAX_NAME_LENGTH];
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			GetClientName(i, sPlayerName, sizeof(sPlayerName));

			menu.AddItem(sUserID, sPlayerName);
		}
	}

	// If no survivors found
	if (menu.ItemCount == 0)
	{
		menu.AddItem("", "No hay jugadores disponibles", ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handle player selection menu
 */
public int MenuHandler_SelectPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sUserID[16];
			menu.GetItem(param2, sUserID, sizeof(sUserID));

			int targetClient = GetClientOfUserId(StringToInt(sUserID));

			if (targetClient > 0 && IsClientInGame(targetClient))
			{
				// Show amount selection menu
				ShowAmountSelectionMenu(param1, targetClient);
			}
			else
			{
				PrintToChat(param1, "[Admin] El jugador se desconectó");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				// Handle back button if needed
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
 * Show menu to select the amount of currency to give
 */
void ShowAmountSelectionMenu(int admin, int target)
{
	Menu menu = new Menu(MenuHandler_SelectAmount);

	char sPlayerName[MAX_NAME_LENGTH];
	GetClientName(target, sPlayerName, sizeof(sPlayerName));

	char sTitle[256];
	Format(sTitle, sizeof(sTitle), "¿Cuánto dinero dar a %s?", sPlayerName);
	menu.SetTitle(sTitle);

	// Store the target client as user data so we can retrieve it later
	char sUserID[16];
	IntToString(GetClientUserId(target), sUserID, sizeof(sUserID));
	menu.ExitBackButton = true;

	// Preset amounts
	int amounts[] = {25, 50, 100, 250, 500, 1000};
	char sAmount[16];
	char sDisplay[64];

	for (int i = 0; i < sizeof(amounts); i++)
	{
		IntToString(amounts[i], sAmount, sizeof(sAmount));
		Format(sDisplay, sizeof(sDisplay), "%d dinero", amounts[i]);
		menu.AddItem(sAmount, sDisplay);
	}

	// Add custom amount option
	menu.AddItem("custom", "Cantidad personalizada");

	// Store target info in a separate variable for retrieval
	g_iAdminMoneyTarget[admin] = target;

	menu.Display(admin, MENU_TIME_FOREVER);
}

/**
 * Handle amount selection menu
 */
public int MenuHandler_SelectAmount(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sAmount[16];
			menu.GetItem(param2, sAmount, sizeof(sAmount));

			int target = g_iAdminMoneyTarget[param1];

			if (target <= 0 || !IsClientInGame(target))
			{
				PrintToChat(param1, "[Admin] El jugador se desconectó");
				return 0;
			}

			// Check if custom option was selected
			if (strcmp(sAmount, "custom") == 0)
			{
				// Ask for custom amount
				ShowCustomAmountPrompt(param1, target);
			}
			else
			{
				int amount = StringToInt(sAmount);
				GivePlayerMoney(param1, target, amount);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowPlayerSelectionMenu(param1);
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
 * Show prompt for custom amount
 */
void ShowCustomAmountPrompt(int admin, int target)
{
	char sTitle[256];
	char sPlayerName[MAX_NAME_LENGTH];
	GetClientName(target, sPlayerName, sizeof(sPlayerName));

	Format(sTitle, sizeof(sTitle), "Cantidad personalizada para %s (escribe un número):", sPlayerName);

	// Store target info
	g_iAdminMoneyTarget[admin] = target;

	// Use a chat message to prompt for input
	PrintToChat(admin, "\n[Admin] Escribe en el chat la cantidad de dinero a dar (ejemplo: !givemoney 500)");
	PrintToChat(admin, "[Admin] Jugador objetivo: %s", sPlayerName);
}

/**
 * Command for custom amount input
 */
public Action Command_GiveMoneySub(int client, int args)
{
	if (args < 1)
	{
		PrintToChat(client, "[Admin] Uso: !givemoney <cantidad>");
		return Plugin_Handled;
	}

	char sAmount[16];
	GetCmdArg(1, sAmount, sizeof(sAmount));

	int amount = StringToInt(sAmount);
	int target = g_iAdminMoneyTarget[client];

	if (target <= 0 || !IsClientInGame(target))
	{
		PrintToChat(client, "[Admin] El jugador se desconectó");
		return Plugin_Handled;
	}

	if (amount <= 0)
	{
		PrintToChat(client, "[Admin] Debes ingresar una cantidad válida (mayor a 0)");
		return Plugin_Handled;
	}

	GivePlayerMoney(client, target, amount);

	return Plugin_Handled;
}

/**
 * Give money to a player using SetPlayerCurrency
 */
void GivePlayerMoney(int admin, int target, int amount)
{
	if (target <= 0 || !IsClientInGame(target))
	{
		PrintToChat(admin, "[Admin] El jugador se desconectó");
		return;
	}

	// Get current currency
	int currentCurrency = GetPlayerCurrency(target);
	int newCurrency = currentCurrency + amount;

	// Set new currency
	SetPlayerCurrency(target, newCurrency);

	// Log the action
	char adminName[MAX_NAME_LENGTH];
	char targetName[MAX_NAME_LENGTH];
	GetClientName(admin, adminName, sizeof(adminName));
	GetClientName(target, targetName, sizeof(targetName));

	PrintToChat(admin, "[Admin] \x04✓\x01 Diste %d dinero a %s (Total: %d)", amount, targetName, newCurrency);
	PrintToChat(target, "[Admin] El admin %s te dio %d dinero (Total: %d)", adminName, amount, newCurrency);

	LogMessage("ADMIN_MONEY: %s gave %d money to %s (new total: %d)", adminName, amount, targetName, newCurrency);
}

/**
 * Reset on client disconnect
 */
public void AdminMoney_OnClientDisconnect(int client)
{
	g_iAdminMoneyTarget[client] = 0;
}
