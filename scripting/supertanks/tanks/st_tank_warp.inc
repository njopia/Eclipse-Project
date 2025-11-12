#if defined _st_tank_warp_included
 #endinput
#endif
#define _st_tank_warp_included

// ============================================================================
// WARP TANK MODULE
// Warp Tank abilities and mechanics
// Color: RGB(130, 130, 255) = 130130255
// ============================================================================

/**
 * Warp Tank passive ability
 * Randomly teleports behind survivors
 *
 * @param client    Warp Tank client index
 * @noreturn
 */
stock TeleportTank(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 130130255)
	{
		new random = GetRandomInt(1,iWarpTeleportDelay);
		if (random == 1)
		{
			new target = Pick();
			if (target)
			{
				new Float:Origin[3], Float:Angles[3];
				GetClientAbsOrigin(target, Origin);
                        	GetClientAbsAngles(target, Angles);
				CreateParticle(client, PARTICLE_WARP, 1.0, 0.0);
				TeleportEntity(client, Origin, Angles, NULL_VECTOR);
			}
		}
	}
}

// Pick() moved to utilities/st_utils.inc
