#if defined _st_tank_fire_included
 #endinput
#endif
#define _st_tank_fire_included

// ============================================================================
// FIRE TANK MODULE
// Fire Tank abilities and mechanics
// Color: RGB(128, 0, 0) = 12800
// ============================================================================

/**
 * Fire Tank claw skill
 * Ignites the target on claw hit
 *
 * @param target    Survivor client index
 * @noreturn
 */
public SkillFlameClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			IgniteEntity(target, 3.0);
			EmitSoundToAll("ambient/fire/gascan_ignite1.wav", target);
			PerformFade(target, 500, 250, 10, 1, {100, 50, 0, 150});
		}
	}
}

/**
 * Fire Tank passive ability
 * Creates gascan explosions around the tank
 *
 * @param client    Fire Tank client index
 * @noreturn
 */
stock FireTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12800)
	{
		decl Float:Origin[3];
		GetClientAbsOrigin(client, Origin);
		GasCanExplode(client, Origin);
	}
}

/**
 * Create and explode a gascan at a location
 *
 * @param client    Client who caused the explosion
 * @param Origin    3D position for the explosion
 * @noreturn
 */
stock GasCanExplode(client, Float:Origin[3])
{
	new gascan = CreateEntityByName("prop_physics");
	if (gascan > 32 && IsValidEntity(gascan))
	{
		DispatchKeyValue(gascan, "model", MODEL_GASCAN);
		DispatchSpawn(gascan);
		if (IsValidClient(client))
		{
			SetEntPropEnt(gascan, Prop_Data, "m_hLastAttacker", client);
		}
		TeleportEntity(gascan, Origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(gascan);
		AcceptEntityInput(gascan, "Break");
	}
}
