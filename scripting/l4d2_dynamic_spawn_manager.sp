#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.1"
#define MAX_PLAYERS 16

// ConVars del plugin
ConVar g_cvEnabled;
ConVar g_cvUpdateInterval;
ConVar g_cvForceHordeInterval;
ConVar g_cvEnableAutoHorde;
ConVar g_cvTankHealthMultiplier;
ConVar g_cvWitchHealthMultiplier;
ConVar g_cvDifficultyTankReduction;
ConVar g_cvChatFeedback;
ConVar g_cvChatFeedbackInterval;

// Variables globales
int g_iCurrentGamemode = -1;
int g_iLastPlayerCount = 0;
int g_iLastFeedbackTime = 0;

public Plugin myinfo =
{
	name = "L4D2 Dynamic Spawn Manager",
	author = "Eclipse Project",
	description = "Manages zombie spawn rates and special infected based on player count (max 16 players)",
	version = PLUGIN_VERSION,
	url = "https://github.com/eclipse-project"
}

public void OnPluginStart()
{
	// ConVars de configuración
	CreateConVar("sm_dsm_version", PLUGIN_VERSION, "Dynamic Spawn Manager Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_cvEnabled = CreateConVar("sm_dsm_enabled", "1", "Enable Dynamic Spawn Manager (0=Disabled, 1=Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvUpdateInterval = CreateConVar("sm_dsm_update_interval", "5.0", "Interval in seconds to update spawn rates", FCVAR_NOTIFY, true, 1.0, true, 60.0);
	g_cvForceHordeInterval = CreateConVar("sm_dsm_force_horde_interval", "60.0", "Interval in seconds to force panic events (0=Disabled)", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	g_cvEnableAutoHorde = CreateConVar("sm_dsm_auto_horde", "1", "Enable automatic forced hordes (0=Disabled, 1=Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTankHealthMultiplier = CreateConVar("sm_dsm_tank_hp_mult", "1.0", "Tank health multiplier", FCVAR_NOTIFY, true, 0.1, true, 5.0);
	g_cvWitchHealthMultiplier = CreateConVar("sm_dsm_witch_hp_mult", "1.0", "Witch health multiplier", FCVAR_NOTIFY, true, 0.1, true, 5.0);
	g_cvDifficultyTankReduction = CreateConVar("sm_dsm_diff_tank_reduction", "5000", "Tank HP reduction on Hard difficulty (not Survival)", FCVAR_NOTIFY, true, 0.0, true, 20000.0);
	g_cvChatFeedback = CreateConVar("sm_dsm_chat_feedback", "1", "Show spawn adjustments in chat (0=Disabled, 1=Enabled, 2=Admins Only)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_cvChatFeedbackInterval = CreateConVar("sm_dsm_feedback_interval", "30", "Minimum seconds between chat feedback messages", FCVAR_NOTIFY, true, 10.0, true, 300.0);

	AutoExecConfig(true, "l4d2_dynamic_spawn_manager");

	// Detectar gamemode
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	// Hook de cambio de equipo para detectar nuevos jugadores
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
}

public void OnMapStart()
{
	g_iCurrentGamemode = GetCurrentGamemodeID();
	g_iLastPlayerCount = 0;
	g_iLastFeedbackTime = 0;

	// Iniciar timer de balance
	if (g_cvEnabled.BoolValue)
	{
		CreateTimer(g_cvUpdateInterval.FloatValue, Timer_BalanceSpawn, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		// Timer de hordas automáticas (si está habilitado)
		if (g_cvEnableAutoHorde.BoolValue && g_cvForceHordeInterval.FloatValue > 0.0)
		{
			CreateTimer(g_cvForceHordeInterval.FloatValue, Timer_ForceHorde, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		// Mensaje inicial
		CreateTimer(3.0, Timer_InitialMessage, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iCurrentGamemode = GetCurrentGamemodeID();
	g_iLastPlayerCount = 0; // Reset para permitir feedback en nuevo round
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	// Esto ayudará a detectar cambios de jugadores
	int newTeam = event.GetInt("team");
	if (newTeam == 2) // Equipo Survivors
	{
		CreateTimer(0.5, Timer_CheckPlayerCountChange, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_InitialMessage(Handle timer)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Stop;

	int feedbackMode = g_cvChatFeedback.IntValue;
	if (feedbackMode == 0)
		return Plugin_Stop;

	PrintToChatAll("\x04[Dynamic Spawn] \x01Sistema de spawn dinámico activado (Max: \x05%d \x01jugadores)", MAX_PLAYERS);
	return Plugin_Stop;
}

public Action Timer_CheckPlayerCountChange(Handle timer)
{
	// Simplemente forzar una actualización inmediata
	return Plugin_Stop;
}

public Action Timer_ForceHorde(Handle timer)
{
	if (!g_cvEnabled.BoolValue || !g_cvEnableAutoHorde.BoolValue)
		return Plugin_Continue;

	// Solo en Coop (gamemode 0), y si hay jugadores humanos
	if (g_iCurrentGamemode == 1 || GetHumanCount() == 0)
		return Plugin_Continue;

	// Buscar un cliente válido para ejecutar el comando
	int client = GetAnyValidClient();
	if (client == -1)
		return Plugin_Continue;

	// Forzar panic event usando FakeClientCommand (más confiable que ServerCommand)
	int flags = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags);

	// Feedback visual
	int feedbackMode = g_cvChatFeedback.IntValue;
	if (feedbackMode > 0)
	{
		PrintToChatAll("\x04[Dynamic Spawn] \x03Horda forzada activada!");
	}

	return Plugin_Continue;
}

public Action Timer_BalanceSpawn(Handle timer)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;

	// No balancear en Versus
	if (g_iCurrentGamemode == 1)
		return Plugin_Continue;

	// Obtener dificultad actual
	char sDifficulty[32];
	ConVar cvDifficulty = FindConVar("z_difficulty");
	if (cvDifficulty == null)
		return Plugin_Continue;

	cvDifficulty.GetString(sDifficulty, sizeof(sDifficulty));

	// Contar jugadores humanos supervivientes
	int iHumanCount = GetTeamHumanCount(2);

	// Limitar a máximo 16 jugadores
	if (iHumanCount > MAX_PLAYERS)
		iHumanCount = MAX_PLAYERS;

	// Calcular configuración según jugadores
	int iMaxSpecials, iSpawnTimeMin, iSpawnTimeMax;
	int iBoomerLimit, iChargerLimit, iHunterLimit, iJockeyLimit, iSmokerLimit, iSpitterLimit, iTankLimit;
	int iTankHealth, iWitchHealth;
	int iMobSpawnMin, iMobSpawnMax;

	// Calcular bonus por jugadores expertos (skill alto)
	int iTankBonus = 0;
	int iSpecialsBonus = 0;
	int iSpawnTimeBonus = GetMastersCount(5);

	if (GetMastersCount(5) > 3)
	{
		iTankBonus = 0;
		iSpecialsBonus = 1;
	}
	if (GetMastersCount(5) > 6)
	{
		iTankBonus = 1;
		iSpecialsBonus = 2;
	}

	// Configuración base según cantidad de jugadores
	if (iHumanCount > 4)
		iMaxSpecials = iHumanCount + iSpecialsBonus;
	else
		iMaxSpecials = 4 + iSpecialsBonus;

	// Configuraciones escalonadas por jugadores (OPTIMIZADO PARA MAX 16)
	if (iHumanCount <= 4)
	{
		iBoomerLimit = 1; iChargerLimit = 1; iHunterLimit = 1; iJockeyLimit = 1;
		iSmokerLimit = 1; iSpitterLimit = 1; iTankLimit = 1;
		iSpawnTimeMin = 20 - iSpawnTimeBonus; iSpawnTimeMax = 30;
		iTankHealth = 5000; iWitchHealth = 1000;
		iMobSpawnMin = 90; iMobSpawnMax = 180;
	}
	else if (iHumanCount == 5)
	{
		iBoomerLimit = 2; iChargerLimit = 1; iHunterLimit = 1; iJockeyLimit = 1;
		iSmokerLimit = 1; iSpitterLimit = 1; iTankLimit = 1;
		iSpawnTimeMin = 20 - iSpawnTimeBonus; iSpawnTimeMax = 30;
		iTankHealth = 6000; iWitchHealth = 1000;
		iMobSpawnMin = 90; iMobSpawnMax = 170;
	}
	else if (iHumanCount == 6)
	{
		iBoomerLimit = 2; iChargerLimit = 1; iHunterLimit = 2; iJockeyLimit = 1;
		iSmokerLimit = 1; iSpitterLimit = 1; iTankLimit = 1;
		iSpawnTimeMin = 20 - iSpawnTimeBonus; iSpawnTimeMax = 30;
		iTankHealth = 7000; iWitchHealth = 1500;
		iMobSpawnMin = 90; iMobSpawnMax = 160;
	}
	else if (iHumanCount == 7)
	{
		iBoomerLimit = 2; iChargerLimit = 1; iHunterLimit = 2; iJockeyLimit = 2;
		iSmokerLimit = 1; iSpitterLimit = 2; iTankLimit = 2;
		iSpawnTimeMin = 20 - iSpawnTimeBonus; iSpawnTimeMax = 30;
		iTankHealth = 8000; iWitchHealth = 1800;
		iMobSpawnMin = 90; iMobSpawnMax = 150;
	}
	else if (iHumanCount == 8)
	{
		iBoomerLimit = 2; iChargerLimit = 1; iHunterLimit = 2; iJockeyLimit = 2;
		iSmokerLimit = 2; iSpitterLimit = 2; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 20 - iSpawnTimeBonus; iSpawnTimeMax = 30;
		iTankHealth = 6000; iWitchHealth = 3000;
		iMobSpawnMin = 90; iMobSpawnMax = 140;
	}
	else if (iHumanCount == 9)
	{
		iBoomerLimit = 2; iChargerLimit = 2; iHunterLimit = 2; iJockeyLimit = 2;
		iSmokerLimit = 2; iSpitterLimit = 2; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 19 - iSpawnTimeBonus; iSpawnTimeMax = 29;
		iTankHealth = 7000; iWitchHealth = 3300;
		iMobSpawnMin = 90; iMobSpawnMax = 130;
	}
	else if (iHumanCount == 10)
	{
		iBoomerLimit = 3; iChargerLimit = 2; iHunterLimit = 3; iJockeyLimit = 2;
		iSmokerLimit = 2; iSpitterLimit = 2; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 18 - iSpawnTimeBonus; iSpawnTimeMax = 28;
		iTankHealth = 8000; iWitchHealth = 3500;
		iMobSpawnMin = 80; iMobSpawnMax = 110;
	}
	else if (iHumanCount == 11)
	{
		iBoomerLimit = 3; iChargerLimit = 2; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 2; iSpitterLimit = 2; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 17 - iSpawnTimeBonus; iSpawnTimeMax = 27;
		iTankHealth = 8000; iWitchHealth = 4000;
		iMobSpawnMin = 70; iMobSpawnMax = 100;
	}
	else if (iHumanCount == 12)
	{
		iBoomerLimit = 3; iChargerLimit = 2; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 2; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 16 - iSpawnTimeBonus; iSpawnTimeMax = 26;
		iTankHealth = 9000; iWitchHealth = 4100;
		iMobSpawnMin = 60; iMobSpawnMax = 90;
	}
	else if (iHumanCount == 13)
	{
		iBoomerLimit = 3; iChargerLimit = 2; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 15 - iSpawnTimeBonus; iSpawnTimeMax = 25;
		iTankHealth = 9000; iWitchHealth = 4200;
		iMobSpawnMin = 55; iMobSpawnMax = 85;
	}
	else if (iHumanCount == 14)
	{
		iBoomerLimit = 3; iChargerLimit = 3; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 3 + iTankBonus;
		iSpawnTimeMin = 14 - iSpawnTimeBonus; iSpawnTimeMax = 24;
		iTankHealth = 10000; iWitchHealth = 4300;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 15)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 3 + iTankBonus;
		iSpawnTimeMin = 13 - iSpawnTimeBonus; iSpawnTimeMax = 23;
		iTankHealth = 10000; iWitchHealth = 4500;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else // iHumanCount >= 16 (MÁXIMO)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 4; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 3 + iTankBonus;
		iSpawnTimeMin = 12 - iSpawnTimeBonus; iSpawnTimeMax = 22;
		iTankHealth = 11000; iWitchHealth = 4600;
		iMobSpawnMin = 45; iMobSpawnMax = 75;
	}

	// Ajustes por dificultad
	if (g_iCurrentGamemode != 3) // No es Survival
	{
		if (StrEqual(sDifficulty, "hard", false))
			iTankHealth -= g_cvDifficultyTankReduction.IntValue;
	}

	// Aplicar multiplicadores de ConVars
	iTankHealth = RoundToNearest(iTankHealth * g_cvTankHealthMultiplier.FloatValue);
	iWitchHealth = RoundToNearest(iWitchHealth * g_cvWitchHealthMultiplier.FloatValue);

	// Detectar cambio significativo de jugadores para feedback
	bool bPlayerCountChanged = (g_iLastPlayerCount != iHumanCount);
	int currentTime = GetTime();
	bool bCanShowFeedback = (currentTime - g_iLastFeedbackTime) >= g_cvChatFeedbackInterval.IntValue;

	// Aplicar cambios solo si son diferentes de los valores actuales
	bool bAnyChange = false;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_boomer_limit", iBoomerLimit) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_charger_limit", iChargerLimit) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_hunter_limit", iHunterLimit) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_jockey_limit", iJockeyLimit) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_smoker_limit", iSmokerLimit) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_spitter_limit", iSpitterLimit) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_tank_limit", iTankLimit) || bAnyChange;

	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_spawn_time_min", iSpawnTimeMin) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_spawn_time_max", iSpawnTimeMax) || bAnyChange;

	bAnyChange = ApplyConVarIfChanged("z_tank_health", iTankHealth) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("z_witch_health", iWitchHealth) || bAnyChange;

	bAnyChange = ApplyConVarIfChanged("z_mob_spawn_min_interval_normal", iMobSpawnMin) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("z_mob_spawn_max_interval_normal", iMobSpawnMax) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("z_mega_mob_spawn_min_interval", iMobSpawnMin) || bAnyChange;
	bAnyChange = ApplyConVarIfChanged("z_mega_mob_spawn_max_interval", iMobSpawnMax) || bAnyChange;

	bAnyChange = ApplyConVarIfChanged("l4d_infectedbots_max_specials", iMaxSpecials) || bAnyChange;

	// Mostrar feedback si hay cambios y se cumplen las condiciones
	if (bAnyChange && bPlayerCountChanged && bCanShowFeedback)
	{
		ShowSpawnFeedback(iHumanCount, iMaxSpecials, iMobSpawnMin, iMobSpawnMax, iTankHealth, iWitchHealth);
		g_iLastFeedbackTime = currentTime;
	}

	g_iLastPlayerCount = iHumanCount;

	return Plugin_Continue;
}

// ========================
// FUNCIONES AUXILIARES
// ========================

void ShowSpawnFeedback(int players, int specials, int mobMin, int mobMax, int tankHP, int witchHP)
{
	int feedbackMode = g_cvChatFeedback.IntValue;

	if (feedbackMode == 0)
		return;

	// Mensaje principal
	char msg[256];
	Format(msg, sizeof(msg), "\x04[Dynamic Spawn] \x01Ajustado para \x05%d \x01jugador%s",
		players, (players == 1) ? "" : "es");

	if (feedbackMode == 1) // Todos
	{
		PrintToChatAll("%s", msg);
		PrintToChatAll("\x04↳ \x03Especiales: \x05%d \x01| Hordas: \x05%d-%ds \x01| Tank: \x05%dHP \x01| Witch: \x05%dHP",
			specials, mobMin, mobMax, tankHP, witchHP);
	}
	else if (feedbackMode == 2) // Solo admins
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
			{
				PrintToChat(i, "%s", msg);
				PrintToChat(i, "\x04↳ \x03Especiales: \x05%d \x01| Hordas: \x05%d-%ds \x01| Tank: \x05%dHP \x01| Witch: \x05%dHP",
					specials, mobMin, mobMax, tankHP, witchHP);
			}
		}
	}
}

bool ApplyConVarIfChanged(const char[] cvarName, int newValue)
{
	ConVar cv = FindConVar(cvarName);
	if (cv == null)
		return false;

	if (cv.IntValue != newValue)
	{
		cv.SetInt(newValue);
		return true;
	}

	return false;
}

int GetTeamHumanCount(int team)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
			count++;
	}
	return count;
}

int GetHumanCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			count++;
	}
	return count;
}

