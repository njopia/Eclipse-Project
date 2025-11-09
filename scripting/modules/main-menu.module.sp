#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === MAIN MENU MODULE ===
// Menú principal que unifica el acceso a todas las funcionalidades
// Similar al sistema del backup Master_3_46
//==================================================

/**
 * Inicializa el módulo de Main Menu
 */
public void MainMenu_OnPluginStart()
{
	// Registrar comandos
	RegConsoleCmd("menu", Command_MainMenu, "Abre el menú principal");
	RegConsoleCmd("sm_menu", Command_MainMenu, "Abre el menú principal");
	RegConsoleCmd("sm_mainmenu", Command_MainMenu, "Abre el menú principal");
}

/**
 * Comando: !menu / menu
 * Abre el menú principal con acceso a todas las funcionalidades
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
 * Muestra el menú principal al jugador
 */
void ShowMainMenu(int client)
{
	Menu menu = new Menu(MainMenu_Handler);

	// Obtener información del jugador
	char playerName[MAX_NAME_LENGTH];
	GetClientName(client, playerName, sizeof(playerName));

	int level = Leveling_GetPlayerLevel(client);
	int currentXP = Leveling_GetPlayerCurrentXP(client);
	int totalXP = Leveling_GetPlayerTotalXP(client);
	int currency = GetPlayerCurrency(client);

	// Título del menú con información del jugador
	char title[256];
	Format(title, sizeof(title), "═══ ECLIPSE MENU ═══\n \nJugador: %s\nNivel: %d | XP: %d/%d\nCurrency: %d\n ",
		playerName, level, currentXP, Leveling_GetXPRequiredForNextLevel(client), currency);
	menu.SetTitle(title);

	// === OPCIONES PRINCIPALES (siempre disponibles) ===
	menu.AddItem("buy", "🛒 Tienda / Buy Menu");
	menu.AddItem("level", "📊 Nivel & XP");
	menu.AddItem("rewards", "⭐ Mis Rewards/Habilidades");
	menu.AddItem("", "", ITEMDRAW_SPACER);

	// === INFORMACIÓN & ESTADÍSTICAS ===
	menu.AddItem("frags", "🎯 Panel de Frags");
	menu.AddItem("players", "👥 Lista de Jugadores");
	menu.AddItem("", "", ITEMDRAW_SPACER);

	// === OPCIONES DE SERVIDOR ===
	menu.AddItem("mapvote", "🗺️ Votación de Mapas");
	menu.AddItem("language", "🌐 Cambiar Idioma");
	menu.AddItem("", "", ITEMDRAW_SPACER);

	// === ACCIONES DE EQUIPO ===
	if (GetClientTeam(client) == 2)
	{
		menu.AddItem("join", "✓ Ya estás en Survivors");
	}
	else
	{
		menu.AddItem("join", "👤 Unirse a Survivors (!join)");
	}

	menu.AddItem("afk", "💤 Ir a Espectadores (!afk)");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú principal
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
				// Mostrar información de nivel
				FakeClientCommand(client, "sm_level");
				// Reabrir menú después de mostrar info
				CreateTimer(0.1, Timer_ReopenMenu, GetClientUserId(client));
			}
			else if (StrEqual(info, "rewards"))
			{
				// Mostrar rewards activos directamente
				ShowActiveRewardsMenuWithBackButton(client);
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
				// Abrir votación de mapas
				FakeClientCommand(client, "sm_custom");
			}
			else if (StrEqual(info, "language"))
			{
				// Abrir menú de idiomas
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
 * Timer: Reabrir el menú principal
 * Se usa después de comandos que muestran información en chat
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
 * Muestra el menú de rewards activos con botón de retorno al menú principal
 */
void ShowActiveRewardsMenuWithBackButton(int client)
{
	int level = Leveling_GetPlayerLevel(client);

	Menu menu = new Menu(ActiveRewards_MainMenuHandler);

	char title[128];
	Format(title, sizeof(title), "═══ MIS REWARDS ACTIVOS ═══\nNivel: %d\n ", level);
	menu.SetTitle(title);

	int count = 0;

	// Lista de rewards con sus niveles requeridos
	if (level >= 1)
	{
		menu.AddItem("info", "✓ Double Jump (Lvl 1)");
		count++;
	}
	if (level >= 2)
	{
		menu.AddItem("info", "✓ Acrobatics (Lvl 2)");
		count++;
	}
	if (level >= 3)
	{
		menu.AddItem("info", "✓ Health Bonus +25 HP (Lvl 3)");
		count++;
	}
	if (level >= 4)
	{
		menu.AddItem("info", "✓ Medic (Lvl 4)");
		count++;
	}
	if (level >= 6)
	{
		menu.AddItem("info", "✓ Pack Rat +25% Ammo (Lvl 6)");
		count++;
	}
	if (level >= 8)
	{
		menu.AddItem("info", "✓ Desert Cobra (Lvl 8)");
		count++;
	}
	if (level >= 9)
	{
		menu.AddItem("info", "✓ Damage Reduction -5% (Lvl 9)");
		count++;
	}
	if (level >= 10)
	{
		menu.AddItem("info", "✓ Gene Mutations I +100 HP (Lvl 10)");
		count++;
	}
	if (level >= 11)
	{
		menu.AddItem("info", "✓ Self Revive (Lvl 11)");
		count++;
	}
	if (level >= 13)
	{
		menu.AddItem("info", "✓ Sleight of Hand 2x Reload (Lvl 13)");
		count++;
	}
	if (level >= 15)
	{
		menu.AddItem("info", "✓ Knife (Lvl 15)");
		count++;
	}
	if (level >= 17)
	{
		menu.AddItem("info", "✓ Hard to Kill 500 HP (Lvl 17)");
		count++;
	}
	if (level >= 19)
	{
		menu.AddItem("info", "✓ Arms Dealer 40 Items (Lvl 19)");
		count++;
	}
	if (level >= 20)
	{
		menu.AddItem("info", "✓ Gene Mutations II +200 HP (Lvl 20)");
		count++;
	}
	if (level >= 22)
	{
		menu.AddItem("info", "✓ Surgeon -50% Heal Time (Lvl 22)");
		count++;
	}
	if (level >= 24)
	{
		menu.AddItem("info", "✓ Extreme Conditioning +25% Speed (Lvl 24)");
		count++;
	}
	if (level >= 26)
	{
		menu.AddItem("info", "✓ BullsEye (Lvl 26)");
		count++;
	}
	if (level >= 29)
	{
		menu.AddItem("info", "✓ Size Matters (Lvl 29)");
		count++;
	}
	if (level >= 30)
	{
		menu.AddItem("info", "✓ Gene Mutations III +300 HP (Lvl 30)");
		count++;
	}
	if (level >= 32)
	{
		menu.AddItem("info", "✓ Master at Arms 2x Melee (Lvl 32)");
		count++;
	}
	if (level >= 35)
	{
		menu.AddItem("info", "✓ Hardened Stance (Lvl 35)");
		count++;
	}
	if (level >= 38)
	{
		menu.AddItem("info", "✓ Critical Hit 10% (Lvl 38)");
		count++;
	}
	if (level >= 40)
	{
		menu.AddItem("info", "✓ Gene Mutations IV +400 HP (Lvl 40)");
		count++;
	}
	if (level >= 41)
	{
		menu.AddItem("info", "✓ Commando (Lvl 41)");
		count++;
	}
	if (level >= 44)
	{
		menu.AddItem("info", "✓ Second Chance (Lvl 44)");
		count++;
	}
	if (level >= 47)
	{
		menu.AddItem("info", "✓ Laser Rounds (Lvl 47)");
		count++;
	}

	if (count == 0)
	{
		menu.AddItem("none", "No tienes rewards activos aún", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú de rewards activos desde el menú principal
 */
public int ActiveRewards_MainMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		// Volver al menú principal
		ShowMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}
