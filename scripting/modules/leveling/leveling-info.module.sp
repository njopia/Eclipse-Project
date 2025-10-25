#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING INFO MODULE ===
// Menú de información para jugadores sobre sus rewards activos
//==================================================

// --- ConVars ---
Handle cvar_Info_Enabled = INVALID_HANDLE;

/**
 * Inicializa el módulo de información
 */
public void LevelingInfo_OnPluginStart()
{
	cvar_Info_Enabled = CreateConVar(
		"leveling_info_enabled",
		"1",
		"Habilita el menú de información de rewards (1 = habilitado, 0 = deshabilitado)",
		FCVAR_PLUGIN
	);

	// Comandos para abrir el menú
	RegConsoleCmd("sm_rewards", Command_ShowRewards, "Muestra tus rewards activos");
	RegConsoleCmd("sm_myrewards", Command_ShowRewards, "Muestra tus rewards activos");
	RegConsoleCmd("sm_skills", Command_ShowRewards, "Muestra tus rewards activos");
	RegConsoleCmd("sm_perks", Command_ShowRewards, "Muestra tus rewards activos");
}

/**
 * Comando: Muestra el menú de rewards
 */
public Action Command_ShowRewards(int client, int args)
{
	if (!GetConVarBool(cvar_Info_Enabled))
	{
		ReplyToCommand(client, "[Rewards] El sistema de información está deshabilitado.");
		return Plugin_Handled;
	}

	if (client == 0)
	{
		ReplyToCommand(client, "[Rewards] Este comando solo puede ser usado in-game.");
		return Plugin_Handled;
	}

	ShowRewardsMainMenu(client);
	return Plugin_Handled;
}

/**
 * Muestra el menú principal de rewards
 */
