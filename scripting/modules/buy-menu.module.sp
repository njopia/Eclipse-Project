Menu g_MainMenu;
Menu g_DeployablesMenu;

#define BM_CHOICE_0_1 "BM_Instant"
#define BM_CHOICE_0_2 "BM_LongAction"
#define BM_CHOICE_0_3 "BM_Deployables"
#define BM_CHOICE_0_4 "BM_TeamBonuses"

#define BM_CHOICE_1_1 "BM_UVL"
#define BM_CHOICE_1_2 "BM_HS"
// Deployable Arrays
static int	  UVLightModel[33];
static int	  UVLightGlow[33];
static bool	  bMenuOn = false;
static Handle hMenuOn = INVALID_HANDLE;

// Healing Station
static int	  HSTrigger[33];
static int	  HSModel[33];
static int	  HSTimer[33];
#define COOLDOWN_TIME 2.0
// --- Globals anti-spam para Healing station ---
float		 g_fNextHint[MAXPLAYERS + 1];		 // próximo momento permitido para mostrar hint
bool		 g_bHadMaxHealth[MAXPLAYERS + 1];	 // record de si ya estuvo a vida máxima

const int	 TIME_UV_LIGHT		  = 300;
const int	 TIME_HEALING_STATION = 300;
// Timer Arrays
static int	 UVLightTimer[33];
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public void buyMenuOnPluginStart()
{
	hMenuOn = CreateConVar("menu_on", "1", "Level menu on or off?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bMenuOn = GetConVarBool(hMenuOn);

	CreateTimer(1.0, TimerUpdate1, _, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	g_fNextHint[client]		= 0.0;
	g_bHadMaxHealth[client] = false;
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fNextHint[i]	   = 0.0;
		g_bHadMaxHealth[i] = false;
	}
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
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

			if (StrEqual(info, BM_CHOICE_0_1))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Instants");
			}
			if (StrEqual(info, BM_CHOICE_0_2))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Long Action");
			}
			if (StrEqual(info, BM_CHOICE_0_3))
			{
				PrintToChat(client, "\x05[Eclipse]\x01  Deployables Menu");
				g_DeployablesMenu.Display(client, 20);
			}
			if (StrEqual(info, BM_CHOICE_0_4))
			{
				PrintToChat(client, "\x05[Eclipse]\x01 Team Bonuses");
			}
		}

		case MenuAction_Cancel:
		{
			PrintToChatAll("Client %d's menu was cancelled for reason %d", client, param2);
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}
// Function to Create Submenu
void CreateSubMenu(int client)
{
	char text[40];
	char title[40];

	// Create Submenu
	g_DeployablesMenu = new Menu(MenuHandler_Deployables, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Submenu Title", client);
	g_DeployablesMenu.SetTitle(title);

	// Add Submenu Items
	Format(text, sizeof(text), "%T", "UV Light", client);
	g_DeployablesMenu.AddItem(BM_CHOICE_1_1, text);

	Format(text, sizeof(text), "%T", "Healing Station", client);
	g_DeployablesMenu.AddItem(BM_CHOICE_1_2, text);
	g_DeployablesMenu.ExitBackButton = true;
	g_DeployablesMenu.ExitButton	 = true;
}

public int MenuHandler_Deployables(Menu menu, MenuAction action, int client, int param)
{
	PrintToChatAll("action: %i", action);
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, BM_CHOICE_1_1))
		{
			if (UVLightTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					SpawnUVLight(client);
					UpdateUVLight(client);
					PrintToChat(client, "\x04[Deployables]\x01 Deploying UV Light");
				}
				else
				{
					PrintToChat(client, "\x05[Eclipse]\x01 You must be on the ground to spawn a UV Light.");
				}
			}
			else
			{
				PrintToChat(client, "\x05[Eclipse]\x01 You have to wait %i seconds to use this again.", UVLightTimer[client]);
			}
		}
		else if (StrEqual(info, BM_CHOICE_1_2)) {
			if (HSTimer[client] <= 0)
			{
				int flags = GetEntityFlags(client);
				if (flags & FL_ONGROUND)
				{
					SpawnHealingStation(client);
					PrintToChat(client, "\x04[Deployables]\x01 Deploying Healing Station");
				}
				else
				{
					PrintToChat(client, "\x05[Eclipse]\x01 You must be on the ground to spawn a Healing Station.");
				}
			}
			else
			{
				PrintToChat(client, "\x05[Eclipse]\x01 You have to wait %i seconds to use this again.", HSTimer[client]);
			}
		}
	}
	return 0;
}

