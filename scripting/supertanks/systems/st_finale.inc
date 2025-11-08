#if defined _st_finale_included
 #endinput
#endif
#define _st_finale_included

// ============================================================================
// FINALE SYSTEM MODULE
// Manages finale events and wave-based tank spawning
// ============================================================================

/**
 * Finale Escape Start event
 * Triggered when survivors reach the escape vehicle
 */
public Action:Finale_Escape_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 3;
	return Plugin_Continue;
}

/**
 * Finale Start event
 * Triggered when finale button is pressed or gauntlet finale starts
 */
public Action:Finale_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 1;
	return Plugin_Continue;
}

/**
 * Finale Vehicle Leaving event
 * Triggered when rescue vehicle is leaving
 */
public Action:Finale_Vehicle_Leaving(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 4;
	return Plugin_Continue;
}

/**
 * Finale Vehicle Ready event
 * Triggered when rescue vehicle arrives
 * Also activates Nightmare mode countdown
 */
public Action:Finale_Vehicle_Ready(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 3;
	if (bSuperTanksEnabled)
	{
		SetConVarInt(hNightmareBegin, 1);
	}
	return Plugin_Continue;
}

/**
 * Tank Wave 2 Timer
 * Advances to wave 2 when all wave 1 tanks are dead
 *
 * @param timer    Timer handle
 * @return         Plugin_Continue
 */
public Action:TimerTankWave2(Handle:timer)
{
	CountTanks();
	if (iNumTanks == 0)
	{
		iFinaleStage = 2;
	}
	return Plugin_Continue;
}

/**
 * Tank Wave 3 Timer
 * Advances to wave 3 when all wave 2 tanks are dead
 *
 * @param timer    Timer handle
 * @return         Plugin_Continue
 */
public Action:TimerTankWave3(Handle:timer)
{
	CountTanks();
	if (iNumTanks == 0)
	{
		iFinaleStage = 3;
	}
	return Plugin_Continue;
}

/**
 * Spawn Tank Timer
 * Continuously spawns tanks during finale based on current wave
 * Wave 1: Spawns up to iWave1Cvar tanks
 * Wave 2: Spawns up to iWave2Cvar tanks
 * Wave 3: Spawns up to iWave3Cvar tanks
 *
 * @param timer    Timer handle
 * @return         Plugin_Continue
 */
public Action:SpawnTankTimer(Handle:timer)
{
	CountTanks();
	if (iFinaleStage == 1)
	{
		if (iNumTanks < iWave1Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (iFinaleStage == 2)
	{
		if (iNumTanks < iWave2Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (iFinaleStage == 3)
	{
		if (iNumTanks < iWave3Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Register finale event hooks
 * Should be called from OnPluginStart
 */
stock RegisterFinaleEvents()
{
	HookEvent("finale_escape_start", Finale_Escape_Start);
	HookEvent("finale_start", Finale_Start, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Finale_Vehicle_Leaving);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready);
	HookEvent("gauntlet_finale_start", Finale_Start);
}
