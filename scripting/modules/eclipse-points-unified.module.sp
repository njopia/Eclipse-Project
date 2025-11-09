#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === ECLIPSE POINTS UNIFIED MODULE ===
// Sistema unificado de puntos que reemplaza los módulos
// currency-events y leveling-xp-events
//
// Un solo evento otorga AMBOS tipos de puntos:
// - Currency Points (para compras) - Persiste entre mapas, se resetea al desconectar
// - XP Points (para subir de nivel) - Se guarda en BD
//==================================================

// --- ConVars para configurar recompensas UNIFICADAS ---
// Cada evento otorga la MISMA cantidad de puntos para currency Y XP
ConVar cvar_PointsCommonKill;
ConVar cvar_PointsUncommonKill;
ConVar cvar_PointsSpecialKill;
ConVar cvar_PointsTankKill;
ConVar cvar_PointsWitchKill;
ConVar cvar_PointsHeadshot;
ConVar cvar_PointsRevive;
ConVar cvar_PointsHeal;
ConVar cvar_PointsDefibrillator;
ConVar cvar_PointsCompleteMap;
ConVar cvar_PointsSmokerSave;
ConVar cvar_PointsHunterSave;
ConVar cvar_PointsJockeySave;
ConVar cvar_PointsSurvivalRound;

// Flags para tracking de eventos por mapa
bool g_bPlayerLeftSafeArea[MAXPLAYERS + 1];
bool g_bMapCompleteAwarded[MAXPLAYERS + 1];

// ConVar para detectar dificultad del servidor
Handle g_hCvarDifficulty = INVALID_HANDLE;

/**
 * Inicializa el módulo de puntos unificados
 * Debe ser llamado desde OnPluginStart()
 *
 * IMPORTANTE: Este módulo reemplaza:
 * - CurrencyEvents_OnPluginStart()
 * - LevelingXPEvents_OnPluginStart()
 */
