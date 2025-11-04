#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING SYSTEM MODULE ===
// Sistema de niveles y experiencia con beneficios
//==================================================

// --- Defines ---
#define LEVELING_MODULE_VERSION "1.0.0"

// --- ConVars para configuración de XP y Niveles ---
Handle cvar_LevelingBaseXP = INVALID_HANDLE;
Handle cvar_LevelingFormulaEasy = INVALID_HANDLE;
Handle cvar_LevelingFormulaNormal = INVALID_HANDLE;
Handle cvar_LevelingFormulaAdvanced = INVALID_HANDLE;
Handle cvar_LevelingFormulaExpert = INVALID_HANDLE;
Handle cvar_LevelingDifficultyMode = INVALID_HANDLE;
Handle cvar_LevelingDebug = INVALID_HANDLE;

// --- Arrays para almacenar datos en memoria (se sincronizan con BD) ---
int g_iPlayerLevel[MAXPLAYERS + 1];
int g_iPlayerXP[MAXPLAYERS + 1];
int g_iTotalPlayerXP[MAXPLAYERS + 1];

// --- Path para logs ---
static char g_szLevelingLogPath[PLATFORM_MAX_PATH];

/**
 * Inicializa el módulo de leveling
 * Debe ser llamado desde OnPluginStart()
 */
public void Leveling_OnPluginStart()
{
	// Crear ConVars para configuración de XP base
	cvar_LevelingBaseXP = CreateConVar(
		"leveling_base_xp",
		"800",
		"XP base requerido para nivel 1",
		FCVAR_PLUGIN
	);

	// Fórmulas para cada dificultad
	// Easy: formula^1.1
	cvar_LevelingFormulaEasy = CreateConVar(
		"leveling_formula_easy",
		"1.1",
		"Exponente para fórmula de dificultad FÁCIL",
		FCVAR_PLUGIN
	);

	// Normal: formula^1.25
	cvar_LevelingFormulaNormal = CreateConVar(
		"leveling_formula_normal",
		"1.25",
		"Exponente para fórmula de dificultad NORMAL",
		FCVAR_PLUGIN
	);

	// Advanced: formula^1.4
	cvar_LevelingFormulaAdvanced = CreateConVar(
		"leveling_formula_advanced",
		"1.4",
		"Exponente para fórmula de dificultad AVANZADA",
		FCVAR_PLUGIN
	);

	// Expert: formula^1.6
	cvar_LevelingFormulaExpert = CreateConVar(
		"leveling_formula_expert",
		"1.6",
		"Exponente para fórmula de dificultad EXPERTO",
		FCVAR_PLUGIN
	);

	// Dificultad actual del servidor
	cvar_LevelingDifficultyMode = CreateConVar(
		"leveling_difficulty",
		"0",
		"Dificultad del servidor (0=Fácil, 1=Normal, 2=Avanzado, 3=Experto)",
		FCVAR_PLUGIN
	);

	cvar_LevelingDebug = CreateConVar(
		"leveling_debug",
		"0",
		"Activa debug verboso para leveling (0/1)",
		FCVAR_PLUGIN
	);

	// Registrar hook para cuando un jugador se conecta
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	// Construir path de log
	BuildPath(Path_SM, g_szLevelingLogPath, sizeof(g_szLevelingLogPath), "logs\\Leveling_System.log");
	LogToFile(g_szLevelingLogPath, "[INIT] Leveling System v%s inicializado", LEVELING_MODULE_VERSION);
}

/**
 * Se llama cuando un cliente está autenticado y listo
 */
public void Leveling_OnClientPostAdminCheck(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	// Cargar datos del jugador desde BD
	Leveling_LoadPlayerData(client);
}

/**
 * Carga los datos de nivel del jugador desde la base de datos
 * @param client - ID del cliente
 */
