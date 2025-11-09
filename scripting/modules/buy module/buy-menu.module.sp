
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

#include <clientprefs>

//==================================================
// === CENTRALIZED COOLDOWN CONFIGURATION ===
//==================================================

// --- Long Actions Cooldowns ---
#define CONFIG_SURV_SPEEDBOOST_DURATION		 30.0	 // Duración del speed boost de sobreviviente (segundos)

// --- Deployables Cooldowns ---
#define CONFIG_AMMO_PILE_COOLDOWN			 180.0	  // Cooldown para usar Ammo Pile (segundos)
#define CONFIG_AMMO_PILE_LIFETIME			 30.0	  // Tiempo de vida de la entidad Ammo Pile (segundos)
#define CONFIG_UVLIGHT_DURATION				 300	  // Duración de la UV Light (segundos)
#define CONFIG_HEALINGSTATION_DURATION		 300	  // Duración de la Healing Station (segundos)
#define CONFIG_IONCANNON_BUY_COOLDOWN		 5.0	  // Cooldown de compra para Ion Cannon (segundos)

// --- Team Bonuses Cooldowns ---
#define CONFIG_TEAM_HEAL_COOLDOWN			 60.0	 // Cooldown entre activaciones de Team Heal (segundos)
#define CONFIG_TEAM_HEAL_TICK_INTERVAL		 0.25	 // Intervalo entre ticks de sanación (segundos)
#define CONFIG_TEAM_HEAL_PER_TICK			 5		 // HP curados por tick

#define CONFIG_TEAM_SPEEDBOOST_COOLDOWN		 60.0	  // Cooldown entre activaciones de Team Speed Boost (segundos)
#define CONFIG_TEAM_SPEEDBOOST_DURATION		 300.0	  // Duración del efecto Team Speed Boost (segundos)
#define CONFIG_TEAM_SPEEDBOOST_AMOUNT		 1.40	  // Multiplicador de velocidad (1.0 = normal, 1.40 = 40% más)
#define CONFIG_TEAM_SPEEDBOOST_TICK_INTERVAL 0.1	  // Intervalo para mantener el boost (segundos)

//==================================================

// ================== CURRENCY SYSTEM ==================
// Currency persiste durante toda la sesión del jugador (se mantiene entre mapas)
// Se mantiene incluso al cambiar de mapa usando cookies de SourceMod
// Se resetea solo al desconectarse completamente del servidor
// NO se guarda en base de datos
int	   g_iPlayerLocalCurrency[MAXPLAYERS + 1];	 // Currency de sesión (se mantiene entre mapas con cookies)
Handle g_hCurrencyCookie = INVALID_HANDLE;			 // Cookie para persistir currency entre cambios de mapa

// Buy Cost ConVars
Handle cvar_CostConvertHP	   = INVALID_HANDLE;
Handle cvar_CostFireYell	   = INVALID_HANDLE;
Handle cvar_CostPowerYell	   = INVALID_HANDLE;
Handle cvar_CostLeap		   = INVALID_HANDLE;
Handle cvar_CostAmmo		   = INVALID_HANDLE;
Handle cvar_CostUVLight		   = INVALID_HANDLE;
Handle cvar_CostHealingStation = INVALID_HANDLE;
Handle cvar_CostIonCannon	   = INVALID_HANDLE;
Handle cvar_CostDefenseGrid	   = INVALID_HANDLE;
Handle cvar_CostTeamHeal	   = INVALID_HANDLE;
Handle cvar_CostTeamSpeedBoost = INVALID_HANDLE;
Handle cvar_CostNuclearStrike  = INVALID_HANDLE;
// ======================================================

/////// HELPERS /////////////////////////////
#tryinclude "helpers/beacons.helpers.sp"
//////////////////////////////////////////////

