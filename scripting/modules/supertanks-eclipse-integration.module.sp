#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === SUPERTANKS - ECLIPSE INTEGRATION MODULE ===
// Integra completamente el sistema SuperTanks Nightmare
// con Eclipse Management System
//==================================================

//==================================================
// CONVARS DE INTEGRACIÓN
//==================================================

// Recompensas base por tipo de SuperTank (se multiplican por dificultad)
ConVar cvar_ST_Reward_Default;
ConVar cvar_ST_Reward_Smasher;
ConVar cvar_ST_Reward_Warp;
ConVar cvar_ST_Reward_Meteor;
ConVar cvar_ST_Reward_Spitter;
ConVar cvar_ST_Reward_Heal;
ConVar cvar_ST_Reward_Fire;
ConVar cvar_ST_Reward_Ice;
ConVar cvar_ST_Reward_Jockey;
ConVar cvar_ST_Reward_Ghost;
ConVar cvar_ST_Reward_Shock;
ConVar cvar_ST_Reward_Witch;
ConVar cvar_ST_Reward_Shield;
ConVar cvar_ST_Reward_Cobalt;
ConVar cvar_ST_Reward_Jumper;
ConVar cvar_ST_Reward_Gravity;
ConVar cvar_ST_Reward_Demon;

// Integración con modos de dificultad
ConVar cvar_ST_DifficultyIntegration;
ConVar cvar_ST_AbilitiesIntegration;
ConVar cvar_ST_LevelingIntegration;

// Tracking de kills por jugador para stats
int g_iSuperTankKills[MAXPLAYERS + 1][17];  // [cliente][tipo de tank]
int g_iTotalSuperTankKills[MAXPLAYERS + 1];

// Colores de render para identificar tipos de SuperTank
#define COLOR_SMASHER       7080100
#define COLOR_WARP          130130255
#define COLOR_METEOR        1002525
#define COLOR_SPITTER       12115128
#define COLOR_HEAL          100255200
#define COLOR_FIRE          12800
#define COLOR_ICE           0100170
#define COLOR_JOCKEY        2552000
#define COLOR_GHOST         100100100
#define COLOR_SHOCK         100165255
#define COLOR_WITCH         255200255
#define COLOR_SHIELD        135205255
#define COLOR_COBALT        0105255
#define COLOR_JUMPER        2002550
#define COLOR_GRAVITY       333435
#define COLOR_DEMON         255150100

//==================================================
// INICIALIZACIÓN
//==================================================

/**
 * Inicializa el módulo de integración SuperTanks-Eclipse
 */
