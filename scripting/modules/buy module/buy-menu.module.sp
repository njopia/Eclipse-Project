
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
/////// HELPERS /////////////////////////////
#tryinclude "helpers/beacons.helpers.sp"
//////////////////////////////////////////////

////// FEATURES /////////////////////////////
#tryinclude "features/01-instants/convert-hp.feature.sp"
#tryinclude "features/01-instants/fire-yell.feature.sp"
#tryinclude "features/01-instants/power-yell.feature.sp"
#tryinclude "features/01-instants/leap-of-desesperation.feature.sp"
//////////////////////////////////////////////
#tryinclude "features/02-long-actions/surv-speed.feature.sp"
//////////////////////////////////////////////
////// DEPLOYABLES ///////////////////////////
#tryinclude "features/03-deployables/ammo.feature.sp"
#tryinclude "features/03-deployables/uv-light.feature.sp"
#tryinclude "features/03-deployables/healing-station.feature.sp"
#tryinclude "features/03-deployables/ion-cannon.feature.sp"
#tryinclude "features/0-menu/buy-menu.feature.sp"
//////////////////////////////////////////////

static bool	  bMenuOn			   = false;
static Handle hMenuOn			   = INVALID_HANDLE;

const int	  TIME_UV_LIGHT		   = 300;
const int	  TIME_HEALING_STATION = 300;

#if !defined  EMS_MAIN_FILE
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
	IonCannon_OnClientDisconnect(client);
}

public void DelegateBuyMenuModule()
{
	g_iBeaconBeamModel = PrecacheModel("materials/sprites/laserbeam.vmt", true);

	for (int i = 1; i <= MaxClients; i++)
	{
		g_fNextHint[i]	   = 0.0;
		g_bHadMaxHealth[i] = false;
	}
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
		case 1:
		{
			DestroyUVLight(client);
			return;
		}
		case 2:
		{
			DestroyHealingStation(client);
			return;
		}
	}
}
stock void UpdateDeployable(int client, int deployable)
{
	switch (deployable)
	{
		case 1:
		{
			UpdateUVLight(client);
			return;
		}
		case 2:
		{
			UpdateHealingStation(client);
			return;
		}
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
		// --- UV Light Timer ---
		// Si el timer está corriendo, actualiza el estado.
		if (UVLightTimer[client] > 0)
		{
			UpdateUVLight(client);	  // Esta función ya resta 1 al timer.
		}
		// Si el timer llega a cero, destrúyelo.
		else if (UVLightTimer[client] == 0)
		{
			DestroyUVLight(client);	   // Esta función pone el timer en -1 para marcarlo como destruido.
		}

		// --- Healing Station Timer ---
		if (HSTimer[client] > 0)
		{
			UpdateHealingStation(client);
		}
		else if (HSTimer[client] == 0)
		{
			DestroyHealingStation(client);
		}
	}
}