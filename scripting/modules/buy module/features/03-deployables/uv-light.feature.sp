///////////////////////////
// DEPLOYABLES: UV Light //
///////////////////////////

int UVLightModel[33];
int UVLightGlow[33];
int UVLightTimer[33];

stock void SpawnUVLight(int client)
{
	float Origin[3];
	float Angles[3];
	float Direction[3];
	GetClientAbsOrigin(client, Origin);
	GetClientEyeAngles(client, Angles);
	GetAngleVectors(Angles, Direction, NULL_VECTOR, NULL_VECTOR);
	Origin[0] += Direction[0] * 32;
	Origin[1] += Direction[1] * 32;
	Origin[2] += Direction[2] * 1;
	Angles[0] = 0.0;
	Angles[2] = 0.0;

	int item  = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(item))
	{
		DispatchKeyValue(item, "model", "models/props_lighting/light_battery_rigged_01.mdl");
		DispatchKeyValue(item, "solid", "6");
		TeleportEntity(item, Origin, Angles, NULL_VECTOR);
		EMS_BeaconPulse_UV(item);
		DispatchSpawn(item);
		AcceptEntityInput(item, "DisableCollision");
		int glowcolor = RGB_TO_INT(255, 255, 255);
		SetEntProp(item, Prop_Send, "m_glowColorOverride", glowcolor);
		SetEntProp(item, Prop_Send, "m_iGlowType", 2);
		UVLightModel[client] = item;
	}
	int light = CreateEntityByName("beam_spotlight");
	if (light > 0)
	{
		GetAngleVectors(Angles, Direction, NULL_VECTOR, NULL_VECTOR);
		Origin[0] += Direction[0] * 6;
		Origin[1] += Direction[1] * 6;
		Angles[0] = -90.0;
		Angles[1] = 90.0;
		TeleportEntity(light, Origin, Angles, NULL_VECTOR);
		DispatchKeyValue(light, "spotlightwidth", "102");
		DispatchKeyValue(light, "spotlightlength", "120");
		DispatchKeyValue(light, "spawnflags", "3");
		DispatchKeyValue(light, "rendercolor", "160 145 255");
		DispatchKeyValue(light, "renderamt", "150");
		DispatchKeyValue(light, "maxspeed", "100");
		DispatchKeyValue(light, "HDRColorScale", "0.7");
		DispatchKeyValue(light, "fadescale", "1");
		DispatchKeyValue(light, "fademindist", "-1");
		DispatchSpawn(light);
		UVLightGlow[client] = light;
	}
	if (UVLightTimer[client] <= 0)
	{
		if (UVLightModel[client] > 0 && UVLightGlow[client] > 0)
		{
			UVLightTimer[client] = CONFIG_UVLIGHT_DURATION - 1;
		}
		else if (UVLightModel[client] > 0)
		{
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(item, "AddOutput");
			AcceptEntityInput(item, "FireUser1");
			UVLightModel[client] = 0;
		}
		else if (UVLightGlow[client] > 0)
		{
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(light, "AddOutput");
			AcceptEntityInput(light, "FireUser1");
			UVLightGlow[client] = 0;
		}
	}
}

stock void UpdateUVLight(int client)
{
	int item	= UVLightModel[client];
	int light	= UVLightGlow[client];
	int timer	= UVLightTimer[client];
	int lighton = -1;
	if (light > 0 && IsValidEntity(light))
	{
		char classname[16];
		GetEdictClassname(light, classname, sizeof(classname));
		if (StrEqual(classname, "beam_spotlight", false))
		{
			lighton = GetEntProp(light, Prop_Send, "m_bSpotlightOn");
			if (lighton == 1 && timer <= 250)
				AcceptEntityInput(light, "LightOff");
			else if (timer <= 250)
				AcceptEntityInput(light, "LightOn");
		}
	}
	if (item > 0 && IsValidEntity(item))
	{
		char classname[16];
		GetEdictClassname(item, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[50];
			GetEntPropString(item, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_lighting/light_battery_rigged_01.mdl", false))
			{
				if (timer <= 250)
				{
					SetEntProp(item, Prop_Send, "m_bFlashing", 1);
				}
				if (lighton == 1)
				{
					float Origin[3];
					GetEntPropVector(item, Prop_Send, "m_vecOrigin", Origin);
					int entity = -1;
					while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
					{
						float jOrigin[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", jOrigin);
						float distance = GetVectorDistance(Origin, jOrigin, false);
						if (distance <= 400)
						{
							int ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
							if (ragdoll == 0)
							{
								DealDamageEntity(entity, client, 10, 600, "uv_light");
							}
						}
					}
				}
			}
		}
	}
	UVLightTimer[client] -= 1;
}
stock void DestroyUVLight(int client)
{
	int item  = UVLightModel[client];
	int light = UVLightGlow[client];
	if (item > 0 && IsValidEntity(item))
	{
		char classname[16];
		GetEdictClassname(item, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[50];
			GetEntPropString(item, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_lighting/light_battery_rigged_01.mdl", false))
			{
				SetVariantString("OnUser1 !self:Kill::0.1:-1");
				AcceptEntityInput(item, "AddOutput");
				AcceptEntityInput(item, "FireUser1");
				UVLightModel[client] = 0;
			}
		}
	}
	if (light > 0 && IsValidEntity(light))
	{
		char classname[16];
		GetEdictClassname(light, classname, sizeof(classname));
		if (StrEqual(classname, "beam_spotlight", false))
		{
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(light, "AddOutput");
			AcceptEntityInput(light, "FireUser1");
			UVLightGlow[client] = 0;
		}
	}
	UVLightTimer[client] -= 1;
}