public void EclipsePointsUnified_OnPluginStart()
{
	// === CONVARS UNIFICADOS ===
	// Cada ConVar controla AMBOS sistemas (Currency + XP)

	// IMPORTANTE: Los valores configurados aquí son para dificultad EASY
	// Se multiplican automáticamente según la dificultad:
	// Easy = 1x, Normal = 2x, Advanced = 3x, Expert = 4x

	cvar_PointsCommonKill = CreateConVar(
		"eclipse_points_common_kill",
		"1",
		"Puntos BASE (Currency + XP) por matar un infectado común (Easy=1, Normal=2, Advanced=3, Expert=4)",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsUncommonKill = CreateConVar(
		"eclipse_points_uncommon_kill",
		"3",
		"Puntos BASE (Currency + XP) por matar un infectado uncommon como Riot Cop (Easy=3, Normal=6, Advanced=9, Expert=12)",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsSpecialKill = CreateConVar(
		"eclipse_points_special_kill",
		"10",
		"Puntos BASE (Currency + XP) por matar un infectado especial (Easy=10, Normal=20, Advanced=30, Expert=40)",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsTankKill = CreateConVar(
		"eclipse_points_tank_kill",
		"100",
		"Puntos BASE (Currency + XP) por matar un Tank (Easy=100, Normal=200, Advanced=300, Expert=400)",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsWitchKill = CreateConVar(
		"eclipse_points_witch_kill",
		"5",
		"Puntos BASE (Currency + XP) por matar una Witch (Easy=5, Normal=10, Advanced=15, Expert=20)",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsHeadshot = CreateConVar(
		"eclipse_points_headshot",
		"3",
		"Puntos (Currency + XP) bonus por headshot",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsRevive = CreateConVar(
		"eclipse_points_revive",
		"75",
		"Puntos (Currency + XP) por revivir a un compañero",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsHeal = CreateConVar(
		"eclipse_points_heal",
		"30",
		"Puntos (Currency + XP) por curar a un compañero",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsDefibrillator = CreateConVar(
		"eclipse_points_defibrillator",
		"100",
		"Puntos (Currency + XP) por usar desfibrilador",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsCompleteMap = CreateConVar(
		"eclipse_points_complete_map",
		"1000",
		"Puntos BASE (Currency + XP) por completar un mapa/finale (Easy=1000, Normal=2000, Advanced=3000, Expert=4000)",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsSmokerSave = CreateConVar(
		"eclipse_points_smoker_save",
		"35",
		"Puntos (Currency + XP) por salvar de Smoker",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsHunterSave = CreateConVar(
		"eclipse_points_hunter_save",
		"35",
		"Puntos (Currency + XP) por salvar de Hunter",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsJockeySave = CreateConVar(
		"eclipse_points_jockey_save",
		"35",
		"Puntos (Currency + XP) por salvar de Jockey",
		FCVAR_PLUGIN,
		true, 0.0
	);

	cvar_PointsSurvivalRound = CreateConVar(
		"eclipse_points_survival_round",
		"250",
		"Puntos (Currency + XP) por completar ronda de supervivencia",
		FCVAR_PLUGIN,
		true, 0.0
	);

	// === REGISTRAR EVENT HOOKS ===

	// Eventos básicos de combate
	HookEvent("infected_death", EclipsePoints_Event_InfectedDeath, EventHookMode_Pre);
	HookEvent("player_death", EclipsePoints_Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("tank_killed", EclipsePoints_Event_TankKilled, EventHookMode_Pre);
	HookEvent("witch_killed", EclipsePoints_Event_WitchKilled, EventHookMode_Pre);

	// Eventos de soporte
	HookEvent("heal_success", EclipsePoints_Event_HealSuccess, EventHookMode_Pre);
	HookEvent("revive_success", EclipsePoints_Event_ReviveSuccess, EventHookMode_Pre);

	// L4D2 specific
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		HookEvent("defibrillator_used", EclipsePoints_Event_DefibUsed, EventHookMode_Pre);
	}

	// Eventos avanzados de saves
	HookEvent("tongue_pull_stopped", EclipsePoints_Event_SmokerSave, EventHookMode_Pre);
	HookEvent("pounce_stopped", EclipsePoints_Event_HunterSave, EventHookMode_Pre);
	HookEvent("jockey_ride_end", EclipsePoints_Event_JockeySave, EventHookMode_Pre);

	// Eventos de progreso de mapa
	HookEvent("player_left_safe_area", EclipsePoints_Event_LeftSafeArea, EventHookMode_Post);
	HookEvent("finale_vehicle_leaving", EclipsePoints_Event_MapComplete, EventHookMode_Post);
	HookEvent("map_transition", EclipsePoints_Event_MapComplete, EventHookMode_Post);

	// Survival mode
	HookEvent("survival_round_start", EclipsePoints_Event_SurvivalRound, EventHookMode_Post);

	// Obtener ConVar de dificultad del servidor
	g_hCvarDifficulty = FindConVar("z_difficulty");

	LogMessage("[Eclipse Points] Sistema unificado de puntos inicializado");
}

/**
 * Reset tracking flags on map start
 */
public void EclipsePointsUnified_OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bPlayerLeftSafeArea[i] = false;
		g_bMapCompleteAwarded[i] = false;
	}
}

/**
 * Reset tracking flags on client disconnect
 */
public void EclipsePointsUnified_OnClientDisconnect(int client)
{
	g_bPlayerLeftSafeArea[client] = false;
	g_bMapCompleteAwarded[client] = false;
}

//==================================================
// === FUNCIONES DE DIFICULTAD ===
//==================================================

/**
 * Obtiene el multiplicador de dificultad actual del servidor
 * Easy = 1x, Normal = 2x, Advanced = 3x, Expert = 4x
 *
 * NOTA: Este multiplicador afecta tanto a Currency como a XP
 * Currency persiste entre mapas (se resetea al desconectar), XP se guarda en BD
 *
 * @return Multiplicador de puntos según dificultad
 */
int GetDifficultyMultiplier()
{
	if (g_hCvarDifficulty == INVALID_HANDLE)
		return 1; // Default a Easy si no se puede detectar

	char difficulty[32];
	GetConVarString(g_hCvarDifficulty, difficulty, sizeof(difficulty));

	// Determinar multiplicador basado en la dificultad
	if (StrEqual(difficulty, "Easy", false))
		return 1;
	else if (StrEqual(difficulty, "Normal", false))
		return 2;
	else if (StrEqual(difficulty, "Hard", false) || StrEqual(difficulty, "Advanced", false))
		return 3;
	else if (StrEqual(difficulty, "Impossible", false) || StrEqual(difficulty, "Expert", false))
		return 4;

	return 1; // Default a Easy
}

/**
 * Verifica si la dificultad actual es Easy
 * NOTA: Esta función se mantiene por compatibilidad
 * Currency persiste entre mapas pero no se guarda en BD
 *
 * @return true si es Easy, false en caso contrario
 */
/* bool IsEasyDifficulty()
{
	if (g_hCvarDifficulty == INVALID_HANDLE)
		return true; // Default a Easy si no se puede detectar

	char difficulty[32];
	GetConVarString(g_hCvarDifficulty, difficulty, sizeof(difficulty));

	return StrEqual(difficulty, "Easy", false);
} */

//==================================================
// === FUNCIÓN CENTRAL DE OTORGAMIENTO DE PUNTOS ===
//==================================================

/**
 * Otorga puntos UNIFICADOS a un jugador
 * Esta función otorga AMBOS tipos de puntos simultáneamente:
 * - Currency (para compras) - Persiste entre mapas, se resetea al desconectar (NO se guarda en BD)
 * - XP (para niveles) - Se guarda en BD
 *
 * Los puntos se multiplican según la dificultad:
 * Easy = 1x, Normal = 2x, Advanced = 3x, Expert = 4x
 *
 * @param client        Cliente que recibe los puntos
 * @param points        Cantidad de puntos BASE a otorgar (se multiplica por dificultad)
 * @param reason        Razón del otorgamiento (para logs/mensajes)
 */
void AwardUnifiedPoints(int client, int points, const char[] reason)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	if (points <= 0)
		return;

	// Aplicar multiplicador de dificultad
	int difficultyMultiplier = GetDifficultyMultiplier();
	int finalPoints = points * difficultyMultiplier;

	// Otorgar Currency Points (sistema de compras)
	AwardCurrency(client, finalPoints, reason);

	// Actualizar estadísticas de currency según el tipo de evento
	if (StrContains(reason, "común", false) != -1 || StrContains(reason, "comun", false) != -1)
		CurrencyStats_AddCommonKill(client);
	else if (StrContains(reason, "Headshot", false) != -1)
		CurrencyStats_AddHeadshot(client);
	else if (StrContains(reason, "revivir", false) != -1)
		CurrencyStats_AddRevival(client);
	else if (StrContains(reason, "curar", false) != -1)
		CurrencyStats_AddHeal(client);

	// Otorgar XP Points (sistema de niveles)
	Leveling_AwardXP(client, finalPoints, reason);

	// Log para debugging con dificultad
	// LogMessage("[Eclipse Points] %N recibió %d puntos (%d base x%d dificultad) por: %s",
	//            client, finalPoints, points, difficultyMultiplier, reason);
}

//==================================================
// === EVENT HANDLERS - COMBATE ===
//==================================================

/**
 * Evento: Infected Death (infectados comunes y uncommon)
 */
public Action EclipsePoints_Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)  // Team 2 = Survivors
		return Plugin_Continue;

	bool isHeadshot = event.GetBool("headshot", false);

	// Detectar si es uncommon infected (L4D2 only)
	bool isUncommon = false;
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		// Los uncommon tienen la propiedad "type" en el evento
		// Valor 0 = común, valor > 0 = uncommon (riot, clown, mudman, etc.)
		int type = event.GetInt("type", 0);
		isUncommon = (type > 0);
	}

	// Seleccionar puntos base según tipo
	int points = isUncommon ? cvar_PointsUncommonKill.IntValue : cvar_PointsCommonKill.IntValue;

	// Otorgar puntos base por infectado
	if (isUncommon)
		AwardUnifiedPoints(attacker, points, "Matar infectado uncommon");
	else
		AwardUnifiedPoints(attacker, points, "Matar infectado común");

	// Bonus por headshot
	if (isHeadshot)
	{
		int headshotBonus = cvar_PointsHeadshot.IntValue;
		AwardUnifiedPoints(attacker, headshotBonus, "Headshot");
	}

	return Plugin_Continue;
}

/**
 * Evento: Player Death (para infectados especiales)
 * Nota: Este evento NO se usa para otorgar puntos directamente,
 * los eventos específicos (tank_killed, witch_killed) se manejan por separado
 */
public Action EclipsePoints_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	// Si el atacante es survivor y la víctima es infectado especial
	if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
	{
		// Verificar que NO sea Tank ni Witch (esos tienen eventos propios)
		int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

		// ZombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger, 8=Tank
		// Solo otorgamos puntos para 1-7 (especiales normales, NO Tank)
		if (zombieClass >= 1 && zombieClass <= 7 && zombieClass != 8)
		{
			int points = cvar_PointsSpecialKill.IntValue;
			bool isHeadshot = event.GetBool("headshot", false);

			AwardUnifiedPoints(attacker, points, "Matar infectado especial");

			// Bonus por headshot
			if (isHeadshot)
			{
				int headshotBonus = cvar_PointsHeadshot.IntValue;
				AwardUnifiedPoints(attacker, headshotBonus, "Headshot en especial");
			}
		}
	}

	return Plugin_Continue;
}

/**
 * Evento: Tank Killed
 */
public Action EclipsePoints_Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)
		return Plugin_Continue;

	int points = cvar_PointsTankKill.IntValue;
	AwardUnifiedPoints(attacker, points, "Matar Tank");

	return Plugin_Continue;
}

/**
 * Evento: Witch Killed
 */
public Action EclipsePoints_Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)
		return Plugin_Continue;

	int points = cvar_PointsWitchKill.IntValue;
	AwardUnifiedPoints(attacker, points, "Matar Witch");

	return Plugin_Continue;
}

//==================================================
// === EVENT HANDLERS - SOPORTE ===
//==================================================

/**
 * Evento: Heal Success (curar con medkit)
 */
public Action EclipsePoints_Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (healer <= 0 || healer > MaxClients || !IsClientInGame(healer))
		return Plugin_Continue;

	// No otorgar puntos por auto-curarse
	if (healer == subject)
		return Plugin_Continue;

	int points = cvar_PointsHeal.IntValue;
	AwardUnifiedPoints(healer, points, "Curar compañero");

	return Plugin_Continue;
}

