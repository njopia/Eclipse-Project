//////////////////////////////////
// DEPLOYABLES: Healing Station //
//////////////////////////////////

int	  HSTrigger[33];
int	  HSModel[33];
int	  HSTimer[33];

// --- Globals anti-spam para Healing station ---
float g_fNextHint[MAXPLAYERS + 1];		 // proximo momento permitido para mostrar hint
bool  g_bHadMaxHealth[MAXPLAYERS + 1];	 // record de si ya estuvo a vida maxima

// --- Define local para anti-spam (basado en CONFIG_HEALINGSTATION_DURATION) ---
#define COOLDOWN_TIME 2.0

stock void SpawnHealingStation(int client)
{
	float Origin[3];
	float Angles[3];
	float Direction[3];
	float minbounds[3];
	float maxbounds[3];

	GetClientAbsOrigin(client, Origin);
	GetClientEyeAngles(client, Angles);
	GetAngleVectors(Angles, Direction, NULL_VECTOR, NULL_VECTOR);
	Origin[0] += Direction[0] * 32;
	Origin[1] += Direction[1] * 32;
	Origin[2] += Direction[2] * 1;
	Angles[0] = 0.0;
	Angles[2] = 0.0;

	int item = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(item))
	{
		DispatchKeyValue(item, "model", "models/props_unique/hospital/iv_pole.mdl");
		DispatchKeyValue(item, "solid", "6");
		TeleportEntity(item, Origin, Angles, NULL_VECTOR);
		EMS_BeaconPulse_Healing(item);
		DispatchSpawn(item);
		AcceptEntityInput(item, "DisableCollision");
		HSModel[client] = item;
		GetEntPropVector(item, Prop_Send, "m_vecMins", minbounds);
		GetEntPropVector(item, Prop_Send, "m_vecMaxs", maxbounds);
		int glowcolor = RGB_TO_INT(29, 185, 2);
		SetEntProp(item, Prop_Send, "m_glowColorOverride", glowcolor);
		SetEntProp(item, Prop_Send, "m_iGlowType", 2);
	}
	int item2 = CreateEntityByName("func_button_timed");
	if (IsValidEntity(item2))
	{
		DispatchKeyValue(item2, "model", "models/props_unique/hospital/iv_pole.mdl");
		DispatchKeyValue(item2, "solid", "2");
		DispatchKeyValue(item2, "use_string", "Curandose como un campeon");
		DispatchKeyValue(item2, "use_time", "2");
		DispatchKeyValue(item2, "auto_disable", "0");
		DispatchSpawn(item2);
		ActivateEntity(item2);
		TeleportEntity(item2, Origin, Angles, NULL_VECTOR);
		HSTrigger[client] = item2;
		SetEntPropVector(item2, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(item2, Prop_Send, "m_vecMaxs", maxbounds);
		int enteffects = GetEntProp(item2, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(item2, Prop_Send, "m_fEffects", enteffects);
		SDKHook(item2, SDKHook_Use, HSOnPressed);
		SDKHook(item2, SDKHook_Think, HSOnThink);
		HookSingleEntityOutput(item2, "OnTimeUp", HSOnTimeUp, false);
	}
	if (HSTimer[client] <= 0)
	{
		if (HSModel[client] > 0 && HSTrigger[client] > 0)
		{
			HSTimer[client] = CONFIG_HEALINGSTATION_DURATION;
		}
		else if (HSModel[client] > 0)
		{
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(item, "AddOutput");
			AcceptEntityInput(item, "FireUser1");
			HSModel[client] = 0;
		}
		else if (HSTrigger[client] > 0)
		{
			SetVariantString("OnUser1 !self:Kill::0.1:-1");
			AcceptEntityInput(item2, "AddOutput");
			AcceptEntityInput(item2, "FireUser1");
			HSTrigger[client] = 0;
		}
	}
}

public Action HSOnPressed(int entity, int activator, int caller, UseType type, float value)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (HSTrigger[i] == entity)
		{
			if (HSTimer[i] <= 0)
			{
				return Plugin_Handled;
			}
		}
	}

	if (IsClientInGame(activator) && GetClientTeam(activator) == 2)
	{
		int	  maxhealth = GetEntProp(activator, Prop_Data, "m_iMaxHealth");
		int	  health	= GetEntProp(activator, Prop_Data, "m_iHealth");
		bool  bHasMax	= (health >= maxhealth);
		float now		= GetGameTime();

		if (bHasMax)
		{
			if (!g_bHadMaxHealth[activator])
			{
				if (now >= g_fNextHint[activator])
				{
					PrintToChat(activator, "Tienes salud maxima papi: %i / %i", health, maxhealth);
					g_fNextHint[activator] = now + COOLDOWN_TIME;
				}
				g_bHadMaxHealth[activator] = true;
			}
			return Plugin_Handled;
		}

		g_bHadMaxHealth[activator] = false;

		if (now >= g_fNextHint[activator])
		{
			PrintToChat(activator, "Salud actual: %i - Salud maxima: %i", health, maxhealth);
			g_fNextHint[activator] = now + COOLDOWN_TIME;
		}

		EMS_BeaconPulse_Healing(entity);
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action HSOnThink(int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		char classname[18];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "func_button_timed", false))
		{
			int client = GetEntPropEnt(entity, Prop_Data, "m_hActivator");
			if (client > 0)
			{
				if (IsClientInGame(client) && GetClientTeam(client) == 2)
				{
					float Origin[3];
					float TOrigin[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
					float distance = GetVectorDistance(Origin, TOrigin, false);
					if (distance < 125.0)
					{
						EMS_BeaconPulse_Healing(entity);
						return Plugin_Continue;
					}
				}
				AcceptEntityInput(entity, "Disable");
				SetVariantString("OnUser1 !self:Enable::0.1:-1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");
			}
		}
	}
	return Plugin_Handled;
}
stock void DestroyHealingStation(int client)
{
	int item  = HSModel[client];
	int item2 = HSTrigger[client];
	if (item > 0 && IsValidEntity(item))
	{
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(item, "AddOutput");
		AcceptEntityInput(item, "FireUser1");
		HSModel[client] = 0;
	}
	if (item2 > 0 && IsValidEntity(item2))
	{
		CreateTimer(0.1, RemoveHS, item2, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.1, ResetHealingStation, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	HSTimer[client] -= 1;
}

public HSOnTimeUp(const char[] name, int caller, int activator, float delay)
{
	if (IsClientInGame(activator) && GetClientTeam(activator) == 2)
	{
		CheatCommand(activator, "give", "health");
		L4D2_UseAdrenaline(activator, 20.0);
	}
}

public void RemoveHS(Handle timer, int entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Disable");
		AcceptEntityInput(entity, "Kill");
	}
}

public void ResetHealingStation(Handle timer, int client)
{
	HSTrigger[client] = 0;
}

stock void UpdateHealingStation(int client)
{
	int item  = HSModel[client];
	int timer = HSTimer[client];

	if (item > 0)
	{
		bool valid = IsValidEntity(item);
		if (valid)
		{
			char classname[32];
			GetEdictClassname(item, classname, sizeof(classname));
			if (!StrEqual(classname, "prop_dynamic", false))
				valid = false;
		}

		if (!valid)
		{
			// Entidad reciclada o destruida (e.g. cambio de mapa) — limpiar estado
			HSModel[client]   = 0;
			HSTrigger[client] = 0;
			HSTimer[client]   = 0;
			return;
		}

		if (timer <= 250)
			SetEntProp(item, Prop_Send, "m_bFlashing", 1);
	}

	HSTimer[client] -= 1;
}