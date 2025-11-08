#if defined _st_variables_included
 #endinput
#endif
#define _st_variables_included

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

// Finale State
new bool:bIsFinale = false;

// Weapon classnames array
#pragma unused WeaponClassname
new const String:WeaponClassname[][] =
{
	"0", //0
	"weapon_pipe_bomb",
	"weapon_molotov",
	"weapon_vomitjar", //1-3
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary", //4-7
	"weapon_pain_pills",
	"weapon_adrenaline", //8-9
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_chainsaw",
	"weapon_fireaxe",
	"weapon_frying_pan",
	"weapon_machete",
	"weapon_baseball_bat",
	"weapon_crowbar",
	"weapon_cricket_bat",
	"weapon_tonfa",
	"weapon_katana",
	"weapon_electric_guitar",
	"weapon_knife",
	"weapon_golfclub", //10-23
	"weapon_pumpshotgun",
	"weapon_autoshotgun",
	"weapon_rifle",
	"weapon_smg",
	"weapon_hunting_rifle",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_shotgun_chrome",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_grenade_launcher",
	"weapon_rifle_m60", //24-40
	"weapon_gascan",
	"weapon_propanetank",
	"weapon_oxygentank",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_fireworkcrate", //41-46
	"weapon_melee" //polymorph
};

// ============================================================================
// CONVAR HANDLES
// ============================================================================

// Core ConVars
new Handle:hSuperTanksEnabled = INVALID_HANDLE;
new Handle:hDisplayHealthCvar = INVALID_HANDLE;
new Handle:hWave1Cvar = INVALID_HANDLE;
new Handle:hWave2Cvar = INVALID_HANDLE;
new Handle:hWave3Cvar = INVALID_HANDLE;
new Handle:hFinaleOnly = INVALID_HANDLE;
new Handle:hDefaultTanks = INVALID_HANDLE;
new Handle:hGamemodeCvar = INVALID_HANDLE;

// Default Tank ConVars
new Handle:hDefaultOverride = INVALID_HANDLE;
new Handle:hDefaultExtraHealth = INVALID_HANDLE;
new Handle:hDefaultSpeed = INVALID_HANDLE;
new Handle:hDefaultThrow = INVALID_HANDLE;
new Handle:hDefaultFireImmunity = INVALID_HANDLE;

// Smasher Tank ConVars
new Handle:hSmasherEnabled = INVALID_HANDLE;
new Handle:hSmasherExtraHealth = INVALID_HANDLE;
new Handle:hSmasherSpeed = INVALID_HANDLE;
new Handle:hSmasherThrow = INVALID_HANDLE;
new Handle:hSmasherFireImmunity = INVALID_HANDLE;
new Handle:hSmasherMaimDamage = INVALID_HANDLE;
new Handle:hSmasherCrushDamage = INVALID_HANDLE;
new Handle:hSmasherRemoveBody = INVALID_HANDLE;

// Warp Tank ConVars
new Handle:hWarpEnabled = INVALID_HANDLE;
new Handle:hWarpExtraHealth = INVALID_HANDLE;
new Handle:hWarpSpeed = INVALID_HANDLE;
new Handle:hWarpThrow = INVALID_HANDLE;
new Handle:hWarpFireImmunity = INVALID_HANDLE;
new Handle:hWarpTeleportDelay = INVALID_HANDLE;

// Meteor Tank ConVars
new Handle:hMeteorEnabled = INVALID_HANDLE;
new Handle:hMeteorExtraHealth = INVALID_HANDLE;
new Handle:hMeteorSpeed = INVALID_HANDLE;
new Handle:hMeteorThrow = INVALID_HANDLE;
new Handle:hMeteorFireImmunity = INVALID_HANDLE;
new Handle:hMeteorStormDelay = INVALID_HANDLE;
new Handle:hMeteorStormDamage = INVALID_HANDLE;

// Spitter Tank ConVars
new Handle:hSpitterEnabled = INVALID_HANDLE;
new Handle:hSpitterExtraHealth = INVALID_HANDLE;
new Handle:hSpitterSpeed = INVALID_HANDLE;
new Handle:hSpitterThrow = INVALID_HANDLE;
new Handle:hSpitterFireImmunity = INVALID_HANDLE;

