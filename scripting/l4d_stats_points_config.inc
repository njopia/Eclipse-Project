/**
 * =============================================================================
 * L4D Stats - Points Configuration File
 * =============================================================================
 *
 * This file contains all point/score related convar definitions for the
 * L4D Stats plugin. All scoring values can be customized here.
 *
 * =============================================================================
 */

#if defined _l4d_stats_points_config_included
	#endinput
#endif
#define _l4d_stats_points_config_included

// ============================================================================
// INFECTED KILLS - Base score for killing special infected
// ============================================================================

Handle cvar_Infected = INVALID_HANDLE;			// Base score for killing Common Infected
Handle cvar_Hunter = INVALID_HANDLE;			// Base score for killing a Hunter
Handle cvar_Smoker = INVALID_HANDLE;			// Base score for killing a Smoker
Handle cvar_Boomer = INVALID_HANDLE;			// Base score for killing a Boomer
Handle cvar_Spitter = INVALID_HANDLE;			// Base score for killing a Spitter (L4D2)
Handle cvar_Jockey = INVALID_HANDLE;			// Base score for killing a Jockey (L4D2)
Handle cvar_Charger = INVALID_HANDLE;			// Base score for killing a Charger (L4D2)
Handle cvar_InfectedDamage = INVALID_HANDLE;	// Damage to earn 1 point (Infected team)

// ============================================================================
// PERSONAL GAIN - Individual player rewards
// ============================================================================

Handle cvar_Pills = INVALID_HANDLE;				// Base score for giving Pills to a friendly
Handle cvar_Adrenaline = INVALID_HANDLE;		// Base score for giving Adrenaline (L4D2)
Handle cvar_Medkit = INVALID_HANDLE;			// Base score for using Medkit on a friendly
Handle cvar_Defib = INVALID_HANDLE;				// Base score for using Defibrillator (L4D2)
Handle cvar_SmokerDrag = INVALID_HANDLE;		// Base score for saving from Smoker drag
Handle cvar_JockeyRide = INVALID_HANDLE;		// Base score for saving from Jockey ride (L4D2)
Handle cvar_ChargerPlummel = INVALID_HANDLE;	// Base score for saving from Charger plummel (L4D2)
Handle cvar_ChargerCarry = INVALID_HANDLE;		// Base score for saving from Charger carry (L4D2)
Handle cvar_ChokePounce = INVALID_HANDLE;		// Base score for saving from Hunter pounce / Smoker choke
Handle cvar_Revive = INVALID_HANDLE;			// Base score for reviving an incapacitated friendly
Handle cvar_Rescue = INVALID_HANDLE;			// Base score for rescuing from a closet
Handle cvar_Protect = INVALID_HANDLE;			// Base score for protecting a friendly in combat
Handle cvar_PlayerLedgeSuccess = INVALID_HANDLE;	// Base score for causing ledge grab
Handle cvar_Matador = INVALID_HANDLE;			// Base score for killing charging Charger with melee (L4D2)
Handle cvar_WitchCrowned = INVALID_HANDLE;		// Base score for crowning a Witch

// ============================================================================
// TEAM GAIN - Team-wide rewards
// ============================================================================

Handle cvar_Tank = INVALID_HANDLE;				// Base team score for killing Tank
Handle cvar_Panic = INVALID_HANDLE;				// Base team score for surviving Panic Event with no incaps
Handle cvar_BoomerMob = INVALID_HANDLE;			// Base team score for surviving Boomer Mob with no incaps
Handle cvar_SafeHouse = INVALID_HANDLE;			// Base score for reaching Safe House
Handle cvar_Witch = INVALID_HANDLE;				// Base score for not disturbing a Witch
Handle cvar_VictorySurvivors = INVALID_HANDLE;	// Base score for completing a Campaign (Survivors)
Handle cvar_VictoryInfected = INVALID_HANDLE;	// Base score for completing a Campaign (Infected)

// ============================================================================
// POINT LOSSES - Penalties for negative actions
// ============================================================================

