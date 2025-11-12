#if defined _st_config_included
 #endinput
#endif
#define _st_config_included

// ============================================================================
// CONFIGURATION MODULE
// Handles all ConVar creation, initialization, and change callbacks
// ============================================================================

/**
 * Initialize all ConVars for the plugin
 * Called from OnPluginStart()
 */
stock ST_Config_CreateConVars()
{
	// Core ConVars
	hSuperTanksEnabled = CreateConVar("st_on", "1", "Is Super Tanks enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hDisplayHealthCvar = CreateConVar("st_display_health", "1", "Display tanks health in crosshair?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hWave1Cvar = CreateConVar("st_wave1_tanks", "1", "Default number of tanks in the 1st wave of finale.", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	hWave2Cvar = CreateConVar("st_wave2_tanks", "2", "Default number of tanks in the 2nd wave of finale.", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	hWave3Cvar = CreateConVar("st_wave3_tanks", "3", "Default number of tanks in the finale escape.", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	hFinaleOnly = CreateConVar("st_finale_only", "0", "Create Super Tanks in finale only?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hDefaultTanks = CreateConVar("st_default_tanks", "0", "Only use default tanks?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hGamemodeCvar = FindConVar("mp_gamemode");

	// Default Tank ConVars
	hDefaultOverride = CreateConVar("st_default_override", "0", "Setting this to 1 will allow further customization to default tanks.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hDefaultExtraHealth = CreateConVar("st_default_extra_health", "0", "Default Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hDefaultSpeed = CreateConVar("st_default_speed", "1.0", "Default Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hDefaultThrow = CreateConVar("st_default_throw", "5.0", "Default Tanks rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hDefaultFireImmunity = CreateConVar("st_default_fire_immunity", "0", "Are Default Tanks immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Smasher Tank ConVars
	hSmasherEnabled = CreateConVar("st_smasher", "1", "Is Smasher Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hSmasherExtraHealth = CreateConVar("st_smasher_extra_health", "0", "Smasher Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hSmasherSpeed = CreateConVar("st_smasher_speed", "0.65", "Smasher Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hSmasherThrow = CreateConVar("st_smasher_throw", "30.0", "Smasher Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hSmasherFireImmunity = CreateConVar("st_smasher_fire_immunity", "0", "Is Smasher Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hSmasherMaimDamage = CreateConVar("st_smasher_maim_damage", "1", "Smasher Tanks maim attack will set victims health to this amount.", FCVAR_NOTIFY, true, 1.0, true, 99.0);
	hSmasherCrushDamage = CreateConVar("st_smasher_crush_damage", "300", "Smasher Tanks claw attack damage.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	hSmasherRemoveBody = CreateConVar("st_smasher_remove_body", "1", "Smasher Tanks crush attack will remove survivors death body?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Warp Tank ConVars
	hWarpEnabled = CreateConVar("st_warp", "1", "Is Warp Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hWarpExtraHealth = CreateConVar("st_warp_extra_health", "0", "Warp Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hWarpSpeed = CreateConVar("st_warp_speed", "1.0", "Warp Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hWarpThrow = CreateConVar("st_warp_throw", "9.0", "Warp Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hWarpFireImmunity = CreateConVar("st_warp_fire_immunity", "1", "Is Warp Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hWarpTeleportDelay = CreateConVar("st_warp_teleport_delay", "20", "Warp Tanks Teleport Delay Interval.", FCVAR_NOTIFY, true, 1.0, true, 60.0);

	// Meteor Tank ConVars
	hMeteorEnabled = CreateConVar("st_meteor", "1", "Is Meteor Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hMeteorExtraHealth = CreateConVar("st_meteor_extra_health", "0", "Meteor Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hMeteorSpeed = CreateConVar("st_meteor_speed", "1.0", "Meteor Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hMeteorThrow = CreateConVar("st_meteor_throw", "10.0", "Meteor Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hMeteorFireImmunity = CreateConVar("st_meteor_fire_immunity", "1", "Is Meteor Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hMeteorStormDelay = CreateConVar("st_meteor_storm_delay", "30", "Meteor Tanks Meteor Storm Delay Interval.", FCVAR_NOTIFY, true, 1.0, true, 60.0);
	hMeteorStormDamage = CreateConVar("st_meteor_storm_damage", "25.0", "Meteor Tanks falling meteor damage.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);

	// Spitter Tank ConVars
	hSpitterEnabled = CreateConVar("st_spitter", "1", "Is Spitter Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hSpitterExtraHealth = CreateConVar("st_spitter_extra_health", "0", "Spitter Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hSpitterSpeed = CreateConVar("st_spitter_speed", "1.0", "Spitter Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hSpitterThrow = CreateConVar("st_spitter_throw", "6.0", "Spitter Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hSpitterFireImmunity = CreateConVar("st_spitter_fire_immunity", "1", "Is Spitter Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Heal Tank ConVars
	hHealEnabled = CreateConVar("st_heal", "1", "Is Heal Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHealExtraHealth = CreateConVar("st_heal_extra_health", "0", "Heal Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hHealSpeed = CreateConVar("st_heal_speed", "1.0", "Heal Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hHealThrow = CreateConVar("st_heal_throw", "15.0", "Heal Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hHealFireImmunity = CreateConVar("st_heal_fire_immunity", "1", "Is Heal Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHealHealth = CreateConVar("st_heal_health", "25", "Heal Tanks receive this much health per frame when near a survivor", FCVAR_NOTIFY, true, 0.0, true, 1000.0);

	// Fire Tank ConVars
	hFireEnabled = CreateConVar("st_fire", "1", "Is Fire Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hFireExtraHealth = CreateConVar("st_fire_extra_health", "0", "Fire Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hFireSpeed = CreateConVar("st_fire_speed", "1.0", "Fire Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hFireThrow = CreateConVar("st_fire_throw", "6.0", "Fire Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hFireFireImmunity = CreateConVar("st_fire_fire_immunity", "1", "Is Fire Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Ice Tank ConVars
	hIceEnabled = CreateConVar("st_ice", "1", "Is Ice Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hIceExtraHealth = CreateConVar("st_ice_extra_health", "0", "Ice Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hIceSpeed = CreateConVar("st_ice_speed", "1.0", "Ice Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hIceThrow = CreateConVar("st_ice_throw", "6.0", "Ice Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hIceFireImmunity = CreateConVar("st_ice_fire_immunity", "1", "Is Ice Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Jockey Tank ConVars
	hJockeyEnabled = CreateConVar("st_jockey", "1", "Is Jockey Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hJockeyExtraHealth = CreateConVar("st_jockey_extra_health", "0", "Jockey Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hJockeySpeed = CreateConVar("st_jockey_speed", "1.33", "Jockey Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hJockeyThrow = CreateConVar("st_jockey_throw", "7.0", "Jockey Tank jockey throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hJockeyFireImmunity = CreateConVar("st_jockey_fire_immunity", "1", "Is Jockey Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Ghost Tank ConVars
	hGhostEnabled = CreateConVar("st_ghost", "1", "Is Ghost Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hGhostExtraHealth = CreateConVar("st_ghost_extra_health", "0", "Ghost Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hGhostSpeed = CreateConVar("st_ghost_speed", "1.0", "Ghost Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hGhostThrow = CreateConVar("st_ghost_throw", "15.0", "Ghost Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hGhostFireImmunity = CreateConVar("st_ghost_fire_immunity", "1", "Is Ghost Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hGhostDisarm = CreateConVar("st_ghost_disarm", "1", "Does Ghost Tank have a chance of disarming an attacking melee survivor?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Shock Tank ConVars
	hShockEnabled = CreateConVar("st_shock", "1", "Is Shock Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hShockExtraHealth = CreateConVar("st_shock_extra_health", "0", "Shock Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hShockSpeed = CreateConVar("st_shock_speed", "1.0", "Shock Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hShockThrow = CreateConVar("st_shock_throw", "10.0", "Shock Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hShockFireImmunity = CreateConVar("st_shock_fire_immunity", "1", "Is Shock Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hShockStunDamage = CreateConVar("st_shock_stun_damage", "12", "Shock Tanks stun damage.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	hShockStunMovement = CreateConVar("st_shock_stun_movement", "0.75", "Shock Tanks stun reduce survivors speed to this amount.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Witch Tank ConVars
	hWitchEnabled = CreateConVar("st_witch", "1", "Is Witch Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hWitchExtraHealth = CreateConVar("st_witch_extra_health", "0", "Witch Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hWitchSpeed = CreateConVar("st_witch_speed", "1.0", "Witch Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hWitchThrow = CreateConVar("st_witch_throw", "7.0", "Witch Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hWitchFireImmunity = CreateConVar("st_witch_fire_immunity", "1", "Is Witch Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hWitchMaxWitches = CreateConVar("st_witch_max_witches", "30", "Maximum number of witches can be active from witch tank.", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	// Shield Tank ConVars
	hShieldEnabled = CreateConVar("st_shield", "1", "Is Shield Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hShieldExtraHealth = CreateConVar("st_shield_extra_health", "0", "Shield Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hShieldSpeed = CreateConVar("st_shield_speed", "1.0", "Shield Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hShieldThrow = CreateConVar("st_shield_throw", "8.0", "Shield Tank propane throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hShieldFireImmunity = CreateConVar("st_shield_fire_immunity", "1", "Is Shield Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hShieldShieldsDownInterval = CreateConVar("st_shield_shields_down_interval", "8.0", "When Shield Tanks shields are disabled, how long before shields activate again.", FCVAR_NOTIFY, true, 0.1, true, 60.0);

	// Cobalt Tank ConVars
	hCobaltEnabled = CreateConVar("st_cobalt", "1", "Is Cobalt Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCobaltExtraHealth = CreateConVar("st_cobalt_extra_health", "0", "Cobalt Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hCobaltSpeed = CreateConVar("st_cobalt_speed", "1.0", "Cobalt Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hCobaltThrow = CreateConVar("st_cobalt_throw", "999.0", "Cobalt Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hCobaltFireImmunity = CreateConVar("st_cobalt_fire_immunity", "1", "Is Cobalt Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCobaltSpecialSpeed = CreateConVar("st_cobalt_Special_speed", "2.5", "Cobalt Tanks movement value when speeding towards a survivor.", FCVAR_NOTIFY, true, 1.0, true, 5.0);

	// Jumper Tank ConVars
	hJumperEnabled = CreateConVar("st_jumper", "1", "Is Jumper Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hJumperExtraHealth = CreateConVar("st_jumper_extra_health", "0", "Jumper Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hJumperSpeed = CreateConVar("st_jumper_speed", "1.20", "Jumper Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hJumperThrow = CreateConVar("st_jumper_throw", "999.0", "Jumper Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hJumperFireImmunity = CreateConVar("st_jumper_fire_immunity", "1", "Is Jumper Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hJumperJumpDelay = CreateConVar("st_jumper_jump_delay", "3", "Jumper Tanks delay interval to jump again.", FCVAR_NOTIFY, true, 1.0, true, 60.0);

	// Gravity Tank ConVars
	hGravityEnabled = CreateConVar("st_gravity", "1", "Is Gravity Tank Enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hGravityExtraHealth = CreateConVar("st_gravity_extra_health", "0", "Gravity Tanks receive this many additional hitpoints.", FCVAR_NOTIFY, true, 0.0, true, 100000.0);
	hGravitySpeed = CreateConVar("st_gravity_speed", "1.0", "Gravity Tanks default movement speed.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hGravityThrow = CreateConVar("st_gravity_throw", "10.0", "Gravity Tank rock throw ability interval.", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	hGravityFireImmunity = CreateConVar("st_gravity_fire_immunity", "1", "Is Gravity Tank immune to fire?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hGravityPullForce = CreateConVar("st_gravity_pull_force", "-50.0", "Gravity Tanks pull force value. Higher negative values equals greater pull forces.", FCVAR_NOTIFY, true, -200.0, true, 0.0);

	// Nightmare Mode ConVars
	hNightmare = CreateConVar("nightmare_on", "0", "Is nightmare gamemode enabled?", FCVAR_NONE, true, 0.0, true, 1.0);
	hNightmareBegin = CreateConVar("nightmare_begin", "0", "Begin nightmare mode countdown?", FCVAR_NONE, true, -1.0, true, 1.0);

	// Auto-execute config file
	AutoExecConfig(true, "SuperTanks");
}

/**
 * Load all ConVar values into variables
 * Called after ConVars are created
 */
stock ST_Config_LoadValues()
{
	bNightmare = GetConVarBool(hNightmare);
	iNightmareBegin = GetConVarInt(hNightmareBegin);

	bSuperTanksEnabled = GetConVarBool(hSuperTanksEnabled);
	bDisplayHealthCvar = GetConVarBool(hDisplayHealthCvar);
	iWave1Cvar = GetConVarInt(hWave1Cvar);
	iWave2Cvar = GetConVarInt(hWave2Cvar);
	iWave3Cvar = GetConVarInt(hWave3Cvar);
	bFinaleOnly = GetConVarBool(hFinaleOnly);
	bDefaultTanks = GetConVarBool(hDefaultTanks);
	bDefaultOverride = GetConVarBool(hDefaultOverride);

	bTankEnabled[1] = GetConVarBool(hSmasherEnabled);
	bTankEnabled[2] = GetConVarBool(hWarpEnabled);
	bTankEnabled[3] = GetConVarBool(hMeteorEnabled);
	bTankEnabled[4] = GetConVarBool(hSpitterEnabled);
	bTankEnabled[5] = GetConVarBool(hHealEnabled);
	bTankEnabled[6] = GetConVarBool(hFireEnabled);
	bTankEnabled[7] = GetConVarBool(hIceEnabled);
	bTankEnabled[8] = GetConVarBool(hJockeyEnabled);
	bTankEnabled[9] = GetConVarBool(hGhostEnabled);
	bTankEnabled[10] = GetConVarBool(hShockEnabled);
	bTankEnabled[11] = GetConVarBool(hWitchEnabled);
	bTankEnabled[12] = GetConVarBool(hShieldEnabled);
	bTankEnabled[13] = GetConVarBool(hCobaltEnabled);
	bTankEnabled[14] = GetConVarBool(hJumperEnabled);
	bTankEnabled[15] = GetConVarBool(hGravityEnabled);

	iTankExtraHealth[0] = GetConVarInt(hDefaultExtraHealth);
	iTankExtraHealth[1] = GetConVarInt(hSmasherExtraHealth);
	iTankExtraHealth[2] = GetConVarInt(hWarpExtraHealth);
	iTankExtraHealth[3] = GetConVarInt(hMeteorExtraHealth);
	iTankExtraHealth[4] = GetConVarInt(hSpitterExtraHealth);
	iTankExtraHealth[5] = GetConVarInt(hHealExtraHealth);
	iTankExtraHealth[6] = GetConVarInt(hFireExtraHealth);
	iTankExtraHealth[7] = GetConVarInt(hIceExtraHealth);
	iTankExtraHealth[8] = GetConVarInt(hJockeyExtraHealth);
	iTankExtraHealth[9] = GetConVarInt(hGhostExtraHealth);
	iTankExtraHealth[10] = GetConVarInt(hShockExtraHealth);
	iTankExtraHealth[11] = GetConVarInt(hWitchExtraHealth);
	iTankExtraHealth[12] = GetConVarInt(hShieldExtraHealth);
	iTankExtraHealth[13] = GetConVarInt(hCobaltExtraHealth);
	iTankExtraHealth[14] = GetConVarInt(hJumperExtraHealth);
	iTankExtraHealth[15] = GetConVarInt(hGravityExtraHealth);
	iTankExtraHealth[16] = 0;

	flTankSpeed[0] = GetConVarFloat(hDefaultSpeed);
	flTankSpeed[1] = GetConVarFloat(hSmasherSpeed);
	flTankSpeed[2] = GetConVarFloat(hWarpSpeed);
	flTankSpeed[3] = GetConVarFloat(hMeteorSpeed);
	flTankSpeed[4] = GetConVarFloat(hSpitterSpeed);
	flTankSpeed[5] = GetConVarFloat(hHealSpeed);
	flTankSpeed[6] = GetConVarFloat(hFireSpeed);
	flTankSpeed[7] = GetConVarFloat(hIceSpeed);
	flTankSpeed[8] = GetConVarFloat(hJockeySpeed);
	flTankSpeed[9] = GetConVarFloat(hGhostSpeed);
	flTankSpeed[10] = GetConVarFloat(hShockSpeed);
	flTankSpeed[11] = GetConVarFloat(hWitchSpeed);
	flTankSpeed[12] = GetConVarFloat(hShieldSpeed);
	flTankSpeed[13] = GetConVarFloat(hCobaltSpeed);
	flTankSpeed[14] = GetConVarFloat(hJumperSpeed);
	flTankSpeed[15] = GetConVarFloat(hGravitySpeed);
	flTankSpeed[16] = 1.0;

	flTankThrow[0] = GetConVarFloat(hDefaultThrow);
	flTankThrow[1] = GetConVarFloat(hSmasherThrow);
	flTankThrow[2] = GetConVarFloat(hWarpThrow);
	flTankThrow[3] = GetConVarFloat(hMeteorThrow);
	flTankThrow[4] = GetConVarFloat(hSpitterThrow);
	flTankThrow[5] = GetConVarFloat(hHealThrow);
	flTankThrow[6] = GetConVarFloat(hFireThrow);
	flTankThrow[7] = GetConVarFloat(hIceThrow);
	flTankThrow[8] = GetConVarFloat(hJockeyThrow);
	flTankThrow[9] = GetConVarFloat(hGhostThrow);
	flTankThrow[10] = GetConVarFloat(hShockThrow);
	flTankThrow[11] = GetConVarFloat(hWitchThrow);
	flTankThrow[12] = GetConVarFloat(hShieldThrow);
	flTankThrow[13] = GetConVarFloat(hCobaltThrow);
	flTankThrow[14] = GetConVarFloat(hJumperThrow);
	flTankThrow[15] = GetConVarFloat(hGravityThrow);
	flTankThrow[16] = 999.0;

	bTankFireImmunity[0] = GetConVarBool(hDefaultFireImmunity);
	bTankFireImmunity[1] = GetConVarBool(hSmasherFireImmunity);
	bTankFireImmunity[2] = GetConVarBool(hWarpFireImmunity);
	bTankFireImmunity[3] = GetConVarBool(hMeteorFireImmunity);
	bTankFireImmunity[4] = GetConVarBool(hSpitterFireImmunity);
	bTankFireImmunity[5] = GetConVarBool(hHealFireImmunity);
	bTankFireImmunity[6] = GetConVarBool(hFireFireImmunity);
	bTankFireImmunity[7] = GetConVarBool(hIceFireImmunity);
	bTankFireImmunity[8] = GetConVarBool(hJockeyFireImmunity);
	bTankFireImmunity[9] = GetConVarBool(hGhostFireImmunity);
	bTankFireImmunity[10] = GetConVarBool(hShockFireImmunity);
	bTankFireImmunity[11] = GetConVarBool(hWitchFireImmunity);
	bTankFireImmunity[12] = GetConVarBool(hShieldFireImmunity);
	bTankFireImmunity[13] = GetConVarBool(hCobaltFireImmunity);
	bTankFireImmunity[14] = GetConVarBool(hJumperFireImmunity);
	bTankFireImmunity[15] = GetConVarBool(hGravityFireImmunity);
	bTankFireImmunity[16] = true;

	iSmasherMaimDamage = GetConVarInt(hSmasherMaimDamage);
	iSmasherCrushDamage = GetConVarInt(hSmasherCrushDamage);
	bSmasherRemoveBody = GetConVarBool(hSmasherRemoveBody);
	iWarpTeleportDelay = GetConVarInt(hWarpTeleportDelay);
	iMeteorStormDelay = GetConVarInt(hMeteorStormDelay);
	flMeteorStormDamage = GetConVarFloat(hMeteorStormDamage);
	iHealHealth = GetConVarInt(hHealHealth);
	bGhostDisarm = GetConVarBool(hGhostDisarm);
	iShockStunDamage = GetConVarInt(hShockStunDamage);
	flShockStunMovement = GetConVarFloat(hShockStunMovement);
	iWitchMaxWitches = GetConVarInt(hWitchMaxWitches);
	flShieldShieldsDownInterval = GetConVarFloat(hShieldShieldsDownInterval);
	flCobaltSpecialSpeed = GetConVarFloat(hCobaltSpecialSpeed);
	iJumperJumpDelay = GetConVarInt(hJumperJumpDelay);
	flGravityPullForce = GetConVarFloat(hGravityPullForce);
}

/**
 * Hook all ConVar change callbacks
 * Called after ConVars are created
 */
stock ST_Config_HookConVars()
{
	HookConVarChange(hSuperTanksEnabled, SuperTanksCvarChanged);
	HookConVarChange(hDisplayHealthCvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave1Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave2Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hWave3Cvar, SuperTanksSettingsChanged);
	HookConVarChange(hFinaleOnly, SuperTanksSettingsChanged);
	HookConVarChange(hDefaultTanks, SuperTanksSettingsChanged);
	HookConVarChange(hDefaultOverride, DefaultTanksSettingsChanged);
	HookConVarChange(hGamemodeCvar, GamemodeCvarChanged);

	HookConVarChange(hSmasherEnabled, TanksSettingsChanged);
	HookConVarChange(hWarpEnabled, TanksSettingsChanged);
	HookConVarChange(hMeteorEnabled, TanksSettingsChanged);
	HookConVarChange(hSpitterEnabled, TanksSettingsChanged);
	HookConVarChange(hHealEnabled, TanksSettingsChanged);
	HookConVarChange(hFireEnabled, TanksSettingsChanged);
	HookConVarChange(hIceEnabled, TanksSettingsChanged);
	HookConVarChange(hJockeyEnabled, TanksSettingsChanged);
	HookConVarChange(hGhostEnabled, TanksSettingsChanged);
	HookConVarChange(hShockEnabled, TanksSettingsChanged);
	HookConVarChange(hWitchEnabled, TanksSettingsChanged);
	HookConVarChange(hShieldEnabled, TanksSettingsChanged);
	HookConVarChange(hCobaltEnabled, TanksSettingsChanged);
	HookConVarChange(hJumperEnabled, TanksSettingsChanged);
	HookConVarChange(hGravityEnabled, TanksSettingsChanged);

	HookConVarChange(hDefaultExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSmasherExtraHealth, TanksSettingsChanged);
	HookConVarChange(hWarpExtraHealth, TanksSettingsChanged);
	HookConVarChange(hMeteorExtraHealth, TanksSettingsChanged);
	HookConVarChange(hSpitterExtraHealth, TanksSettingsChanged);
	HookConVarChange(hHealExtraHealth, TanksSettingsChanged);
	HookConVarChange(hFireExtraHealth, TanksSettingsChanged);
	HookConVarChange(hIceExtraHealth, TanksSettingsChanged);
	HookConVarChange(hJockeyExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGhostExtraHealth, TanksSettingsChanged);
	HookConVarChange(hShockExtraHealth, TanksSettingsChanged);
	HookConVarChange(hWitchExtraHealth, TanksSettingsChanged);
	HookConVarChange(hShieldExtraHealth, TanksSettingsChanged);
	HookConVarChange(hCobaltExtraHealth, TanksSettingsChanged);
	HookConVarChange(hJumperExtraHealth, TanksSettingsChanged);
	HookConVarChange(hGravityExtraHealth, TanksSettingsChanged);

	HookConVarChange(hDefaultSpeed, TanksSettingsChanged);
	HookConVarChange(hSmasherSpeed, TanksSettingsChanged);
	HookConVarChange(hWarpSpeed, TanksSettingsChanged);
	HookConVarChange(hMeteorSpeed, TanksSettingsChanged);
	HookConVarChange(hSpitterSpeed, TanksSettingsChanged);
	HookConVarChange(hHealSpeed, TanksSettingsChanged);
	HookConVarChange(hFireSpeed, TanksSettingsChanged);
	HookConVarChange(hIceSpeed, TanksSettingsChanged);
	HookConVarChange(hJockeySpeed, TanksSettingsChanged);
	HookConVarChange(hGhostSpeed, TanksSettingsChanged);
	HookConVarChange(hShockSpeed, TanksSettingsChanged);
	HookConVarChange(hWitchSpeed, TanksSettingsChanged);
	HookConVarChange(hShieldSpeed, TanksSettingsChanged);
	HookConVarChange(hCobaltSpeed, TanksSettingsChanged);
	HookConVarChange(hJumperSpeed, TanksSettingsChanged);
	HookConVarChange(hGravitySpeed, TanksSettingsChanged);

	HookConVarChange(hDefaultThrow, TanksSettingsChanged);
	HookConVarChange(hSmasherThrow, TanksSettingsChanged);
	HookConVarChange(hWarpThrow, TanksSettingsChanged);
	HookConVarChange(hMeteorThrow, TanksSettingsChanged);
	HookConVarChange(hSpitterThrow, TanksSettingsChanged);
	HookConVarChange(hHealThrow, TanksSettingsChanged);
	HookConVarChange(hFireThrow, TanksSettingsChanged);
	HookConVarChange(hIceThrow, TanksSettingsChanged);
	HookConVarChange(hJockeyThrow, TanksSettingsChanged);
	HookConVarChange(hGhostThrow, TanksSettingsChanged);
	HookConVarChange(hShockThrow, TanksSettingsChanged);
	HookConVarChange(hWitchThrow, TanksSettingsChanged);
	HookConVarChange(hShieldThrow, TanksSettingsChanged);
	HookConVarChange(hCobaltThrow, TanksSettingsChanged);
	HookConVarChange(hJumperThrow, TanksSettingsChanged);
	HookConVarChange(hGravityThrow, TanksSettingsChanged);

	HookConVarChange(hDefaultFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSmasherFireImmunity, TanksSettingsChanged);
	HookConVarChange(hWarpFireImmunity, TanksSettingsChanged);
	HookConVarChange(hMeteorFireImmunity, TanksSettingsChanged);
	HookConVarChange(hSpitterFireImmunity, TanksSettingsChanged);
	HookConVarChange(hHealFireImmunity, TanksSettingsChanged);
	HookConVarChange(hFireFireImmunity, TanksSettingsChanged);
	HookConVarChange(hIceFireImmunity, TanksSettingsChanged);
	HookConVarChange(hJockeyFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGhostFireImmunity, TanksSettingsChanged);
	HookConVarChange(hShockFireImmunity, TanksSettingsChanged);
	HookConVarChange(hWitchFireImmunity, TanksSettingsChanged);
	HookConVarChange(hShieldFireImmunity, TanksSettingsChanged);
	HookConVarChange(hCobaltFireImmunity, TanksSettingsChanged);
	HookConVarChange(hJumperFireImmunity, TanksSettingsChanged);
	HookConVarChange(hGravityFireImmunity, TanksSettingsChanged);

	HookConVarChange(hSmasherMaimDamage, TanksSettingsChanged);
	HookConVarChange(hSmasherCrushDamage, TanksSettingsChanged);
	HookConVarChange(hWarpTeleportDelay, TanksSettingsChanged);
	HookConVarChange(hMeteorStormDelay, TanksSettingsChanged);
	HookConVarChange(hMeteorStormDamage, TanksSettingsChanged);
	HookConVarChange(hHealHealth, TanksSettingsChanged);
	HookConVarChange(hGhostDisarm, TanksSettingsChanged);
	HookConVarChange(hShockStunDamage, TanksSettingsChanged);
	HookConVarChange(hShockStunMovement, TanksSettingsChanged);
	HookConVarChange(hWitchMaxWitches, TanksSettingsChanged);
	HookConVarChange(hShieldShieldsDownInterval, TanksSettingsChanged);
	HookConVarChange(hCobaltSpecialSpeed, TanksSettingsChanged);
	HookConVarChange(hJumperJumpDelay, TanksSettingsChanged);
	HookConVarChange(hGravityPullForce, TanksSettingsChanged);

	HookConVarChange(hNightmare, NightmareChanged);
	HookConVarChange(hNightmareBegin, NightmareBeginChanged);
}

// ============================================================================
// CONVAR CHANGE CALLBACKS
// ============================================================================

public GamemodeCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (bSuperTanksEnabled)
	{
		if (convar == hGamemodeCvar)
		{
			if (StrEqual(oldValue, newValue, false)) return;

			if (!StrEqual(newValue, "coop", false) && !StrEqual(newValue, "realism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarBool(hSuperTanksEnabled, false);
			}
		}
	}
}

public SuperTanksCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hSuperTanksEnabled)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);

		if (newval == oldval) return;

		if (newval == 1)
		{
			decl String:gamemode[24];
			GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
			if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarBool(hSuperTanksEnabled, false);
				bSuperTanksEnabled = false;
			}
			else bSuperTanksEnabled = true;
		}
		else bSuperTanksEnabled = false;
	}
}

public SuperTanksSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bDisplayHealthCvar = GetConVarBool(hDisplayHealthCvar);
	iWave1Cvar = GetConVarInt(hWave1Cvar);
	iWave2Cvar = GetConVarInt(hWave2Cvar);
	iWave3Cvar = GetConVarInt(hWave3Cvar);
	bFinaleOnly = GetConVarBool(hFinaleOnly);
	bDefaultTanks = GetConVarBool(hDefaultTanks);
}

public DefaultTanksSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hDefaultOverride)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);

		if (newval == oldval) return;

		if (newval == 0)
		{
			SetConVarInt(hDefaultExtraHealth, 0);
			SetConVarFloat(hDefaultSpeed, 1.0);
			SetConVarFloat(hDefaultThrow, 5.0);
			SetConVarBool(hDefaultFireImmunity, false);
		}
	}
	bDefaultOverride = GetConVarBool(hDefaultOverride);
}

public TanksSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bTankEnabled[1] = GetConVarBool(hSmasherEnabled);
	bTankEnabled[2] = GetConVarBool(hWarpEnabled);
	bTankEnabled[3] = GetConVarBool(hMeteorEnabled);
	bTankEnabled[4] = GetConVarBool(hSpitterEnabled);
	bTankEnabled[5] = GetConVarBool(hHealEnabled);
	bTankEnabled[6] = GetConVarBool(hFireEnabled);
	bTankEnabled[7] = GetConVarBool(hIceEnabled);
	bTankEnabled[8] = GetConVarBool(hJockeyEnabled);
	bTankEnabled[9] = GetConVarBool(hGhostEnabled);
	bTankEnabled[10] = GetConVarBool(hShockEnabled);
	bTankEnabled[11] = GetConVarBool(hWitchEnabled);
	bTankEnabled[12] = GetConVarBool(hShieldEnabled);
	bTankEnabled[13] = GetConVarBool(hCobaltEnabled);
	bTankEnabled[14] = GetConVarBool(hJumperEnabled);
	bTankEnabled[15] = GetConVarBool(hGravityEnabled);

	iTankExtraHealth[0] = GetConVarInt(hDefaultExtraHealth);
	iTankExtraHealth[1] = GetConVarInt(hSmasherExtraHealth);
	iTankExtraHealth[2] = GetConVarInt(hWarpExtraHealth);
	iTankExtraHealth[3] = GetConVarInt(hMeteorExtraHealth);
	iTankExtraHealth[4] = GetConVarInt(hSpitterExtraHealth);
	iTankExtraHealth[5] = GetConVarInt(hHealExtraHealth);
	iTankExtraHealth[6] = GetConVarInt(hFireExtraHealth);
	iTankExtraHealth[7] = GetConVarInt(hIceExtraHealth);
	iTankExtraHealth[8] = GetConVarInt(hJockeyExtraHealth);
	iTankExtraHealth[9] = GetConVarInt(hGhostExtraHealth);
	iTankExtraHealth[10] = GetConVarInt(hShockExtraHealth);
	iTankExtraHealth[11] = GetConVarInt(hWitchExtraHealth);
	iTankExtraHealth[12] = GetConVarInt(hShieldExtraHealth);
	iTankExtraHealth[13] = GetConVarInt(hCobaltExtraHealth);
	iTankExtraHealth[14] = GetConVarInt(hJumperExtraHealth);
	iTankExtraHealth[15] = GetConVarInt(hGravityExtraHealth);

	flTankSpeed[0] = GetConVarFloat(hDefaultSpeed);
	flTankSpeed[1] = GetConVarFloat(hSmasherSpeed);
	flTankSpeed[2] = GetConVarFloat(hWarpSpeed);
	flTankSpeed[3] = GetConVarFloat(hMeteorSpeed);
	flTankSpeed[4] = GetConVarFloat(hSpitterSpeed);
	flTankSpeed[5] = GetConVarFloat(hHealSpeed);
	flTankSpeed[6] = GetConVarFloat(hFireSpeed);
	flTankSpeed[7] = GetConVarFloat(hIceSpeed);
	flTankSpeed[8] = GetConVarFloat(hJockeySpeed);
	flTankSpeed[9] = GetConVarFloat(hGhostSpeed);
	flTankSpeed[10] = GetConVarFloat(hShockSpeed);
	flTankSpeed[11] = GetConVarFloat(hWitchSpeed);
	flTankSpeed[12] = GetConVarFloat(hShieldSpeed);
	flTankSpeed[13] = GetConVarFloat(hCobaltSpeed);
	flTankSpeed[14] = GetConVarFloat(hJumperSpeed);
	flTankSpeed[15] = GetConVarFloat(hGravitySpeed);

	flTankThrow[0] = GetConVarFloat(hDefaultThrow);
	flTankThrow[1] = GetConVarFloat(hSmasherThrow);
	flTankThrow[2] = GetConVarFloat(hWarpThrow);
	flTankThrow[3] = GetConVarFloat(hMeteorThrow);
	flTankThrow[4] = GetConVarFloat(hSpitterThrow);
	flTankThrow[5] = GetConVarFloat(hHealThrow);
	flTankThrow[6] = GetConVarFloat(hFireThrow);
	flTankThrow[7] = GetConVarFloat(hIceThrow);
	flTankThrow[8] = GetConVarFloat(hJockeyThrow);
	flTankThrow[9] = GetConVarFloat(hGhostThrow);
	flTankThrow[10] = GetConVarFloat(hShockThrow);
	flTankThrow[11] = GetConVarFloat(hWitchThrow);
	flTankThrow[12] = GetConVarFloat(hShieldThrow);
	flTankThrow[13] = GetConVarFloat(hCobaltThrow);
	flTankThrow[14] = GetConVarFloat(hJumperThrow);
	flTankThrow[15] = GetConVarFloat(hGravityThrow);

	bTankFireImmunity[0] = GetConVarBool(hDefaultFireImmunity);
	bTankFireImmunity[1] = GetConVarBool(hSmasherFireImmunity);
	bTankFireImmunity[2] = GetConVarBool(hWarpFireImmunity);
	bTankFireImmunity[3] = GetConVarBool(hMeteorFireImmunity);
	bTankFireImmunity[4] = GetConVarBool(hSpitterFireImmunity);
	bTankFireImmunity[5] = GetConVarBool(hHealFireImmunity);
	bTankFireImmunity[6] = GetConVarBool(hFireFireImmunity);
	bTankFireImmunity[7] = GetConVarBool(hIceFireImmunity);
	bTankFireImmunity[8] = GetConVarBool(hJockeyFireImmunity);
	bTankFireImmunity[9] = GetConVarBool(hGhostFireImmunity);
	bTankFireImmunity[10] = GetConVarBool(hShockFireImmunity);
	bTankFireImmunity[11] = GetConVarBool(hWitchFireImmunity);
	bTankFireImmunity[12] = GetConVarBool(hShieldFireImmunity);
	bTankFireImmunity[13] = GetConVarBool(hCobaltFireImmunity);
	bTankFireImmunity[14] = GetConVarBool(hJumperFireImmunity);
	bTankFireImmunity[15] = GetConVarBool(hGravityFireImmunity);

	iSmasherMaimDamage = GetConVarInt(hSmasherMaimDamage);
	iSmasherCrushDamage = GetConVarInt(hSmasherCrushDamage);
	bSmasherRemoveBody = GetConVarBool(hSmasherRemoveBody);
	iWarpTeleportDelay = GetConVarInt(hWarpTeleportDelay);
	iMeteorStormDelay = GetConVarInt(hMeteorStormDelay);
	flMeteorStormDamage = GetConVarFloat(hMeteorStormDamage);
	iHealHealth = GetConVarInt(hHealHealth);
	bGhostDisarm = GetConVarBool(hGhostDisarm);
	iShockStunDamage = GetConVarInt(hShockStunDamage);
	flShockStunMovement = GetConVarFloat(hShockStunMovement);
	iWitchMaxWitches = GetConVarInt(hWitchMaxWitches);
	flShieldShieldsDownInterval = GetConVarFloat(hShieldShieldsDownInterval);
	flCobaltSpecialSpeed = GetConVarFloat(hCobaltSpecialSpeed);
	iJumperJumpDelay = GetConVarInt(hJumperJumpDelay);
	flGravityPullForce = GetConVarFloat(hGravityPullForce);
}

public NightmareChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hNightmare)
	{
		bNightmare = GetConVarBool(hNightmare);
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		if (oldval != newval)
		{
			if (newval == 0)
			{
				iNightmareTick = 0;
			}
			// Note: AutoDifficulty function should be implemented in nightmare module
			// AutoDifficulty(true);
		}
	}
}

public NightmareBeginChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hNightmareBegin)
	{
		iNightmareBegin = GetConVarInt(hNightmareBegin);
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		if (oldval != newval)
		{
			if (newval == 0 || newval == -1)
			{
				iNightmareTick = 0;
				SetConVarBool(hNightmare, false);
			}
			else
			{
				// Note: StartCountdown function should be implemented in nightmare module
				// StartCountdown();
			}
		}
	}
}
