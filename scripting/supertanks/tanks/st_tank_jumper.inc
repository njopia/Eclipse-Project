#if defined _st_tank_jumper_included
 #endinput
#endif
#define _st_tank_jumper_included

// ============================================================================
// JUMPER TANK MODULE
// Jumper Tank cosmetic tire attachments
// Color: RGB(200, 255, 0) = 2002550
// ============================================================================

/**
 * Jumper Tank cosmetic timer
 * Attaches tire props to the tank's feet for visual effect
 *
 * @param timer    Timer handle
 * @param client   Jumper Tank client index
 * @return         Plugin_Continue if tank is valid, Plugin_Stop otherwise
 */
public Action:JumperTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 2002550)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		new ent[3];
		for (new count=1; count<=2; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
				DispatchKeyValueVector(ent[count], "origin", Origin);
				DispatchKeyValueVector(ent[count], "angles", Angles);
				DispatchSpawn(ent[count]);
				AcceptEntityInput(ent[count], "DisableCollision");
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);

				SetVariantString("!activator");
				AcceptEntityInput(ent[count], "SetParent", client);
				switch(count)
				{
					case 1:SetVariantString("rfoot");
					case 2:SetVariantString("lfoot");
				}
				AcceptEntityInput(ent[count], "SetParentAttachment");

				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