// Heal Tank ConVars
new Handle:hHealEnabled = INVALID_HANDLE;
new Handle:hHealExtraHealth = INVALID_HANDLE;
new Handle:hHealSpeed = INVALID_HANDLE;
new Handle:hHealThrow = INVALID_HANDLE;
new Handle:hHealFireImmunity = INVALID_HANDLE;
new Handle:hHealHealth = INVALID_HANDLE;

// Fire Tank ConVars
new Handle:hFireEnabled = INVALID_HANDLE;
new Handle:hFireExtraHealth = INVALID_HANDLE;
new Handle:hFireSpeed = INVALID_HANDLE;
new Handle:hFireThrow = INVALID_HANDLE;
new Handle:hFireFireImmunity = INVALID_HANDLE;

// Ice Tank ConVars
new Handle:hIceEnabled = INVALID_HANDLE;
new Handle:hIceExtraHealth = INVALID_HANDLE;
new Handle:hIceSpeed = INVALID_HANDLE;
new Handle:hIceThrow = INVALID_HANDLE;
new Handle:hIceFireImmunity = INVALID_HANDLE;

// Jockey Tank ConVars
new Handle:hJockeyEnabled = INVALID_HANDLE;
new Handle:hJockeyExtraHealth = INVALID_HANDLE;
new Handle:hJockeySpeed = INVALID_HANDLE;
new Handle:hJockeyThrow = INVALID_HANDLE;
new Handle:hJockeyFireImmunity = INVALID_HANDLE;

// Ghost Tank ConVars
new Handle:hGhostEnabled = INVALID_HANDLE;
new Handle:hGhostExtraHealth = INVALID_HANDLE;
new Handle:hGhostSpeed = INVALID_HANDLE;
new Handle:hGhostThrow = INVALID_HANDLE;
new Handle:hGhostFireImmunity = INVALID_HANDLE;
new Handle:hGhostDisarm = INVALID_HANDLE;

// Shock Tank ConVars
new Handle:hShockEnabled = INVALID_HANDLE;
new Handle:hShockExtraHealth = INVALID_HANDLE;
new Handle:hShockSpeed = INVALID_HANDLE;
new Handle:hShockThrow = INVALID_HANDLE;
new Handle:hShockFireImmunity = INVALID_HANDLE;
new Handle:hShockStunDamage = INVALID_HANDLE;
new Handle:hShockStunMovement = INVALID_HANDLE;

// Witch Tank ConVars
new Handle:hWitchEnabled = INVALID_HANDLE;
new Handle:hWitchExtraHealth = INVALID_HANDLE;
new Handle:hWitchSpeed = INVALID_HANDLE;
new Handle:hWitchThrow = INVALID_HANDLE;
new Handle:hWitchFireImmunity = INVALID_HANDLE;
new Handle:hWitchMaxWitches = INVALID_HANDLE;

// Shield Tank ConVars
new Handle:hShieldEnabled = INVALID_HANDLE;
new Handle:hShieldExtraHealth = INVALID_HANDLE;
new Handle:hShieldSpeed = INVALID_HANDLE;
new Handle:hShieldThrow = INVALID_HANDLE;
new Handle:hShieldFireImmunity = INVALID_HANDLE;
new Handle:hShieldShieldsDownInterval = INVALID_HANDLE;

// Cobalt Tank ConVars
new Handle:hCobaltEnabled = INVALID_HANDLE;
new Handle:hCobaltExtraHealth = INVALID_HANDLE;
new Handle:hCobaltSpeed = INVALID_HANDLE;
new Handle:hCobaltThrow = INVALID_HANDLE;
new Handle:hCobaltFireImmunity = INVALID_HANDLE;
new Handle:hCobaltSpecialSpeed = INVALID_HANDLE;