int GetAnyValidClient()
{
	// Preferir supervivientes humanos primero
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			return i;
	}

	// Si no hay supervivientes humanos, cualquier humano sirve
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return i;
	}

	// Si no hay humanos, usar cualquier cliente (incluso bots)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			return i;
	}

	return -1; // No hay clientes válidos
}

int GetCurrentGamemodeID()
{
	char sGamemode[32];
	ConVar cvGamemode = FindConVar("mp_gamemode");
	if (cvGamemode == null)
		return -1;

	cvGamemode.GetString(sGamemode, sizeof(sGamemode));

	if (StrEqual(sGamemode, "coop", false))
		return 0;
	else if (StrEqual(sGamemode, "versus", false) || StrEqual(sGamemode, "teamversus", false))
		return 1;
	else if (StrEqual(sGamemode, "realism", false))
		return 2;
	else if (StrEqual(sGamemode, "survival", false))
		return 3;
	else if (StrEqual(sGamemode, "scavenge", false) || StrEqual(sGamemode, "teamscavenge", false))
		return 4;
	else if (StrContains(sGamemode, "mutation", false) == 0)
		return 6;

	return -1;
}

int GetMastersCount(int maxSkill)
{
	// Esta función requiere integración con sistema de skill
	// Por ahora retorna 0 (deshabilitado)
	// Para activar, necesitas integrar con tu sistema de ranking/skill
	return 0;
}
