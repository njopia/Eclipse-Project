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

/**
 * Rock Throw Timer
 * Handles tank rock modifications based on tank type
 */
public Action:RockThrowTimer(Handle:timer)
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		new thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if (thrower > 0 && thrower < 33 && IsTank(thrower))
		{
			new color = GetEntRenderColor(thrower);
			switch(color)
			{
				//Fire Tank
				case 12800:
				{
					SetEntityRenderColor(entity, 128, 0, 0, 255);
					CreateTimer(0.8, Timer_AttachFIRE_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Ice Tank
				case 0100170:
				{
					SetEntityRenderMode(entity, RenderMode:3);
					SetEntityRenderColor(entity, 0, 100, 170, 180);
				}
				//Spitter Tank
				case 12115128:
				{
					SetEntityRenderMode(entity, RenderMode:3);
					SetEntityRenderColor(entity, 121, 151, 28, 30);
					CreateTimer(0.8, Timer_SpitSound, thrower, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(0.8, Timer_AttachSPIT_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Shock Tank
				case 100165255:
				{
					CreateTimer(0.8, Timer_AttachELEC_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	return Plugin_Continue;
}