public void Leveling_LoadPlayerData(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	if (strlen(steamid) == 0 || StrEqual(steamid, "BOT"))
		return;

	// Verificar que la BD esté conectada
	if (g_hDbPlayers == INVALID_HANDLE || g_hDbPlayers == null)
	{
		LogToFile(g_szLevelingLogPath, "[ERROR] Handle de BD Players inválido, no se puede cargar datos de %N", client);
		return;
	}

	// Query para obtener datos del jugador (incluyendo currency)
	char query[512];
	Format(query, sizeof(query),
		"SELECT current_level, current_xp, total_xp, current_currency FROM player_levels WHERE steamid = '%s'",
		steamid);

	if (GetConVarBool(cvar_LevelingDebug))
	{
		LogToFile(g_szLevelingLogPath, "[DEBUG] Cargando datos de %N (SteamID: %s)", client, steamid);
	}

	SQL_TQuery(g_hDbPlayers, Callback_LoadPlayerLevel, query, GetClientUserId(client), DBPrio_High);
}

/**
 * Callback para cargar datos del jugador
 */
public void Callback_LoadPlayerLevel(Database db, DBResultSet results, const char[] error, any data)
{
	int userid = data;
	int client = GetClientOfUserId(userid);

	if (client <= 0 || !IsClientInGame(client))
	{
		LogToFile(g_szLevelingLogPath, "[WARNING] Cliente desconectado antes de cargar datos");
		return;
	}

	if (results == null)
	{
		LogToFile(g_szLevelingLogPath, "[ERROR] Fallo al cargar datos de nivel de %N: %s", client, error);
		g_iPlayerLevel[client] = 0;
		g_iPlayerXP[client] = 0;
		g_iTotalPlayerXP[client] = 0;
		return;
	}

	if (results.FetchRow())
	{
		g_iPlayerLevel[client] = results.FetchInt(0);
		g_iPlayerXP[client] = results.FetchInt(1);
		g_iTotalPlayerXP[client] = results.FetchInt(2);

		// Cargar currency también (asumimos que la columna existe después de migración)
		// Si la columna no existe, esto devolverá 0 o producirá error que se manejará
		g_iPlayerCurrency[client] = results.FetchInt(3);

		LogToFile(g_szLevelingLogPath, "[LOAD] %N - Nivel: %d, XP: %d/%d, Total: %d, Currency: %d",
			client, g_iPlayerLevel[client], g_iPlayerXP[client],
			Leveling_GetXPRequiredForNextLevel(client), g_iTotalPlayerXP[client], g_iPlayerCurrency[client]);
	}
	else
	{
		// Nuevo jugador, crear registro
		g_iPlayerLevel[client] = 0;
		g_iPlayerXP[client] = 0;
		g_iTotalPlayerXP[client] = 0;
		g_iPlayerCurrency[client] = 0;  // Inicializar currency también

		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));

		// Escapar caracteres especiales en el nombre
		char escapedName[MAX_NAME_LENGTH * 2];
		SQL_EscapeString(g_hDbPlayers, name, escapedName, sizeof(escapedName));

		// Insertar nuevo registro (incluyendo currency)
		char insertQuery[512];
		Format(insertQuery, sizeof(insertQuery),
			"INSERT INTO player_levels (steamid, player_name, current_level, current_xp, total_xp, current_currency) VALUES ('%s', '%s', 0, 0, 0, 0)",
			steamid, escapedName);

		LogToFile(g_szLevelingLogPath, "[NEW] Creando nuevo jugador: %N (%s)", client, steamid);

		SQL_TQuery(g_hDbPlayers, Callback_InsertPlayerLevel, insertQuery, _, DBPrio_Low);
	}
}

/**
 * Callback para insertar nuevo jugador
 */
public void Callback_InsertPlayerLevel(Database db, DBResultSet results, const char[] error, any data)
{
	if (strlen(error) > 0)
	{
		LogToFile(g_szLevelingLogPath, "[ERROR] Fallo al insertar nuevo jugador: %s", error);
	}
	else
	{
		LogToFile(g_szLevelingLogPath, "[SUCCESS] Nuevo jugador insertado correctamente");
	}
}

