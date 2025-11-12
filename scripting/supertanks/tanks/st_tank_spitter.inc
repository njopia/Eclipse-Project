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

// Timer_AttachSPIT, Timer_SpitSound, and Timer_AttachSPIT_Rock moved to utilities/st_tank_attach_timers.inc
