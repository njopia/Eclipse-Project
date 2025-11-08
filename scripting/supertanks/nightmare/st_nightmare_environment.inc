#if defined _st_nightmare_environment_included
 #endinput
#endif
#define _st_nightmare_environment_included

// ============================================================================
// NIGHTMARE MODE - ENVIRONMENT MODULE
// Fog control, color correction, and visual atmosphere
// ============================================================================

/**
 * Create color correction entity
 * Applies color grading effect for atmosphere
 *
 * @param FileName    Path to color correction file (.raw)
 * @noreturn
 */
stock CreateColorCorrection(String:FileName[])
{
	decl String:tName[8];
	if (iCCEnt <= 0)
	{
		new colorent = CreateEntityByName("color_correction");
		if (colorent > 32 && IsValidEntity(colorent))
		{
			DispatchKeyValue(colorent, "spawnflags", "2");
			DispatchKeyValue(colorent, "maxweight", "0.6");
			DispatchKeyValue(colorent, "fadeInDuration", "4");
			DispatchKeyValue(colorent, "fadeOutDuration", "4");
			DispatchKeyValue(colorent, "filename", FileName);
			Format(tName, sizeof(tName), "target");
			DispatchKeyValue(colorent, "targetname", tName);
			DispatchSpawn(colorent);
			ActivateEntity(colorent);
			AcceptEntityInput(colorent, "Enable");
			iCCEnt = colorent;
		}
	}
}

/**
 * Execute game mode environmental changes
 * Controls fog and time-of-day based on Nightmare mode
 *
 * @noreturn
 */
stock ExecGameModes()
{
	if (bNightmare)
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			SetEntPropFloat(entity, Prop_Send, "m_fog.start", 242.0);
			SetEntPropFloat(entity, Prop_Send, "m_fog.end", 730.0);
		}
		new Handle:cvar = FindConVar("sv_force_time_of_day");
		if (cvar != INVALID_HANDLE)
		{
			SetConVarInt(cvar, 3);
		}
	}
	else
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			SetEntPropFloat(entity, Prop_Send, "m_fog.start", 0.0);
			SetEntPropFloat(entity, Prop_Send, "m_fog.end", 0.0);
		}
		new Handle:cvar = FindConVar("sv_force_time_of_day");
		if (cvar != INVALID_HANDLE)
		{
			SetConVarInt(cvar, 0);
		}
		if (iCCEnt > 0 && IsValidEntity(iCCEnt))
		{
			AcceptEntityInput(iCCEnt, "Kill");
			iCCEnt = 0;
		}
	}
}