public Action Cmd_Buy(int client, int args)
{
	char text[40];
	char title[40];
	g_MainMenu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	Format(title, sizeof(title), "%T", "Menu Title", client);
	g_MainMenu.SetTitle(title, LANG_SERVER);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_1, client);
	g_MainMenu.AddItem(BM_CHOICE_0_1, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_2, client);
	g_MainMenu.AddItem(BM_CHOICE_0_2, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_3, client);
	g_MainMenu.AddItem(BM_CHOICE_0_3, text);
	Format(text, sizeof(text), "%T", BM_CHOICE_0_4, client);
	g_MainMenu.AddItem(BM_CHOICE_0_4, text);
	g_MainMenu.ExitButton = true;
	g_MainMenu.Display(client, 20);
	// Initialize Submenu if it doesn't exist
	if (g_DeployablesMenu == null)
	{
		CreateSubMenu(client);
	}
	return Plugin_Handled;
}

///////////////////////////
// DEPLOYABLES: UV Light //
///////////////////////////

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
			UVLightTimer[client] = TIME_UV_LIGHT - 1;
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

//////////////////////////////////
// DEPLOYABLES: Healing Station //
//////////////////////////////////
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

	int item  = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(item))
	{
		DispatchKeyValue(item, "model", "models/props_unique/hospital/iv_pole.mdl");
		DispatchKeyValue(item, "solid", "6");
		TeleportEntity(item, Origin, Angles, NULL_VECTOR);
		DispatchSpawn(item);
		AcceptEntityInput(item, "DisableCollision");
		HSModel[client] = item;
		GetEntPropVector(item, Prop_Send, "m_vecMins", minbounds);
		GetEntPropVector(item, Prop_Send, "m_vecMaxs", maxbounds);
		// PrintToChat(client, "%f %f %f", minbounds[0], minbounds[1], minbounds[2]);
		// PrintToChat(client, "%f %f %f", maxbounds[0], maxbounds[1], maxbounds[2]);
		int glowcolor = RGB_TO_INT(29, 185, 2);
		SetEntProp(item, Prop_Send, "m_glowColorOverride", glowcolor);
		SetEntProp(item, Prop_Send, "m_iGlowType", 2);
	}
	int item2 = CreateEntityByName("func_button_timed");
	if (IsValidEntity(item2))
	{
		DispatchKeyValue(item2, "model", "models/props_unique/hospital/iv_pole.mdl");
		DispatchKeyValue(item2, "solid", "2");
		DispatchKeyValue(item2, "use_string", "Curandose como un campeón");
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
			HSTimer[client] = TIME_HEALING_STATION;
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
	// Mantengo tu lógica previa
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

		// --- Si está en vida máxima: bloquear acción ---
		if (bHasMax)
		{
			// Solo avisar la PRIMERA vez que alcanza vida máxima
			if (!g_bHadMaxHealth[activator])
			{
				// Además, respeta cooldown por seguridad
				if (now >= g_fNextHint[activator])
				{
					PrintToChat(activator, "Tienes salud máxima papi: %i / %i", health, maxhealth);
					g_fNextHint[activator] = now + COOLDOWN_TIME;
				}
				g_bHadMaxHealth[activator] = true;
			}
			return Plugin_Handled;
		}

		// --- Si NO está en vida máxima: permitir acción y limpiar estado ---
		g_bHadMaxHealth[activator] = false;

		// Si igual quieres informar, que sea con cooldown
		if (now >= g_fNextHint[activator])
		{
			PrintToChat(activator, "Salud actual: %i - Salud máxima: %i", health, maxhealth);
			g_fNextHint[activator] = now + COOLDOWN_TIME;
		}

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
						return Plugin_Continue;
					}
				}
				PrintToChatAll("disabling");
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
		char classname[16];
		GetEdictClassname(item, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[42];
			GetEntPropString(item, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_unique/hospital/iv_pole.mdl", false))
			{
				SetVariantString("OnUser1 !self:Kill::0.1:-1");
				AcceptEntityInput(item, "AddOutput");
				AcceptEntityInput(item, "FireUser1");
				HSModel[client] = 0;
			}
		}
	}
	if (item2 > 0 && IsValidEntity(item2))
	{
		char classname[18];
		GetEdictClassname(item2, classname, sizeof(classname));
		if (StrEqual(classname, "func_button_timed", false))
		{
			CreateTimer(0.1, RemoveHS, item2, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, ResetHealingStation, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	HSTimer[client] -= 1;
}

public HSOnTimeUp(const char[] name, int caller, activator, float delay)
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
		char classname[18];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "func_button_timed", false))
		{
			AcceptEntityInput(entity, "Disable");
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public void ResetHealingStation(Handle timer, int client)
{
	HSTrigger[client] = 0;
}
//////////////////////////////////
stock RGB_TO_INT(red, green, blue)
{
	return (blue * 65536) + (green * 256) + red;
}
stock void DealDamageEntity(int target, int attacker, int dmgtype, int dmg, const char[] inflictor)
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
			char sDamage[16];
			char sDmgType[16];
			IntToString(dmg, sDamage, sizeof(sDamage));
			IntToString(dmgtype, sDmgType, sizeof(sDmgType));
			int pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				if (IsInfected(target) || IsWitch(target))
				{
					int ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
					if (ragdoll == 0)
					{
						DispatchKeyValue(target, "targetname", "hurtme");
						DispatchKeyValue(pointHurt, "Damage", sDamage);
						DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
						DispatchKeyValue(pointHurt, "DamageType", sDmgType);
						DispatchKeyValue(pointHurt, "classname", inflictor);
						DispatchSpawn(pointHurt);
						if (IsClientInGame(attacker))
						{
							AcceptEntityInput(pointHurt, "Hurt", attacker);
						}
						DispatchKeyValue(target, "targetname", "donthurtme");
					}
				}
				AcceptEntityInput(pointHurt, "Kill");
			}
		}
	}
}