////// FEATURES /////////////////////////////
#tryinclude "features/01-instants/convert-hp.feature.sp"
#tryinclude "features/01-instants/fire-yell.feature.sp"
#tryinclude "features/01-instants/power-yell.feature.sp"
#tryinclude "features/01-instants/leap-of-desesperation.feature.sp"
//////////////////////////////////////////////
// Long Actions removidas - ahora son Abilities desbloqueables por nivel
//////////////////////////////////////////////
////// DEPLOYABLES ///////////////////////////
#tryinclude "features/03-deployables/ammo.feature.sp"
#tryinclude "features/03-deployables/uv-light.feature.sp"
#tryinclude "features/03-deployables/healing-station.feature.sp"
#tryinclude "features/03-deployables/ion-cannon/ion-cannon.module.sp"
#tryinclude "features/03-deployables/ion-cannon.feature.sp"
#tryinclude "features/03-deployables/defense-grid.feature.sp"
//////////////////////////////////////////////
////// TEAM BONUSES ///////////////////////////
#tryinclude "features/04-team-bonuses/team-speed-boost.feature.sp"
#tryinclude "features/04-team-bonuses/team-heal.feature.sp"
#tryinclude "features/04-team-bonuses/nuclear-strike.feature.sp"
//////////////////////////////////////////////
#tryinclude "features/0-menu/buy-menu.feature.sp"
#tryinclude "features/0-menu/admin-currency.feature.sp"
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
	hMenuOn					= CreateConVar("menu_on", "1", "Level menu on or off?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bMenuOn					= GetConVarBool(hMenuOn);

	// ============ INITIALIZE BUY COSTS ============
	cvar_CostConvertHP		= CreateConVar("buy_cost_convert_hp", "25", "Cost in points to buy Convert HP", FCVAR_PLUGIN);
	cvar_CostFireYell		= CreateConVar("buy_cost_fire_yell", "20", "Cost in points to buy Fire Yell", FCVAR_PLUGIN);
	cvar_CostPowerYell		= CreateConVar("buy_cost_power_yell", "30", "Cost in points to buy Power Yell", FCVAR_PLUGIN);
	cvar_CostLeap			= CreateConVar("buy_cost_leap", "35", "Cost in points to buy Leap of Desperation", FCVAR_PLUGIN);
	cvar_CostAmmo			= CreateConVar("buy_cost_ammo", "30", "Cost in points to buy Ammo Pile", FCVAR_PLUGIN);
	cvar_CostUVLight		= CreateConVar("buy_cost_uv_light", "45", "Cost in points to buy UV Light", FCVAR_PLUGIN);
	cvar_CostHealingStation = CreateConVar("buy_cost_healing_station", "50", "Cost in points to buy Healing Station", FCVAR_PLUGIN);
	cvar_CostIonCannon		= CreateConVar("buy_cost_ion_cannon", "75", "Cost in points to buy Ion Cannon", FCVAR_PLUGIN);
	cvar_CostDefenseGrid	= CreateConVar("buy_cost_defense_grid", "65", "Cost in points to buy Defense Grid", FCVAR_PLUGIN);
	cvar_CostTeamHeal		= CreateConVar("buy_cost_team_heal", "55", "Cost in points to buy Team Heal", FCVAR_PLUGIN);
	cvar_CostTeamSpeedBoost = CreateConVar("buy_cost_team_speed_boost", "60", "Cost in points to buy Team Speed Boost", FCVAR_PLUGIN);
	cvar_CostNuclearStrike	= CreateConVar("buy_cost_nuclear_strike", "100", "Cost in points to buy Nuclear Strike", FCVAR_PLUGIN);
	// ============================================

	// Create cookie to persist currency across map changes
	g_hCurrencyCookie = RegClientCookie("eclipse_session_currency", "Currency points during current session", CookieAccess_Private);

	// Initialize player currency (always temporal)
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerLocalCurrency[i] = 0;
	}

	// Initialize Ion Cannon module
	IonCannon_OnPluginStart();

	// Initialize Active Abilities
	// Removidas - ahora son parte del sistema de Abilities
	// (Berserker, AcidBath, LifeStealer, SpeedFreak, ShoulderCannon)

	// Hook events
	HookEvent("round_start", Event_RoundStart_IonCannon, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_BuyMenu_PlayerDeath, EventHookMode_Post);
	HookEvent("infected_hurt", Event_BuyMenu_InfectedHurt, EventHookMode_Post);
	HookEvent("player_hurt", Event_BuyMenu_PlayerHurt, EventHookMode_Post);

	// Hook para daño
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, Hook_BuyMenu_OnTakeDamage);
		}
	}

	CreateTimer(1.0, TimerUpdate1, _, TIMER_REPEAT);
}

/**
 * Evento de inicio de ronda - Restaurar cargas de Ion Cannon
 */
public void Event_RoundStart_IonCannon(Event event, const char[] name, bool dontBroadcast)
{
	IonCannon_OnRoundStart();
}

public void BuyMenu_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_BuyMenu_OnTakeDamage);

	// Cargar currency desde cookie (persiste entre cambios de mapa)
	if (!IsFakeClient(client) && AreClientCookiesCached(client))
	{
		char sCurrency[32];
		GetClientCookie(client, g_hCurrencyCookie, sCurrency, sizeof(sCurrency));
		if (strlen(sCurrency) > 0)
		{
			g_iPlayerLocalCurrency[client] = StringToInt(sCurrency);
		}
		else
		{
			g_iPlayerLocalCurrency[client] = 0;
		}
	}
	else
	{
		g_iPlayerLocalCurrency[client] = 0;
	}

	// Active Abilities OnClientConnect removidas
	// Ahora son parte del sistema de Abilities
}