void ShowRewardsMainMenu(int client)
{
	int level = GetPlayerLevel(client);
	int activeCount = GetActiveRewardsCount(level);

	Menu menu = new Menu(RewardsMainMenu_Handler);

	char title[256];
	Format(title, sizeof(title), "=== Mis Rewards ===\nNivel: %d | Activos: %d/23\n \nSelecciona una categoría:",
		level, activeCount);
	menu.SetTitle(title);

	menu.AddItem("active", "Ver Rewards Activos");
	menu.AddItem("locked", "Ver Rewards Bloqueados");
	menu.AddItem("all", "Ver Todos los Rewards");
	menu.AddItem("next", "Próximo Reward");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú principal
 */
public int RewardsMainMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "active"))
		{
			ShowActiveRewardsMenu(client);
		}
		else if (StrEqual(info, "locked"))
		{
			ShowLockedRewardsMenu(client);
		}
		else if (StrEqual(info, "all"))
		{
			ShowAllRewardsMenu(client);
		}
		else if (StrEqual(info, "next"))
		{
			ShowNextRewardInfo(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra el menú de rewards activos
 */
void ShowActiveRewardsMenu(int client)
{
	int level = GetPlayerLevel(client);

	Menu menu = new Menu(ActiveRewardsMenu_Handler);

	char title[128];
	Format(title, sizeof(title), "=== Rewards Activos ===\nNivel: %d\n ", level);
	menu.SetTitle(title);

	int count = 0;

	// Lista de rewards con sus niveles requeridos
	if (level >= 1)
	{
		menu.AddItem("1", "✓ Double Jump (Lvl 1)");
		count++;
	}
	if (level >= 2)
	{
		menu.AddItem("2", "✓ Acrobatics (Lvl 2)");
		count++;
	}
	if (level >= 3)
	{
		menu.AddItem("3", "✓ Health Bonus (Lvl 3)");
		count++;
	}
	if (level >= 4)
	{
		menu.AddItem("4", "✓ Medic (Lvl 4)");
		count++;
	}
	if (level >= 6)
	{
		menu.AddItem("6", "✓ Pack Rat (Lvl 6)");
		count++;
	}
	if (level >= 8)
	{
		menu.AddItem("8", "✓ Desert Cobra (Lvl 8)");
		count++;
	}
	if (level >= 9)
	{
		menu.AddItem("9", "✓ Damage Reduction (Lvl 9)");
		count++;
	}
	if (level >= 10)
	{
		menu.AddItem("10", "✓ Gene Mutations I (Lvl 10)");
		count++;
	}
	if (level >= 11)
	{
		menu.AddItem("11", "✓ Self Revive (Lvl 11)");
		count++;
	}
	if (level >= 13)
	{
		menu.AddItem("13", "✓ Sleight of Hand (Lvl 13)");
		count++;
	}
	if (level >= 15)
	{
		menu.AddItem("15", "✓ Knife (Lvl 15)");
		count++;
	}
	if (level >= 17)
	{
		menu.AddItem("17", "✓ Hard to Kill (Lvl 17)");
		count++;
	}
	if (level >= 19)
	{
		menu.AddItem("19", "✓ Arms Dealer (Lvl 19)");
		count++;
	}
	if (level >= 20)
	{
		menu.AddItem("20", "✓ Gene Mutations II (Lvl 20)");
		count++;
	}
	if (level >= 22)
	{
		menu.AddItem("22", "✓ Surgeon (Lvl 22)");
		count++;
	}
	if (level >= 24)
	{
		menu.AddItem("24", "✓ Extreme Conditioning (Lvl 24)");
		count++;
	}
	if (level >= 26)
	{
		menu.AddItem("26", "✓ BullsEye (Lvl 26)");
		count++;
	}
	if (level >= 29)
	{
		menu.AddItem("29", "✓ Size Matters (Lvl 29)");
		count++;
	}
	if (level >= 30)
	{
		menu.AddItem("30", "✓ Gene Mutations III (Lvl 30)");
		count++;
	}
	if (level >= 32)
	{
		menu.AddItem("32", "✓ Master at Arms (Lvl 32)");
		count++;
	}
	if (level >= 35)
	{
		menu.AddItem("35", "✓ Hardened Stance (Lvl 35)");
		count++;
	}
	if (level >= 38)
	{
		menu.AddItem("38", "✓ Critical Hit (Lvl 38)");
		count++;
	}
	if (level >= 40)
	{
		menu.AddItem("40", "✓ Gene Mutations IV (Lvl 40)");
		count++;
	}
	if (level >= 41)
	{
		menu.AddItem("41", "✓ Commando (Lvl 41)");
		count++;
	}
	if (level >= 44)
	{
		menu.AddItem("44", "✓ Second Chance (Lvl 44)");
		count++;
	}
	if (level >= 47)
	{
		menu.AddItem("47", "✓ Laser Rounds (Lvl 47)");
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
 * Handler del menú de rewards activos
 */
public int ActiveRewardsMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));

		if (!StrEqual(info, "none"))
		{
			int rewardLevel = StringToInt(info);
			ShowRewardDetailMenu(client, rewardLevel, true);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowRewardsMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra el menú de rewards bloqueados
 */
void ShowLockedRewardsMenu(int client)
{
	int level = GetPlayerLevel(client);

	Menu menu = new Menu(LockedRewardsMenu_Handler);

	char title[128];
	Format(title, sizeof(title), "=== Rewards Bloqueados ===\nNivel: %d\n ", level);
	menu.SetTitle(title);

	int count = 0;

	// Lista de rewards bloqueados
	if (level < 1)
	{
		menu.AddItem("1", "✗ Double Jump (Lvl 1)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 2)
	{
		menu.AddItem("2", "✗ Acrobatics (Lvl 2)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 3)
	{
		menu.AddItem("3", "✗ Health Bonus (Lvl 3)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 4)
	{
		menu.AddItem("4", "✗ Medic (Lvl 4)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 6)
	{
		menu.AddItem("6", "✗ Pack Rat (Lvl 6)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 8)
	{
		menu.AddItem("8", "✗ Desert Cobra (Lvl 8)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 9)
	{
		menu.AddItem("9", "✗ Damage Reduction (Lvl 9)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 10)
	{
		menu.AddItem("10", "✗ Gene Mutations I (Lvl 10)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 11)
	{
		menu.AddItem("11", "✗ Self Revive (Lvl 11)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 13)
	{
		menu.AddItem("13", "✗ Sleight of Hand (Lvl 13)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 15)
	{
		menu.AddItem("15", "✗ Knife (Lvl 15)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 17)
	{
		menu.AddItem("17", "✗ Hard to Kill (Lvl 17)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 19)
	{
		menu.AddItem("19", "✗ Arms Dealer (Lvl 19)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 20)
	{
		menu.AddItem("20", "✗ Gene Mutations II (Lvl 20)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 22)
	{
		menu.AddItem("22", "✗ Surgeon (Lvl 22)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 24)
	{
		menu.AddItem("24", "✗ Extreme Conditioning (Lvl 24)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 26)
	{
		menu.AddItem("26", "✗ BullsEye (Lvl 26)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 29)
	{
		menu.AddItem("29", "✗ Size Matters (Lvl 29)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 30)
	{
		menu.AddItem("30", "✗ Gene Mutations III (Lvl 30)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 32)
	{
		menu.AddItem("32", "✗ Master at Arms (Lvl 32)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 35)
	{
		menu.AddItem("35", "✗ Hardened Stance (Lvl 35)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 38)
	{
		menu.AddItem("38", "✗ Critical Hit (Lvl 38)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 40)
	{
		menu.AddItem("40", "✗ Gene Mutations IV (Lvl 40)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 41)
	{
		menu.AddItem("41", "✗ Commando (Lvl 41)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 44)
	{
		menu.AddItem("44", "✗ Second Chance (Lvl 44)", ITEMDRAW_DISABLED);
		count++;
	}
	if (level < 47)
	{
		menu.AddItem("47", "✗ Laser Rounds (Lvl 47)", ITEMDRAW_DISABLED);
		count++;
	}

	if (count == 0)
	{
		menu.AddItem("none", "¡Tienes todos los rewards desbloqueados!", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú de rewards bloqueados
 */
public int LockedRewardsMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowRewardsMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra todos los rewards (activos y bloqueados)
 */
void ShowAllRewardsMenu(int client)
{
	int level = GetPlayerLevel(client);

	Menu menu = new Menu(AllRewardsMenu_Handler);

	char title[128];
	Format(title, sizeof(title), "=== Todos los Rewards ===\nNivel: %d\n ", level);
	menu.SetTitle(title);

	// Lista completa con indicadores de estado
	AddRewardToMenu(menu, 1, "Double Jump", level);
	AddRewardToMenu(menu, 2, "Acrobatics", level);
	AddRewardToMenu(menu, 3, "Health Bonus", level);
	AddRewardToMenu(menu, 4, "Medic", level);
	AddRewardToMenu(menu, 6, "Pack Rat", level);
	AddRewardToMenu(menu, 8, "Desert Cobra", level);
	AddRewardToMenu(menu, 9, "Damage Reduction", level);
	AddRewardToMenu(menu, 10, "Gene Mutations I", level);
	AddRewardToMenu(menu, 11, "Self Revive", level);
	AddRewardToMenu(menu, 13, "Sleight of Hand", level);
	AddRewardToMenu(menu, 15, "Knife", level);
	AddRewardToMenu(menu, 17, "Hard to Kill", level);
	AddRewardToMenu(menu, 19, "Arms Dealer", level);
	AddRewardToMenu(menu, 20, "Gene Mutations II", level);
	AddRewardToMenu(menu, 22, "Surgeon", level);
	AddRewardToMenu(menu, 24, "Extreme Conditioning", level);
	AddRewardToMenu(menu, 26, "BullsEye", level);
	AddRewardToMenu(menu, 29, "Size Matters", level);
	AddRewardToMenu(menu, 30, "Gene Mutations III", level);
	AddRewardToMenu(menu, 32, "Master at Arms", level);
	AddRewardToMenu(menu, 35, "Hardened Stance", level);
	AddRewardToMenu(menu, 38, "Critical Hit", level);
	AddRewardToMenu(menu, 40, "Gene Mutations IV", level);
	AddRewardToMenu(menu, 41, "Commando", level);
	AddRewardToMenu(menu, 44, "Second Chance", level);
	AddRewardToMenu(menu, 47, "Laser Rounds", level);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú de todos los rewards
 */
public int AllRewardsMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		// Extraer el nivel del formato "active_X" o "locked_X"
		char parts[2][16];
		ExplodeString(info, "_", parts, 2, 16);

		int rewardLevel = StringToInt(parts[1]);
		bool isActive = StrEqual(parts[0], "active");

		ShowRewardDetailMenu(client, rewardLevel, isActive);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowRewardsMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Agrega un reward al menú con el formato correcto
 */
void AddRewardToMenu(Menu menu, int rewardLevel, const char[] name, int playerLevel)
{
	char display[64], info[32];

	if (playerLevel >= rewardLevel)
	{
		Format(display, sizeof(display), "✓ %s (Lvl %d)", name, rewardLevel);
		Format(info, sizeof(info), "active_%d", rewardLevel);
		menu.AddItem(info, display);
	}
	else
	{
		Format(display, sizeof(display), "✗ %s (Lvl %d)", name, rewardLevel);
		Format(info, sizeof(info), "locked_%d", rewardLevel);
		menu.AddItem(info, display, ITEMDRAW_DISABLED);
	}
}

/**
 * Muestra información detallada de un reward
 */
void ShowRewardDetailMenu(int client, int rewardLevel, bool isActive)
{
	Menu menu = new Menu(RewardDetailMenu_Handler);

	char title[256], description[512];
	GetRewardInfo(rewardLevel, title, sizeof(title), description, sizeof(description));

	char fullTitle[768];
	if (isActive)
	{
		Format(fullTitle, sizeof(fullTitle), "=== %s ===\nEstado: ACTIVO ✓\nNivel: %d\n \n%s",
			title, rewardLevel, description);
	}
	else
	{
		Format(fullTitle, sizeof(fullTitle), "=== %s ===\nEstado: BLOQUEADO ✗\nRequiere nivel: %d\n \n%s",
			title, rewardLevel, description);
	}

	menu.SetTitle(fullTitle);
	menu.AddItem("back", "← Volver");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú de detalles
 */
public int RewardDetailMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		ShowAllRewardsMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Muestra información sobre el próximo reward
 */
void ShowNextRewardInfo(int client)
{
	int level = GetPlayerLevel(client);
	int nextLevel = GetNextRewardLevel(level);

	if (nextLevel == -1)
	{
		PrintToChat(client, "\x04[Rewards]\x01 ¡Ya tienes todos los rewards desbloqueados!");
		ShowRewardsMainMenu(client);
		return;
	}

	Menu menu = new Menu(NextRewardMenu_Handler);

	char title[256], description[512], rewardName[64];
	GetRewardInfo(nextLevel, rewardName, sizeof(rewardName), description, sizeof(description));

	int levelsNeeded = nextLevel - level;

	Format(title, sizeof(title), "=== Próximo Reward ===\n%s\nNivel requerido: %d\nTe faltan %d niveles\n \n%s",
		rewardName, nextLevel, levelsNeeded, description);

	menu.SetTitle(title);
	menu.AddItem("back", "← Volver");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Handler del menú de próximo reward
 */
public int NextRewardMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		ShowRewardsMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

/**
 * Obtiene información de un reward específico
 */
void GetRewardInfo(int level, char[] name, int nameLen, char[] description, int descLen)
{
	switch (level)
	{
		case 1:
		{
			strcopy(name, nameLen, "Double Jump");
			strcopy(description, descLen, "Permite realizar un segundo salto en el aire.\nIdeal para alcanzar lugares altos o esquivar ataques.");
		}
		case 2:
		{
			strcopy(name, nameLen, "Acrobatics");
			strcopy(description, descLen, "Aumenta la altura de salto y reduce el daño de caída en 50%.\nPerfecto para movilidad vertical.");
		}
		case 3:
		{
			strcopy(name, nameLen, "Health Bonus");
			strcopy(description, descLen, "Otorga +25 HP adicionales al aparecer.\nMayor supervivencia desde el inicio.");
		}
		case 4:
		{
			strcopy(name, nameLen, "Medic");
			strcopy(description, descLen, "Bonus HP de items curativos:\n• Pills: +50 HP\n• Adrenaline: +25 HP\n• First Aid: +200 HP");
		}
		case 6:
		{
			strcopy(name, nameLen, "Pack Rat");
			strcopy(description, descLen, "Aumenta la capacidad de munición en 25%.\nMás balas = más tiempo disparando.");
		}
		case 8:
		{
			strcopy(name, nameLen, "Desert Cobra");
			strcopy(description, descLen, "Reemplaza tu pistola con un Magnum cuando estás incapacitado.\nMayor daño para defenderte en situaciones críticas.");
		}
		case 9:
		{
			strcopy(name, nameLen, "Damage Reduction");
			strcopy(description, descLen, "Reduce el daño recibido en 5%.\nMayor resistencia a ataques enemigos.");
		}
		case 10:
		{
			strcopy(name, nameLen, "Gene Mutations I");
			strcopy(description, descLen, "+100 HP máximo adicional\nRegeneración: +1 HP cada 5 segundos\nPrimera mejora genética.");
		}
		case 11:
		{
			strcopy(name, nameLen, "Self Revive");
			strcopy(description, descLen, "Auto-revive usando la tecla USE cuando estás incapacitado.\nDuración: 2.5 segundos\n¡No necesitas ayuda de nadie!");
		}
		case 13:
		{
			strcopy(name, nameLen, "Sleight of Hand");
			strcopy(description, descLen, "Duplica la velocidad de recarga de armas.\nMenos tiempo recargando = más tiempo disparando.");
		}
		case 15:
		{
			strcopy(name, nameLen, "Knife");
			strcopy(description, descLen, "Apuñala infectados especiales cuando te capturan.\nUsa la tecla USE durante 1.5s para intentar liberarte.");
		}
		case 17:
		{
			strcopy(name, nameLen, "Hard to Kill");
			strcopy(description, descLen, "HP de incapacitación aumentado de 300 a 500.\nMás difícil de morir cuando estás caído.");
		}
		case 19:
		{
			strcopy(name, nameLen, "Arms Dealer");
			strcopy(description, descLen, "Expande tu mochila de 9 a 40 items.\n¡Lleva todo el arsenal que necesites!");
		}
		case 20:
		{
			strcopy(name, nameLen, "Gene Mutations II");
			strcopy(description, descLen, "+200 HP máximo adicional (total: +300)\nRegeneración: +2 HP cada 5 segundos\nSegunda mejora genética.");
		}
		case 22:
		{
			strcopy(name, nameLen, "Surgeon");
			strcopy(description, descLen, "Reduce el tiempo de uso de items de curación en 50%.\nCura más rápido = mayor supervivencia.");
		}
		case 24:
		{
			strcopy(name, nameLen, "Extreme Conditioning");
			strcopy(description, descLen, "Aumenta la velocidad de movimiento en 25%.\n¡Corre más rápido que los infectados!");
		}
		case 26:
		{
			strcopy(name, nameLen, "BullsEye");
			strcopy(description, descLen, "Equipa laser sight gratis en todas tus armas primarias.\nMejor precisión sin gastar puntos de mejora.");
		}
		case 29:
		{
			strcopy(name, nameLen, "Size Matters");
			strcopy(description, descLen, "Recarga M60 y Grenade Launcher en ammo piles.\nArmas pesadas siempre listas para la acción.");
		}
		case 30:
		{
			strcopy(name, nameLen, "Gene Mutations III");
			strcopy(description, descLen, "+300 HP máximo adicional (total: +600)\nRegeneración: +3 HP cada 5 segundos\nTercera mejora genética.");
		}
		case 32:
		{
			strcopy(name, nameLen, "Master at Arms");
			strcopy(description, descLen, "Duplica el daño de armas melee.\nDaño: 100 → 200\n¡Destruye infectados cuerpo a cuerpo!");
		}
		case 35:
		{
			strcopy(name, nameLen, "Hardened Stance");
			strcopy(description, descLen, "Elimina el efecto de stagger de la witch.\nCamina cerca de witches sin ser empujado.");
		}
		case 38:
		{
			strcopy(name, nameLen, "Critical Hit");
			strcopy(description, descLen, "10% de probabilidad de hacer daño crítico.\nMultiplicador: 1.5x - 3.0x daño\n¡Hits devastadores!");
		}
		case 40:
		{
			strcopy(name, nameLen, "Gene Mutations IV");
			strcopy(description, descLen, "+400 HP máximo adicional (total: +1000)\nRegeneración: +4 HP cada 5 segundos\nMejora genética máxima.");
		}
		case 41:
		{
			strcopy(name, nameLen, "Commando");
			strcopy(description, descLen, "Permite recargar M60 en ammo piles.\nCartucho extendido de 300 balas\n¡Nunca te quedes sin munición!");
		}
		case 44:
		{
			strcopy(name, nameLen, "Second Chance");
			strcopy(description, descLen, "Auto-revive automático una vez por ronda.\nVuelves a la vida después de morir\n¡Una segunda oportunidad!");
		}
		case 47:
		{
			strcopy(name, nameLen, "Laser Rounds");
			strcopy(description, descLen, "Munición láser para rifles y SMGs.\nDaño aumentado + efecto de incineración\n¡Poder de fuego máximo!");
		}
		default:
		{
			strcopy(name, nameLen, "Reward Desconocido");
			strcopy(description, descLen, "No hay información disponible.");
		}
	}
}

/**
 * Obtiene el siguiente nivel de reward después del nivel actual
 */
int GetNextRewardLevel(int currentLevel)
{
	int rewardLevels[26] = {1, 2, 3, 4, 6, 8, 9, 10, 11, 13, 15, 17, 19, 20, 22, 24, 26, 29, 30, 32, 35, 38, 40, 41, 44, 47};

	for (int i = 0; i < 26; i++)
	{
		if (rewardLevels[i] > currentLevel)
		{
			return rewardLevels[i];
		}
	}

	return -1; // Ya tiene todos
}

/**
 * Cuenta cuántos rewards activos tiene el jugador
 */
int GetActiveRewardsCount(int level)
{
	int count = 0;
	int rewardLevels[26] = {1, 2, 3, 4, 6, 8, 9, 10, 11, 13, 15, 17, 19, 20, 22, 24, 26, 29, 30, 32, 35, 38, 40, 41, 44, 47};

	for (int i = 0; i < 26; i++)
	{
		if (level >= rewardLevels[i])
		{
			count++;
		}
	}

	return count;
}

/**
 * Obtiene el nivel del jugador del sistema de leveling real
 */
int GetPlayerLevel(int client)
{
	// Primero verificar si hay un override de debug
	int debugLevel = LevelingDebug_GetForcedLevel(client);
	if (debugLevel >= 0)
		return debugLevel;

	// Obtener el nivel real del sistema de leveling
	return Leveling_GetPlayerLevel(client);
}

/**
 * Obtiene si el módulo de info está habilitado
 */
public bool LevelingInfo_IsEnabled()
{
	return GetConVarBool(cvar_Info_Enabled);
}