/**
 * Evento: player_spawn - Se dispara cuando el jugador aparece en el mapa
 */
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Cargar datos de nivel cuando aparece por primera vez
	Leveling_LoadPlayerData(client);

	return Plugin_Continue;
}

/**
 * Otorga XP a un jugador y maneja el level-up
 * @param client - ID del cliente
 * @param xp_amount - Cantidad de XP a otorgar
 * @param reason - Razón por la cual se otorgó XP (para logs)
 */
public void Leveling_AwardXP(int client, int xp_amount, const char[] reason)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	if (xp_amount <= 0)
		return;

	// Agregar XP al total
	g_iTotalPlayerXP[client] += xp_amount;
	g_iPlayerXP[client] += xp_amount;

	// Verificar level-ups
	int xp_required = Leveling_GetXPRequiredForNextLevel(client);

	while (g_iPlayerXP[client] >= xp_required)
	{
		g_iPlayerXP[client] -= xp_required;
		g_iPlayerLevel[client]++;

		// Notificar al jugador del level-up
		Leveling_OnLevelUp(client);

		// Obtener XP requerido para el siguiente nivel
		xp_required = Leveling_GetXPRequiredForNextLevel(client);
	}

	// Log detallado
	if (GetConVarBool(cvar_LevelingDebug))
	{
		LogToFile(g_szLevelingLogPath, "[XP] %N +%d XP (%s) - Nivel: %d, XP: %d/%d",
			client, xp_amount, reason, g_iPlayerLevel[client], g_iPlayerXP[client], xp_required);
	}

	// Actualizar en base de datos (asíncrono)
	Leveling_UpdatePlayerDatabase(client);
}

/**
 * Se llama cuando un jugador sube de nivel
 */
public void Leveling_OnLevelUp(int client)
{
	// Mostrar mensaje en chat
	char message[128];
	Format(message, sizeof(message), "%T", "Leveling_LevelUp", client, g_iPlayerLevel[client]);
	PrintToChat(client, "\x04[LEVELING]\x01 %s", message);

	// Log antes de aplicar rewards
	LogMessage("[LEVELING DEBUG] OnLevelUp - %N alcanzó nivel %d, aplicando rewards...", client, g_iPlayerLevel[client]);

	// Aplicar beneficios del nuevo nivel
	Leveling_ApplyLevelRewards(client, g_iPlayerLevel[client]);

	// Log
	LogToFile(g_szLevelingLogPath, "[LEVELUP] %N alcanzó Nivel %d", client, g_iPlayerLevel[client]);
	LogMessage("[LEVELING DEBUG] OnLevelUp completado para %N", client);
}

/**
 * Obtiene el XP requerido para pasar al siguiente nivel
 * Usa la fórmula: base_xp * (nivel+1)^exponente
 * @param client - ID del cliente (para obtener el nivel actual)
 * @return - XP requerido para el siguiente nivel
 */
public int Leveling_GetXPRequiredForNextLevel(int client)
{
	int nextLevel = g_iPlayerLevel[client] + 1;
	int baseXP = GetConVarInt(cvar_LevelingBaseXP);

	float formula = Leveling_GetDifficultyFormula();
	float xp_required = baseXP * pow(float(nextLevel), formula);

	return RoundToNearest(xp_required);
}

/**
 * Obtiene el exponente de la fórmula según la dificultad del servidor
 */
public float Leveling_GetDifficultyFormula()
{
	int difficulty = GetConVarInt(cvar_LevelingDifficultyMode);

	switch (difficulty)
	{
		case 0: return GetConVarFloat(cvar_LevelingFormulaEasy);      // 1.1
		case 1: return GetConVarFloat(cvar_LevelingFormulaNormal);    // 1.25
		case 2: return GetConVarFloat(cvar_LevelingFormulaAdvanced);  // 1.4
		case 3: return GetConVarFloat(cvar_LevelingFormulaExpert);    // 1.6
		default: return 1.1;
	}
}

