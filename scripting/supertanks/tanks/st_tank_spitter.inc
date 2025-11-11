#if defined _st_tank_spitter_included
 #endinput
#endif
#define _st_tank_spitter_included

// ============================================================================
// SPITTER TANK MODULE
// Spitter Tank abilities and mechanics
// Color: RGB(12, 115, 128) = 12115128
// ============================================================================

/**
 * Spitter Tank passive ability
 * Creates acid puddles at tank's feet
 *
 * @param client    Spitter Tank client index
 * @noreturn
 */
stock SpitterTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		new Float:Origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		Origin[2] += 10.0;

		new ent = CreateEntityByName("spitter_projectile");
		if (IsValidEntity(ent))
		{
			DispatchSpawn(ent);
			SetEntPropFloat(ent, Prop_Send, "m_DmgRadius", 1024.0);
			SetEntProp(ent, Prop_Send, "m_bIsLive", 1 );
			SetEntPropEnt(ent, Prop_Send, "m_hThrower", client);
			TeleportEntity(ent, Origin, NULL_VECTOR, NULL_VECTOR);
			L4D2_SpitBurst(ent);
		}
	}
}

/**
 * Attach acid particle effect to Spitter Tank
 *
 * @param client    Spitter Tank client index
 * @return          Plugin_Continue or Plugin_Stop
 */
public Action:Timer_AttachSPIT(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		AttachParticle(client, PARTICLE_SPIT, 2.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

/**
 * Play spit sound for rock throw
 *
 * @param client    Spitter Tank client index
 * @noreturn
 */
public Action:Timer_SpitSound(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client);
	}
}

/**
 * Attach acid particle to Spitter Tank rock
 *
 * @param entity    Tank rock entity
 * @return          Plugin_Continue or Plugin_Stop
 */
public Action:Timer_AttachSPIT_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			AttachParticle(entity, PARTICLE_SPITPROJ, 0.8, 0.0, 0.0, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
