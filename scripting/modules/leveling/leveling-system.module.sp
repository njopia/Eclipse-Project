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
Handle		cvar_LevelingBaseXP			 = INVALID_HANDLE;
Handle		cvar_LevelingFormulaEasy	 = INVALID_HANDLE;
Handle		cvar_LevelingFormulaNormal	 = INVALID_HANDLE;
Handle		cvar_LevelingFormulaAdvanced = INVALID_HANDLE;
Handle		cvar_LevelingFormulaExpert	 = INVALID_HANDLE;
Handle		cvar_LevelingDifficultyMode	 = INVALID_HANDLE;
Handle		cvar_LevelingDebug			 = INVALID_HANDLE;

// --- Arrays para almacenar datos en memoria (se sincronizan con BD) ---
int			g_iPlayerLevel[MAXPLAYERS + 1];
int			g_iPlayerXP[MAXPLAYERS + 1];
int			g_iTotalPlayerXP[MAXPLAYERS + 1];

// --- Variable para congelar currency durante eventos especiales (ej: Nightmare) ---
bool		g_bCurrencyFrozen = false; // Cuando es true, no se gana/pierde/resetea currency

// --- Path para logs ---
static char g_szLevelingLogPath[PLATFORM_MAX_PATH];

// Trophy XP Events Module
#define CVAR_FLAGS				   FCVAR_NOTIFY

#define PARTICLE_ACHIEVED		   "achieved"
#define PARTICLE_FIREWORK		   "mini_fireworks"
#define SOUND_ACHIEVEMENT		   "npc/moustachio/strengthlvl4_notbad.wav"
#define SOUND_AUXLIARY_ACHIEVEMENT "ambient/tones/elev1.wav"

