Menu g_MainMenu;
Menu g_DeployablesMenu;
Menu g_InstantsMenu;

#define BM_CHOICE_0_1 "BM_Instant"
#define BM_CHOICE_0_2 "BM_LongAction"
#define BM_CHOICE_0_3 "BM_Deployables"
#define BM_CHOICE_0_4 "BM_TeamBonuses"

#define BM_CHOICE_1_1 "BM_Instant_FireYell"
#define BM_CHOICE_1_2 "BM_Instant_PowerYell"

#define BM_CHOICE_2_1 "BM_LongAction_Long1Yell"
#define BM_CHOICE_2_2 "BM_LongAction_Long2Yell"

#define BM_CHOICE_3_1 "BM_Deployables_UV_Light"
#define BM_CHOICE_3_2 "BM_Deployables_Healing_Station"

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
			}
			if (StrEqual(info, BM_CHOICE_0_3))
			{
				PrintToChat(client, "\x05[Eclipse]\x01  Deployables Menu");
				g_DeployablesMenu.Display(client, 20);
			}
			if (StrEqual(info, BM_CHOICE_0_4))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Team Bonuses");
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
	char text[40];
	char title[40];

	// Create Submenu
	g_InstantsMenu = new Menu(MenuHandler_Instants, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Submenu Title", client);
	g_InstantsMenu.SetTitle(title);

	// Add Submenu Items
	Format(text, sizeof(text), "%T", BM_CHOICE_1_1, client);
	g_InstantsMenu.AddItem(BM_CHOICE_1_1, text);

	Format(text, sizeof(text), "%T", BM_CHOICE_1_2, client);
	g_InstantsMenu.AddItem(BM_CHOICE_1_2, text);
	g_InstantsMenu.ExitBackButton = true;
	g_InstantsMenu.ExitButton	  = true;
}

// Function to Create Submenu
public void DeployablesMenu(int client)
{
	char text[40];
	char title[40];

	// Create Submenu
	g_DeployablesMenu = new Menu(MenuHandler_Deployables, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Submenu Title", client);
	g_DeployablesMenu.SetTitle(title);

	// Add Submenu Items
	Format(text, sizeof(text), "%T", BM_CHOICE_3_1, client);
	g_DeployablesMenu.AddItem(BM_CHOICE_3_1, text);

	Format(text, sizeof(text), "%T", BM_CHOICE_3_2, client);
	g_DeployablesMenu.AddItem(BM_CHOICE_3_2, text);
	g_DeployablesMenu.ExitBackButton = true;
	g_DeployablesMenu.ExitButton	 = true;
}

public int MenuHandler_Deployables(Menu menu, MenuAction action, int client, int param)
{
	PrintToChatAll("action: %i", action);
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_3_1))
		{
			if (UVLightTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					SpawnUVLight(client);
					UpdateUVLight(client);
					PrintToChat(client, "\x04[Deployables]\x01 Deploying UV Light");
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
		else if (StrEqual(info, BM_CHOICE_3_2)) {
			if (HSTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					SpawnHealingStation(client);
					PrintToChat(client, "\x04[Deployables]\x01 Deploying Healing Station");
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
			Activate_FireYell(client);
		}
		else if (StrEqual(info, BM_CHOICE_1_2))
		{
			Activate_PowerYell(client);
		}
	}
	return 0;
}

public Action Cmd_Buy(int client, int args)
{
	char text[40];
	char title[40];
	g_MainMenu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Menu Title", client);
	g_MainMenu.SetTitle(title, LANG_SERVER);
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
	// Initialize Submenu if it doesn't exist
	if (g_DeployablesMenu == null)
	{
		DeployablesMenu(client);
	}
	if (g_InstantsMenu == null)
	{
		InstantsMenu(client);
	}
	return Plugin_Handled;
}