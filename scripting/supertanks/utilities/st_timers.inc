#if defined _st_timers_included
 #endinput
#endif
#define _st_timers_included

// ============================================================================
// TIMERS MODULE
// Main game loop timers and client update functions
// ============================================================================

/**
 * Main timer - 0.1 second interval
 * Displays tank health on crosshair for survivors
 */
public Action:TimerUpdate01(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;

	if (bSuperTanksEnabled && bDisplayHealthCvar)
	{
		if (iNumTanks > 0)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					if (!IsFakeClient(i))
					{
						new entity = GetClientAimTarget(i, true);
						if (IsTank(entity))
						{
							new health = GetClientHealth(entity);
							if (health > 0)
							{
								PrintHintText(i, "%N (%i HP)", entity, health);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/**
 * Main timer - 1.0 second interval
 * Executes core game logic updates
 */
public Action:TimerUpdate1(Handle:timer)
{
	if (bSuperTanksEnabled)
	{
		TankController();
		SpawnInfectedInterval();
		TimerUpdateClients();
		ExecNightmare();
		ExecGameModes();
	}

	return Plugin_Continue;
}

/**
 * Update all client timers
 * Called every second
 */
stock TimerUpdateClients()
{
	for (new i=1; i<=MaxClients; i++)
	{
		UpdateTimers(i);
	}
}