Handle cvar_FFire = INVALID_HANDLE;				// Base score penalty for Friendly Fire
Handle cvar_FIncap = INVALID_HANDLE;			// Base score penalty for friendly incapacitation
Handle cvar_FKill = INVALID_HANDLE;				// Base score penalty for friendly kill
Handle cvar_InSafeRoom = INVALID_HANDLE;		// Base score penalty for letting Infected in Safe Room
Handle cvar_Restart = INVALID_HANDLE;			// Base score penalty for Round Restart
Handle cvar_CarAlarm = INVALID_HANDLE;			// Base score penalty for triggering Car Alarm (L4D2)

// ============================================================================
// MEDKIT PENALTIES - Scaling penalties for medkit usage
// ============================================================================

Handle cvar_MedkitUsedPointPenalty = INVALID_HANDLE;		// Score reduction multiplier per medkit
Handle cvar_MedkitUsedPointPenaltyMax = INVALID_HANDLE;	// Maximum score reduction cap
Handle cvar_MedkitUsedFree = INVALID_HANDLE;				// Free medkits allowed without penalty
Handle cvar_MedkitUsedRealismFree = INVALID_HANDLE;		// Free medkits for Realism mode

// ============================================================================
// SURVIVOR-SPECIFIC POINTS - Infected team rewards
// ============================================================================

Handle cvar_SurvivorDeath = INVALID_HANDLE;		// Base score for killing a Survivor
Handle cvar_SurvivorIncap = INVALID_HANDLE;		// Base score for incapacitating a Survivor

// ============================================================================
// HUNTER-SPECIFIC POINTS - Hunter pounce rewards
// ============================================================================

Handle cvar_HunterPerfectPounceDamage = INVALID_HANDLE;	// Damage threshold for Perfect Pounce
Handle cvar_HunterPerfectPounceSuccess = INVALID_HANDLE;	// Base score for Perfect Pounce
Handle cvar_HunterNicePounceDamage = INVALID_HANDLE;		// Damage threshold for Nice Pounce
Handle cvar_HunterNicePounceSuccess = INVALID_HANDLE;		// Base score for Nice Pounce
Handle cvar_HunterDamageCap = INVALID_HANDLE;				// Maximum stored pounce damage

// ============================================================================
// BOOMER-SPECIFIC POINTS - Boomer vomit rewards
// ============================================================================

Handle cvar_BoomerSuccess = INVALID_HANDLE;				// Base score for successful vomit
Handle cvar_BoomerPerfectHits = INVALID_HANDLE;			// Number of survivors for Perfect Vomit
Handle cvar_BoomerPerfectSuccess = INVALID_HANDLE;		// Base score for Perfect Vomit

// ============================================================================
// TANK-SPECIFIC POINTS - Tank damage rewards
// ============================================================================

Handle cvar_TankDamageCap = INVALID_HANDLE;				// Maximum damage cap for point earning
Handle cvar_TankDamageTotal = INVALID_HANDLE;			// Damage threshold for Bulldozer Award
Handle cvar_TankDamageTotalSuccess = INVALID_HANDLE;	// Base score for Bulldozer Award
Handle cvar_TankThrowRockSuccess = INVALID_HANDLE;		// Base score for tank thrown rock hit

// ============================================================================
// CHARGER-SPECIFIC POINTS - Charger ram rewards
// ============================================================================

Handle cvar_ChargerRamSuccess = INVALID_HANDLE;			// Base score for successful ram
Handle cvar_ChargerRamHits = INVALID_HANDLE;			// Number of impacts for Ram Award

// ============================================================================
// MISCELLANEOUS L4D2 POINTS
// ============================================================================

Handle cvar_AmmoUpgradeAdded = INVALID_HANDLE;			// Base score for deploying ammo upgrade (L4D2)
Handle cvar_GascanPoured = INVALID_HANDLE;				// Base score for pouring gascan (L4D2)

// ============================================================================
// MULTIPLIERS & BOT-RELATED
// ============================================================================

Handle cvar_BotScoreMultiplier = INVALID_HANDLE;		// Multiplier for bot-related score penalties

// ============================================================================
// INITIALIZATION FUNCTION - Call this in OnPluginStart()
// ============================================================================

/**
 * Initializes all points-related ConVars
 * Should be called from OnPluginStart()
 */