public void OnClientDisconnect(int client)
{
	// Guardar currency en cookie ANTES de resetear (persiste entre cambios de mapa)
	if (!IsFakeClient(client))
	{
		char sCurrency[32];
		IntToString(g_iPlayerLocalCurrency[client], sCurrency, sizeof(sCurrency));
		SetClientCookie(client, g_hCurrencyCookie, sCurrency);
	}

	// Guardar datos del jugador antes de resetear
	Leveling_OnClientDisconnect(client);

	g_fNextHint[client]		  = 0.0;
	g_bHadMaxHealth[client]	  = false;
	g_iPlayerLocalCurrency[client] = 0;	  // Reset local variable (pero ya guardado en cookie)
	IonCannon_OnClientDisconnect(client);
	IonCannonFeature_OnClientDisconnect(client);
	DefenseGrid_OnClientDisconnect(client);
	TeamHeal_OnClientDisconnect(client);
	NuclearStrike_OnClientDisconnect(client);
	ResetPlayerCurrencyStats(client);					// Reset currency stats on disconnect
	AdminMoney_OnClientDisconnect(client);				// Reset admin money data on disconnect
	LevelingRewards_OnClientDisconnect(client);			// Reset leveling rewards on disconnect
	Bloodmoon_OnClientDisconnect(client);				// Cleanup bloodmoon hooks
	LevelingUI_OnClientDisconnect(client);				// Cleanup leveling UI flags
	EclipsePointsUnified_OnClientDisconnect(client);	// Reset unified points tracking flags

	// Cleanup active abilities
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_BuyMenu_OnTakeDamage);
	// Active Abilities OnClientDisconnect removidas
	// Ahora son parte del sistema de Abilities
}

public void DelegateBuyMenuModule()
{
	g_iBeaconBeamModel = PrecacheModel("materials/sprites/laserbeam.vmt", true);

	// Initialize Ion Cannon resources
	IonCannon_OnMapStart();

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

		// Update active abilities
		// Removidas - ahora son parte del sistema de Abilities
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

		// --- Defense Grid Timer ---
		if (DefenseGrid_IsActive(client))
		{
			DefenseGrid_Update(client);
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

	// Currency persiste durante la sesión
	return g_iPlayerLocalCurrency[client] >= cost;
}

/**
 * Attempt to purchase an item
 * Returns true if purchase was successful, false otherwise
 *
 * NOTA: Currency persiste durante toda la sesión (se mantiene entre mapas, se pierde al desconectar)
 * Durante eventos especiales (Nightmare), el currency está congelado y no se puede comprar.
 */
stock bool PurchaseItem(int client, int cost, const char[] itemName)
{
	// Si el currency está congelado (evento especial activo), no permitir compras
	if (Leveling_IsCurrencyFrozen())
	{
		char message[128];
		Format(message, sizeof(message), "No puedes comprar durante eventos especiales (Currency congelado).");
		PrintToChat(client, "\x05[Sistema]\x01 %s", message);
		return false;
	}

	if (!CanAffordPurchase(client, cost))
	{
		char message[128];
		Format(message, sizeof(message), "%T", "Buy_InsufficientPoints", client, cost, g_iPlayerLocalCurrency[client]);
		PrintToChat(client, "\x05[Buy]\x01 %s", message);
		return false;
	}

	// Deduct currency (persiste entre mapas con cookies)
	g_iPlayerLocalCurrency[client] -= cost;

	// Actualizar cookie para persistir entre cambios de mapa
	UpdateCurrencyCookie(client);

	char message[128];
	Format(message, sizeof(message), "%T", "Buy_PurchaseSuccess", client, itemName, g_iPlayerLocalCurrency[client]);
	PrintToChat(client, "\x04[Buy]\x01 %s", message);
	return true;
}

/**
 * Award currency to player
 *
 * NOTA: Currency persiste durante la sesión (se mantiene entre mapas, se resetea al desconectar)
 * Durante eventos especiales (Nightmare), el currency está congelado y no se otorgan puntos.
 */
stock void AwardCurrency(int client, int amount, const char[] reason = "")
{
	if (client <= 0 || !IsClientInGame(client))
		return;

	// Si el currency está congelado (evento especial activo), no otorgar puntos
	if (Leveling_IsCurrencyFrozen())
	{
		return;
	}

	// Agregar currency (persiste entre mapas con cookies)
	g_iPlayerLocalCurrency[client] += amount;

	// Actualizar cookie para persistir entre cambios de mapa
	UpdateCurrencyCookie(client);

	// Registrar en estadísticas
	CurrencyStats_AddEarnings(client, amount);

// El parámetro 'reason' se usa en llamadas externas para logging/estadísticas
#pragma unused reason
}

/**
 * Actualiza la cookie de currency para persistir entre cambios de mapa
 */
stock void UpdateCurrencyCookie(int client)
{
	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return;

	char sCurrency[32];
	IntToString(g_iPlayerLocalCurrency[client], sCurrency, sizeof(sCurrency));
	SetClientCookie(client, g_hCurrencyCookie, sCurrency);
}

/**
 * Mostrar mensaje de evento de frags/muerte con puntos ganados
 * Esta función centraliza todos los mensajes de kills, frags y puntos
 */
stock void BuyMenu_PrintKillMessage(int attacker, int victim, int frags, int topPosition, int pointsGained)
{
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return;

	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return;

	// Mostrar mensaje con puntos ganados si hay puntos
	if (pointsGained > 0)
	{
		char message[256];
		Format(message, sizeof(message), "%T", "Buy_KillRewardWithCurrency", LANG_SERVER, attacker, victim, frags, topPosition, pointsGained);
		PrintToChatAll("\x04[Eclipse]\x01 %s", message);
	}
	else
	{
		char message[256];
		Format(message, sizeof(message), "%T", "Buy_KillReward", LANG_SERVER, attacker, victim, frags, topPosition);
		PrintToChatAll("\x04[Eclipse]\x01 %s", message);
	}
}

/**
 * Get player's current currency balance
 * NOTA: Currency persiste durante la sesión (entre mapas)
 */
stock int GetPlayerCurrency(int client)
{
	if (client <= 0 || !IsClientInGame(client))
		return 0;

	// Currency persiste durante la sesión
	return g_iPlayerLocalCurrency[client];
}

/**
 * Set player's currency directly (for admin commands, etc.)
 * NOTA: Currency persiste durante la sesión (entre mapas con cookies)
 */
stock void SetPlayerCurrency(int client, int amount)
{
	if (client <= 0 || !IsClientInGame(client))
		return;

	// Currency persiste durante la sesión
	g_iPlayerLocalCurrency[client] = amount;

	// Actualizar cookie para persistir entre cambios de mapa
	UpdateCurrencyCookie(client);

	char message[128];
	Format(message, sizeof(message), "%T", "Buy_AdminSetBalance", client, amount);
	PrintToChat(client, "\x04[Admin]\x01 %s", message);
}
// ============================================================================

// ==================== ACTIVE ABILITIES EVENT HANDLERS ====================

/**
 * Hook cuando un jugador muere
 */
public Action Event_BuyMenu_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients)
	{
		ShoulderCannon_OnPlayerDeath(client);
	}
	return Plugin_Continue;
}

