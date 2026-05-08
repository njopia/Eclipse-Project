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
		SetGlobalTransTarget(client);
		char message[128];
		Format(message, sizeof(message), "%t", "AdminMoney_SystemDisabled");
		PrintToChat(client, "[Admin] %s", message);
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
		SetGlobalTransTarget(client);
		char message[128];
		Format(message, sizeof(message), "%t", "AdminMoney_NoPermission");
		PrintToChat(client, "[Admin] %s", message);
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
	SetGlobalTransTarget(client);
	char title[128];
	Format(title, sizeof(title), "%t", "AdminMoney_SelectPlayer");
	menu.SetTitle(title);

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
		char noPlayersText[64];
		Format(noPlayersText, sizeof(noPlayersText), "%T", "AdminMoney_NoPlayers", client);
		menu.AddItem("", noPlayersText, ITEMDRAW_DISABLED);
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
				SetGlobalTransTarget(param1);
				char message[128];
				Format(message, sizeof(message), "%t", "AdminMoney_PlayerDisconnected");
				PrintToChat(param1, "[Admin] %s", message);
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

	SetGlobalTransTarget(admin);
	char sTitle[256];
	Format(sTitle, sizeof(sTitle), "%t", "AdminMoney_HowMuch", sPlayerName);
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
		Format(sDisplay, sizeof(sDisplay), "%T", "AdminMoney_AmountLabel", admin, amounts[i]);
		menu.AddItem(sAmount, sDisplay);
	}

	// Add custom amount option
	char customText[64];
	Format(customText, sizeof(customText), "%T", "AdminMoney_CustomAmount", admin);
	menu.AddItem("custom", customText);

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
				SetGlobalTransTarget(param1);
				char message[128];
				Format(message, sizeof(message), "%t", "AdminMoney_PlayerDisconnected");
				PrintToChat(param1, "[Admin] %s", message);
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

	Format(sTitle, sizeof(sTitle), "Cantidad personalizada para %s (escribe un numero):", sPlayerName);

	// Store target info
	g_iAdminMoneyTarget[admin] = target;

	// Use a chat message to prompt for input
	SetGlobalTransTarget(admin);
	char instructions[256];
	char targetText[128];
	Format(instructions, sizeof(instructions), "%t", "AdminMoney_ChatInstructions");
	Format(targetText, sizeof(targetText), "%t", "AdminMoney_TargetPlayer", sPlayerName);
	PrintToChat(admin, "\n[Admin] %s", instructions);
	PrintToChat(admin, "[Admin] %s", targetText);
}

/**
 * Command for custom amount input
 */
public Action Command_GiveMoneySub(int client, int args)
{
	if (args < 1)
	{
		SetGlobalTransTarget(client);
		char message[128];
		Format(message, sizeof(message), "%t", "AdminMoney_Usage");
		PrintToChat(client, "[Admin] %s", message);
		return Plugin_Handled;
	}

	char sAmount[16];
	GetCmdArg(1, sAmount, sizeof(sAmount));

	int amount = StringToInt(sAmount);
	int target = g_iAdminMoneyTarget[client];

	if (target <= 0 || !IsClientInGame(target))
	{
		SetGlobalTransTarget(client);
		char message[128];
		Format(message, sizeof(message), "%t", "AdminMoney_PlayerDisconnected");
		PrintToChat(client, "[Admin] %s", message);
		return Plugin_Handled;
	}

	if (amount <= 0)
	{
		SetGlobalTransTarget(client);
		char message[128];
		Format(message, sizeof(message), "%t", "AdminMoney_InvalidAmount");
		PrintToChat(client, "[Admin] %s", message);
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
		SetGlobalTransTarget(admin);
		char message[128];
		Format(message, sizeof(message), "%t", "AdminMoney_PlayerDisconnected");
		PrintToChat(admin, "[Admin] %s", message);
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

	SetGlobalTransTarget(admin);
	char adminMessage[256];
	Format(adminMessage, sizeof(adminMessage), "%t", "AdminMoney_GaveSuccess", amount, targetName, newCurrency);
	PrintToChat(admin, "[Admin] \x04%s\x01", adminMessage);

	SetGlobalTransTarget(target);
	char targetMessage[256];
	Format(targetMessage, sizeof(targetMessage), "%t", "AdminMoney_ReceivedMoney", adminName, amount, newCurrency);
	PrintToChat(target, "[Admin] %s", targetMessage);

	LogMessage("ADMIN_MONEY: %s gave %d money to %s (new total: %d)", adminName, amount, targetName, newCurrency);
}

/**
 * Reset on client disconnect
 */
public void AdminMoney_OnClientDisconnect(int client)
{
	g_iAdminMoneyTarget[client] = 0;
}