public Action TimerUpdate1(Handle timer)
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
stock void DestroyDeployable(int client, int deployable)
{
	switch (deployable)
	{
		case 1: DestroyUVLight(client);
		case 2: DestroyHealingStation(client);
	}
}
stock void UpdateHealingStation(int client)
{
	int item  = HSModel[client];
	int timer = HSTimer[client];
	if (item > 0 && IsValidEntity(item))
	{
		char classname[16];
		GetEdictClassname(item, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			char model[42];
			GetEntPropString(item, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_unique/hospital/iv_pole.mdl", false))
			{
				if (timer <= 250)
				{
					SetEntProp(item, Prop_Send, "m_bFlashing", 1);
				}
			}
		}
	}
	HSTimer[client] -= 1;
}
stock void UpdateDeployable(int client, int deployable)
{
	switch (deployable)
	{
		case 1: UpdateUVLight(client);
		case 2: UpdateHealingStation(client);
	}
}
stock void TimerUpdateClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		UpdateTimers(i);
	}
}
stock void UpdateTimers(int client)
{
	if (IsSurvivor(client) || IsSpectator(client))
	{
		int maxdeployables = 2;

		int deployabletimer[2 + 1];
		deployabletimer[1] = UVLightTimer[client];
		deployabletimer[2] = HSTimer[client];
		new deployabletime[2 + 1];
		deployabletime[1] = TIME_UV_LIGHT;
		deployabletime[2] = TIME_HEALING_STATION;
		for (new deployables = 1; deployables <= maxdeployables; deployables++)
		{
			if (deployabletimer[deployables] >= 0)
			{
				if (deployabletimer[deployables] == 0)
				{
					DestroyDeployable(client, deployables);
				}
				else {
					// PrintToChatAll("deployabletimer: %i deployabletime: %i", deployabletimer[deployables], deployabletime[deployables]);
					UpdateDeployable(client, deployables);
				}
			}
		}
	}
}