/**
 * Hook cuando un infectado común recibe daño
 * NOTA: LifeStealer ahora es parte del sistema de Abilities
 */
public Action Event_BuyMenu_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	// LifeStealer removido - ahora es parte del sistema de Abilities
	return Plugin_Continue;
}

/**
 * Hook cuando un jugador (infectado especial/tank) recibe daño
 * NOTA: LifeStealer ahora es parte del sistema de Abilities
 */
public Action Event_BuyMenu_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	// LifeStealer removido - ahora es parte del sistema de Abilities
	return Plugin_Continue;
}

/**
 * Hook para manejar daño (para todas las habilidades)
 * NOTA: Berserker, Acid Bath, Lifestealer y Speed Freak ahora son parte del sistema de Abilities
 */
public Action Hook_BuyMenu_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Las habilidades de daño se manejan ahora en el sistema de Abilities
	return Plugin_Continue;
}

// ============================================================================

// ==================== ACTIVE ABILITIES HELPER FUNCTIONS ====================
// NOTA: Estas funciones ya no se usan - las abilities fueron movidas al sistema de Abilities

/**
 * Obtiene información de habilidad para el menú de compra (solo estado)
 * DEPRECADA: Las abilities ahora son parte del sistema de Abilities (!abilities)
 */
public void ActiveAbilities_GetAbilityInfo(int client, int level, char[] buffer, int maxlen, const char[] abilityName)
{
	// Función deprecada - abilities movidas al sistema de Abilities
	Format(buffer, maxlen, "[Ver !abilities]");
}

/**
 * Activa una habilidad por nombre
 * DEPRECADA: Las abilities ahora son parte del sistema de Abilities (!abilities)
 */
public bool ActiveAbilities_ActivateAbility(int client, const char[] abilityName)
{
	// Función deprecada - abilities movidas al sistema de Abilities
	PrintToChat(client, "\x04[Eclipse]\x01 Las habilidades ahora están en el sistema de Abilities. Usa \x05!abilities\x01");
	return false;
}

/**
 * Verifica si el jugador puede usar una habilidad
 * DEPRECADA: Las abilities ahora son parte del sistema de Abilities (!abilities)
 */
public bool ActiveAbilities_CanUseAbility(int client, int level, const char[] abilityName)
{
	// Función deprecada - abilities movidas al sistema de Abilities
	return false;
}

// ============================================================================