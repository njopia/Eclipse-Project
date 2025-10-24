
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === CENTRALIZED COOLDOWN CONFIGURATION ===
//==================================================

// --- Long Actions Cooldowns ---
#define CONFIG_SURV_SPEEDBOOST_DURATION 30.0		// Duración del speed boost de sobreviviente (segundos)

// --- Deployables Cooldowns ---
#define CONFIG_AMMO_PILE_COOLDOWN		180.0	// Cooldown para usar Ammo Pile (segundos)
#define CONFIG_AMMO_PILE_LIFETIME		30.0	// Tiempo de vida de la entidad Ammo Pile (segundos)
#define CONFIG_UVLIGHT_DURATION			300		// Duración de la UV Light (segundos)
#define CONFIG_HEALINGSTATION_DURATION	300		// Duración de la Healing Station (segundos)
#define CONFIG_IONCANNON_BUY_COOLDOWN	5.0		// Cooldown de compra para Ion Cannon (segundos)

// --- Team Bonuses Cooldowns ---
#define CONFIG_TEAM_HEAL_COOLDOWN			60.0	// Cooldown entre activaciones de Team Heal (segundos)
#define CONFIG_TEAM_HEAL_TICK_INTERVAL		0.25	// Intervalo entre ticks de sanación (segundos)
#define CONFIG_TEAM_HEAL_PER_TICK			5		// HP curados por tick

#define CONFIG_TEAM_SPEEDBOOST_COOLDOWN		60.0	// Cooldown entre activaciones de Team Speed Boost (segundos)
#define CONFIG_TEAM_SPEEDBOOST_DURATION		300.0	// Duración del efecto Team Speed Boost (segundos)
#define CONFIG_TEAM_SPEEDBOOST_AMOUNT		1.40	// Multiplicador de velocidad (1.0 = normal, 1.40 = 40% más)
#define CONFIG_TEAM_SPEEDBOOST_TICK_INTERVAL 0.1	// Intervalo para mantener el boost (segundos)

//==================================================

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
//////////////////////////////////////////////
////// TEAM BONUSES ///////////////////////////
#tryinclude "features/04-team-bonuses/team-speed-boost.feature.sp"
#tryinclude "features/04-team-bonuses/team-heal.feature.sp"
//////////////////////////////////////////////
#tryinclude "features/0-menu/buy-menu.feature.sp"
//////////////////////////////////////////////
///// COST VERIFICATION WRAPPERS (L4D STATS INTEGRATION)
#tryinclude "features/buy-cost-wrapper.inc"
//////////////////////////////////////////////

static bool	  bMenuOn			   = false;
static Handle hMenuOn			   = INVALID_HANDLE;

// ================== CURRENCY SYSTEM (L4D STATS INTEGRATION) ==================
static int g_iPlayerCurrency[MAXPLAYERS + 1];			// Player currency for buying items

// Buy Cost ConVars
static Handle cvar_CostConvertHP = INVALID_HANDLE;
static Handle cvar_CostFireYell = INVALID_HANDLE;
static Handle cvar_CostPowerYell = INVALID_HANDLE;
static Handle cvar_CostLeap = INVALID_HANDLE;
static Handle cvar_CostSurvSpeed = INVALID_HANDLE;
static Handle cvar_CostAmmo = INVALID_HANDLE;
static Handle cvar_CostUVLight = INVALID_HANDLE;
static Handle cvar_CostHealingStation = INVALID_HANDLE;
static Handle cvar_CostIonCannon = INVALID_HANDLE;
static Handle cvar_CostTeamHeal = INVALID_HANDLE;
static Handle cvar_CostTeamSpeedBoost = INVALID_HANDLE;
// ==============================================================================

const int	  TIME_UV_LIGHT		   = 300;
const int	  TIME_HEALING_STATION = 300;

