#if defined _st_tank_cobalt_included
 #endinput
#endif
#define _st_tank_cobalt_included

// ============================================================================
// COBALT TANK MODULE
// Cobalt Tank special speed boost with blur effect
// Color: RGB(0, 105, 255) = 0105255
// ============================================================================

/**
 * Cobalt Tank blur effect
 * Creates visual afterimages when tank is in speed boost mode
 *
 * @param timer    Timer handle
 * @param client   Cobalt Tank client index
 * @return         Plugin_Continue if tank is valid and ability active, Plugin_Stop otherwise
 */
public Action:BlurEffect(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0105255 && TankAbility[client] == 1)
	{
		new Float:TankPos[3], Float:TankAng[3];
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, Prop_Send, "m_nSequence");
		new entity = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			SetEntityRenderColor(entity, 0, 105, 255, 255);
			SetEntProp(entity, Prop_Send, "m_nSequence", Anim);
			SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 15.0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect, entity, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

/**
 * Remove blur effect entity
 * Destroys the afterimage prop after a short delay
 *
 * @param timer    Timer handle
 * @param entity   Blur effect entity index
 * @return         Plugin_Stop
 */
public Action:RemoveBlurEffect(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	return Plugin_Stop;
}