// Jumper Tank ConVars
new Handle:hJumperEnabled = INVALID_HANDLE;
new Handle:hJumperExtraHealth = INVALID_HANDLE;
new Handle:hJumperSpeed = INVALID_HANDLE;
new Handle:hJumperThrow = INVALID_HANDLE;
new Handle:hJumperFireImmunity = INVALID_HANDLE;
new Handle:hJumperJumpDelay = INVALID_HANDLE;

// Gravity Tank ConVars
new Handle:hGravityEnabled = INVALID_HANDLE;
new Handle:hGravityExtraHealth = INVALID_HANDLE;
new Handle:hGravitySpeed = INVALID_HANDLE;
new Handle:hGravityThrow = INVALID_HANDLE;
new Handle:hGravityFireImmunity = INVALID_HANDLE;
new Handle:hGravityPullForce = INVALID_HANDLE;

// Nightmare Mode ConVars
new Handle:hNightmare = INVALID_HANDLE;
new Handle:hNightmareBegin = INVALID_HANDLE;

// ============================================================================
// SDK HANDLES
// ============================================================================

new Handle:SDKSpitBurst = INVALID_HANDLE;
new Handle:SDKInfectedHitByVomitJar = INVALID_HANDLE;
new Handle:SDKIsMissionFinalMap = INVALID_HANDLE;

// ============================================================================
// PLUGIN STATE VARIABLES
// ============================================================================

new bool:bSuperTanksEnabled = true;
new bool:bNightmare = false;

// Core Settings
new iWave1Cvar;
new iWave2Cvar;
new iWave3Cvar;
#pragma unused bFinaleOnly
new bool:bFinaleOnly;
new bool:bDisplayHealthCvar;
new bool:bDefaultTanks;

// ============================================================================
// TANK CONFIGURATION ARRAYS
// ============================================================================

new bool:bTankEnabled[15+1];
new iTankExtraHealth[16+1];
new Float:flTankSpeed[16+1];
new Float:flTankThrow[16+1];
new bool:bTankFireImmunity[16+1];

// ============================================================================
// TANK-SPECIFIC CONFIGURATION VALUES
// ============================================================================

new bool:bDefaultOverride;
new iSmasherMaimDamage;
new iSmasherCrushDamage;
new bool:bSmasherRemoveBody;
new iWarpTeleportDelay;
new iMeteorStormDelay;
new Float:flMeteorStormDamage;
#pragma unused iHealHealth
new iHealHealth;
new bool:bGhostDisarm;
new iShockStunDamage;
new Float:flShockStunMovement;
new iWitchMaxWitches;
new Float:flShieldShieldsDownInterval;
new Float:flCobaltSpecialSpeed;
#pragma unused iJumperJumpDelay
new iJumperJumpDelay;
#pragma unused flGravityPullForce
new Float:flGravityPullForce;

// ============================================================================
// NIGHTMARE MODE VARIABLES
// ============================================================================

new iNightmareBegin;
new iSpecialMin;
new iSpecialMax;
new iSpecialAmount;
#pragma unused iDifficulty
new iDifficulty;
new iNightmareTick;
new iCountDownTimer;
new iSpawnBotTick;
new iFinaleStage;
new iNumTanks;
new iRound = 0;

// ============================================================================
// ENVIRONMENT VARIABLES
// ============================================================================

#pragma unused aFogStart
new Float:aFogStart[33];
#pragma unused aFogEnd
new Float:aFogEnd[33];
#pragma unused timeofday
new timeofday;
new iCCEnt;
#pragma unused iFogVolEnt
new iFogVolEnt;
#pragma unused iGameMode
new iGameMode;
#pragma unused iFogControl
new iFogControl;
#pragma unused iSRDoor
new iSRDoor;

// ============================================================================
// TANK-RELATED PLAYER ARRAYS
// ============================================================================

new PlayerSpeed[33];
new TankAbility[33];
new TankAlive[33];
new ShieldsUp[33];
new ShieldState[33];
new GravityClaw[33];
new Rock[33];
new TankAbilityTimer[33];

// ============================================================================
// MISCELLANEOUS
// ============================================================================

#pragma unused MODEL_DEFIB
new MODEL_DEFIB;