/**
 * Evento: Revive Success (levantar a compañero)
 */
public Action EclipsePoints_Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int reviver = GetClientOfUserId(event.GetInt("userid"));

	if (reviver <= 0 || reviver > MaxClients || !IsClientInGame(reviver))
		return Plugin_Continue;

	int points = cvar_PointsRevive.IntValue;
	AwardUnifiedPoints(reviver, points, "Revivir compañero");

	return Plugin_Continue;
}

/**
 * Evento: Defibrillator Used (L4D2 only)
 */
public Action EclipsePoints_Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
	int user = GetClientOfUserId(event.GetInt("userid"));

	if (user <= 0 || user > MaxClients || !IsClientInGame(user))
		return Plugin_Continue;

	int points = cvar_PointsDefibrillator.IntValue;
	AwardUnifiedPoints(user, points, "Usar desfibrilador");

	return Plugin_Continue;
}

//==================================================
// === EVENT HANDLERS - SAVES AVANZADOS ===
//==================================================

/**
 * Evento: Smoker Save (liberar de lengua)
 */
public Action EclipsePoints_Event_SmokerSave(Event event, const char[] name, bool dontBroadcast)
{
	int savior = GetClientOfUserId(event.GetInt("userid"));

	if (savior <= 0 || savior > MaxClients || !IsClientInGame(savior))
		return Plugin_Continue;

	int points = cvar_PointsSmokerSave.IntValue;
	AwardUnifiedPoints(savior, points, "Salvar de Smoker");

	return Plugin_Continue;
}