#if !defined  EMS_MAIN_FILE
	 #error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public void buyMenuOnPluginStart()
{
	hMenuOn = CreateConVar("menu_on", "1", "Level menu on or off?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bMenuOn = GetConVarBool(hMenuOn);

	// ============ INITIALIZE BUY COSTS ============
	// These costs are in points from l4d_stats
	cvar_CostConvertHP = CreateConVar("buy_cost_convert_hp", "25", "Cost in points to buy Convert HP", FCVAR_PLUGIN);
	cvar_CostFireYell = CreateConVar("buy_cost_fire_yell", "20", "Cost in points to buy Fire Yell", FCVAR_PLUGIN);
	cvar_CostPowerYell = CreateConVar("buy_cost_power_yell", "30", "Cost in points to buy Power Yell", FCVAR_PLUGIN);
	cvar_CostLeap = CreateConVar("buy_cost_leap", "35", "Cost in points to buy Leap of Desperation", FCVAR_PLUGIN);
	cvar_CostSurvSpeed = CreateConVar("buy_cost_surv_speed", "40", "Cost in points to buy Survivor Speed Boost", FCVAR_PLUGIN);
	cvar_CostAmmo = CreateConVar("buy_cost_ammo", "30", "Cost in points to buy Ammo Pile", FCVAR_PLUGIN);
	cvar_CostUVLight = CreateConVar("buy_cost_uv_light", "45", "Cost in points to buy UV Light", FCVAR_PLUGIN);
	cvar_CostHealingStation = CreateConVar("buy_cost_healing_station", "50", "Cost in points to buy Healing Station", FCVAR_PLUGIN);
	cvar_CostIonCannon = CreateConVar("buy_cost_ion_cannon", "75", "Cost in points to buy Ion Cannon", FCVAR_PLUGIN);
	cvar_CostTeamHeal = CreateConVar("buy_cost_team_heal", "55", "Cost in points to buy Team Heal", FCVAR_PLUGIN);
	cvar_CostTeamSpeedBoost = CreateConVar("buy_cost_team_speed_boost", "60", "Cost in points to buy Team Speed Boost", FCVAR_PLUGIN);
	// ============================================

	// Initialize player currency
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerCurrency[i] = 0;
	}

	CreateTimer(1.0, TimerUpdate1, _, TIMER_REPEAT);

}

public void OnClientDisconnect(int client)
{
	g_fNextHint[client]		= 0.0;
	g_bHadMaxHealth[client] = false;
	g_iPlayerCurrency[client] = 0;  // Reset currency on disconnect
	IonCannon_OnClientDisconnect(client);
	TeamHeal_OnClientDisconnect(client);
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

// ==================== CURRENCY SYSTEM HELPER FUNCTIONS ====================
/**
 * Check if player can afford a purchase
 */
stock bool CanAffordPurchase(int client, int cost)
{
	if (client <= 0 || !IsClientInGame(client))
		return false;

	return g_iPlayerCurrency[client] >= cost;
}

/**
 * Attempt to purchase an item
 * Returns true if purchase was successful, false otherwise
 */
stock bool PurchaseItem(int client, int cost, const char[] itemName)
{
	if (!CanAffordPurchase(client, cost))
	{
		PrintToChat(client, "[Buy] Necesitas %d puntos, tienes %d", cost, g_iPlayerCurrency[client]);
		return false;
	}

	// Deduct currency
	g_iPlayerCurrency[client] -= cost;
	PrintToChat(client, "[Buy] \x04¡Compraste %s!\x01 Puntos restantes: %d", itemName, g_iPlayerCurrency[client]);
	return true;
}

/**
 * Award currency to player (from l4d_stats points)
 */
stock void AwardCurrency(int client, int amount, const char[] reason = "")
{
	if (client <= 0 || !IsClientInGame(client))
		return;

	g_iPlayerCurrency[client] += amount;

	if (strlen(reason) > 0)
		PrintToChat(client, "[Ranking] Ganaste %d puntos (%s). Balance: %d", amount, reason, g_iPlayerCurrency[client]);
	else
		PrintToChat(client, "[Ranking] Ganaste %d puntos. Balance: %d", amount, g_iPlayerCurrency[client]);
}

/**
 * Get player's current currency balance
 */
stock int GetPlayerCurrency(int client)
{
	if (client <= 0 || !IsClientInGame(client))
		return 0;

	return g_iPlayerCurrency[client];
}

/**
 * Set player's currency directly (for admin commands, etc.)
 */
stock void SetPlayerCurrency(int client, int amount)
{
	if (client <= 0 || !IsClientInGame(client))
		return;

	g_iPlayerCurrency[client] = amount;
	PrintToChat(client, "[Admin] Tu balance se estableció en %d puntos", amount);
}
// ============================================================================