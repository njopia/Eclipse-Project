#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING UI MODULE ===
// Interfaz en chat para mostrar nivel y progreso
//==================================================

// --- ConVars para configurar UI ---
Handle cvar_UIShowOnSpawn = INVALID_HANDLE;
Handle cvar_UIShowOnKill = INVALID_HANDLE;
Handle cvar_UIShowProgressBar = INVALID_HANDLE;

/**
 * Inicializa el módulo de UI
 */
public void LevelingUI_OnPluginStart()
{
	cvar_UIShowOnSpawn = CreateConVar(
		"leveling_ui_show_spawn",
		"1",
		"Mostrar nivel/XP al aparecer en el mapa (0/1)",
		FCVAR_PLUGIN
	);

	cvar_UIShowOnKill = CreateConVar(
		"leveling_ui_show_kill",
		"1",
		"Mostrar XP ganado al matar enemigos (0/1)",
		FCVAR_PLUGIN
	);

	cvar_UIShowProgressBar = CreateConVar(
		"leveling_ui_progress_bar",
		"1",
		"Mostrar barra de progreso en formato ASCII (0/1)",
		FCVAR_PLUGIN
	);

	// Registrar comando para ver info de nivel
	RegConsoleCmd("sm_level", Cmd_ShowLevelInfo);
	RegConsoleCmd("sm_xp", Cmd_ShowLevelInfo);
	RegConsoleCmd("sm_exp", Cmd_ShowLevelInfo);
}

/**
 * Muestra la información de nivel en chat al spawn (llamado desde rewards)
 * @param client - ID del cliente
 */
public void LevelingUI_ShowOnSpawn(int client)
{
	if (!GetConVarBool(cvar_UIShowOnSpawn))
		return;

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return;

	// Mostrar info con pequeño delay
	CreateTimer(0.5, Timer_ShowSpawnInfo, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Timer: Mostrar info al spawn
 */
public Action Timer_ShowSpawnInfo(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Stop;

	LevelingUI_DisplayLevelInfo(client);

	return Plugin_Stop;
}

/**
 * Muestra la información de nivel en chat
 * @param client - ID del cliente
 */
public void LevelingUI_DisplayLevelInfo(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	int level = Leveling_GetPlayerLevel(client);
	int currentXP = Leveling_GetPlayerCurrentXP(client);
	int totalXP = Leveling_GetPlayerTotalXP(client);
	int nextLevelXP = Leveling_GetXPRequiredForNextLevel(client);
	int progress = Leveling_GetLevelProgress(client);

	// Encabezado
	PrintToChat(client, "\x04=== INFORMACIÓN DE NIVEL ===");

	// Nivel
	PrintToChat(client, "\x04Level:\x01 \x05%d", level);

	// XP actual vs requerido
	PrintToChat(client, "\x04XP Actual:\x01 \x03%d\x01 / \x03%d\x01", currentXP, nextLevelXP);

	// XP total acumulado
	PrintToChat(client, "\x04XP Total:\x01 \x03%d", totalXP);

	// Barra de progreso (si está habilitada)
	if (GetConVarBool(cvar_UIShowProgressBar))
	{
		char progressBar[256];
		LevelingUI_CreateProgressBar(progress, progressBar, sizeof(progressBar));
		PrintToChat(client, "\x04Progreso:\x01 %s \x03%d%%%%", progressBar, progress);
	}
	else
	{
		PrintToChat(client, "\x04Progreso:\x01 \x03%d%%%%", progress);
	}
}

/**
 * Muestra XP ganado (llamado cuando el jugador gana XP)
 * @param client - ID del cliente
 * @param xp_gained - XP ganado
 * @param reason - Razón del XP
 */
public void LevelingUI_DisplayXPGain(int client, int xp_gained, const char[] reason)
{
	if (!GetConVarBool(cvar_UIShowOnKill))
		return;

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	int currentXP = Leveling_GetPlayerCurrentXP(client);
	int nextLevelXP = Leveling_GetXPRequiredForNextLevel(client);
	int progress = Leveling_GetLevelProgress(client);

	PrintToChat(client, "\x04[XP]\x01 +\x03%d\x01 XP (\x05%s\x01) - \x03%d\x01/\x03%d\x01 (\x03%d%%%%\x01)",
		xp_gained, reason, currentXP, nextLevelXP, progress);
}

/**
 * Crea una barra de progreso en ASCII
 * @param progress - Porcentaje de progreso (0-100)
 * @param buffer - Buffer para almacenar la barra
 * @param buflen - Tamaño del buffer
 */
stock void LevelingUI_CreateProgressBar(int progress, char[] buffer, int buflen)
{
	// Barra de 20 caracteres
	int filled = (progress / 5);  // 20 * (progress/100)
	int empty = 20 - filled;

	char bar[64];
	Format(bar, sizeof(bar), "[");

	for (int i = 0; i < filled; i++)
		StrCat(bar, sizeof(bar), "█");

	for (int i = 0; i < empty; i++)
		StrCat(bar, sizeof(bar), "░");

	StrCat(bar, sizeof(bar), "]");

	strcopy(buffer, buflen, bar);
}

/**
 * Comando: sm_level / sm_xp / sm_exp
 * Muestra la información de nivel del jugador
 */
public Action Cmd_ShowLevelInfo(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Handled;

	LevelingUI_DisplayLevelInfo(client);

	return Plugin_Handled;
}
