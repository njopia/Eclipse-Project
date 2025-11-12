#if defined _st_tank_gravity_timer_included
 #endinput
#endif
#define _st_tank_gravity_timer_included

// ============================================================================
// GRAVITY TANK TIMER
// Creates spotlight and gravity pull effects for Gravity Tank
// ============================================================================

/**
 * Gravity Tank Timer
 * Creates spotlight beam and gravity pull field
 */
public Action:GravityTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 333435)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		Angles[0] += -90.0;

		// Create spotlight beam
		new entity = CreateEntityByName("beam_spotlight");
		if (IsValidEntity(entity))
		{
			DispatchKeyValueVector(entity, "origin", Origin);
			DispatchKeyValueVector(entity, "angles", Angles);
			DispatchKeyValue(entity, "spotlightwidth", "10");
			DispatchKeyValue(entity, "spotlightlength", "60");
			DispatchKeyValue(entity, "spawnflags", "3");
			DispatchKeyValue(entity, "rendercolor", "100 100 100");
			DispatchKeyValue(entity, "renderamt", "125");
			DispatchKeyValue(entity, "maxspeed", "100");
			DispatchKeyValue(entity, "HDRColorScale", "0.7");
			DispatchKeyValue(entity, "fadescale", "1");
			DispatchKeyValue(entity, "fademindist", "-1");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "Enable");
			AcceptEntityInput(entity, "DisableCollision");

			SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
			SetVariantString("mouth");
			AcceptEntityInput(entity, "SetParentAttachment");

			TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
		}

		// Create gravity pull field
		new blackhole = CreateEntityByName("point_push");
		if (IsValidEntity(blackhole))
		{
			DispatchKeyValueVector(blackhole, "origin", Origin);
			DispatchKeyValueVector(blackhole, "angles", Angles);
			DispatchKeyValue(blackhole, "radius", "750");
			DispatchKeyValueFloat(blackhole, "magnitude", flGravityPullForce);
			DispatchKeyValue(blackhole, "spawnflags", "8");
			DispatchSpawn(blackhole);
			AcceptEntityInput(blackhole, "Enable");

			SetEntProp(blackhole, Prop_Send, "m_glowColorOverride", client);

			SetVariantString("!activator");
			AcceptEntityInput(blackhole, "SetParent", client);
		}
	}
	return Plugin_Continue;
}
