// Deployable Arrays
static UVLightModel[33];
static UVLightGlow[33];
static bool	  bMenuOn = false;
static Handle hMenuOn = INVALID_HANDLE;
// Timer Arrays
static UVLightTimer[33];
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public void buyMenuOnPluginStart()
{
	hMenuOn = CreateConVar("menu_on", "1", "Level menu on or off?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bMenuOn = GetConVarBool(hMenuOn);
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToChatAll("Displaying menu");
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, CHOICE3))
			{
				PrintToChatAll("Client %d somehow selected %s despite it being disabled", param1, info);
			}
			else
			{
				PrintToChatAll("Clientes %d selected %s", param1, info);
				if (StrEqual(info, CHOICE2))
				{
					SpawnUVLight(param1);
					PrintToChat(param1, "\x04[Deployables]\x01 Deploying UV Light");
					UpdateUVLight(param1);
				}
			}
		}

		case MenuAction_Cancel:
		{
			PrintToChatAll("Client %d's menu was cancelled for reason %d", param1, param2);
		}

		case MenuAction_End:
		{
			delete menu;
		}

		case MenuAction_DrawItem:
		{
			int	 style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);

			if (StrEqual(info, CHOICE3))
			{
				return ITEMDRAW_DISABLED;
			}
			else
			{
				return style;
			}
		}
	}

	return 0;
}

public Action Cmd_Buy(int client, int args)
{
	char text[40];
	char title[40];
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Menu Title", client);
	menu.SetTitle(title, LANG_SERVER);
	Format(text, sizeof(text), "%T", "Choice 1", client);
	menu.AddItem(CHOICE1, text);
	Format(text, sizeof(text), "%T", "Choice 2", client);
	menu.AddItem(CHOICE2, text);
	Format(text, sizeof(text), "%T", "Choice 3", client);
	menu.AddItem(CHOICE3, text);
	menu.ExitButton = true;
	menu.Display(client, 20);

	return Plugin_Handled;
}

/////////////////
// DEPLOYABLES //
/////////////////
stock SpawnUVLight(client)
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

	new item  = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(item))
	{
		DispatchKeyValue(item, "model", "models/props_lighting/light_battery_rigged_01.mdl");
		DispatchKeyValue(item, "solid", "6");
		TeleportEntity(item, Origin, Angles, NULL_VECTOR);
		DispatchSpawn(item);
		AcceptEntityInput(item, "DisableCollision");
		new glowcolor = RGB_TO_INT(255, 255, 255);
		SetEntProp(item, Prop_Send, "m_glowColorOverride", glowcolor);
		SetEntProp(item, Prop_Send, "m_iGlowType", 2);
		UVLightModel[client] = item;
	}
	new light = CreateEntityByName("beam_spotlight");
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
			UVLightTimer[client] = 300;
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
stock TimerUpdateClients()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		UpdateTimers(i);
	}
}
stock UpdateTimers(client)
{
	if (IsSurvivor(client) || IsSpectator(client))
	{
		new maxdeployables = 1;

		new deployabletimer[7 + 1];
		deployabletimer[1] = UVLightTimer[client];
		new deployabletime[7 + 1];
		deployabletime[1] = 240;
		for (new deployables = 1; deployables <= maxdeployables; deployables++)
		{
			if (deployabletimer[deployables] > 0)
			{
				if (deployabletimer[deployables] > deployabletime[deployables] || deployabletimer[deployables] < deployabletime[deployables])
				{
					UpdateDeployable(client, deployables);
				}
				else if (deployabletimer[deployables] == deployabletime[deployables])
				{
					DestroyDeployable(client, deployables);
				}
			}
		}
	}
}
stock UpdateDeployable(client, deployable)
{
	switch (deployable)
	{
		case 1: UpdateUVLight(client);
	}
}
stock UpdateUVLight(client)
{
	PrintToChatAll("Updating UV Light");
	new item	= UVLightModel[client];
	new light	= UVLightGlow[client];
	new timer	= UVLightTimer[client];
	new lighton = -1;
	if (light > 0 && IsValidEntity(light))
	{
		PrintToChatAll("Updating UV Light2");
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
		PrintToChatAll("Updating UV Light3");
		char classname[16];
		GetEdictClassname(item, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			PrintToChatAll("Updating UV Light4");
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
					PrintToChatAll("Updating UV Light5");
					float Origin[3];
					GetEntPropVector(item, Prop_Send, "m_vecOrigin", Origin);
					new entity = -1;
					while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
					{
						PrintToChatAll("Updating UV Light6");
						float jOrigin[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", jOrigin);
						float distance = GetVectorDistance(Origin, jOrigin);
						if (distance <= 400)
						{
							PrintToChatAll("Updating UV Light7");
							new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
							if (ragdoll == 0)
							{
								PrintToChatAll("Updating UV Light8");
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
stock DestroyUVLight(client)
{
	new item  = UVLightModel[client];
	new light = UVLightGlow[client];
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

stock RGB_TO_INT(red, green, blue)
{
	return (blue * 65536) + (green * 256) + red;
}
stock DealDamageEntity(target, attacker, dmgtype, dmg, char inflictor[255])
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
			PrintToChatAll("Dealing damage to 2");
			char damage[16];
			char type[16];
			IntToString(dmg, damage, sizeof(damage));
			IntToString(dmgtype, type, sizeof(type));
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				if (IsInfected(target) || IsWitch(target))
				{
					new ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
					if (ragdoll == 0)
					{
						PrintToChatAll("Dealing damage to 3");
						DispatchKeyValue(target, "targetname", "hurtme");
						DispatchKeyValue(pointHurt, "Damage", damage);
						DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
						DispatchKeyValue(pointHurt, "DamageType", type);
						DispatchKeyValue(pointHurt, "classname", inflictor);
						DispatchSpawn(pointHurt);
						if (IsClientInGame(attacker))
						{
							AcceptEntityInput(pointHurt, "Hurt", attacker);
						}
						DispatchKeyValue(target, "targetname", "donthurtme");
					}
				}
				PrintToChatAll("Dealing damage to4");
				AcceptEntityInput(pointHurt, "Kill");
			}
		}
	}
}
stock bool IsInfected(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			return true;
		}
	}
	return false;
}
stock bool IsWitch(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool IsSpectator(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}

public Action Timer(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}

	if (bMenuOn)
	{
		TimerUpdateClients();
	}

	return Plugin_Continue;
}

stock DestroyDeployable(client, deployable)
{
	switch (deployable)
	{
		case 1: DestroyUVLight(client);
	}
}