ConVar g_hCvarMPGameMode, g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarEffects, g_hCvarSound, g_hCvarThird, g_hCvarTime, g_hCvarWait;
int	   g_iCvarEffects, g_iCvarSound, g_iParticles[MAXPLAYERS + 1][2];
bool   g_bCvarAllow, g_bMapStarted;
float  g_fCvarThird, g_fCvarTime, g_fCvarWait;
bool   g_bLeft4Dead2 = true;
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
		FCVAR_PLUGIN);

	// Fórmulas para cada dificultad
	// Easy: formula^1.1
	cvar_LevelingFormulaEasy = CreateConVar(
		"leveling_formula_easy",
		"1.1",
		"Exponente para fórmula de dificultad FÁCIL",
		FCVAR_PLUGIN);

	// Normal: formula^1.25
	cvar_LevelingFormulaNormal = CreateConVar(
		"leveling_formula_normal",
		"1.25",
		"Exponente para fórmula de dificultad NORMAL",
		FCVAR_PLUGIN);

	// Advanced: formula^1.4
	cvar_LevelingFormulaAdvanced = CreateConVar(
		"leveling_formula_advanced",
		"1.4",
		"Exponente para fórmula de dificultad AVANZADA",
		FCVAR_PLUGIN);

	// Expert: formula^1.6
	cvar_LevelingFormulaExpert = CreateConVar(
		"leveling_formula_expert",
		"1.6",
		"Exponente para fórmula de dificultad EXPERTO",
		FCVAR_PLUGIN);

	// Dificultad actual del servidor
	cvar_LevelingDifficultyMode = CreateConVar(
		"leveling_difficulty",
		"0",
		"Dificultad del servidor (0=Fácil, 1=Normal, 2=Avanzado, 3=Experto)",
		FCVAR_PLUGIN);

	cvar_LevelingDebug = CreateConVar(
		"leveling_debug",
		"0",
		"Activa debug verboso para leveling (0/1)",
		FCVAR_PLUGIN);

	// Trophy XP Events Module
	g_hCvarAllow	= CreateConVar("l4d_trophy_allow", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes	= CreateConVar("l4d_trophy_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff = CreateConVar("l4d_trophy_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog = CreateConVar("l4d_trophy_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	g_hCvarEffects	= CreateConVar("l4d_trophy_effects", "3", "Which effects to display. 1=Trophy, 2=Fireworks, 3=Both.", CVAR_FLAGS);
	g_hCvarSound	= CreateConVar("l4d_trophy_sound", g_bLeft4Dead2 ? "3" : "1", "0=Off. 1=Play sound when using the command. 2=When achievement is earned (not required for L4D1). 3=Both.", CVAR_FLAGS);
	if (g_bLeft4Dead2)
		g_hCvarThird = CreateConVar("l4d_trophy_third", "4.0", "0.0=Off. How long to put the player into thirdperson view.", CVAR_FLAGS);
	g_hCvarTime = CreateConVar("l4d_trophy_time", "3.5", "Remove the particle effects after this many seconds. Increase time to make the effect loop.", CVAR_FLAGS);
	g_hCvarWait = CreateConVar("l4d_trophy_wait", "3.5", "Replay the particles after this many seconds.", CVAR_FLAGS);
	CreateConVar("l4d_trophy_version", PLUGIN_VERSION, "Achievement Trophy plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_trophy");

	RegAdminCmd("sm_trophy", CmdTrophy, ADMFLAG_ROOT, "Display the achievement trophy on yourself. Or optional arg to specify targets [#userid|name]");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarEffects.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSound.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWait.AddChangeHook(ConVarChanged_Cvars);
	if (g_bLeft4Dead2)
		g_hCvarThird.AddChangeHook(ConVarChanged_Cvars);
	// Registrar hook para cuando un jugador se conecta
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	// Construir path de log
	BuildPath(Path_SM, g_szLevelingLogPath, sizeof(g_szLevelingLogPath), "logs\\Leveling_System.log");
	LogToFile(g_szLevelingLogPath, "[INIT] Leveling System v%s inicializado", LEVELING_MODULE_VERSION);
}

public void Leveling_OnPluginEnd()
{
	ResetPlugin();
}

public void Leveling_OnMapStart()
{
	g_bMapStarted = true;
	PrecacheParticle(PARTICLE_ACHIEVED);
	PrecacheParticle(PARTICLE_FIREWORK);
	PrecacheSound(SOUND_ACHIEVEMENT);
	PrecacheSound(SOUND_AUXLIARY_ACHIEVEMENT);
}

public void Leveling_OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
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
 * Guarda los datos del jugador cuando se desconecta
 * @param client - ID del cliente
 */
public void Leveling_OnClientDisconnect(int client)
{
	if (client <= 0 || client > MaxClients || IsFakeClient(client))
		return;

	// Guardar datos en la base de datos (solo nivel/XP, currency NO se guarda en BD)
	Leveling_UpdatePlayerDatabase(client);
	LogToFile(g_szLevelingLogPath, "[DISCONNECT] Guardando datos de %N - Level: %d, XP: %d/%d, Total XP: %d, Currency perdido: %d",
			  client, g_iPlayerLevel[client], g_iPlayerXP[client],
			  Leveling_GetXPRequiredForNextLevel(client), g_iTotalPlayerXP[client],
			  g_iPlayerLocalCurrency[client]);

	// Reset de variables locales
	g_iPlayerLevel[client] = 0;
	g_iPlayerXP[client] = 0;
	g_iTotalPlayerXP[client] = 0;
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

	// Query para obtener datos del jugador (solo nivel y XP, currency es temporal)
	char query[512];
	Format(query, sizeof(query),
		   "SELECT current_level, current_xp, total_xp FROM player_levels WHERE steamid = '%s'",
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
		g_iPlayerLevel[client]	 = 0;
		g_iPlayerXP[client]		 = 0;
		g_iTotalPlayerXP[client] = 0;
		return;
	}

	if (results.FetchRow())
	{
		g_iPlayerLevel[client]	  = results.FetchInt(0);
		g_iPlayerXP[client]		  = results.FetchInt(1);
		g_iTotalPlayerXP[client]  = results.FetchInt(2);

		// Currency se mantiene durante toda la sesión (no se resetea entre mapas)
		// Solo se resetea al desconectar o al iniciar el plugin

		LogToFile(g_szLevelingLogPath, "[LOAD] %N - Nivel: %d, XP: %d/%d, Total: %d, Currency: %d",
				  client, g_iPlayerLevel[client], g_iPlayerXP[client],
				  Leveling_GetXPRequiredForNextLevel(client), g_iTotalPlayerXP[client],
				  g_iPlayerLocalCurrency[client]);

		// Aplicar pasivas inmediatamente si el jugador está vivo
		if (IsPlayerAlive(client) && g_iPlayerLevel[client] > 0)
		{
			LevelingRewards_ApplyRewardsSilent(client, g_iPlayerLevel[client]);
			LogToFile(g_szLevelingLogPath, "[LOAD] Aplicando pasivas a %N (Nivel %d)", client, g_iPlayerLevel[client]);
		}
	}
	else
	{
		// Nuevo jugador, crear registro
		g_iPlayerLevel[client]	  = 0;
		g_iPlayerXP[client]		  = 0;
		g_iTotalPlayerXP[client]  = 0;
		// Currency ya está inicializado en 0 por buyMenuOnPluginStart() o OnClientDisconnect()
		// No lo tocamos aquí para no resetear el currency entre mapas

		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));

		// Escapar caracteres especiales en el nombre
		char escapedName[MAX_NAME_LENGTH * 2];
		SQL_EscapeString(g_hDbPlayers, name, escapedName, sizeof(escapedName));

		// Insertar nuevo registro (sin currency, solo nivel/XP)
		char insertQuery[512];
		Format(insertQuery, sizeof(insertQuery),
			   "INSERT INTO player_levels (steamid, player_name, current_level, current_xp, total_xp) VALUES ('%s', '%s', 0, 0, 0)",
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

	// Actualizar en base de datos (asíncrono) - Solo nivel y XP, currency es temporal
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
	CmdTrophy(client, 0);	 // Mostrar trofeo
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
	int	  nextLevel	  = g_iPlayerLevel[client] + 1;
	int	  baseXP	  = GetConVarInt(cvar_LevelingBaseXP);

	float formula	  = Leveling_GetDifficultyFormula();
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
		case 0: return GetConVarFloat(cvar_LevelingFormulaEasy);		// 1.1
		case 1: return GetConVarFloat(cvar_LevelingFormulaNormal);		// 1.25
		case 2: return GetConVarFloat(cvar_LevelingFormulaAdvanced);	// 1.4
		case 3: return GetConVarFloat(cvar_LevelingFormulaExpert);		// 1.6
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

	// Guardar solo nivel y XP (currency es siempre temporal, no se guarda en BD)
	char query[1024];
	Format(query, sizeof(query),
		   "INSERT INTO player_levels (steamid, player_name, current_level, current_xp, total_xp, last_update) VALUES ('%s', '%s', %d, %d, %d, CURRENT_TIMESTAMP) ON DUPLICATE KEY UPDATE current_level = %d, current_xp = %d, total_xp = %d, player_name = '%s', last_update = CURRENT_TIMESTAMP",
		   steamid, escapedName, g_iPlayerLevel[client], g_iPlayerXP[client], g_iTotalPlayerXP[client],
		   g_iPlayerLevel[client], g_iPlayerXP[client], g_iTotalPlayerXP[client], escapedName);

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

	int currentXP  = g_iPlayerXP[client];
	int requiredXP = Leveling_GetXPRequiredForNextLevel(client);

	if (requiredXP <= 0)
		return 0;

	return RoundToNearest((float(currentXP) / float(requiredXP)) * 100.0);
}

/**
 * Detecta cambios de dificultad
 * NOTA: Currency persiste entre mapas (durante toda la sesión), no requiere reset por cambio de dificultad
 * Esta función se mantiene por compatibilidad pero ya no gestiona currency
 *
 * NOTA: Durante eventos especiales (Nightmare, etc), el currency está congelado
 */
stock void Leveling_CheckDifficultyChange(int client)
{
	// Esta función ahora es un stub (vacía) porque currency es siempre temporal
	// Se mantiene para no romper llamadas existentes en el código
	return;
}

/**
 * Congela el currency para todos los jugadores (usado durante eventos especiales)
 * Cuando está congelado: no se gana, no se pierde, no se resetea por cambio de dificultad
 *
 * USO: Llamar al inicio del evento Nightmare o similar
 */
public void Leveling_FreezeCurrency()
{
	g_bCurrencyFrozen = true;
	LogToFile(g_szLevelingLogPath, "[CURRENCY] Currency CONGELADO - Evento especial iniciado");
	PrintToChatAll("\x04[Sistema]\x01 Currency congelado durante el evento especial.");
}

/**
 * Descongela el currency para todos los jugadores
 *
 * USO: Llamar al finalizar el evento Nightmare o similar
 */
public void Leveling_UnfreezeCurrency()
{
	g_bCurrencyFrozen = false;
	LogToFile(g_szLevelingLogPath, "[CURRENCY] Currency DESCONGELADO - Evento especial finalizado");
	PrintToChatAll("\x04[Sistema]\x01 Currency descongelado. Sistema normal restaurado.");
}

/**
 * Verifica si el currency está actualmente congelado
 *
 * @return true si está congelado, false si no
 */
public bool Leveling_IsCurrencyFrozen()
{
	return g_bCurrencyFrozen;
}

/**
 * Función auxiliar para calcular potencias
 */
stock float pow(float base, float exponent)
{
	return Pow(base, exponent);
}

// Trophy XP Events Module

void ResetPlugin()
{
	for (int i = 1; i <= MaxClients; i++)
		RemoveEffects(i);
}

void RemoveEffects(int client)
{
	int entity;

	entity = g_iParticles[client][0];
	if (IsValidEntRef(entity))
		RemoveEntity(entity);
	g_iParticles[client][0] = 0;

	entity					= g_iParticles[client][1];
	if (IsValidEntRef(entity))
		RemoveEntity(entity);
	g_iParticles[client][1] = 0;
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void Leveling_OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarEffects = g_hCvarEffects.IntValue;
	g_iCvarSound   = g_hCvarSound.IntValue;
	g_fCvarTime	   = g_hCvarTime.FloatValue;
	g_fCvarWait	   = g_hCvarWait.FloatValue;
	if (g_bLeft4Dead2)
		g_fCvarThird = g_hCvarThird.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true)
	{
		g_bCvarAllow = true;
		HookEvent("achievement_earned", Event_Achievement);
		HookEvent("player_death", Event_Remove);
		HookEvent("player_team", Event_Remove);
		HookEvent("round_end", Event_RemoveAll, EventHookMode_PostNoCopy);
	}

	else if (g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false))
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("achievement_earned", Event_Achievement);
		UnhookEvent("player_death", Event_Remove);
		UnhookEvent("player_team", Event_Remove);
		UnhookEvent("round_end", Event_RemoveAll, EventHookMode_PostNoCopy);
	}
}