/**
 * Evento: Hunter Save (liberar de pounce)
 */
public Action EclipsePoints_Event_HunterSave(Event event, const char[] name, bool dontBroadcast)
{
	int savior = GetClientOfUserId(event.GetInt("userid"));

	if (savior <= 0 || savior > MaxClients || !IsClientInGame(savior))
		return Plugin_Continue;

	int points = cvar_PointsHunterSave.IntValue;
	AwardUnifiedPoints(savior, points, "Salvar de Hunter");

	return Plugin_Continue;
}

/**
 * Evento: Jockey Save (liberar de jockey)
 */
public Action EclipsePoints_Event_JockeySave(Event event, const char[] name, bool dontBroadcast)
{
	int savior = GetClientOfUserId(event.GetInt("userid"));

	if (savior <= 0 || savior > MaxClients || !IsClientInGame(savior))
		return Plugin_Continue;

	int points = cvar_PointsJockeySave.IntValue;
	AwardUnifiedPoints(savior, points, "Salvar de Jockey");

	return Plugin_Continue;
}

//==================================================
// === EVENT HANDLERS - PROGRESO DE MAPA ===
//==================================================

/**
 * Evento: Left Safe Area (tracking)
 */
public Action EclipsePoints_Event_LeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		g_bPlayerLeftSafeArea[client] = true;
	}

	return Plugin_Continue;
}

/**
 * Evento: Map Complete (finale o transición)
 * Solo otorga puntos a jugadores que salieron del safe area inicial
 */
public Action EclipsePoints_Event_MapComplete(Event event, const char[] name, bool dontBroadcast)
{
	int points = cvar_PointsCompleteMap.IntValue;

	// Otorgar a todos los survivors vivos que participaron
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			// Solo otorgar si el jugador salió del safe area y no ha recibido el premio
			if (g_bPlayerLeftSafeArea[client] && !g_bMapCompleteAwarded[client])
			{
				AwardUnifiedPoints(client, points, "Completar mapa");
				g_bMapCompleteAwarded[client] = true;
			}
		}
	}

	return Plugin_Continue;
}

/**
 * Evento: Survival Round Start
 */
public Action EclipsePoints_Event_SurvivalRound(Event event, const char[] name, bool dontBroadcast)
{
	int points = cvar_PointsSurvivalRound.IntValue;

	// Otorgar a todos los survivors
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			AwardUnifiedPoints(client, points, "Completar ronda de supervivencia");
		}
	}

	return Plugin_Continue;
}
