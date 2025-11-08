#if defined _st_tank_shield_included
 #endinput
#endif
#define _st_tank_shield_included

// ============================================================================
// SHIELD TANK MODULE
// Shield Tank shield mechanics and abilities
// Color: RGB(135, 205, 255) = 135205255
// ============================================================================

/**
 * Activate shield for Shield Tank
 * Creates a translucent shield prop parented to the tank
 *
 * @param client    Shield Tank client index
 * @noreturn
 */
stock ActivateShield(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 135205255 && ShieldsUp[client] == 0)
	{
		decl Float:Origin[3];
		GetClientAbsOrigin(client, Origin);
		Origin[2] -= 120.0;
		new entity = CreateEntityByName("prop_dynamic_override");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/props_unique/airport/atlas_break_ball.mdl");
			DispatchKeyValueVector(entity, "origin", Origin);
			DispatchSpawn(entity);

			SetEntityRenderMode(entity, RenderMode:3);
     			SetEntityRenderColor(entity, 25, 125, 125, 50);
			AcceptEntityInput(entity, "DisableCollision");
			AcceptEntityInput(entity, "DisableShadow");
			SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
			SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
		}
		ShieldsUp[client] = 1;
	}
}

/**
 * Deactivate shield for Shield Tank
 * Removes shield prop and schedules shield reactivation
 *
 * @param client    Shield Tank client index
 * @param time      Time before shield reactivates (unused - uses flShieldShieldsDownInterval from config)
 * @noreturn
 */
stock DeactivateShield(client, Float:time)
{
	#pragma unused time
	if (IsTank(client) && GetEntRenderColor(client) == 135205255 && ShieldsUp[client] == 1)
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
		{
			decl String:model[64];
            		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl", false))
			{
				new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
				if (owner == client)
				{
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
		CreateTimer(flShieldShieldsDownInterval, ActivateShieldTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		ShieldsUp[client] = 0;
	}
}

/**
 * Timer callback to reactivate shield
 *
 * @param timer    Timer handle
 * @param client   Shield Tank client index
 * @return         Plugin_Stop
 */
public Action:ActivateShieldTimer(Handle:timer, any:client)
{
	ActivateShield(client);
}