public void SuperTanksEclipse_OnPluginStart()
{
	PrintToServer("[Eclipse] Initializing SuperTanks Integration Module...");

	// === CONVARS DE RECOMPENSAS ===
	cvar_ST_Reward_Default = CreateConVar("eclipse_st_reward_default", "100", "Puntos BASE por matar Default Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Smasher = CreateConVar("eclipse_st_reward_smasher", "150", "Puntos BASE por matar Smasher Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Warp = CreateConVar("eclipse_st_reward_warp", "120", "Puntos BASE por matar Warp Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Meteor = CreateConVar("eclipse_st_reward_meteor", "180", "Puntos BASE por matar Meteor Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Spitter = CreateConVar("eclipse_st_reward_spitter", "130", "Puntos BASE por matar Spitter Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Heal = CreateConVar("eclipse_st_reward_heal", "140", "Puntos BASE por matar Heal Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Fire = CreateConVar("eclipse_st_reward_fire", "160", "Puntos BASE por matar Fire Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Ice = CreateConVar("eclipse_st_reward_ice", "140", "Puntos BASE por matar Ice Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Jockey = CreateConVar("eclipse_st_reward_jockey", "130", "Puntos BASE por matar Jockey Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Ghost = CreateConVar("eclipse_st_reward_ghost", "200", "Puntos BASE por matar Ghost Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Shock = CreateConVar("eclipse_st_reward_shock", "150", "Puntos BASE por matar Shock Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Witch = CreateConVar("eclipse_st_reward_witch", "170", "Puntos BASE por matar Witch Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Shield = CreateConVar("eclipse_st_reward_shield", "190", "Puntos BASE por matar Shield Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Cobalt = CreateConVar("eclipse_st_reward_cobalt", "180", "Puntos BASE por matar Cobalt Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Jumper = CreateConVar("eclipse_st_reward_jumper", "150", "Puntos BASE por matar Jumper Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Gravity = CreateConVar("eclipse_st_reward_gravity", "200", "Puntos BASE por matar Gravity Tank", FCVAR_PLUGIN, true, 0.0);
	cvar_ST_Reward_Demon = CreateConVar("eclipse_st_reward_demon", "500", "Puntos BASE por matar Demon Tank", FCVAR_PLUGIN, true, 0.0);

	// === CONVARS DE INTEGRACIÓN ===
	cvar_ST_DifficultyIntegration = CreateConVar("eclipse_st_difficulty_integration", "1", "Modos Eclipse afectan SuperTanks", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ST_AbilitiesIntegration = CreateConVar("eclipse_st_abilities_integration", "1", "Habilidades Eclipse afectan SuperTanks", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ST_LevelingIntegration = CreateConVar("eclipse_st_leveling_integration", "1", "Niveles dan ventajas contra SuperTanks", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	PrintToServer("[Eclipse] SuperTanks Integration Module initialized!");
}

/**
 * Reset de mapa - limpia stats
 */
public void SuperTanksEclipse_OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iTotalSuperTankKills[i] = 0;
		for (int j = 0; j < 17; j++)
		{
			g_iSuperTankKills[i][j] = 0;
		}
	}
}

//==================================================
// SISTEMA DE RECOMPENSAS
//==================================================

/**
 * Obtiene el tipo de SuperTank según su color de render
 */
int GetSuperTankTypeByColor(int color)
{
	switch(color)
	{
		case COLOR_SMASHER:  return 1;
		case COLOR_WARP:     return 2;
		case COLOR_METEOR:   return 3;
		case COLOR_SPITTER:  return 4;
		case COLOR_HEAL:     return 5;
		case COLOR_FIRE:     return 6;
		case COLOR_ICE:      return 7;
		case COLOR_JOCKEY:   return 8;
		case COLOR_GHOST:    return 9;
		case COLOR_SHOCK:    return 10;
		case COLOR_WITCH:    return 11;
		case COLOR_SHIELD:   return 12;
		case COLOR_COBALT:   return 13;
		case COLOR_JUMPER:   return 14;
		case COLOR_GRAVITY:  return 15;
		case COLOR_DEMON:    return 16;
		default:             return 0;
	}
}

/**
 * Obtiene el nombre del tipo de SuperTank
 */
void GetSuperTankName(int type, char[] buffer, int maxlen)
{
	char names[][] = {
		"Default Tank", "Smasher Tank", "Warp Tank", "Meteor Tank",
		"Spitter Tank", "Heal Tank", "Fire Tank", "Ice Tank",
		"Jockey Tank", "Ghost Tank", "Shock Tank", "Witch Tank",
		"Shield Tank", "Cobalt Tank", "Jumper Tank", "Gravity Tank", "Demon Tank"
	};

	if (type >= 0 && type <= 16)
		strcopy(buffer, maxlen, names[type]);
	else
		strcopy(buffer, maxlen, "Unknown Tank");
}

/**
 * Obtiene la recompensa base por tipo de SuperTank
 */
int GetSuperTankReward(int type)
{
	switch(type)
	{
		case 0:  return cvar_ST_Reward_Default.IntValue;
		case 1:  return cvar_ST_Reward_Smasher.IntValue;
		case 2:  return cvar_ST_Reward_Warp.IntValue;
		case 3:  return cvar_ST_Reward_Meteor.IntValue;
		case 4:  return cvar_ST_Reward_Spitter.IntValue;
		case 5:  return cvar_ST_Reward_Heal.IntValue;
		case 6:  return cvar_ST_Reward_Fire.IntValue;
		case 7:  return cvar_ST_Reward_Ice.IntValue;
		case 8:  return cvar_ST_Reward_Jockey.IntValue;
		case 9:  return cvar_ST_Reward_Ghost.IntValue;
		case 10: return cvar_ST_Reward_Shock.IntValue;
		case 11: return cvar_ST_Reward_Witch.IntValue;
		case 12: return cvar_ST_Reward_Shield.IntValue;
		case 13: return cvar_ST_Reward_Cobalt.IntValue;
		case 14: return cvar_ST_Reward_Jumper.IntValue;
		case 15: return cvar_ST_Reward_Gravity.IntValue;
		case 16: return cvar_ST_Reward_Demon.IntValue;
		default: return 100;
	}
}

/**
 * Procesa la muerte de un SuperTank y otorga recompensas
 */
public void SuperTanksEclipse_OnSuperTankKilled(int victim, int attacker)
{
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
		return;

	// Obtener tipo de SuperTank por color
	int color = GetEntRenderColor(victim);
	int tankType = GetSuperTankTypeByColor(color);

	// Obtener recompensa base
	int baseReward = GetSuperTankReward(tankType);

	// Ya incluye multiplicador de dificultad
	int finalReward = baseReward;

	// Bonus por nivel del jugador
	if (cvar_ST_LevelingIntegration.BoolValue)
	{
		int level = Leveling_GetPlayerLevel(attacker);
		float levelBonus = 1.0 + (float(level) * 0.02);
		finalReward = RoundToNearest(float(finalReward) * levelBonus);
	}

	// Bonus por modo de dificultad activo
	if (cvar_ST_DifficultyIntegration.BoolValue)
	{
		finalReward = ApplyDifficultyModeBonus(finalReward);
	}

	// Otorgar puntos unificados (Currency + XP)
	char reason[64];
	GetSuperTankName(tankType, reason, sizeof(reason));
	Format(reason, sizeof(reason), "Matar %s", reason);
	AwardUnifiedPoints(attacker, finalReward, reason);

	// Tracking de kills
	g_iSuperTankKills[attacker][tankType]++;
	g_iTotalSuperTankKills[attacker]++;

	// Mensaje al jugador
	char tankName[64];
	GetSuperTankName(tankType, tankName, sizeof(tankName));

	int diffMult = GetDifficultyMultiplier();
	PrintToChat(attacker, "\x04[Eclipse]\x01 Eliminaste \x05%s\x01! +\x03%d\x01 puntos (x%d dificultad)", tankName, finalReward, diffMult);

	// Mensaje global para tanks especiales
	if (tankType >= 9)
	{
		char playerName[64];
		GetClientName(attacker, playerName, sizeof(playerName));
		PrintToChatAll("\x04[Eclipse]\x03 %s\x01 eliminó un \x05%s\x01!", playerName, tankName);
	}

	// Bonus extra para Demon Tank
	if (tankType == 16)
	{
		int demonBonus = 1000 * diffMult;
		AwardUnifiedPoints(attacker, demonBonus, "Bonus Demon Tank");

		char playerName[64];
		GetClientName(attacker, playerName, sizeof(playerName));
		PrintToChatAll("\x04[Eclipse]\x05 ¡DEMON TANK DERROTADO! \x03%s\x01 recibe \x05%d\x01 puntos bonus!", playerName, demonBonus);
	}
}

//==================================================
// INTEGRACIÓN CON MODOS DE DIFICULTAD
//==================================================

/**
 * Aplica bonus según el modo de dificultad Eclipse activo
 */
int ApplyDifficultyModeBonus(int baseReward)
{
	DifficultyMode currentMode = g_CurrentMode;

	switch(currentMode)
	{
		case MODE_BLOODMOON: return RoundToNearest(float(baseReward) * 1.5);
		case MODE_HELL:      return RoundToNearest(float(baseReward) * 2.0);
		case MODE_INFERNO:   return RoundToNearest(float(baseReward) * 3.0);
		case MODE_COWLEVEL:  return RoundToNearest(float(baseReward) * 5.0);
		default:             return baseReward;
	}
}

/**
 * Modifica stats de SuperTanks según el modo Eclipse activo
 */
public void SuperTanksEclipse_ModifyTankStats(int tank)
{
	if (!cvar_ST_DifficultyIntegration.BoolValue)
		return;

	DifficultyMode currentMode = g_CurrentMode;
	if (currentMode == MODE_NONE)
		return;

	int currentHP = GetEntProp(tank, Prop_Send, "m_iHealth");
	int currentMaxHP = GetEntProp(tank, Prop_Send, "m_iMaxHealth");
	float currentSpeed = GetEntPropFloat(tank, Prop_Data, "m_flLaggedMovementValue");

	int newHP, newMaxHP;
	float newSpeed;

	switch(currentMode)
	{
		case MODE_BLOODMOON:
		{
			newMaxHP = RoundToNearest(float(currentMaxHP) * 1.5);
			newHP = RoundToNearest(float(currentHP) * 1.5);
			newSpeed = currentSpeed * 1.1;
		}
		case MODE_HELL:
		{
			newMaxHP = currentMaxHP * 2;
			newHP = currentHP * 2;
			newSpeed = currentSpeed * 1.2;
		}
		case MODE_INFERNO:
		{
			newMaxHP = currentMaxHP * 3;
			newHP = currentHP * 3;
			newSpeed = currentSpeed * 1.3;
		}
		case MODE_COWLEVEL:
		{
			newMaxHP = currentMaxHP * 6;
			newHP = currentHP * 6;
			newSpeed = currentSpeed * 1.5;
		}
		default: return;
	}

	SetEntProp(tank, Prop_Send, "m_iMaxHealth", newMaxHP);
	SetEntProp(tank, Prop_Send, "m_iHealth", newHP);
	SetEntPropFloat(tank, Prop_Data, "m_flLaggedMovementValue", newSpeed);
}

//==================================================
// INTEGRACIÓN CON HABILIDADES
//==================================================

/**
 * Calcula daño bonus contra SuperTanks según habilidades activas
 */
public float SuperTanksEclipse_CalculateDamageBonus(int attacker, int victim, float damage)
{
	if (!cvar_ST_AbilitiesIntegration.BoolValue)
		return damage;

	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
		return damage;

	float finalDamage = damage;

	// Berserker: +50% daño
	if (Abilities_IsActive(attacker, Ability_Berserker))
		finalDamage *= 1.5;

	// Instagib: 5% chance 50% HP
	if (Abilities_IsActive(attacker, Ability_Instagib))
	{
		int level = Leveling_GetPlayerLevel(attacker);
		float instagibChance = 0.05 + (float(level) * 0.001);

		if (GetRandomFloat(0.0, 1.0) <= instagibChance)
		{
			int tankHP = GetEntProp(victim, Prop_Send, "m_iHealth");
			finalDamage = float(tankHP) * 0.5;

			char playerName[64];
			GetClientName(attacker, playerName, sizeof(playerName));
			PrintToChatAll("\x04[Eclipse]\x03 %s\x01 activó \x05Instagib\x01 contra SuperTank!", playerName);
		}
	}

	// Flame Shield: +25% daño
	if (Abilities_IsActive(attacker, Ability_Flameshield))
		finalDamage *= 1.25;

	// Acid Bath: +30% daño
	if (Abilities_IsActive(attacker, Ability_AcidBath))
		finalDamage *= 1.3;

	// Heat Seeker: +40% daño
	if (Abilities_IsActive(attacker, Ability_HeatSeeker))
		finalDamage *= 1.4;

	return finalDamage;
}

//==================================================
// ESTADÍSTICAS
//==================================================

/**
 * Comando para ver estadísticas de SuperTanks
 */
public Action Command_SuperTankStats(int client, int args)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return Plugin_Handled;

	PrintToChat(client, "\x04[Eclipse SuperTanks]\x01 Tus estadísticas:");
	PrintToChat(client, "\x03Total eliminados:\x01 %d SuperTanks", g_iTotalSuperTankKills[client]);

	// Top 5 tipos más matados
	int topTypes[5] = {-1, -1, -1, -1, -1};
	int topCounts[5] = {0, 0, 0, 0, 0};

	for (int type = 0; type <= 16; type++)
	{
		int kills = g_iSuperTankKills[client][type];
		for (int i = 0; i < 5; i++)
		{
			if (kills > topCounts[i])
			{
				for (int j = 4; j > i; j--)
				{
					topTypes[j] = topTypes[j-1];
					topCounts[j] = topCounts[j-1];
				}
				topTypes[i] = type;
				topCounts[i] = kills;
				break;
			}
		}
	}

	for (int i = 0; i < 5 && topTypes[i] != -1; i++)
	{
		char tankName[64];
		GetSuperTankName(topTypes[i], tankName, sizeof(tankName));
		PrintToChat(client, "  %d. \x05%s:\x01 %d kills", i+1, tankName, topCounts[i]);
	}

	return Plugin_Handled;
}

//==================================================
// UTILIDADES
//==================================================

/**
 * Obtiene el color de render de una entidad
 */
int GetEntRenderColor(int entity)
{
	int r, g, b, a;
	GetEntityRenderColor(entity, r, g, b, a);
	return r * 1000000 + g * 1000 + b;
}