int	 g_iCurrentMode;
bool IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == null)
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if (iCvarModesTog != 0)
	{
		if (g_bMapStarted == false)
			return false;

		g_iCurrentMode = 0;

		int entity	   = CreateEntityByName("info_gamemode");
		if (IsValidEntity(entity))
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if (IsValidEntity(entity))	  // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity);	  // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if (g_iCurrentMode == 0)
			return false;

		if (!(iCvarModesTog & g_iCurrentMode))
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if (strcmp(output, "OnCoop") == 0)
		g_iCurrentMode = 1;
	else if (strcmp(output, "OnSurvival") == 0)
		g_iCurrentMode = 2;
	else if (strcmp(output, "OnVersus") == 0)
		g_iCurrentMode = 4;
	else if (strcmp(output, "OnScavenge") == 0)
		g_iCurrentMode = 8;
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================
void Event_Remove(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	RemoveEffects(client);
}

void Event_RemoveAll(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		RemoveEffects(i);
}

void Event_Achievement(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("player");
	CreateEffects(client, true);
}

void CreateEffects(int client, bool event)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
	{
		// Thirdperson view
		if (g_fCvarThird != 0.0)
		{
			// Survivor Thirdperson plugin sets 99999.3.
			if (GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") != 99999.3)
				SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + g_fCvarThird);
		}

		// Sound
		if (g_iCvarSound == 3 || (!event && g_iCvarSound == 1) || (event && g_iCvarSound == 2))
		{
			EmitSoundToAll(SOUND_AUXLIARY_ACHIEVEMENT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			EmitSoundToAll(SOUND_ACHIEVEMENT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}

		// Effect
		int entity;
		if (g_iCvarEffects == 3 || g_iCvarEffects == 1)
		{
			entity = CreateEntityByName("info_particle_system");
			if (entity != INVALID_ENT_REFERENCE)
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_ACHIEVED);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				AcceptEntityInput(entity, "start");

				// Attach to survivor
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);
				TeleportEntity(entity, view_as<float>({ 0.0, 0.0, 50.0 }), NULL_VECTOR, NULL_VECTOR);

				// Loop
				char sTemp[64];
				SetVariantString("OnUser1 !self:Start::0.0:-1");
				AcceptEntityInput(entity, "AddOutput");
				Format(sTemp, sizeof(sTemp), "OnUser2 !self:Stop::%f:-1", g_fCvarWait);
				SetVariantString(sTemp);
				AcceptEntityInput(entity, "AddOutput");
				Format(sTemp, sizeof(sTemp), "OnUser2 !self:FireUser1::%f:-1", g_fCvarWait + 0.1);
				SetVariantString(sTemp);
				AcceptEntityInput(entity, "AddOutput");
				Format(sTemp, sizeof(sTemp), "OnUser2 !self:FireUser2::%f:-1", g_fCvarWait + 0.1);
				SetVariantString(sTemp);
				AcceptEntityInput(entity, "AddOutput");

				AcceptEntityInput(entity, "FireUser1");
				AcceptEntityInput(entity, "FireUser2");

				// Remove
				Format(sTemp, sizeof(sTemp), "OnUser3 !self:Kill::%f:-1", g_fCvarTime);
				SetVariantString(sTemp);
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser3");

				g_iParticles[client][0] = EntIndexToEntRef(entity);
			}
		}

		if (g_iCvarEffects == 3 || g_iCvarEffects == 2)
		{
			entity = CreateEntityByName("info_particle_system");
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_FIREWORK);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				AcceptEntityInput(entity, "start");

				// Attach to survivor
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);
				TeleportEntity(entity, view_as<float>({ 0.0, 0.0, 50.0 }), NULL_VECTOR, NULL_VECTOR);

				// Loop
				char sTemp[64];
				SetVariantString("OnUser1 !self:Start::0.0:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser2 !self:Stop::4.0:-1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser2 !self:FireUser1::4.0:-1");
				AcceptEntityInput(entity, "AddOutput");

				AcceptEntityInput(entity, "FireUser1");
				AcceptEntityInput(entity, "FireUser2");

				// Remove
				Format(sTemp, sizeof(sTemp), "OnUser3 !self:Kill::%f:-1", g_fCvarTime);
				SetVariantString(sTemp);
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser3");

				g_iParticles[client][1] = EntIndexToEntRef(entity);
			}
		}
	}
}

Action CmdTrophy(int client, int args)
{
	if (args == 0)
	{
		CreateEffects(client, false);
	}
	else
	{
		char target_name[MAX_TARGET_LENGTH], arg1[32];
		int	 target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		GetCmdArg(1, arg1, sizeof(arg1));

		if ((target_count = ProcessTargetString(
				 arg1,
				 client,
				 target_list,
				 MAXPLAYERS,
				 COMMAND_FILTER_ALIVE,
				 target_name,
				 sizeof(target_name),
				 tn_is_ml))
			<= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (int i = 0; i < target_count; i++)
			CreateEffects(target_list[i], false);
	}

	return Plugin_Handled;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if (FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

bool IsValidEntRef(int entity)
{
	if (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}