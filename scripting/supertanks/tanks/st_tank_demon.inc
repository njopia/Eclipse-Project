#if defined _st_tank_demon_included
 #endinput
#endif
#define _st_tank_demon_included

// ============================================================================
// DEMON TANK MODULE
// Demon Tank special health and particle effects
// Color: RGB(255, 150, 100) = 255150100
// ============================================================================

/**
 * Set Demon Tank health to special value
 * Sets health to 60666 (666 reference)
 *
 * @param client    Demon Tank client index
 * @noreturn
 */
stock SetDemonTankHealth(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255150100)
	{
		SetEntProp(client, Prop_Send, "m_iMaxHealth", 60666);
		SetEntProp(client, Prop_Send, "m_iHealth", 60666);
	}
}

/**
 * Demon Tank cosmetic timer
 * Attaches fire particles and sets special model
 *
 * @param timer    Timer handle
 * @param client   Demon Tank client index
 * @return         Plugin_Continue if tank is valid, Plugin_Stop otherwise
 */
public Action:DemonTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255150100)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		Angles[0] += -90.0;
		SetEntityModel(client, MODEL_TANK_DLC3);

   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
			DispatchKeyValueVector(particle, "origin", Origin);
			DispatchKeyValue(particle, "effect_name", PARTICLE_FIRE);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client);
			AcceptEntityInput(particle, "start");
		}

		new Float:RandAngles[3];
		for (new count=1; count<=4; count++)
		{
			new ent = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent))
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchKeyValueVector(ent, "origin", Origin);
				DispatchKeyValueVector(ent, "angles", Angles);
				DispatchSpawn(ent);
				AcceptEntityInput(ent, "DisableCollision");
				SetEntProp(ent, Prop_Send, "m_hOwnerEntity", client);

				SetVariantString("!activator");
				AcceptEntityInput(ent, "SetParent", client);
				switch(count)
				{
					case 1:SetVariantString("relbow");
					case 2:SetVariantString("lelbow");
					case 3:SetVariantString("rshoulder");
					case 4:SetVariantString("lshoulder");
				}
				AcceptEntityInput(ent, "SetParentAttachment");
				switch(count)
				{
					case 1,2:SetEntPropFloat(ent, Prop_Data, "m_flModelScale", 0.4);
					case 3,4:SetEntPropFloat(ent, Prop_Data, "m_flModelScale", 0.5);
				}
				RandAngles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
				RandAngles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
				RandAngles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
				TeleportEntity(ent, NULL_VECTOR, RandAngles, NULL_VECTOR);
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
