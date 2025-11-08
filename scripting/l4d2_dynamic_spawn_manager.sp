#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

// ConVars del plugin
ConVar g_cvEnabled;
ConVar g_cvUpdateInterval;
ConVar g_cvForceHordeInterval;
ConVar g_cvEnableAutoHorde;
ConVar g_cvTankHealthMultiplier;
ConVar g_cvWitchHealthMultiplier;
ConVar g_cvDifficultyTankReduction;

// Variables globales
int g_iCurrentGamemode = -1;

public Plugin myinfo =
{
	name = "L4D2 Dynamic Spawn Manager",
	author = "Eclipse Project",
	description = "Manages zombie spawn rates and special infected based on player count and difficulty",
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

	AutoExecConfig(true, "l4d2_dynamic_spawn_manager");

	// Detectar gamemode
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	g_iCurrentGamemode = GetCurrentGamemodeID();

	// Iniciar timer de balance
	if (g_cvEnabled.BoolValue)
	{
		CreateTimer(g_cvUpdateInterval.FloatValue, Timer_BalanceSpawn, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		// Timer de hordas automáticas (si está habilitado)
		if (g_cvEnableAutoHorde.BoolValue && g_cvForceHordeInterval.FloatValue > 0.0)
		{
			CreateTimer(g_cvForceHordeInterval.FloatValue, Timer_ForceHorde, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iCurrentGamemode = GetCurrentGamemodeID();
}

public Action Timer_ForceHorde(Handle timer)
{
	if (!g_cvEnabled.BoolValue || !g_cvEnableAutoHorde.BoolValue)
		return Plugin_Continue;

	// Solo en Coop (gamemode 0), y si hay jugadores humanos
	if (g_iCurrentGamemode == 1 || GetHumanCount() == 0)
		return Plugin_Continue;

	// Forzar panic event
	int flags = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags & ~FCVAR_CHEAT);
	ServerCommand("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flags);

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

	// Configuraciones escalonadas por jugadores
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
		iTankHealth = 6000; iWitchHealth = 4000;
		iMobSpawnMin = 70; iMobSpawnMax = 100;
	}
	else if (iHumanCount == 12)
	{
		iBoomerLimit = 3; iChargerLimit = 2; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 2; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 16 - iSpawnTimeBonus; iSpawnTimeMax = 26;
		iTankHealth = 7000; iWitchHealth = 4100;
		iMobSpawnMin = 60; iMobSpawnMax = 90;
	}
	else if (iHumanCount == 13)
	{
		iBoomerLimit = 3; iChargerLimit = 2; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 2 + iTankBonus;
		iSpawnTimeMin = 15 - iSpawnTimeBonus; iSpawnTimeMax = 25;
		iTankHealth = 8000; iWitchHealth = 4200;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 14)
	{
		iBoomerLimit = 3; iChargerLimit = 3; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 3 + iTankBonus;
		iSpawnTimeMin = 14 - iSpawnTimeBonus; iSpawnTimeMax = 24;
		iTankHealth = 8000; iWitchHealth = 4300;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 15)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 3; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 3 + iTankBonus;
		iSpawnTimeMin = 13 - iSpawnTimeBonus; iSpawnTimeMax = 23;
		iTankHealth = 9000; iWitchHealth = 4500;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 16)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 4; iJockeyLimit = 3;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 3 + iTankBonus;
		iSpawnTimeMin = 12 - iSpawnTimeBonus; iSpawnTimeMax = 22;
		iTankHealth = 10000; iWitchHealth = 4600;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 17)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 4; iJockeyLimit = 4;
		iSmokerLimit = 3; iSpitterLimit = 3; iTankLimit = 4 + iTankBonus;
		iSpawnTimeMin = 11 - iSpawnTimeBonus; iSpawnTimeMax = 21;
		iTankHealth = 9000; iWitchHealth = 4700;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 18)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 4; iJockeyLimit = 4;
		iSmokerLimit = 4; iSpitterLimit = 4; iTankLimit = 4 + iTankBonus;
		iSpawnTimeMin = 10 - iSpawnTimeBonus; iSpawnTimeMax = 20;
		iTankHealth = 10000; iWitchHealth = 4800;
		iMobSpawnMin = 50; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 19)
	{
		iBoomerLimit = 4; iChargerLimit = 3; iHunterLimit = 4; iJockeyLimit = 4;
		iSmokerLimit = 4; iSpitterLimit = 4; iTankLimit = 4 + iTankBonus;
		iSpawnTimeMin = 10 - iSpawnTimeBonus; iSpawnTimeMax = 20;
		iTankHealth = 11000; iWitchHealth = 4900;
		iMobSpawnMin = 40; iMobSpawnMax = 80;
	}
	else if (iHumanCount == 20)
	{
		iBoomerLimit = 4; iChargerLimit = 4; iHunterLimit = 4; iJockeyLimit = 4;
		iSmokerLimit = 4; iSpitterLimit = 4; iTankLimit = 4 + iTankBonus;
		iSpawnTimeMin = 10 - iSpawnTimeBonus; iSpawnTimeMax = 20;
		iTankHealth = 12000; iWitchHealth = 5000;
		iMobSpawnMin = 30; iMobSpawnMax = 80;
	}
	else // > 20 jugadores
	{
		iBoomerLimit = 4; iChargerLimit = 4; iHunterLimit = 4; iJockeyLimit = 4;
		iSmokerLimit = 4; iSpitterLimit = 4; iTankLimit = 5;
		iSpawnTimeMin = 10 - iSpawnTimeBonus; iSpawnTimeMax = 20;
		iTankHealth = 12000; iWitchHealth = 5000;
		iMobSpawnMin = 20; iMobSpawnMax = 80;
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

	// Aplicar cambios solo si son diferentes de los valores actuales
	ApplyConVarIfChanged("l4d_infectedbots_boomer_limit", iBoomerLimit);
	ApplyConVarIfChanged("l4d_infectedbots_charger_limit", iChargerLimit);
	ApplyConVarIfChanged("l4d_infectedbots_hunter_limit", iHunterLimit);
	ApplyConVarIfChanged("l4d_infectedbots_jockey_limit", iJockeyLimit);
	ApplyConVarIfChanged("l4d_infectedbots_smoker_limit", iSmokerLimit);
	ApplyConVarIfChanged("l4d_infectedbots_spitter_limit", iSpitterLimit);
	ApplyConVarIfChanged("l4d_infectedbots_tank_limit", iTankLimit);

	ApplyConVarIfChanged("l4d_infectedbots_spawn_time_min", iSpawnTimeMin);
	ApplyConVarIfChanged("l4d_infectedbots_spawn_time_max", iSpawnTimeMax);

	ApplyConVarIfChanged("z_tank_health", iTankHealth);
	ApplyConVarIfChanged("z_witch_health", iWitchHealth);

	ApplyConVarIfChanged("z_mob_spawn_min_interval_normal", iMobSpawnMin);
	ApplyConVarIfChanged("z_mob_spawn_max_interval_normal", iMobSpawnMax);
	ApplyConVarIfChanged("z_mega_mob_spawn_min_interval", iMobSpawnMin);
	ApplyConVarIfChanged("z_mega_mob_spawn_max_interval", iMobSpawnMax);

	ApplyConVarIfChanged("l4d_infectedbots_max_specials", iMaxSpecials);

	return Plugin_Continue;
}

// ========================
// FUNCIONES AUXILIARES
// ========================

void ApplyConVarIfChanged(const char[] cvarName, int newValue)
{
	ConVar cv = FindConVar(cvarName);
	if (cv == null)
		return;

	if (cv.IntValue != newValue)
		cv.SetInt(newValue);
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
