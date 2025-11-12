#if defined _st_tank_attach_timers_included
 #endinput
#endif
#define _st_tank_attach_timers_included

// ============================================================================
// TANK ATTACHMENT TIMERS
// Particle and visual effect attachment timers for all tank types
// ============================================================================

// ====================
// FIRE TANK TIMERS
// ====================

public Action:Timer_AttachFIRE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12800)
	{
		AttachParticle(client, PARTICLE_FIRE, 0.8, 0.0, 0.0, 0.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action:Timer_AttachFIRE_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			IgniteEntity(entity, 100.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

// ====================
// ICE TANK TIMERS
// ====================

public Action:Timer_AttachICE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0100170)
	{
		AttachParticle(client, PARTICLE_SMOKE, 2.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

// ====================
// SPITTER TANK TIMERS
// ====================

public Action:Timer_AttachSPIT(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		AttachParticle(client, PARTICLE_SPIT, 2.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action:Timer_SpitSound(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client);
	}
	return Plugin_Continue;
}

public Action:Timer_AttachSPIT_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			AttachParticle(entity, PARTICLE_SPITPROJ, 0.8, 0.0, 0.0, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

// ====================
// SHOCK TANK TIMERS
// ====================

public Action:Timer_AttachELEC(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100165255)
	{
		AttachParticle(client, PARTICLE_ELEC, 0.8, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action:Timer_AttachELEC_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			AttachParticle(entity, PARTICLE_ELEC, 0.8, 0.0, 0.0, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

// ====================
// WITCH TANK TIMERS (BLOOD)
// ====================

public Action:Timer_AttachBLOOD(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255200255)
	{
		AttachParticle(client, PARTICLE_BLOOD_EXPLODE, 0.8, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
