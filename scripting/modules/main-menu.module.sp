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
				// Mostrar rewards activos
				FakeClientCommand(client, "sm_rewards");
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
