
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
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
			if (StrEqual(info, CHOICE3))
			{
				PrintToChatAll("Client %d somehow selected %s despite it being disabled", param1, info);
			}
			else
			{
				PrintToChatAll("Clientes %d selected %s", param1, info);
			}
		}

		case MenuAction_Cancel:
		{
			PrintToChatAll("Client %d's menu was cancelled for reason %d", param1, param2);
		}

		case MenuAction_End:
		{
			delete menu;
		}

		case MenuAction_DrawItem:
		{
			int	 style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);

			if (StrEqual(info, CHOICE3))
			{
				return ITEMDRAW_DISABLED;
			}
			else
			{
				return style;
			}
		}
	}

	return 0;
}

public Action Cmd_Buy(int client, int args)
{
	char text[40];
	char title[40];
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Menu Title", client);
	menu.SetTitle(title, LANG_SERVER);
	Format(text, sizeof(text), "%T", "Choice 1", client);
	menu.AddItem(CHOICE1, text);
	Format(text, sizeof(text), "%T", "Choice 2", client);
	menu.AddItem(CHOICE2, text);
	Format(text, sizeof(text), "%T", "Choice 3", client);
	menu.AddItem(CHOICE3, text);
	menu.ExitButton = true;
	menu.Display(client, 20);

	return Plugin_Handled;
}