void InitializePointsConfig()
{
	// ========================================================================
	// INFECTED KILLS
	// ========================================================================
	cvar_Infected = CreateConVar(
		"l4d_stats_infected",
		"1",
		"Base score for killing a Common Infected",
		_,
		true, 1.0
	);

	cvar_Hunter = CreateConVar(
		"l4d_stats_hunter",
		"2",
		"Base score for killing a Hunter",
		_,
		true, 1.0
	);

	cvar_Smoker = CreateConVar(
		"l4d_stats_smoker",
		"3",
		"Base score for killing a Smoker",
		_,
		true, 1.0
	);

	cvar_Boomer = CreateConVar(
		"l4d_stats_boomer",
		"5",
		"Base score for killing a Boomer",
		_,
		true, 1.0
	);

	cvar_Spitter = CreateConVar(
		"l4d_stats_spitter",
		"5",
		"[L4D2] Base score for killing a Spitter",
		_,
		true, 1.0
	);

	cvar_Jockey = CreateConVar(
		"l4d_stats_jockey",
		"5",
		"[L4D2] Base score for killing a Jockey",
		_,
		true, 1.0
	);

	cvar_Charger = CreateConVar(
		"l4d_stats_charger",
		"5",
		"[L4D2] Base score for killing a Charger",
		_,
		true, 1.0
	);

	cvar_InfectedDamage = CreateConVar(
		"l4d_stats_infected_damage",
		"2",
		"The amount of damage inflicted to Survivors to earn 1 point",
		_,
		true, 1.0
	);

	// ========================================================================
	// PERSONAL GAIN
	// ========================================================================
	cvar_Pills = CreateConVar(
		"l4d_stats_pills",
		"15",
		"Base score for giving Pills to a friendly",
		_,
		true, 1.0
	);

	cvar_Adrenaline = CreateConVar(
		"l4d_stats_adrenaline",
		"15",
		"[L4D2] Base score for giving Adrenaline to a friendly",
		_,
		true, 1.0
	);

	cvar_Medkit = CreateConVar(
		"l4d_stats_medkit",
		"20",
		"Base score for using a Medkit on a friendly",
		_,
		true, 1.0
	);

	cvar_Defib = CreateConVar(
		"l4d_stats_defib",
		"20",
		"[L4D2] Base score for using a Defibrillator on a friendly",
		_,
		true, 1.0
	);

	cvar_SmokerDrag = CreateConVar(
		"l4d_stats_smokerdrag",
		"5",
		"Base score for saving a friendly from a Smoker Tongue Drag",
		_,
		true, 1.0
	);

	cvar_JockeyRide = CreateConVar(
		"l4d_stats_jockeyride",
		"10",
		"[L4D2] Base score for saving a friendly from a Jockey Ride",
		_,
		true, 1.0
	);

	cvar_ChargerPlummel = CreateConVar(
		"l4d_stats_chargerplummel",
		"10",
		"[L4D2] Base score for saving a friendly from a Charger Plummel",
		_,
		true, 1.0
	);

	cvar_ChargerCarry = CreateConVar(
		"l4d_stats_chargercarry",
		"15",
		"[L4D2] Base score for saving a friendly from a Charger Carry",
		_,
		true, 1.0
	);

	cvar_ChokePounce = CreateConVar(
		"l4d_stats_chokepounce",
		"10",
		"Base score for saving a friendly from a Hunter Pounce / Smoker Choke",
		_,
		true, 1.0
	);

	cvar_Revive = CreateConVar(
		"l4d_stats_revive",
		"15",
		"Base score for Revive a friendly from Incapacitated state",
		_,
		true, 1.0
	);

	cvar_Rescue = CreateConVar(
		"l4d_stats_rescue",
		"10",
		"Base score for Rescue a friendly from a closet",
		_,
		true, 1.0
	);

	cvar_Protect = CreateConVar(
		"l4d_stats_protect",
		"3",
		"Base score for Protect a friendly in combat",
		_,
		true, 1.0
	);

	cvar_PlayerLedgeSuccess = CreateConVar(
		"l4d_stats_ledgegrap",
		"15",
		"Base score for causing a survivor to grap a ledge",
		_,
		true, 1.0
	);

	cvar_Matador = CreateConVar(
		"l4d_stats_matador",
		"30",
		"[L4D2] Base score for killing a charging Charger with a melee weapon",
		_,
		true, 1.0
	);

	cvar_WitchCrowned = CreateConVar(
		"l4d_stats_witchcrowned",
		"30",
		"Base score for Crowning a Witch",
		_,
		true, 1.0
	);

	// ========================================================================
	// TEAM GAIN
	// ========================================================================
	cvar_Tank = CreateConVar(
		"l4d_stats_tank",
		"25",
		"Base team score for killing a Tank",
		_,
		true, 1.0
	);

	cvar_Panic = CreateConVar(
		"l4d_stats_panic",
		"25",
		"Base team score for surviving a Panic Event with no Incapacitations",
		_,
		true, 1.0
	);

	cvar_BoomerMob = CreateConVar(
		"l4d_stats_boomermob",
		"10",
		"Base team score for surviving a Boomer Mob with no Incapacitations",
		_,
		true, 1.0
	);

	cvar_SafeHouse = CreateConVar(
		"l4d_stats_safehouse",
		"10",
		"Base score for reaching a Safe House",
		_,
		true, 1.0
	);

	cvar_Witch = CreateConVar(
		"l4d_stats_witch",
		"10",
		"Base score for Not Disturbing a Witch",
		_,
		true, 1.0
	);

	cvar_VictorySurvivors = CreateConVar(
		"l4d_stats_campaign",
		"5",
		"Base score for Completing a Campaign",
		_,
		true, 1.0
	);

	cvar_VictoryInfected = CreateConVar(
		"l4d_stats_infected_win",
		"30",
		"Base victory score for Infected Team",
		_,
		true, 1.0
	);

	// ========================================================================
	// POINT LOSSES
	// ========================================================================
	cvar_FFire = CreateConVar(
		"l4d_stats_ffire",
		"25",
		"Base score for Friendly Fire",
		_,
		true, 1.0
	);

	cvar_FIncap = CreateConVar(
		"l4d_stats_fincap",
		"75",
		"Base score for a Friendly Incap",
		_,
		true, 1.0
	);

	cvar_FKill = CreateConVar(
		"l4d_stats_fkill",
		"250",
		"Base score for a Friendly Kill",
		_,
		true, 1.0
	);

	cvar_InSafeRoom = CreateConVar(
		"l4d_stats_insaferoom",
		"5",
		"Base score for letting Infected in the Safe Room",
		_,
		true, 1.0
	);

	cvar_Restart = CreateConVar(
		"l4d_stats_restart",
		"100",
		"Base score for a Round Restart",
		_,
		true, 1.0
	);

	cvar_MedkitUsedPointPenalty = CreateConVar(
		"l4d_stats_medkitpenalty",
		"0.1",
		"Score reduction for all Survivor earned points for each used Medkit (Formula: Score = NormalPoints * (1 - MedkitsUsed * MedkitPenalty))",
		_,
		true, 0.0,
		true, 0.5
	);

	cvar_MedkitUsedPointPenaltyMax = CreateConVar(
		"l4d_stats_medkitpenaltymax",
		"1.0",
		"Maximum score reduction (the score reduction will not go over this value when a Medkit is used)",
		_,
		true, 0.0,
		true, 1.0
	);

	cvar_MedkitUsedFree = CreateConVar(
		"l4d_stats_medkitpenaltyfree",
		"0",
		"Team Survivors can use this many Medkits for free without any reduction to the score",
		_,
		true, 0.0
	);

	cvar_MedkitUsedRealismFree = CreateConVar(
		"l4d_stats_medkitpenaltyfree_r",
		"4",
		"Team Survivors can use this many Medkits for free without any reduction to the score when playing in Realism gamemodes (-1 = use the value in l4d_stats_medkitpenaltyfree)",
		_,
		true, -1.0
	);

	cvar_CarAlarm = CreateConVar(
		"l4d_stats_caralarm",
		"50",
		"[L4D2] Base score for a Triggering Car Alarm",
		_,
		true, 1.0
	);

	// ========================================================================
	// SURVIVOR-SPECIFIC POINTS
	// ========================================================================
	cvar_SurvivorDeath = CreateConVar(
		"l4d_stats_survivor_death",
		"40",
		"Base score for killing a Survivor",
		_,
		true, 1.0
	);

	cvar_SurvivorIncap = CreateConVar(
		"l4d_stats_survivor_incap",
		"15",
		"Base score for incapacitating a Survivor",
		_,
		true, 1.0
	);

	// ========================================================================
	// HUNTER-SPECIFIC POINTS
	// ========================================================================
	cvar_HunterPerfectPounceDamage = CreateConVar(
		"l4d_stats_perfectpouncedamage",
		"25",
		"The amount of damage from a pounce to earn Perfect Pounce (Death From Above) success points",
		_,
		true, 1.0
	);

	cvar_HunterPerfectPounceSuccess = CreateConVar(
		"l4d_stats_perfectpouncesuccess",
		"25",
		"Base score for a successful Perfect Pounce",
		_,
		true, 1.0
	);

	cvar_HunterNicePounceDamage = CreateConVar(
		"l4d_stats_nicepouncedamage",
		"15",
		"The amount of damage from a pounce to earn Nice Pounce (Pain From Above) success points",
		_,
		true, 1.0
	);

	cvar_HunterNicePounceSuccess = CreateConVar(
		"l4d_stats_nicepouncesuccess",
		"10",
		"Base score for a successful Nice Pounce",
		_,
		true, 1.0
	);

	cvar_HunterDamageCap = CreateConVar(
		"l4d_stats_hunterdamagecap",
		"25",
		"Hunter stored damage cap",
		_,
		true, 25.0
	);

	// ========================================================================
	// BOOMER-SPECIFIC POINTS
	// ========================================================================
	cvar_BoomerSuccess = CreateConVar(
		"l4d_stats_boomersuccess",
		"5",
		"Base score for a successfully vomiting on survivor",
		_,
		true, 1.0
	);

	cvar_BoomerPerfectHits = CreateConVar(
		"l4d_stats_boomerperfecthits",
		"4",
		"The number of survivors that needs to get blinded to earn Boomer Perfect Vomit Award and success points",
		_,
		true, 4.0
	);

	cvar_BoomerPerfectSuccess = CreateConVar(
		"l4d_stats_boomerperfectsuccess",
		"30",
		"Base score for a successful Boomer Perfect Vomit",
		_,
		true, 1.0
	);

	// ========================================================================
	// TANK-SPECIFIC POINTS
	// ========================================================================
	cvar_TankDamageCap = CreateConVar(
		"l4d_stats_tankdmgcap",
		"500",
		"Maximum inflicted damage done by Tank to earn Infected damagepoints",
		_,
		true, 150.0
	);

	cvar_TankDamageTotal = CreateConVar(
		"l4d_stats_bulldozer",
		"200",
		"Damage inflicted by Tank to earn Bulldozer Award and success points",
		_,
		true, 200.0
	);

	cvar_TankDamageTotalSuccess = CreateConVar(
		"l4d_stats_bulldozersuccess",
		"50",
		"Base score for Bulldozer Award",
		_,
		true, 1.0
	);

	cvar_TankThrowRockSuccess = CreateConVar(
		"l4d_stats_tankthrowrocksuccess",
		"5",
		"Base score for a Tank thrown rock hit",
		_,
		true, 0.0
	);

	// ========================================================================
	// CHARGER-SPECIFIC POINTS
	// ========================================================================
	cvar_ChargerRamSuccess = CreateConVar(
		"l4d_stats_chargerramsuccess",
		"40",
		"Base score for a successful Charger Scattering Ram",
		_,
		true, 1.0
	);

	cvar_ChargerRamHits = CreateConVar(
		"l4d_stats_chargerramhits",
		"4",
		"The number of impacts on survivors to earn Scattering Ram Award and success points",
		_,
		true, 2.0
	);

	// ========================================================================
	// MISCELLANEOUS L4D2
	// ========================================================================
	cvar_AmmoUpgradeAdded = CreateConVar(
		"l4d_stats_deployammoupgrade",
		"10",
		"[L4D2] Base score for deploying ammo upgrade pack",
		_,
		true, 0.0
	);

	cvar_GascanPoured = CreateConVar(
		"l4d_stats_gascanpoured",
		"5",
		"[L4D2] Base score for successfully pouring a gascan",
		_,
		true, 0.0
	);

	// ========================================================================
	// MULTIPLIERS & BOT-RELATED
	// ========================================================================
	cvar_BotScoreMultiplier = CreateConVar(
		"l4d_stats_botscoremultiplier",
		"1.0",
		"Multiplier to use when receiving bot related score penalty. 0 = Disable",
		_,
		true, 0.0
	);
}
