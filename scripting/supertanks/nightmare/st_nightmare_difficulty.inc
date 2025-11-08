#if defined _st_nightmare_difficulty_included
 #endinput
#endif
#define _st_nightmare_difficulty_included

// ============================================================================
// NIGHTMARE MODE - DIFFICULTY MODULE
// Dynamic difficulty adjustment system
// ============================================================================

/**
 * Auto-difficulty timer
 * Adjusts infected health and spawn rates based on Nightmare mode
 *
 * @param timer    Timer handle
 * @param client   Client index (unused)
 * @return         Plugin_Continue
 */
public Action:AutoDiffTimer(Handle:timer, any:client)
{
	new AD_special_spawn_delay_min;
	new AD_special_spawn_delay_max;
	new AD_special_spawn_amount;
	new AD_tank_burn_duration;
	new AD_smoker_health;
	new AD_hunter_health;
	new AD_boomer_health;
	new AD_spitter_health;
	new AD_jockey_health;
	new AD_charger_health;
	new AD_witch_health;
	new AD_common_health;
	new AD_zombie_health;
	new AD_tank_health;
	new AD_tank_throw_interval;
	new AD_megamob_spawn_delay;

	if (bNightmare)
	{
		AD_special_spawn_delay_min = 6;
		AD_special_spawn_delay_max = 6;
		AD_special_spawn_amount = 10;
		AD_tank_burn_duration = 666;
		AD_smoker_health = 1666;
		AD_hunter_health = 1666;
		AD_boomer_health = 1666;
		AD_spitter_health = 1666;
		AD_jockey_health = 1666;
		AD_charger_health = 1666;
		AD_witch_health = 1666;
		AD_common_health = 666;
		AD_zombie_health = 666;
		AD_tank_health = 66666;
		AD_tank_throw_interval = 3;
		AD_megamob_spawn_delay = 300;
	}
	else
	{
		AD_special_spawn_delay_min = 0;
		AD_special_spawn_delay_max = 45;
		AD_special_spawn_amount = 3;
		AD_tank_burn_duration = 75;
		AD_smoker_health = 250;
		AD_hunter_health = 250;
		AD_boomer_health = 50;
		AD_spitter_health = 100;
		AD_jockey_health = 325;
		AD_charger_health = 600;
		AD_witch_health = 1000;
		AD_common_health = 50;
		AD_zombie_health = 50;
		AD_tank_health = 4000;
		AD_tank_throw_interval = 5;
		AD_megamob_spawn_delay = 420;
	}

	new Handle:cvar;
	cvar = FindConVar("z_special_spawn_delay_min");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_special_spawn_delay_min);

	cvar = FindConVar("z_special_spawn_delay_max");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_special_spawn_delay_max);

	cvar = FindConVar("z_special_spawn_amount");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_special_spawn_amount);

	cvar = FindConVar("tank_burn_duration");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_tank_burn_duration);

	cvar = FindConVar("z_gas_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_smoker_health);

	cvar = FindConVar("z_hunter_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_hunter_health);

	cvar = FindConVar("z_exploding_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_boomer_health);

	cvar = FindConVar("z_spitter_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_spitter_health);

	cvar = FindConVar("z_jockey_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_jockey_health);

	cvar = FindConVar("z_charger_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_charger_health);

	cvar = FindConVar("z_witch_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_witch_health);

	cvar = FindConVar("z_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_common_health);

	cvar = FindConVar("z_common_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_zombie_health);

	cvar = FindConVar("z_tank_health");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_tank_health);

	cvar = FindConVar("z_tank_throw_interval");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_tank_throw_interval);

	cvar = FindConVar("z_mega_mob_spawn_delay");
	if (cvar != INVALID_HANDLE) SetConVarInt(cvar, AD_megamob_spawn_delay);

	return Plugin_Continue;
}

/**
 * Auto-difficulty adjustment
 * Sets difficulty string and triggers timer
 *
 * @param initialize    True to create new timer, false to just update cvars
 * @noreturn
 */
stock AutoDifficulty(bool:initialize)
{
	decl String:difficulty[32];
	if (bNightmare)
	{
		difficulty = "Impossible";
	}
	else
	{
		difficulty = "Normal";
	}

	new Handle:cvar = FindConVar("z_difficulty");
	if (cvar != INVALID_HANDLE)
	{
		SetConVarString(cvar, difficulty);
	}

	if (initialize)
	{
		CreateTimer(1.0, AutoDiffTimer);
	}
}