/**
 * Aplica los beneficios/rewards según el nivel
 * @param client - ID del cliente
 * @param level - Nivel alcanzado
 */
public void Leveling_ApplyLevelRewards(int client, int level)
{
	// Llamar a la función real de rewards del módulo de rewards
	// Usa LevelingRewards_ApplyRewards que muestra mensajes (llamado al subir de nivel)
	LevelingRewards_ApplyRewards(client, level);
}

/**
 * Actualiza los datos del jugador en la base de datos
 * @param client - ID del cliente
 */
public void Leveling_UpdatePlayerDatabase(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	if (strlen(steamid) == 0 || StrEqual(steamid, "BOT"))
		return;

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	// Verificar que la BD esté conectada
	if (g_hDbPlayers == INVALID_HANDLE || g_hDbPlayers == null)
	{
		LogToFile(g_szLevelingLogPath, "[ERROR] Handle de BD Players inválido, no se puede actualizar");
		return;
	}

	// Escapar caracteres especiales
	char escapedName[MAX_NAME_LENGTH * 2];
	SQL_EscapeString(g_hDbPlayers, name, escapedName, sizeof(escapedName));

	// Query de inserción/actualización (INSERT ... ON DUPLICATE KEY UPDATE) incluyendo currency
	char query[1024];
	Format(query, sizeof(query),
		"INSERT INTO player_levels (steamid, player_name, current_level, current_xp, total_xp, current_currency, last_update) VALUES ('%s', '%s', %d, %d, %d, %d, CURRENT_TIMESTAMP) ON DUPLICATE KEY UPDATE current_level = %d, current_xp = %d, total_xp = %d, current_currency = %d, player_name = '%s', last_update = CURRENT_TIMESTAMP",
		steamid, escapedName, g_iPlayerLevel[client], g_iPlayerXP[client], g_iTotalPlayerXP[client], g_iPlayerCurrency[client],
		g_iPlayerLevel[client], g_iPlayerXP[client], g_iTotalPlayerXP[client], g_iPlayerCurrency[client], escapedName);

	if (GetConVarBool(cvar_LevelingDebug))
	{
		LogToFile(g_szLevelingLogPath, "[DEBUG] Ejecutando query: %s", query);
	}

	SQL_TQuery(g_hDbPlayers, Callback_UpdatePlayerLevel, query, _, DBPrio_High);
}

/**
 * Callback para actualizar datos del jugador
 */
public void Callback_UpdatePlayerLevel(Database db, DBResultSet results, const char[] error, any data)
{
	if (strlen(error) > 0)
	{
		LogToFile(g_szLevelingLogPath, "[ERROR] Fallo al actualizar nivel del jugador: %s", error);
	}
	else if (GetConVarBool(cvar_LevelingDebug))
	{
		LogToFile(g_szLevelingLogPath, "[UPDATE] Datos actualizados correctamente en BD");
	}
}

/**
 * Obtiene el nivel actual del jugador
 */
public int Leveling_GetPlayerLevel(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iPlayerLevel[client];
}

/**
 * Obtiene el XP actual del jugador (dentro del nivel)
 */
public int Leveling_GetPlayerCurrentXP(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iPlayerXP[client];
}

/**
 * Obtiene el XP total acumulado del jugador
 */
public int Leveling_GetPlayerTotalXP(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	return g_iTotalPlayerXP[client];
}

/**
 * Obtiene el progreso en porcentaje para el siguiente nivel
 */
public int Leveling_GetLevelProgress(int client)
{
	if (client <= 0 || client > MaxClients)
		return 0;

	int currentXP = g_iPlayerXP[client];
	int requiredXP = Leveling_GetXPRequiredForNextLevel(client);

	if (requiredXP <= 0)
		return 0;

	return RoundToNearest((float(currentXP) / float(requiredXP)) * 100.0);
}

/**
 * Función auxiliar para calcular potencias
 */
stock float pow(float base, float exponent)
{
	return Pow(base, exponent);
}
