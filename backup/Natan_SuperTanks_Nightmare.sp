#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/*
Super Tanks:
0)Normal
1)Smasher
2)Warp
3)Meteor
4)Spitter
5)Heal
6)Fire
7)Ice
8)Jockey
9)Ghost
10)Shock
11)Witch
12)Shield
13)Cobalt
14)Jumper
15)Gravity
16)Demon
*/

static const FFADE_IN = 0x0001;
static const FFADE_OUT = 0x0002;
static const FFADE_MODULATE = 0x0004;
static const FFADE_STAYOUT = 0x0008;
static const FFADE_PURGE = 0x0010;

static const String:MODEL_NICK[] 		= "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] 		= "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] 		= "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] 		= "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] 		= "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] 		= "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] 		= "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] 		= "models/survivors/survivor_manager.mdl";

static const String:MODEL_TANK_DLC3[] 		= "models/infected/hulk_dlc3.mdl";

static const String:MODEL_V_FIREAXE[] 		= "models/weapons/melee/v_fireaxe.mdl";
static const String:MODEL_V_FRYING_PAN[] 	= "models/weapons/melee/v_frying_pan.mdl";
static const String:MODEL_V_MACHETE[] 		= "models/weapons/melee/v_machete.mdl";
static const String:MODEL_V_BAT[] 		= "models/weapons/melee/v_bat.mdl";
static const String:MODEL_V_CROWBAR[] 		= "models/weapons/melee/v_crowbar.mdl";
static const String:MODEL_V_CRICKET_BAT[] 	= "models/weapons/melee/v_cricket_bat.mdl";
static const String:MODEL_V_TONFA[] 		= "models/weapons/melee/v_tonfa.mdl";
static const String:MODEL_V_KATANA[] 		= "models/weapons/melee/v_katana.mdl";
static const String:MODEL_V_ELECTRIC_GUITAR[] 	= "models/weapons/melee/v_electric_guitar.mdl";
static const String:MODEL_V_KNIFE[] 		= "models/v_models/v_knife_t.mdl";
static const String:MODEL_V_GOLFCLUB[] 		= "models/weapons/melee/v_golfclub.mdl";

static const String:MODEL_GASCAN[] 		= "models/props_junk/gascan001a.mdl";
static const String:MODEL_PROPANE[] 		= "models/props_junk/propanecanister001a.mdl";

static const String:PARTICLE_LS_BOLT[] 		= "storm_lightning_01_thin";
static const String:PARTICLE_SMOKE[] 		= "apc_wheel_smoke1";
static const String:PARTICLE_FIRE[] 		= "aircraft_destroy_fastFireTrail";
static const String:PARTICLE_WARP[] 		= "electrical_arc_01_system";
static const String:PARTICLE_SPIT[] 		= "spitter_areaofdenial_glow2";
static const String:PARTICLE_SPITPROJ[] 	= "spitter_projectile";
static const String:PARTICLE_ELEC[] 		= "electrical_arc_01_parent";
static const String:PARTICLE_BLOOD_EXPLODE[] 	= "boomer_explode_D";
static const String:PARTICLE_EXPLODE[] 		= "boomer_explode";
static const String:PARTICLE_METEOR[] 		= "smoke_medium_01";
static const String:PARTICLE_FLARE[] 		= "flare_burning";
static const String:PARTICLE_DEMON_SMOKE[] 	= "smoke_campfire";
//static const String:PARTICLE_DEMON_HEAT[] 	= "fire_medium_heatwave";


static bool:bIsFinale		= false;


static const String:WeaponClassname[][] =
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
static Handle:hSuperTanksEnabled = INVALID_HANDLE;
static Handle:hDisplayHealthCvar = INVALID_HANDLE;
static Handle:hWave1Cvar = INVALID_HANDLE;
static Handle:hWave2Cvar = INVALID_HANDLE;
static Handle:hWave3Cvar = INVALID_HANDLE;
static Handle:hFinaleOnly = INVALID_HANDLE;
static Handle:hDefaultTanks = INVALID_HANDLE;
static Handle:hGamemodeCvar = INVALID_HANDLE;

static Handle:hDefaultOverride = INVALID_HANDLE;
static Handle:hDefaultExtraHealth = INVALID_HANDLE;
static Handle:hDefaultSpeed = INVALID_HANDLE;
static Handle:hDefaultThrow = INVALID_HANDLE;
static Handle:hDefaultFireImmunity = INVALID_HANDLE;

static Handle:hSmasherEnabled = INVALID_HANDLE;
static Handle:hSmasherExtraHealth = INVALID_HANDLE;
static Handle:hSmasherSpeed = INVALID_HANDLE;
static Handle:hSmasherThrow = INVALID_HANDLE;
static Handle:hSmasherFireImmunity = INVALID_HANDLE;
static Handle:hSmasherMaimDamage = INVALID_HANDLE;
static Handle:hSmasherCrushDamage = INVALID_HANDLE;
static Handle:hSmasherRemoveBody = INVALID_HANDLE;

static Handle:hWarpEnabled = INVALID_HANDLE;
static Handle:hWarpExtraHealth = INVALID_HANDLE;
static Handle:hWarpSpeed = INVALID_HANDLE;
static Handle:hWarpThrow = INVALID_HANDLE;
static Handle:hWarpFireImmunity = INVALID_HANDLE;
static Handle:hWarpTeleportDelay = INVALID_HANDLE;

static Handle:hMeteorEnabled = INVALID_HANDLE;
static Handle:hMeteorExtraHealth = INVALID_HANDLE;
static Handle:hMeteorSpeed = INVALID_HANDLE;
static Handle:hMeteorThrow = INVALID_HANDLE;
static Handle:hMeteorFireImmunity = INVALID_HANDLE;
static Handle:hMeteorStormDelay = INVALID_HANDLE;
static Handle:hMeteorStormDamage = INVALID_HANDLE;

static Handle:hSpitterEnabled = INVALID_HANDLE;
static Handle:hSpitterExtraHealth = INVALID_HANDLE;
static Handle:hSpitterSpeed = INVALID_HANDLE;
static Handle:hSpitterThrow = INVALID_HANDLE;
static Handle:hSpitterFireImmunity = INVALID_HANDLE;

static Handle:hHealEnabled = INVALID_HANDLE;
static Handle:hHealExtraHealth = INVALID_HANDLE;
static Handle:hHealSpeed = INVALID_HANDLE;
static Handle:hHealThrow = INVALID_HANDLE;
static Handle:hHealFireImmunity = INVALID_HANDLE;
static Handle:hHealHealth = INVALID_HANDLE;

static Handle:hFireEnabled = INVALID_HANDLE;
static Handle:hFireExtraHealth = INVALID_HANDLE;
static Handle:hFireSpeed = INVALID_HANDLE;
static Handle:hFireThrow = INVALID_HANDLE;
static Handle:hFireFireImmunity = INVALID_HANDLE;

static Handle:hIceEnabled = INVALID_HANDLE;
static Handle:hIceExtraHealth = INVALID_HANDLE;
static Handle:hIceSpeed = INVALID_HANDLE;
static Handle:hIceThrow = INVALID_HANDLE;
static Handle:hIceFireImmunity = INVALID_HANDLE;

static Handle:hJockeyEnabled = INVALID_HANDLE;
static Handle:hJockeyExtraHealth = INVALID_HANDLE;
static Handle:hJockeySpeed = INVALID_HANDLE;
static Handle:hJockeyThrow = INVALID_HANDLE;
static Handle:hJockeyFireImmunity = INVALID_HANDLE;

static Handle:hGhostEnabled = INVALID_HANDLE;
static Handle:hGhostExtraHealth = INVALID_HANDLE;
static Handle:hGhostSpeed = INVALID_HANDLE;
static Handle:hGhostThrow = INVALID_HANDLE;
static Handle:hGhostFireImmunity = INVALID_HANDLE;
static Handle:hGhostDisarm = INVALID_HANDLE;

static Handle:hShockEnabled = INVALID_HANDLE;
static Handle:hShockExtraHealth = INVALID_HANDLE;
static Handle:hShockSpeed = INVALID_HANDLE;
static Handle:hShockThrow = INVALID_HANDLE;
static Handle:hShockFireImmunity = INVALID_HANDLE;
static Handle:hShockStunDamage = INVALID_HANDLE;
static Handle:hShockStunMovement = INVALID_HANDLE;

static Handle:hWitchEnabled = INVALID_HANDLE;
static Handle:hWitchExtraHealth = INVALID_HANDLE;
static Handle:hWitchSpeed = INVALID_HANDLE;
static Handle:hWitchThrow = INVALID_HANDLE;
static Handle:hWitchFireImmunity = INVALID_HANDLE;
static Handle:hWitchMaxWitches = INVALID_HANDLE;

static Handle:hShieldEnabled = INVALID_HANDLE;
static Handle:hShieldExtraHealth = INVALID_HANDLE;
static Handle:hShieldSpeed = INVALID_HANDLE;
static Handle:hShieldThrow = INVALID_HANDLE;
static Handle:hShieldFireImmunity = INVALID_HANDLE;
static Handle:hShieldShieldsDownInterval = INVALID_HANDLE;

static Handle:hCobaltEnabled = INVALID_HANDLE;
static Handle:hCobaltExtraHealth = INVALID_HANDLE;
static Handle:hCobaltSpeed = INVALID_HANDLE;
static Handle:hCobaltThrow = INVALID_HANDLE;
static Handle:hCobaltFireImmunity = INVALID_HANDLE;
static Handle:hCobaltSpecialSpeed = INVALID_HANDLE;

static Handle:hJumperEnabled = INVALID_HANDLE;
static Handle:hJumperExtraHealth = INVALID_HANDLE;
static Handle:hJumperSpeed = INVALID_HANDLE;
static Handle:hJumperThrow = INVALID_HANDLE;
static Handle:hJumperFireImmunity = INVALID_HANDLE;
static Handle:hJumperJumpDelay = INVALID_HANDLE;

static Handle:hGravityEnabled = INVALID_HANDLE;
static Handle:hGravityExtraHealth = INVALID_HANDLE;
static Handle:hGravitySpeed = INVALID_HANDLE;
static Handle:hGravityThrow = INVALID_HANDLE;
static Handle:hGravityFireImmunity = INVALID_HANDLE;
static Handle:hGravityPullForce = INVALID_HANDLE;

static Handle:hNightmare                = INVALID_HANDLE;
static Handle:hNightmareBegin           = INVALID_HANDLE;

static Handle:SDKSpitBurst 		= INVALID_HANDLE;
static Handle:SDKInfectedHitByVomitJar 	= INVALID_HANDLE;
static Handle:SDKIsMissionFinalMap	= INVALID_HANDLE;

static bool:bSuperTanksEnabled		= true;
static bool:bNightmare			= false;

static iWave1Cvar;
static iWave2Cvar;
static iWave3Cvar;
static bool:bFinaleOnly;
static bool:bDisplayHealthCvar;
static bool:bDefaultTanks;

static bool:bTankEnabled[15+1];
static iTankExtraHealth[16+1];
static Float:flTankSpeed[16+1];
static Float:flTankThrow[16+1];
static bool:bTankFireImmunity[16+1];

static bool:bDefaultOverride;
static iSmasherMaimDamage;
static iSmasherCrushDamage;
static bool:bSmasherRemoveBody;
static iWarpTeleportDelay;
static iMeteorStormDelay;
static Float:flMeteorStormDamage;
static iHealHealth;
static bool:bGhostDisarm;
static iShockStunDamage;
static Float:flShockStunMovement;
static iWitchMaxWitches;
static Float:flShieldShieldsDownInterval;
static Float:flCobaltSpecialSpeed;
static iJumperJumpDelay;
static Float:flGravityPullForce;

static iNightmareBegin;
static iSpecialMin;
static iSpecialMax;
static iSpecialAmount;
static iDifficulty;
static iNightmareTick;
static iCountDownTimer;
static iSpawnBotTick;
static iFinaleStage;
static iNumTanks;
static iRound = 0;

static Float:aFogStart[33];
static Float:aFogEnd[33];
static timeofday;
static iCCEnt;
static iFogVolEnt;
static iGameMode;
static iFogControl;
static iSRDoor;

//Tank Related
static PlayerSpeed[33];
static TankAbility[33];
static TankAlive[33];
static ShieldsUp[33];
static ShieldState[33];
static GravityClaw[33];
static Rock[33];
static TankAbilityTimer[33];

//Misc
static MODEL_DEFIB;

public OnPluginStart()
{
	RegAdminCmd("sm_nightmare", Command_Nightmare, ADMFLAG_ROOT, "Nightmare Gamemode On/Off");

	hSuperTanksEnabled = CreateConVar("st_on", "1", "Is Super Tanks enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hDisplayHealthCvar = CreateConVar("st_display_health", "1", "Display tanks health in crosshair?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hWave1Cvar = CreateConVar("st_wave1_tanks", "1", "Default number of tanks in the 1st wave of finale.",FCVAR_NOTIFY,true,0.0,true,5.0);
	hWave2Cvar = CreateConVar("st_wave2_tanks", "2", "Default number of tanks in the 2nd wave of finale.",FCVAR_NOTIFY,true,0.0,true,5.0);
	hWave3Cvar = CreateConVar("st_wave3_tanks", "3", "Default number of tanks in the finale escape.",FCVAR_NOTIFY,true,0.0,true,5.0);
	hFinaleOnly = CreateConVar("st_finale_only", "0", "Create Super Tanks in finale only?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hDefaultTanks = CreateConVar("st_default_tanks", "0", "Only use default tanks?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hGamemodeCvar = FindConVar("mp_gamemode");


	hDefaultOverride = CreateConVar("st_default_override", "0", "Setting this to 1 will allow further customization to default tanks.",FCVAR_NOTIFY,true,0.0,true,1.0);
	hDefaultExtraHealth = CreateConVar("st_default_extra_health", "0", "Default Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hDefaultSpeed = CreateConVar("st_default_speed", "1.0", "Default Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hDefaultThrow = CreateConVar("st_default_throw", "5.0", "Default Tanks rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hDefaultFireImmunity = CreateConVar("st_default_fire_immunity", "0", "Are Default Tanks immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hSmasherEnabled = CreateConVar("st_smasher", "1", "Is Smasher Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hSmasherExtraHealth = CreateConVar("st_smasher_extra_health", "0", "Smasher Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hSmasherSpeed = CreateConVar("st_smasher_speed", "0.65", "Smasher Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hSmasherThrow = CreateConVar("st_smasher_throw", "30.0", "Smasher Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hSmasherFireImmunity = CreateConVar("st_smasher_fire_immunity", "0", "Is Smasher Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hSmasherMaimDamage = CreateConVar("st_smasher_maim_damage", "1", "Smasher Tanks maim attack will set victims health to this amount.",FCVAR_NOTIFY,true,1.0,true,99.0);
	hSmasherCrushDamage = CreateConVar("st_smasher_crush_damage", "300", "Smasher Tanks claw attack damage.",FCVAR_NOTIFY,true,0.0,true,1000.0);
	hSmasherRemoveBody = CreateConVar("st_smasher_remove_body", "1", "Smasher Tanks crush attack will remove survivors death body?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hWarpEnabled = CreateConVar("st_warp", "1", "Is Warp Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hWarpExtraHealth = CreateConVar("st_warp_extra_health", "0", "Warp Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hWarpSpeed = CreateConVar("st_warp_speed", "1.0", "Warp Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hWarpThrow = CreateConVar("st_warp_throw", "9.0", "Warp Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hWarpFireImmunity = CreateConVar("st_warp_fire_immunity", "1", "Is Warp Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hWarpTeleportDelay = CreateConVar("st_warp_teleport_delay", "20", "Warp Tanks Teleport Delay Interval.",FCVAR_NOTIFY,true,1.0,true,60.0);

	hMeteorEnabled = CreateConVar("st_meteor", "1", "Is Meteor Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hMeteorExtraHealth = CreateConVar("st_meteor_extra_health", "0", "Meteor Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hMeteorSpeed = CreateConVar("st_meteor_speed", "1.0", "Meteor Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hMeteorThrow = CreateConVar("st_meteor_throw", "10.0", "Meteor Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hMeteorFireImmunity = CreateConVar("st_meteor_fire_immunity", "1", "Is Meteor Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hMeteorStormDelay = CreateConVar("st_meteor_storm_delay", "30", "Meteor Tanks Meteor Storm Delay Interval.",FCVAR_NOTIFY,true,1.0,true,60.0);
	hMeteorStormDamage = CreateConVar("st_meteor_storm_damage", "25.0", "Meteor Tanks falling meteor damage.",FCVAR_NOTIFY,true,0.0,true,1000.0);

	hSpitterEnabled = CreateConVar("st_spitter", "1", "Is Spitter Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hSpitterExtraHealth = CreateConVar("st_spitter_extra_health", "0", "Spitter Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hSpitterSpeed = CreateConVar("st_spitter_speed", "1.0", "Spitter Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hSpitterThrow = CreateConVar("st_spitter_throw", "6.0", "Spitter Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hSpitterFireImmunity = CreateConVar("st_spitter_fire_immunity", "1", "Is Spitter Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hHealEnabled = CreateConVar("st_heal", "1", "Is Heal Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hHealExtraHealth = CreateConVar("st_heal_extra_health", "0", "Heal Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hHealSpeed = CreateConVar("st_heal_speed", "1.0", "Heal Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hHealThrow = CreateConVar("st_heal_throw", "15.0", "Heal Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hHealFireImmunity = CreateConVar("st_heal_fire_immunity", "1", "Is Heal Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hHealHealth = CreateConVar("st_heal_health", "25", "Heal Tanks receive this much health per frame when near a survivor",FCVAR_NOTIFY,true,0.0,true,1000.0);

	hFireEnabled = CreateConVar("st_fire", "1", "Is Fire Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hFireExtraHealth = CreateConVar("st_fire_extra_health", "0", "Fire Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hFireSpeed = CreateConVar("st_fire_speed", "1.0", "Fire Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hFireThrow = CreateConVar("st_fire_throw", "6.0", "Fire Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hFireFireImmunity = CreateConVar("st_fire_fire_immunity", "1", "Is Fire Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hIceEnabled = CreateConVar("st_ice", "1", "Is Ice Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hIceExtraHealth = CreateConVar("st_ice_extra_health", "0", "Ice Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hIceSpeed = CreateConVar("st_ice_speed", "1.0", "Ice Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hIceThrow = CreateConVar("st_ice_throw", "6.0", "Ice Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hIceFireImmunity = CreateConVar("st_ice_fire_immunity", "1", "Is Ice Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hJockeyEnabled = CreateConVar("st_jockey", "1", "Is Jockey Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hJockeyExtraHealth = CreateConVar("st_jockey_extra_health", "0", "Jockey Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hJockeySpeed = CreateConVar("st_jockey_speed", "1.33", "Jockey Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hJockeyThrow = CreateConVar("st_jockey_throw", "7.0", "Jockey Tank jockey throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hJockeyFireImmunity = CreateConVar("st_jockey_fire_immunity", "1", "Is Jockey Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hGhostEnabled = CreateConVar("st_ghost", "1", "Is Ghost Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hGhostExtraHealth = CreateConVar("st_ghost_extra_health", "0", "Ghost Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hGhostSpeed = CreateConVar("st_ghost_speed", "1.0", "Ghost Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hGhostThrow = CreateConVar("st_ghost_throw", "15.0", "Ghost Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hGhostFireImmunity = CreateConVar("st_ghost_fire_immunity", "1", "Is Ghost Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hGhostDisarm = CreateConVar("st_ghost_disarm", "1", "Does Ghost Tank have a chance of disarming an attacking melee survivor?",FCVAR_NOTIFY,true,0.0,true,1.0);

	hShockEnabled = CreateConVar("st_shock", "1", "Is Shock Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hShockExtraHealth = CreateConVar("st_shock_extra_health", "0", "Shock Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hShockSpeed = CreateConVar("st_shock_speed", "1.0", "Shock Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hShockThrow = CreateConVar("st_shock_throw", "10.0", "Shock Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hShockFireImmunity = CreateConVar("st_shock_fire_immunity", "1", "Is Shock Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hShockStunDamage = CreateConVar("st_shock_stun_damage", "12", "Shock Tanks stun damage.",FCVAR_NOTIFY,true,0.0,true,1000.0);
	hShockStunMovement = CreateConVar("st_shock_stun_movement", "0.75", "Shock Tanks stun reduce survivors speed to this amount.",FCVAR_NOTIFY,true,0.0,true,1.0);

	hWitchEnabled = CreateConVar("st_witch", "1", "Is Witch Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hWitchExtraHealth = CreateConVar("st_witch_extra_health", "0", "Witch Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hWitchSpeed = CreateConVar("st_witch_speed", "1.0", "Witch Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hWitchThrow = CreateConVar("st_witch_throw", "7.0", "Witch Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hWitchFireImmunity = CreateConVar("st_witch_fire_immunity", "1", "Is Witch Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hWitchMaxWitches = CreateConVar("st_witch_max_witches", "30", "Maximum number of witches can be active from witch tank.",FCVAR_NOTIFY,true,0.0,true,100.0);

	hShieldEnabled = CreateConVar("st_shield", "1", "Is Shield Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hShieldExtraHealth = CreateConVar("st_shield_extra_health", "0", "Shield Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hShieldSpeed = CreateConVar("st_shield_speed", "1.0", "Shield Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hShieldThrow = CreateConVar("st_shield_throw", "8.0", "Shield Tank propane throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hShieldFireImmunity = CreateConVar("st_shield_fire_immunity", "1", "Is Shield Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hShieldShieldsDownInterval = CreateConVar("st_shield_shields_down_interval", "8.0", "When Shield Tanks shields are disabled, how long before shields activate again.",FCVAR_NOTIFY,true,0.1,true,60.0);

	hCobaltEnabled = CreateConVar("st_cobalt", "1", "Is Cobalt Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hCobaltExtraHealth = CreateConVar("st_cobalt_extra_health", "0", "Cobalt Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hCobaltSpeed = CreateConVar("st_cobalt_speed", "1.0", "Cobalt Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hCobaltThrow = CreateConVar("st_cobalt_throw", "999.0", "Cobalt Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hCobaltFireImmunity = CreateConVar("st_cobalt_fire_immunity", "1", "Is Cobalt Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hCobaltSpecialSpeed = CreateConVar("st_cobalt_Special_speed", "2.5", "Cobalt Tanks movement value when speeding towards a survivor.",FCVAR_NOTIFY,true,1.0,true,5.0);

	hJumperEnabled = CreateConVar("st_jumper", "1", "Is Jumper Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hJumperExtraHealth = CreateConVar("st_jumper_extra_health", "0", "Jumper Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hJumperSpeed = CreateConVar("st_jumper_speed", "1.20", "Jumper Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hJumperThrow = CreateConVar("st_jumper_throw", "999.0", "Jumper Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hJumperFireImmunity = CreateConVar("st_jumper_fire_immunity", "1", "Is Jumper Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hJumperJumpDelay = CreateConVar("st_jumper_jump_delay", "3", "Jumper Tanks delay interval to jump again.",FCVAR_NOTIFY,true,1.0,true,60.0);

	hGravityEnabled = CreateConVar("st_gravity", "1", "Is Gravity Tank Enabled?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hGravityExtraHealth = CreateConVar("st_gravity_extra_health", "0", "Gravity Tanks receive this many additional hitpoints.",FCVAR_NOTIFY,true,0.0,true,100000.0);
	hGravitySpeed = CreateConVar("st_gravity_speed", "1.0", "Gravity Tanks default movement speed.",FCVAR_NOTIFY,true,0.0,true,2.0);
	hGravityThrow = CreateConVar("st_gravity_throw", "10.0", "Gravity Tank rock throw ability interval.",FCVAR_NOTIFY,true,0.0,true,999.0);
	hGravityFireImmunity = CreateConVar("st_gravity_fire_immunity", "1", "Is Gravity Tank immune to fire?",FCVAR_NOTIFY,true,0.0,true,1.0);
	hGravityPullForce = CreateConVar("st_gravity_pull_force", "-50.0", "Gravity Tanks pull force value. Higher negative values equals greater pull forces.",FCVAR_NOTIFY,true,-200.0,true,0.0);

	hNightmare = CreateConVar("nightmare_on", "0", "Is nightmare gamemode enabled?", FCVAR_NONE, true, 0.0, true, 1.0);
	hNightmareBegin = CreateConVar("nightmare_begin", "0", "Begin nightmare mode countdown?", FCVAR_NONE, true, -1.0, true, 1.0);

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

	HookEvent("ability_use", Ability_Use);
	HookEvent("difficulty_changed", Difficulty_Changed);
	HookEvent("finale_escape_start", Finale_Escape_Start);
	HookEvent("finale_start", Finale_Start, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Finale_Vehicle_Leaving);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready);
	HookEvent("gauntlet_finale_start", Finale_Start);
	HookEvent("player_death", Player_Death);
	HookEvent("player_now_it", Player_Now_It);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_use", Player_Use);
	HookEvent("round_end", Round_End);
	HookEvent("round_start", Round_Start);

	LoadTranslations("common.phrases");

	CreateTimer(0.1, TimerUpdate01, _, TIMER_REPEAT);
	CreateTimer(1.0, TimerUpdate1, _, TIMER_REPEAT);
	
	InitSDKCalls();
	InitStartUp();

	AutoExecConfig(true, "SuperTanks");
}
//=============================
// StartUp
//=============================
InitStartUp()
{
	if (bSuperTanksEnabled)
	{
		decl String:gamemode[24];
		GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
       		if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false))
		{
			PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
			PrintToServer("[SuperTanks] Plugin Disabled.");
			SetConVarBool(hSuperTanksEnabled, false);		
		}
	}
}
InitSDKCalls()
{
	new Handle:ConfigFile = LoadGameConfigFile("supertanks");
	new Handle:MySDKCall = INVALID_HANDLE;

	/////////////
	//SpitBurst//
	/////////////
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CSpitterProjectile_Detonate");
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CSpitterProjectile_Detonate SDKCall");
	}
	SDKSpitBurst = CloneHandle(MySDKCall, SDKSpitBurst);

	/////////////////////////
	//InfectedHitByVomitJar//
	/////////////////////////
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize Infected_OnHitByVomitJar SDKCall");
	}
	SDKInfectedHitByVomitJar = CloneHandle(MySDKCall, SDKInfectedHitByVomitJar);

	//////////////////////
	//IsMissionFinalMap//
	//////////////////////
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "IsMissionFinalMap");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	MySDKCall = EndPrepSDKCall();
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize IsMissionFinalMap SDKCall");
	}
	SDKIsMissionFinalMap = CloneHandle(MySDKCall, SDKIsMissionFinalMap);

	CloseHandle(ConfigFile);
	CloseHandle(MySDKCall);
}
stock L4D2_SpitBurst(entity)
{
	SDKCall(SDKSpitBurst, entity);
}
stock L4D2_InfectedHitByVomitJar(victim, attacker)
{
	SDKCall(SDKInfectedHitByVomitJar, victim, attacker);
}
stock L4D2_IsMissionFinalMap()
{
	return SDKCall(SDKIsMissionFinalMap);
}
public OnMapStart()
{
	PrecacheParticle(PARTICLE_LS_BOLT);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);
	PrecacheParticle(PARTICLE_SPIT);
	PrecacheParticle(PARTICLE_ELEC);
	PrecacheParticle(PARTICLE_BLOOD_EXPLODE);
	PrecacheParticle(PARTICLE_EXPLODE);
	PrecacheParticle(PARTICLE_METEOR);


	PrecacheParticle(PARTICLE_FLARE);
	PrecacheParticle(PARTICLE_DEMON_SMOKE);
	//PrecacheParticle(PARTICLE_DEMON_HEAT);

   	CheckModelPreCache(MODEL_NICK);
   	CheckModelPreCache(MODEL_ROCHELLE);
   	CheckModelPreCache(MODEL_COACH);
   	CheckModelPreCache(MODEL_ELLIS);
   	CheckModelPreCache(MODEL_BILL);
    	CheckModelPreCache(MODEL_ZOEY);
    	CheckModelPreCache(MODEL_FRANCIS);
    	CheckModelPreCache(MODEL_LOUIS);

    	CheckModelPreCache(MODEL_TANK_DLC3);

    	CheckModelPreCache("models/infected/hulk.mdl");
    	CheckModelPreCache("models/infected/witch.mdl");
	CheckModelPreCache("models/infected/witch_bride.mdl");
   	CheckModelPreCache("models/infected/boomette.mdl");
    	CheckModelPreCache("models/infected/common_male_ceda.mdl");
    	CheckModelPreCache("models/infected/common_male_clown.mdl");
    	CheckModelPreCache("models/infected/common_male_mud.mdl");
    	CheckModelPreCache("models/infected/common_male_roadcrew.mdl");
    	CheckModelPreCache("models/infected/common_male_riot.mdl");
    	CheckModelPreCache("models/infected/common_male_fallen_survivor.mdl");
    	CheckModelPreCache("models/infected/common_male_jimmy.mdl");

	CheckModelPreCache(MODEL_V_FIREAXE);
	CheckModelPreCache(MODEL_V_FRYING_PAN);
	CheckModelPreCache(MODEL_V_MACHETE);
	CheckModelPreCache(MODEL_V_BAT);
	CheckModelPreCache(MODEL_V_CROWBAR);
	CheckModelPreCache(MODEL_V_CRICKET_BAT);
	CheckModelPreCache(MODEL_V_TONFA);
	CheckModelPreCache(MODEL_V_KATANA);
	CheckModelPreCache(MODEL_V_ELECTRIC_GUITAR);
	CheckModelPreCache(MODEL_V_GOLFCLUB);

	CheckModelPreCache(MODEL_GASCAN);
	CheckModelPreCache(MODEL_PROPANE);
	
    	CheckModelPreCache("models/props_vehicles/tire001c_car.mdl");
	CheckModelPreCache("models/props_unique/airport/atlas_break_ball.mdl");
    	CheckModelPreCache("models/props_debris/concrete_chunk01a.mdl");

	CheckSoundPreCache("ambient/ambience/rainscapes/rain/debris_05.wav");
	CheckSoundPreCache("ambient/fire/gascan_ignite1.wav");
	CheckSoundPreCache("ambient/energy/spark5.wav");
	CheckSoundPreCache("ambient/energy/spark6.wav");
	CheckSoundPreCache("ambient/energy/zap5.wav");
	CheckSoundPreCache("ambient/energy/zap6.wav");
	CheckSoundPreCache("ambient/energy/zap7.wav");
	CheckSoundPreCache("ambient/energy/zap8.wav");
	CheckSoundPreCache("ambient/energy/zap9.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_42.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_43.wav");
	CheckSoundPreCache("npc/mega_mob/mega_mob_incoming.wav");
	CheckSoundPreCache("player/charger/hit/charger_smash_02.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_01.wav");
	CheckSoundPreCache("player/spitter/voice/warn/spitter_spit_02.wav");
	CheckSoundPreCache("player/boomer/explode/explo_medium_09.wav");
	CheckSoundPreCache("player/boomer/explode/explo_medium_10.wav");
	CheckSoundPreCache("player/boomer/explode/explo_medium_14.wav");
	CheckSoundPreCache("ui/beep22.wav");

	//Model Indexes
	MODEL_DEFIB = PrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl", true);

	ReturnChapterData();
	iFogControl = 0;
}
stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model:%s",Modelfile);
	}
}
stock CheckSoundPreCache(const String:Soundfile[])
{
	PrecacheSound(Soundfile, true);
	PrintToServer("Precaching Sound:%s",Soundfile);
}
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
			}	
		}
		bSuperTanksEnabled = GetConVarBool(hSuperTanksEnabled);
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
			AutoDifficulty(true);
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
				iNightmareTick = 0;
			}
			AutoDifficulty(true);
		}
	}
}
//=============================
//	EVENTS
//=============================
public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);

	if (!IsFakeClient(client))
	{
		ResetClientArrays(client);
	}
}
public Action:Ability_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (bSuperTanksEnabled)
	{
		if (IsTank(client))
		{
			new index = GetSuperTankByRenderColor(GetEntRenderColor(client));
			if (index >= 0 && index <= 16)
			{
				if (index != 0 || (index == 0 && bDefaultOverride))
				{
					ResetInfectedAbility(client, flTankThrow[index]);
				}
			}
		}
	}
}
public Action:Difficulty_Changed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	SetGameDifficulty();
	CreateTimer(0.1, AutoDiffTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Finale_Escape_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 3;
}
public Action:Finale_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 1;
}
public Action:Finale_Vehicle_Leaving(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 4;
}
public Action:Finale_Vehicle_Ready(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iFinaleStage = 3;
	if (bSuperTanksEnabled)
	{
		SetConVarInt(hNightmareBegin, 1);
	}
}
public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponused[16];
	GetEventString(event, "weapon", weaponused, sizeof(weaponused));
	if (bSuperTanksEnabled)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				if (GetClientTeam(client) == 2)
				{
					SetEntityMoveType(client, MOVETYPE_OBSERVER);
					new entity = -1;
					while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
					{
						new Float:Origin[3], Float:EOrigin[3];
						GetClientAbsOrigin(client, Origin);
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EOrigin);
						if (Origin[0] == EOrigin[0] && Origin[1] == EOrigin[1] && Origin[2] == EOrigin[2])
						{
							SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);
						}
					}
				}
				else if (GetClientTeam(client) == 3)
				{
					if (IsTank(client))
					{
						ExecTankDeath(client);
					}
				}
				SetEntityGravity(client, 1.0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			}
		}
	}
}
public Action:Player_Now_It(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        if (bSuperTanksEnabled)
        {
		if (attacker > 0 && client > 0)
		{
			if (IsTank(client) && GetEntRenderColor(client) == 100255200)
			{
				//disable healing ability for 20 secs
				TankAbilityTimer[client] = 20;
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_bFlashing", 0);
			}
		}
	}
}
public Action:Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (bSuperTanksEnabled)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				SetEntityGravity(client, 1.0);

				if (GetClientTeam(client) == 3)
				{
					decl String:classname[16];
					GetEntityNetClass(client, classname, sizeof(classname));
					if (StrEqual(classname, "Tank", false))
					{
						CountTanks();

						TankAlive[client] = 1;
						TankAbility[client] = 0;
						CreateTimer(0.1, TankSpawnTimer, client, TIMER_FLAG_NO_MAPCHANGE);

						if (bNightmare || !bFinaleOnly || (bFinaleOnly && iFinaleStage > 0))
						{
							RandomizeTank(client);
							switch(iFinaleStage)
							{
								case 1:
								{
									if (iNumTanks < iWave1Cvar)
									{
										CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (bNightmare && iNumTanks > 6)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
									else if (iNumTanks > iWave1Cvar)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
								}
								case 2:
								{
									if (iNumTanks < iWave2Cvar)
									{
										CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (bNightmare && iNumTanks > 6)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
									else if (iNumTanks > iWave2Cvar)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
								}
								case 3:
								{
									if (iNumTanks < iWave3Cvar)
									{
										CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (bNightmare && iNumTanks > 6)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
									else if (iNumTanks > iWave3Cvar)
									{
										if (IsFakeClient(client))
										{
											KickClient(client);
										}
									}
								}
							}
						}	
					}
				}
			}
		}
	}
}
public Action:Player_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "targetid");
	if (bSuperTanksEnabled)
	{
		if (entity == iSRDoor)
		{
			if (!bIsFinale && !bNightmare && iNightmareBegin == 0)
			{
				SetConVarInt(hNightmareBegin, 1);
			}		
		}
	}
}
public Action:Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSuperTanksEnabled)
	{
		KickAIBots();
	}
}
public Action:Round_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	iRound++;
	SetGameDifficulty();
	ResetVariables();
	IdentifySRDoor();

	if (bSuperTanksEnabled)
	{
		CloseSRDoor();
	}

	SetConVarInt(hNightmareBegin, 0);
	SetConVarBool(hNightmare, false);
		
	ResetClientArraysAll();
	AutoDifficulty(true);
}
//=============================
// TANK SPAWN RELATED
//=============================
stock RandomizeTank(client)
{
	if (!bDefaultTanks)
	{
		if (bNightmare)
		{
			//Demon
      	 		SetEntityRenderColor(client, 255, 150, 100, 255);
		}
		else
		{
			new count;
			new TempArray[15+1];

			for (new index=1; index<=15; index++)
			{
				if (bTankEnabled[index])
				{
					TempArray[count+1] = index;
					count++;	
				}
			}
			if (count > 0)
			{
				new random = GetRandomInt(1,count);
				new tankpick = TempArray[random];
				switch(tankpick)
				{
					case 1:
					{
						//Smasher
      	 					SetEntityRenderColor(client, 70, 80, 100, 255);
					}
					case 2:
					{
						//Warp
      	 					SetEntityRenderColor(client, 130, 130, 255, 255);
					}
					case 3:
					{
						//Meteor
      	 					SetEntityRenderColor(client, 100, 25, 25, 255);
					}
					case 4:
					{
						//Spitter
      	 					SetEntityRenderColor(client, 12, 115, 128, 255);
					}
					case 5:
					{
						//Heal
      	 					SetEntityRenderColor(client, 100, 255, 200, 255);
					}
					case 6:
					{
						//Fire
      	 					SetEntityRenderColor(client, 128, 0, 0, 255);
					}
					case 7:
					{
						//Ice
						SetEntityRenderMode(client, RenderMode:3);
      	 					SetEntityRenderColor(client, 0, 100, 170, 200);
					}
					case 8:
					{
						//Jockey
      	 					SetEntityRenderColor(client, 255, 200, 0, 255);
					}
					case 9:
					{
						//Ghost
						SetEntityRenderMode(client, RenderMode:3);
      	 					SetEntityRenderColor(client, 100, 100, 100, 0);
					}
					case 10:
					{
						//Shock
      	 					SetEntityRenderColor(client, 100, 165, 255, 255);
					}
					case 11:
					{
						//Witch
      	 					SetEntityRenderColor(client, 255, 200, 255, 255);
					}
					case 12:
					{
						//Shield
      	 					SetEntityRenderColor(client, 135, 205, 255, 255);
					}
					case 13:
					{
						//Cobalt
      	 					SetEntityRenderColor(client, 0, 105, 255, 255);
					}
					case 14:
					{
						//Jumper
      	 					SetEntityRenderColor(client, 200, 255, 0, 255);
					}
					case 15:
					{
						//Gravity
      	 					SetEntityRenderColor(client, 33, 34, 35, 255);
					}
				}
			}
		}
	}
}
public Action:TankSpawnTimer(Handle:timer, any:client)
{
	if (IsTank(client))
	{
		new index = GetSuperTankByRenderColor(GetEntRenderColor(client));
		if (index >= 0 && index <= 16)
		{
			if (index != 0 || (index == 0 && bDefaultOverride))
			{
				switch(index)
				{
					case 1:
					{
						SetEntProp(client, Prop_Send, "m_iGlowType", 3);
						new glowcolor = RGB_TO_INT(50, 50, 50);
						SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Smasher Tank");
						}
					}
					case 2:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Warp Tank");
						}
					}
					case 3:
					{
						CreateTimer(0.1, MeteorTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(6.0, Timer_AttachMETEOR, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Meteor Tank");
						}
					}
					case 4:
					{
						CreateTimer(2.0, Timer_AttachSPIT, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Spitter Tank");
						}
					}
					case 5:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Heal Tank");
						}
					}
					case 6:
					{
						CreateTimer(0.8, Timer_AttachFIRE,client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Fire Tank");
						}
					}
					case 7:
					{
						CreateTimer(2.0, Timer_AttachICE, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Ice Tank");
						}
					}
					case 8:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Jockey Tank");
						}
					}
					case 9:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Ghost Tank");
						}
					}
					case 10:
					{
						CreateTimer(0.8, Timer_AttachELEC, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Shock Tank");
						}
					}
					case 11:
					{
						CreateTimer(2.0, Timer_AttachBLOOD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Witch Tank");
						}
					}
					case 12:
					{
						if (ShieldsUp[client] == 0)
						{
							ActivateShield(client);
						}
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Shield Tank");
						}
					}
					case 13:
					{
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Cobalt Tank");
						}
					}
					case 14:
					{
						CreateTimer(0.1, JumperTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Jumper Tank");
						}
					}
					case 15:
					{
						CreateTimer(0.1, GravityTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Gravity Tank");
						}
					}
					case 16:
					{
						SetDemonTankHealth(client);
						CreateTimer(0.1, DemonTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
						if (IsFakeClient(client))
						{
							SetClientInfo(client, "name", "Demon Tank");
						}
					}
				}
				if (iTankExtraHealth[index] > 0)
				{
					new health = GetEntProp(client, Prop_Send, "m_iHealth");
					new maxhealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
					SetEntProp(client, Prop_Send, "m_iMaxHealth", maxhealth + iTankExtraHealth[index]);
					SetEntProp(client, Prop_Send, "m_iHealth", health + iTankExtraHealth[index]);
				}
				ResetInfectedAbility(client, flTankThrow[index]);
			}
		}
	}
}
//=============================
// TANK CONTROLLER
//=============================
public TankController()
{
	CountTanks();
	if (iNumTanks > 0)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsTank(i))
			{
				new index = GetSuperTankByRenderColor(GetEntRenderColor(i));
				if (index >= 0 && index <= 16)
				{
					if (index != 0 || (index == 0 && bDefaultOverride))
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", flTankSpeed[index]);
						switch(index)
						{
							case 1:
							{
								new glowcolor = RGB_TO_INT(50, 50, 50);
								SetEntProp(i, Prop_Send, "m_glowColorOverride", glowcolor);
								SetEntProp(i, Prop_Send, "m_iGlowType", 2);	
							}
							case 2:
							{
								TeleportTank(i);
							}
							case 3:
							{
								if (TankAbility[i] == 0)
								{
									new random = GetRandomInt(1,iMeteorStormDelay);
									if (random == 1)
									{
										StartMeteorFall(i);
									}
								}
							}
							case 4:
							{
								SpitterTankAbility(i);
							}
							case 5:
							{
								HulkTankAbility(i);
								if (TankAbilityTimer[i] > 0)
								{
									TankAbilityTimer[i] -= 1;
								}
							}
							case 6:
							{
								IgniteEntity(i, 1.0);
								FireTankAbility(i);
							}
							case 7:
							{
								IceTankAbility(i);
							}
							case 9:
							{
								InfectedCloak(i);
								if (CountSurvOutRange(i, 120) == CountSurvivorsAliveAll())
								{
									SetEntityRenderMode(i, RenderMode:3);
      	 								SetEntityRenderColor(i, 100, 100, 100, 50);
									EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i);
								}
								else
								{
									SetEntityRenderMode(i, RenderMode:3);
      	 								SetEntityRenderColor(i, 100, 100, 100, 150);
									EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i);
								}
								GhostTankAbility(i);
							}
							case 10:
							{
								ShockTankAbility(i);
							}
							case 11:
							{
								WitchTankAbility(i);
							}
							case 12:
							{
								ShieldState[i] -= 1;
								if (ShieldState[i] <= -60)
								{
									DeactivateShield(i, 30.0);
									ShieldState[i] = 0;
								}
								if (ShieldsUp[i] > 0)
								{
									new glowcolor = RGB_TO_INT(120, 90, 150);
									SetEntProp(i, Prop_Send, "m_iGlowType", 2);
									SetEntProp(i, Prop_Send, "m_bFlashing", 2);
									SetEntProp(i, Prop_Send, "m_glowColorOverride", glowcolor);
								}
								else
								{
									SetEntProp(i, Prop_Send, "m_iGlowType", 0);
									SetEntProp(i, Prop_Send, "m_bFlashing", 0);
									SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
								}
							}
							case 13:
							{
								if (TankAbility[i] == 0)
								{
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
									new random = GetRandomInt(1,9);
									if (random == 1)
									{
										TankAbility[i] = 1;
										CreateTimer(0.3, BlurEffect, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
									}
								}
								else if (TankAbility[i] == 1)
								{
									SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", flCobaltSpecialSpeed);
								}
							}
							case 15:
							{
								SetEntityGravity(i, 0.5);
							}
							case 16:
							{
								SetEntityGravity(i, 0.5);
							}
						}
						if (bTankFireImmunity[index])
						{
							if (IsPlayerBurning(i))
							{
								ExtinguishEntity(i);
								SetEntPropFloat(i, Prop_Send, "m_burnPercent", 1.0);
							}
						}
					}
				}		
			}
		}
	}
}
//=============================
//	TANK FUNCTIONS
//=============================
stock ExecTankDeath(client)
{
	TankAlive[client] = 0;
	TankAbility[client] = 0;

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		decl String:model[64];
            	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, "models/props_debris/concrete_chunk01a.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_vehicles/tire001c_car.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
			}
		}
		else if (StrEqual(model, "models/props_c17/substation_circuitbreaker03.mdl", false))
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	while ((entity = FindEntityByClassname(entity, "beam_spotlight")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	while ((entity = FindEntityByClassname(entity, "point_push")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	while ((entity = FindEntityByClassname(entity, "info_particle_system")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (owner == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	switch(iFinaleStage)
	{
		case 1: CreateTimer(5.0, TimerTankWave2, _, TIMER_FLAG_NO_MAPCHANGE);
		case 2: CreateTimer(5.0, TimerTankWave3, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
stock TeleportTank(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 130130255)
	{
		new random = GetRandomInt(1,iWarpTeleportDelay);
		if (random == 1)
		{
			new target = Pick();
			if (target)
			{
				new Float:Origin[3], Float:Angles[3];
				GetClientAbsOrigin(target, Origin);
                        	GetClientAbsAngles(target, Angles);
				CreateParticle(client, PARTICLE_WARP, 1.0, 0.0);
				TeleportEntity(client, Origin, Angles, NULL_VECTOR);
			}
		}
	}
}
stock InfectedCloak(client)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSpecialInfected(i))
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
      	 			SetEntityRenderColor(i, 255, 255, 255, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
      	 			SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}
}
stock bool:SurvInRange(client, target, targetDist)
{
	if (IsSurvivor(target) && IsPlayerAlive(target))
	{
		decl Float:TankPos[3], Float:PlayerPos[3];
                GetClientAbsOrigin(client, TankPos);
                GetClientAbsOrigin(target, PlayerPos);
                new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                if (distance <= targetDist)
		{
			return true;
		}
	}
	return false;
}
stock CountSurvInRange(client, targetDist)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			decl Float:TankPos[3], Float:PlayerPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, PlayerPos);
                       	new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                        if (distance <= targetDist)
			{
				count++;
			}
		}
	}
	return count;
}
stock CountSurvOutRange(client, targetDist)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			decl Float:TankPos[3], Float:PlayerPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, PlayerPos);
                       	new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                        if (distance > targetDist)
			{
				count++;
			}
		}
	}
	return count;
}
public Action:BlurEffect(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0105255 && TankAbility[client] == 1)
	{
		new Float:TankPos[3], Float:TankAng[3];
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, Prop_Send, "m_nSequence");
		new entity = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			SetEntityRenderColor(entity, 0, 105, 255, 255);
			SetEntProp(entity, Prop_Send, "m_nSequence", Anim);
			SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 15.0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect, entity, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}		
	}
	return Plugin_Stop;
}
public Action:RemoveBlurEffect(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			decl String:model[128];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/infected/hulk.mdl", false))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}	
	}
}
stock StartMeteorFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	
	new Handle:Pack = CreateDataPack();
	WritePackCell(Pack, iRound);
	WritePackCell(Pack, client);
	WritePackFloat(Pack, pos[0]);
	WritePackFloat(Pack, pos[1]);
	WritePackFloat(Pack, pos[2]);
	WritePackFloat(Pack, GetEngineTime());
	CreateTimer(0.6, UpdateMeteorFall, Pack);
}

public Action:UpdateMeteorFall(Handle:timer, any:data)
{
	ResetPack(data);
	new round = ReadPackCell(data);
	new client = ReadPackCell(data);
	decl Float:pos[3];
	pos[0] = ReadPackFloat(data);
	pos[1] = ReadPackFloat(data);
	pos[2] = ReadPackFloat(data);
	new Float:time = ReadPackFloat(data);
	CloseHandle(data);

	if (iRound != round || !IsServerProcessing())
	{
		return;
	}

	if ((GetEngineTime() - time) > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entity = -1;
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3], Float:velocity[3], Float:hitpos[3];
		angle[0] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[1] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[2] = 60.0;
		
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos);
		if (GetVectorDistance(pos, hitpos) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t, t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock");
			if (ent > 0)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl"); 
				DispatchSpawn(ent);  
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);

				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);

				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
	 
				AcceptEntityInput(ent, "Ignite");
				SetEntProp(ent, Prop_Send, "m_hOwnerEntity", client);
			}
		} 
	}
	else if (TankAbility[client] == 0)
	{
		while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
		{
			new ownerent = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (client == ownerent)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
		return;
	}
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		new ownerent = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (client == ownerent)
		{
			if (OnGroundUnits(entity) < 200.0)
			{
				ExplodeMeteor(entity, ownerent);
			}
		}
	}

	new Handle:Pack = CreateDataPack();
	WritePackCell(Pack, round);
	WritePackCell(Pack, client);
	WritePackFloat(Pack, pos[0]);
	WritePackFloat(Pack, pos[1]);
	WritePackFloat(Pack, pos[2]);
	WritePackFloat(Pack, time);
	CreateTimer(0.6, UpdateMeteorFall, Pack);
}
public Float:OnGroundUnits(i_Ent)
{
	if (!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{ 
		decl Handle:h_Trace, Float:f_Origin[3], Float:f_Position[3], Float:f_Down[3] = { 90.0, 0.0, 0.0 };
		GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin);
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceRayDontHitSelfAndLive, i_Ent);
		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units;
			TR_GetEndPosition(f_Position, h_Trace);
			f_Units = f_Origin[2] - f_Position[2];
			CloseHandle(h_Trace);
			return f_Units;
		}
		CloseHandle(h_Trace);
	} 
	
	return 0.0;
}
stock GetRayHitPos(Float:pos[3], Float:angle[3], Float:hitpos[3], ent=0, bool:useoffset=false)
{
	new Handle:trace;
	new hit=0;
	
	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	
	if (useoffset)
	{
		decl Float:v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, 15.0);
		AddVectors(hitpos, v, hitpos);
	}
	return hit;
}
stock ExplodeMeteor(entity, client)
{
	if (entity > 32 && IsValidEntity(entity) && IsTank(client))
	{
		decl String:classname[16];
		GetEdictClassname(entity, classname, 20);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return;
		}
		new target;
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i))
			{
				target = i;
				break;
			}
		}

		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
		pos[2]+=50.0;
		AcceptEntityInput(entity, "Kill");

		PropaneExplode(target, pos);

		new pointHurt = CreateEntityByName("point_hurt");   
		DispatchKeyValueFloat(pointHurt, "Damage", flMeteorStormDamage);        
		DispatchKeyValue(pointHurt, "DamageType", "128");  
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);  
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
		AcceptEntityInput(pointHurt, "Hurt", client);
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(pointHurt, "AddOutput");
		AcceptEntityInput(pointHurt, "FireUser1");   
	}
} 
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if (entity == data) 
	{
		return false; 
	}
	else if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}
public Action:RockThrowTimer(Handle:timer)
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		new thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if (thrower > 0 && thrower < 33 && IsTank(thrower))
		{
			new color = GetEntRenderColor(thrower);
			switch(color)
			{
				//Fire Tank
				case 12800:
				{
      	 				SetEntityRenderColor(entity, 128, 0, 0, 255);
					CreateTimer(0.8, Timer_AttachFIRE_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Ice Tank
				case 0100170:
				{
					SetEntityRenderMode(entity, RenderMode:3);
					SetEntityRenderColor(entity, 0, 100, 170, 180);
				}
				//Jockey Tank
				case 2552000:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, JockeyThrow, thrower, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Spitter Tank
				case 12115128:
				{
					SetEntityRenderMode(entity, RenderMode:3);
      	 				SetEntityRenderColor(entity, 121, 151, 28, 30);
					CreateTimer(0.8, Timer_SpitSound, thrower, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(0.8, Timer_AttachSPIT_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Shock Tank
				case 100165255:
				{
					CreateTimer(0.8, Timer_AttachELEC_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				//Shield Tank
				case 135205255:
				{
					Rock[thrower] = entity;
					CreateTimer(0.1, PropaneThrow, thrower, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}
public Action:PropaneThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			new propane = CreateEntityByName("prop_physics");
			if (IsValidEntity(propane))
			{
				DispatchKeyValue(propane, "model", MODEL_PROPANE);
				DispatchSpawn(propane);
				new Float:Pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);	
				AcceptEntityInput(entity, "Kill");
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed*1.4);
				TeleportEntity(propane, Pos, NULL_VECTOR, velocity);
			}	
			return Plugin_Stop;
		}		
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action:JockeyThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			if (CountTotal() < 29)
			{
				new bot = CreateFakeClient("Jockey");
				if (bot > 0)
				{
					SpawnInfected(bot, 5, true);
					new Float:Pos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);	
					AcceptEntityInput(entity, "Kill");
					NormalizeVector(velocity, velocity);
					new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
					ScaleVector(velocity, speed*1.4);
					TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
				}	
				return Plugin_Stop;
			}
		}		
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
stock GetNearestSurvivorDist(client)
{
    	new Float:TankPos[3], Float:SurvPos[3], Float:nearest = 0.0, Float:distance = 0.0;
	if (client > 0)
	{
		if (IsTank(client))
		{
			GetClientAbsOrigin(client, TankPos);
   			for (new i=1; i<=MaxClients; i++)
    			{
        			if (IsSurvivor(i) && IsPlayerAlive(i))
				{
					GetClientAbsOrigin(i, SurvPos);
                        		distance = GetVectorDistance(TankPos, SurvPos);
                        		if (nearest == 0.0 || nearest > distance)
					{
						nearest = distance;
					}
				}
			}
		} 
    	}
    	return RoundFloat(distance);
}
stock EntityGetNearestSurvivorDist(entity, bool:incap)
{
	new target = 0;
	if (IsWitch(entity))
	{
		new Float:Origin[3], Float:TOrigin[3], Float:distance = 0.0, Float:savedDistance = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
   		for (new i=1; i<=MaxClients; i++)
    		{
        		if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				if (incap == IsPlayerIncap(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", TOrigin);
                        		distance = GetVectorDistance(Origin, TOrigin);
					if (savedDistance == 0.0 || savedDistance > distance)
					{
						savedDistance = distance;
						target = i;
					}
				}
			}
		} 
    	}
    	return target;
}
public FakeJump(client)
{
	if (IsTank(client))
	{
		new Float:vecVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
		if (vecVelocity[0] > 0.0 && vecVelocity[0] < 500.0)
		{
			vecVelocity[0] += 500.0;
		}
		else if (vecVelocity[0] < 0.0 && vecVelocity[0] > -500.0)
		{
			vecVelocity[0] += -500.0;
		}
		if (vecVelocity[1] > 0.0 && vecVelocity[1] < 500.0)
		{
			vecVelocity[1] += 500.0;
		}
		else if (vecVelocity[1] < 0.0 && vecVelocity[1] > -500.0)
		{
			vecVelocity[1] += -500.0;
		}
		vecVelocity[2] += 750.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
}
public SkillFlameClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			IgniteEntity(target, 3.0);
			EmitSoundToAll("ambient/fire/gascan_ignite1.wav", target);
			PerformFade(target, 500, 250, 10, 1, {100, 50, 0, 150});
		}
	}
}
public SkillIceClaw(target, client)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			DealDamagePlayer(target, client, 128, GetRandomInt(2,6), "point_hurt");
			SetEntityRenderMode(target, RenderMode:3);
			SetEntityRenderColor(target, 0, 100, 170, 180);
			SetEntityMoveType(target, MOVETYPE_VPHYSICS);
			CreateTimer(5.0, Timer_UnFreeze, target, TIMER_FLAG_NO_MAPCHANGE);
			EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", target);
			PerformFade(target, 500, 250, 10, 1, {0, 50, 100, 150});
		}
	}
}
public SkillGravityClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			GravityClaw[target] = 1;
			CreateTimer(2.0, Timer_ResetGravity, target, TIMER_FLAG_NO_MAPCHANGE);
			PerformFade(target, 500, 250, 10, 1, {100, 50, 100, 150});
			ScreenShake(target, 5.0);
		}
	}
}
public Action:MeteorTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 1002525)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		new ent[5];
		for (new count=1; count<=4; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
				DispatchKeyValueVector(ent[count], "origin", Origin);
				DispatchKeyValueVector(ent[count], "angles", Angles);
				DispatchSpawn(ent[count]);
				AcceptEntityInput(ent[count], "DisableCollision");
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);

				SetVariantString("!activator");
				AcceptEntityInput(ent[count], "SetParent", client);
				switch(count)
				{
					case 1:SetVariantString("relbow");
					case 2:SetVariantString("lelbow");
					case 3:SetVariantString("rshoulder");
					case 4:SetVariantString("lshoulder");
				}
				AcceptEntityInput(ent[count], "SetParentAttachment");
				switch(count)
				{
					case 1,2:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.4);
					case 3,4:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.5);
				}
				Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
				Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
				Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
}
public Action:JumperTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 2002550)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		new ent[3];
		for (new count=1; count<=2; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
				DispatchKeyValueVector(ent[count], "origin", Origin);
				DispatchKeyValueVector(ent[count], "angles", Angles);
				DispatchSpawn(ent[count]);
				AcceptEntityInput(ent[count], "DisableCollision");
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);

				SetVariantString("!activator");
				AcceptEntityInput(ent[count], "SetParent", client);
				switch(count)
				{
					case 1:SetVariantString("rfoot");
					case 2:SetVariantString("lfoot");
				}
				AcceptEntityInput(ent[count], "SetParentAttachment");

				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
}
public Action:GravityTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 333435)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		Angles[0] += -90.0;
		new entity = CreateEntityByName("beam_spotlight");
		if (IsValidEntity(entity))
		{
			DispatchKeyValueVector(entity, "origin", Origin);
			DispatchKeyValueVector(entity, "angles", Angles);
			DispatchKeyValue(entity, "spotlightwidth", "10");
			DispatchKeyValue(entity, "spotlightlength", "60");
			DispatchKeyValue(entity, "spawnflags", "3");
			DispatchKeyValue(entity, "rendercolor", "100 100 100");
			DispatchKeyValue(entity, "renderamt", "125");
			DispatchKeyValue(entity, "maxspeed", "100");
			DispatchKeyValue(entity, "HDRColorScale", "0.7");
			DispatchKeyValue(entity, "fadescale", "1");
			DispatchKeyValue(entity, "fademindist", "-1");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "Enable");
			AcceptEntityInput(entity, "DisableCollision");

			SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
			SetVariantString("mouth");
			AcceptEntityInput(entity, "SetParentAttachment");

			TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
		}
		new blackhole = CreateEntityByName("point_push");
		if (IsValidEntity(blackhole))
		{
			DispatchKeyValueVector(blackhole, "origin", Origin);
			DispatchKeyValueVector(blackhole, "angles", Angles);
			DispatchKeyValue(blackhole, "radius", "750");
			DispatchKeyValueFloat(blackhole, "magnitude", flGravityPullForce);
			DispatchKeyValue(blackhole, "spawnflags", "8");
			DispatchSpawn(blackhole);
			AcceptEntityInput(blackhole, "Enable");

			SetEntProp(blackhole, Prop_Send, "m_glowColorOverride", client);

			SetVariantString("!activator");
			AcceptEntityInput(blackhole, "SetParent", client);
		}
	}
}
stock FireTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12800)
	{
		decl Float:Origin[3];
		GetClientAbsOrigin(client, Origin);
		GasCanExplode(client, Origin);
	}
}
stock IceTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0100170)
	{
		new count = CountSurvInRange(client, 300);

		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);

		if (count >= 3)
		{
			new random = GetRandomInt(1,6);
			if (random == 1)
			{
				new glowcolor = RGB_TO_INT(30, 130, 230);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				for (new j=1; j<=MaxClients; j++)
				{
					if (SurvInRange(client, j, 300))
					{
						SkillIceClaw(j, client);
					}
				}
			}
		}
	}
}
stock JumperTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 2002550)
	{
		new flags = GetEntityFlags(client);
		if (flags & FL_ONGROUND)
		{
			new random = GetRandomInt(1,iJumperJumpDelay);
			if (random == 1)
			{
				if (GetNearestSurvivorDist(client) > 200 && GetNearestSurvivorDist(client) < 2000)
				{
					FakeJump(client);
				}
			}
		}
	}
}
stock SpitterTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		new Float:Origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		Origin[2] += 10.0;

		new ent = CreateEntityByName("spitter_projectile");
		if (IsValidEntity(ent))
		{
			DispatchSpawn(ent);
			SetEntPropFloat(ent, Prop_Send, "m_DmgRadius", 1024.0);
			SetEntProp(ent, Prop_Send, "m_bIsLive", 1 );
			SetEntPropEnt(ent, Prop_Send, "m_hThrower", client);
			TeleportEntity(ent, Origin, NULL_VECTOR, NULL_VECTOR);
			L4D2_SpitBurst(ent);
		}
	}
}
stock HulkTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100255200)
	{
		if (TankAbilityTimer[client] <= 0)
		{
			new count = CountSurvInRange(client, 300);

			if (count >= 3)
			{
				new glowcolor = RGB_TO_INT(0, 255, 0);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_bFlashing", 1);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_bFlashing", 0);
			}
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			SetEntProp(client, Prop_Send, "m_bFlashing", 0);
		}
	}
}
stock GhostTankAbility(client)
{
	if (bGhostDisarm)
	{
		if (IsTank(client) && GetEntRenderColor(client) == 100100100)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsSurvivor(i) && IsPlayerAlive(i))
				{
					if (SurvInRange(client, i, 300))
					{
						new random = GetRandomInt(1,8);
						if (random == 1)
						{
							if (ForceWeaponDrop(i))
							{
								PrintToChat(i, "Something disarmed you...");
								EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i);
							}
							return;
						}
					}
				}
			}
		}
	}
}
stock ShockTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100165255)
	{
		new count = CountSurvInRange(client, 400);

		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				if (SurvInRange(client, i, 400))
				{
					ShockBolt(client, i, count);
				}
			}
		}
	}
}
stock WitchTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255200255)
	{
		new random = GetRandomInt(1,3);
		if (random == 1)
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);

			for (new i=1; i<=MaxClients; i++)
			{
				if (SurvInRange(client, i, 400))
				{
					if (CountWitches() < iWitchMaxWitches)
					{
						new witch = CreateEntityByName("witch");
						DispatchSpawn(witch);
						ActivateEntity(witch);
						TeleportEntity(witch, Origin, Angles, NULL_VECTOR);	

						new Handle:Pack = CreateDataPack();
						WritePackCell(Pack, witch);
						WritePackCell(Pack, i);
						CreateTimer(0.1, AngerWitch, Pack, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}
public Action:AngerWitch(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new entity = ReadPackCell(Pack);
	new client = ReadPackCell(Pack);
	CloseHandle(Pack);

	if (IsWitch(entity) && IsSurvivor(client) && IsPlayerAlive(client))
	{
		DealDamageEntity(entity, client, 2, 1, "point_hurt");
		SetEntProp(entity, Prop_Send, "m_hOwnerEntity", 255200255);	
	}
}
stock HealTank(client, damage)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100255200)
	{
		if (damage > 0)
		{
			new health = GetEntProp(client, Prop_Send, "m_iHealth");
			new maxhealth = GetConVarInt(FindConVar("z_tank_health"));
			if (health <= (maxhealth - damage) && health > 500)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", health + damage);
			}
			else if (health > 500)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", maxhealth);
			}
		}
	}
}
stock ShockBolt(client, target, damage)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100165255)
	{
		if (IsSurvivor(target))
		{
			decl String:name[32];
			decl Float:Origin[3], Float:TOrigin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", TOrigin);
			Origin[2] += 30.0;
			TOrigin[2] += 30.0;
			new endpoint = CreateEntityByName("info_particle_target");
			if (endpoint > 0 && IsValidEntity(endpoint))
			{
				Format(name, sizeof(name), "bolttarget%i", endpoint);
				DispatchKeyValue(endpoint, "targetname", name);	
				DispatchKeyValueVector(endpoint, "origin", TOrigin);
				DispatchSpawn(endpoint);
				ActivateEntity(endpoint);
				SetVariantString("OnUser1 !self:Kill::0.8:-1");
				AcceptEntityInput(endpoint, "AddOutput");
				AcceptEntityInput(endpoint, "FireUser1");
			}
			new particle = CreateEntityByName("info_particle_system");
			if (particle > 0 && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "effect_name", PARTICLE_LS_BOLT);
				DispatchKeyValue(particle, "cpoint1", name);
				DispatchKeyValueVector(particle, "origin", Origin);
				DispatchSpawn(particle);
				ActivateEntity(particle);
				SetVariantString("!activator");
				AcceptEntityInput(particle, "SetParent", client);
				AcceptEntityInput(particle, "start");
				SetVariantString("OnUser1 !self:Kill::0.8:-1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
			}
			if (damage > 4)
			{
				damage = 4;
			}
			DealDamagePlayer(target, client, 128, damage, "point_hurt");
			if (damage >= 3)
			{
				new random = GetRandomInt(1,5);
				switch(random)
				{
					case 1: EmitSoundToAll("ambient/energy/zap5.wav", target);
					case 2: EmitSoundToAll("ambient/energy/zap6.wav", target);
					case 3: EmitSoundToAll("ambient/energy/zap7.wav", target);
					case 4: EmitSoundToAll("ambient/energy/zap8.wav", target);
					case 5: EmitSoundToAll("ambient/energy/zap9.wav", target);
				}
			}	
		}
	}
}
stock SetDemonTankHealth(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255150100)
	{
		SetEntProp(client, Prop_Send, "m_iMaxHealth", 60666);
		SetEntProp(client, Prop_Send, "m_iHealth", 60666);
	}
}
public Action:DemonTankTimer(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255150100)
	{
		new Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		Angles[0] += -90.0;
		SetEntityModel(client, MODEL_TANK_DLC3);

   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
			DispatchKeyValueVector(particle, "origin", Origin);
			DispatchKeyValueVector(particle, "angles", Angles);
			DispatchKeyValue(particle, "effect_name", PARTICLE_FLARE);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");

			SetEntProp(particle, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client);
			SetVariantString("mouth");
			AcceptEntityInput(particle, "SetParentAttachment");

			new Float:TOrigin[3] = {-0.5, 3.0, -2.0};
			TeleportEntity(particle, TOrigin, NULL_VECTOR, NULL_VECTOR);
		}
   		particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
			DispatchKeyValueVector(particle, "origin", Origin);
			DispatchKeyValueVector(particle, "angles", Angles);
			DispatchKeyValue(particle, "effect_name", PARTICLE_FLARE);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");

			SetEntProp(particle, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client);
			SetVariantString("mouth");
			AcceptEntityInput(particle, "SetParentAttachment");

			new Float:TOrigin[3] = {-0.5, 3.0, 2.0};
			TeleportEntity(particle, TOrigin, NULL_VECTOR, NULL_VECTOR);
		}
/*
   		particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
			DispatchKeyValueVector(particle, "origin", Origin);
			DispatchKeyValueVector(particle, "angles", Angles);
			DispatchKeyValue(particle, "effect_name", PARTICLE_DEMON_HEAT);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");

			SetEntProp(particle, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client);

			new Float:TOrigin[3] = {0.0, 0.0, 35.0};
			TeleportEntity(particle, TOrigin, NULL_VECTOR, NULL_VECTOR);
		}
*/
		new blackhole = CreateEntityByName("point_push");
		if (IsValidEntity(blackhole))
		{
			DispatchKeyValueVector(blackhole, "origin", Origin);
			DispatchKeyValueVector(blackhole, "angles", Angles);
			DispatchKeyValue(blackhole, "radius", "400");
			DispatchKeyValue(blackhole, "magnitude", "-20");
			DispatchKeyValue(blackhole, "spawnflags", "8");
			DispatchSpawn(blackhole);
			AcceptEntityInput(blackhole, "Enable");

			SetEntProp(blackhole, Prop_Send, "m_glowColorOverride", client);

			SetVariantString("!activator");
			AcceptEntityInput(blackhole, "SetParent", client);
		}
	}
}
stock DemonTankLevelUp(client)
{
	if (IsTank(client))
	{
		new health = GetEntProp(client, Prop_Send, "m_iHealth");
		new maxhealth = GetConVarInt(FindConVar("z_tank_health"));
		if ((health + 5000) < maxhealth)
		{
			SetEntProp(client, Prop_Data, "m_iHealth", health + 5000);
		}
		else
		{
			SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(FindConVar("z_tank_health")));
		}
		new level = TankAbility[client];
		switch(level)
		{
			case 1:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.05);	
			}
			case 2:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.1);
			}
			case 3:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.15);
			}
			case 4:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
			}
			case 5:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.25);
			}
			case 6:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.3);
			}
			case 7:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.35);
			}
			case 8:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
			}
			case 9:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.45);
			}
			case 10:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
			}
		}
	}
}
public SkillSmashClaw(target)
{
	new health = GetEntProp(target, Prop_Data, "m_iHealth");
	if (health > 1 && !IsPlayerIncap(target))
	{
		new Float:time = GetGameTime();
		SetEntProp(target, Prop_Data, "m_iHealth", iSmasherMaimDamage);
		new Float:hbuffer = float(health) - float(iSmasherMaimDamage);
		if (hbuffer > 0.0)
		{
			SetEntPropFloat(target, Prop_Send, "m_healthBuffer", hbuffer);
		}
		SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", time);
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target);
	PerformFade(target, 800, 300, 10, 1, {10, 0, 0, 250});
	ScreenShake(target, 30.0);
}
public SkillSmashClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker);
	AttachParticle(client, PARTICLE_EXPLODE, 0.1, 0.0, 0.0, 0.0);
	new random = GetRandomInt(1,3);
	switch(random)
	{
		case 1: EmitSoundToAll("player/boomer/explode/explo_medium_09.wav", client);
		case 2: EmitSoundToAll("player/boomer/explode/explo_medium_10.wav", client);
		case 3: EmitSoundToAll("player/boomer/explode/explo_medium_14.wav", client);
	}
	if (IsTank(client) && GetEntRenderColor(client) == 7080100)
	{
		DealDamagePlayer(client, attacker, 128, iSmasherCrushDamage, "point_hurt");
		DealDamagePlayer(client, attacker, 128, iSmasherCrushDamage, "point_hurt");
		CreateTimer(0.1, RemoveDeathBody, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		DealDamagePlayer(client, attacker, 128, 999, "point_hurt");
		DealDamagePlayer(client, attacker, 128, 999, "point_hurt");
	}
}
public Action:RemoveDeathBody(Handle:timer, any:client)
{
	if (bSmasherRemoveBody)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
				{
					new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if (client == owner)
					{
						AcceptEntityInput(entity, "Kill");
					}
				}
			}
		}
	}
}
public SkillElecClaw(target, tank)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			PlayerSpeed[target] += 3;
			new Handle:Pack = CreateDataPack();
			WritePackCell(Pack, iRound);
			WritePackCell(Pack, target);
			WritePackCell(Pack, tank);
			WritePackCell(Pack, 4);
			CreateTimer(5.0, Timer_Volt, Pack);

			PerformFade(target, 250, 100, 10, 1, {50, 150, 250, 100});
			ScreenShake(target, 15.0);
			AttachParticle(target, PARTICLE_ELEC, 2.0, 0.0, 0.0, 30.0);
	
			new random = GetRandomInt(1,2);
			switch(random)
			{
				case 1: EmitSoundToAll("ambient/energy/spark5.wav", target);
				case 2: EmitSoundToAll("ambient/energy/spark6.wav", target);
			}
		}
	}
}
public Action:Timer_Volt(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new round = ReadPackCell(Pack);
	new client = ReadPackCell(Pack);
	new tank = ReadPackCell(Pack);
	new amount = ReadPackCell(Pack);
	CloseHandle(Pack);

	if (iRound != round || !IsServerProcessing())
	{
		return;
	}

	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && PlayerSpeed[client] == 0 && IsTank(tank))
		{
			if (amount > 0)
			{
				PlayerSpeed[client] += 2;
				ScreenShake(client, 2.0);
				DealDamagePlayer(client, tank, 128, iShockStunDamage, "point_hurt");
				AttachParticle(client, PARTICLE_ELEC, 2.0, 0.0, 0.0, 30.0);
				new random = GetRandomInt(1,2);
				switch(random)
				{
					case 1: EmitSoundToAll("ambient/energy/spark5.wav", client);
					case 2: EmitSoundToAll("ambient/energy/spark6.wav", client);
				}
				new Handle:NewPack = CreateDataPack();
				WritePackCell(NewPack, iRound);
				WritePackCell(NewPack, client);
				WritePackCell(NewPack, tank);
				WritePackCell(NewPack, amount - 1);
				CreateTimer(5.0, Timer_Volt, NewPack);
			}
		}
	}
}
public Action:Timer_UnFreeze(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RenderMode:3);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}
public Action:Timer_ResetGravity(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			GravityClaw[client] = 0;
			//SetEntityGravity(client, 1.0);
		}
	}
}
public Action:Timer_AttachFIRE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12800)
	{
		AttachParticle(client, PARTICLE_FIRE, 0.8, 0.0, 0.0, 0.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachFIRE_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			IgniteEntity(entity, 100.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachICE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 0100170)
	{
		AttachParticle(client, PARTICLE_SMOKE, 2.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachSPIT(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		AttachParticle(client, PARTICLE_SPIT, 2.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_SpitSound(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 12115128)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client);
	}
}
public Action:Timer_AttachSPIT_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			AttachParticle(entity, PARTICLE_SPITPROJ, 0.8, 0.0, 0.0, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachELEC(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100165255)
	{
		AttachParticle(client, PARTICLE_ELEC, 0.8, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachELEC_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false))
		{
			AttachParticle(entity, PARTICLE_ELEC, 0.8, 0.0, 0.0, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachBLOOD(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 255200255)
	{
		AttachParticle(client, PARTICLE_BLOOD_EXPLODE, 0.8, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachMETEOR(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 1002525)
	{
		AttachParticle(client, PARTICLE_METEOR, 6.0, 0.0, 0.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:ActivateShieldTimer(Handle:timer, any:client)
{
	ActivateShield(client);
}
stock ActivateShield(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 135205255 && ShieldsUp[client] == 0)
	{
		decl Float:Origin[3];
		GetClientAbsOrigin(client, Origin);
		Origin[2] -= 120.0;
		new entity = CreateEntityByName("prop_dynamic_override");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/props_unique/airport/atlas_break_ball.mdl");
			DispatchKeyValueVector(entity, "origin", Origin);
			DispatchSpawn(entity);

			SetEntityRenderMode(entity, RenderMode:3);
      	 		SetEntityRenderColor(entity, 25, 125, 125, 50);
			AcceptEntityInput(entity, "DisableCollision");
			AcceptEntityInput(entity, "DisableShadow");
			SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
			SetEntProp(entity, Prop_Send, "m_hOwnerEntity", client);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
		}
		ShieldsUp[client] = 1;
	}
}
stock DeactivateShield(client, Float:time)
{
	if (IsTank(client) && GetEntRenderColor(client) == 135205255 && ShieldsUp[client] == 1)
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
		{
			decl String:model[64];
            		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl", false))
			{
				new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
				if (owner == client)
				{
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
		CreateTimer(flShieldShieldsDownInterval, ActivateShieldTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		ShieldsUp[client] = 0;
	}
}
stock KickAIBots()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSpecialInfected(i) && IsFakeClient(i))
		{
			if (CountInfectedAll() > 16)
			{
				KickClient(i);
			}
		}
	}
}
//=============================
//	HELPERS
//=============================
stock CountTotal()
{
	new count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			count++;
		}
	}
	return count;
}
stock CountInGame()
{
	new count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
	return count;
}
stock CountSurvivorsAliveAll()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
	}
	return count;
}
stock CountSI()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSmoker(i) || IsBoomer(i) || IsHunter(i) || IsSpitter(i) || IsJockey(i) || IsCharger(i))
		{
			count++;
		}
	}
	return count;
}
stock CountTanks()
{
	iNumTanks = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsTank(i))
		{
			iNumTanks++;
		}
	}
}
stock CountInfectedAll()
{
	new count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count++;
		}
	}
	return count;
}
stock bool:IsInfected(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsUncommon(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected", false))
		{
			decl String:model[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			{
				if (StrContains(model, "roadcrew", false) != -1 || StrContains(model, "ceda", false) != -1 || StrContains(model, "mud", false) != -1 || StrContains(model, "riot", false) != -1 || StrContains(model, "clown", false) != -1 || StrContains(model, "jimmy", false) != -1 || StrContains(model, "fallen", false) != -1)
				{
					return true;
				}	
			}
		}
	}
	return false;
}
stock bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool:IsSpectator(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}
stock bool:IsSpecialInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) || StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) || StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsSpecialInfectedClass(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false) || StrEqual(classname, "Boomer", false) || StrEqual(classname, "Hunter", false) || StrEqual(classname, "Spitter", false) || StrEqual(classname, "Jockey", false) || StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsSmoker(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Smoker", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsBoomer(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Boomer", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsHunter(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Hunter", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsSpitter(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Spitter", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsJockey(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Jockey", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsCharger(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Charger", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsWitch(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
		return false;
	}
	return false;
}
stock bool:IsTank(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && !IsPlayerIncap(client) && TankAlive[client] == 1)
	{
		decl String:classname[16];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}
stock bool:IsPlayerBurning(client)
{
	new Float:IsBurning = GetEntPropFloat(client, Prop_Send, "m_burnPercent");
	if (IsBurning > 0) 
		return true;
	return false;
}
stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}
stock bool:IsPlayerIncap(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
stock Pick()
{
    	new count, clients[MaxClients];
    	for (new i=1; i<=MaxClients; i++)
    	{
        	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
            		clients[count++] = i; 
    	}
    	return clients[GetRandomInt(0,count-1)];
}
stock GetZombieClass(client)
{
	new class = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_zombieClass"));
	return class;
}
//=============================
// 	AUTO DIFFICULTY
//=============================
public Action:AutoDiffTimer(Handle:timer, any:client)
{
	new AD_special_spawn_delay_min;
	new AD_special_spawn_delay_max;
	new AD_special_spawn_amount;
	new AD_tank_burn_duration;
	new AD_smoker_health;
	new AD_boomer_health;
	new AD_hunter_health;
	new AD_spitter_health;
	new AD_jockey_health;
	new AD_charger_health;
	new AD_witch_health;
	new AD_zombie_health;

	if (bNightmare)
	{
		AD_special_spawn_delay_min = 6;
		AD_special_spawn_delay_max = 6;
		AD_special_spawn_amount = 10;
		AD_tank_burn_duration = 666;
		AD_smoker_health = 1666;
		AD_boomer_health = 1666;
		AD_hunter_health = 1666;
		AD_spitter_health = 1666;
		AD_jockey_health = 1666;
		AD_charger_health = 1666;
		AD_witch_health = 1666;
		AD_zombie_health = 666;
	}
	else
	{
		switch(iDifficulty)
		{
			case 1:
			{
				AD_special_spawn_delay_min = 0;
				AD_special_spawn_delay_max = 0;
				AD_special_spawn_amount = 0;
				AD_tank_burn_duration = 85;
				AD_smoker_health = 250;
				AD_boomer_health = 50;
				AD_hunter_health = 250;
				AD_spitter_health = 150;
				AD_jockey_health = 325;
				AD_charger_health = 600;
				AD_witch_health = 1000;
				AD_zombie_health = 50;
			}
			case 2:
			{
				AD_special_spawn_delay_min = 0;
				AD_special_spawn_delay_max = 0;
				AD_special_spawn_amount = 0;
				AD_tank_burn_duration = 85;
				AD_smoker_health = 250;
				AD_boomer_health = 50;
				AD_hunter_health = 250;
				AD_spitter_health = 100;
				AD_jockey_health = 325;
				AD_charger_health = 600;
				AD_witch_health = 1000;
				AD_zombie_health = 50;
			}
			case 3:
			{
				AD_special_spawn_delay_min = 0;
				AD_special_spawn_delay_max = 0;
				AD_special_spawn_amount = 0;
				AD_tank_burn_duration = 85;
				AD_smoker_health = 250;
				AD_boomer_health = 50;
				AD_hunter_health = 250;
				AD_spitter_health = 100;
				AD_jockey_health = 325;
				AD_charger_health = 600;
				AD_witch_health = 1000;
				AD_zombie_health = 50;
			}
			case 4:
			{
				AD_special_spawn_delay_min = 0;
				AD_special_spawn_delay_max = 0;
				AD_special_spawn_amount = 0;
				AD_tank_burn_duration = 85;
				AD_smoker_health = 250;
				AD_boomer_health = 50;
				AD_hunter_health = 250;
				AD_spitter_health = 100;
				AD_jockey_health = 325;
				AD_charger_health = 600;
				AD_witch_health = 1000;
				AD_zombie_health = 50;
			}
		}
	}
	iSpecialMin = AD_special_spawn_delay_min;
	iSpecialMax = AD_special_spawn_delay_max;
	iSpecialAmount = AD_special_spawn_amount;
	SetConVarInt(FindConVar("tank_burn_duration_expert"), AD_tank_burn_duration);
	SetConVarInt(FindConVar("z_gas_health"), AD_smoker_health);
	SetConVarInt(FindConVar("z_exploding_health"), AD_boomer_health);
	SetConVarInt(FindConVar("z_hunter_health"), AD_hunter_health);
	SetConVarInt(FindConVar("z_spitter_health"), AD_spitter_health);
	SetConVarInt(FindConVar("z_jockey_health"), AD_jockey_health);
	SetConVarInt(FindConVar("z_charger_health"), AD_charger_health);
	SetConVarInt(FindConVar("z_witch_health"), AD_witch_health);
	SetConVarInt(FindConVar("z_health"), AD_zombie_health);
}
stock AutoDifficulty(bool:bDiffReset)
{
	if (!IsServerProcessing()) return;

	decl String:GameDifficulty[16];
	GetConVarString(FindConVar("z_difficulty"), GameDifficulty, sizeof(GameDifficulty));
	new diffchanged;

	if (bNightmare)
	{
		if (!StrEqual(GameDifficulty, "Impossible", false))
		{
			SetConVarString(FindConVar("z_difficulty"), "Impossible");
			diffchanged = 1;
		}
	}
	else
	{
		switch(iDifficulty)
		{
			case 1:
			{
				if (!StrEqual(GameDifficulty, "Easy", false))
				{
					SetConVarString(FindConVar("z_difficulty"), "Easy");
					diffchanged = 1;
				}
			}
			case 2:
			{
				if (!StrEqual(GameDifficulty, "Normal", false))
				{
					SetConVarString(FindConVar("z_difficulty"), "Normal");
					diffchanged = 1;
				}
			}
			case 3:
			{
				if (!StrEqual(GameDifficulty, "Hard", false))
				{
					SetConVarString(FindConVar("z_difficulty"), "Hard");
					diffchanged = 1;
				}
			}
			case 4:
			{
				if (!StrEqual(GameDifficulty, "Impossible", false))
				{
					SetConVarString(FindConVar("z_difficulty"), "Impossible");
					diffchanged = 1;
				}
			}
		}
	}
	if (diffchanged == 1 || bDiffReset)
	{
		new AD_special_spawn_delay_min;
		new AD_special_spawn_delay_max;
		new AD_special_spawn_amount;
		new AD_tank_burn_duration;
		new AD_smoker_health;
		new AD_boomer_health;
		new AD_hunter_health;
		new AD_spitter_health;
		new AD_jockey_health;
		new AD_charger_health;
		new AD_witch_health;
		new AD_zombie_health;

		if (bNightmare)
		{
			AD_special_spawn_delay_min = 6;
			AD_special_spawn_delay_max = 6;
			AD_special_spawn_amount = 10;
			AD_tank_burn_duration = 666;
			AD_smoker_health = 1666;
			AD_boomer_health = 1666;
			AD_hunter_health = 1666;
			AD_spitter_health = 1666;
			AD_jockey_health = 1666;
			AD_charger_health = 1666;
			AD_witch_health = 1666;
			AD_zombie_health = 666;
		}
		else
		{
			switch(iDifficulty)
			{
				case 1:
				{
					AD_special_spawn_delay_min = 0;
					AD_special_spawn_delay_max = 0;
					AD_special_spawn_amount = 0;
					AD_tank_burn_duration = 85;
					AD_smoker_health = 250;
					AD_boomer_health = 50;
					AD_hunter_health = 250;
					AD_spitter_health = 150;
					AD_jockey_health = 325;
					AD_charger_health = 600;
					AD_witch_health = 1000;
					AD_zombie_health = 50;
				}
				case 2:
				{
					AD_special_spawn_delay_min = 0;
					AD_special_spawn_delay_max = 0;
					AD_special_spawn_amount = 0;
					AD_tank_burn_duration = 85;
					AD_smoker_health = 250;
					AD_boomer_health = 50;
					AD_hunter_health = 250;
					AD_spitter_health = 100;
					AD_jockey_health = 325;
					AD_charger_health = 600;
					AD_witch_health = 1000;
					AD_zombie_health = 50;
				}
				case 3:
				{
					AD_special_spawn_delay_min = 0;
					AD_special_spawn_delay_max = 0;
					AD_special_spawn_amount = 0;
					AD_tank_burn_duration = 85;
					AD_smoker_health = 250;
					AD_boomer_health = 50;
					AD_hunter_health = 250;
					AD_spitter_health = 100;
					AD_jockey_health = 325;
					AD_charger_health = 600;
					AD_witch_health = 1000;
					AD_zombie_health = 50;
				}
				case 4:
				{
					AD_special_spawn_delay_min = 0;
					AD_special_spawn_delay_max = 0;
					AD_special_spawn_amount = 0;
					AD_tank_burn_duration = 85;
					AD_smoker_health = 250;
					AD_boomer_health = 50;
					AD_hunter_health = 250;
					AD_spitter_health = 100;
					AD_jockey_health = 325;
					AD_charger_health = 600;
					AD_witch_health = 1000;
					AD_zombie_health = 50;
				}
			}
		}
		iSpecialMin = AD_special_spawn_delay_min;
		iSpecialMax = AD_special_spawn_delay_max;
		iSpecialAmount = AD_special_spawn_amount;
		SetConVarInt(FindConVar("tank_burn_duration_expert"), AD_tank_burn_duration);
		SetConVarInt(FindConVar("z_gas_health"), AD_smoker_health);
		SetConVarInt(FindConVar("z_exploding_health"), AD_boomer_health);
		SetConVarInt(FindConVar("z_hunter_health"), AD_hunter_health);
		SetConVarInt(FindConVar("z_spitter_health"), AD_spitter_health);
		SetConVarInt(FindConVar("z_jockey_health"), AD_jockey_health);
		SetConVarInt(FindConVar("z_charger_health"), AD_charger_health);
		SetConVarInt(FindConVar("z_witch_health"), AD_witch_health);
		SetConVarInt(FindConVar("z_health"), AD_zombie_health);
	}
}
stock ResetVariables()
{
	iCountDownTimer = 0;
	iSpawnBotTick = 0;
	iFinaleStage = 0;
	iCCEnt = 0;
	iFogVolEnt = 0;
	iSRDoor = 0;
}
stock ResetClientArrays(client)
{
	GravityClaw[client] = 0;
	PlayerSpeed[client] = 0;
	ShieldsUp[client] = 0;
	TankAbility[client] = 0;
	TankAlive[client] = 0;
	TankAbilityTimer[client] = 0;
}
stock ResetClientArraysAll()
{
	for (new client=1; client<=MaxClients; client++)
	{
		GravityClaw[client] = 0;
		PlayerSpeed[client] = 0;
		ShieldsUp[client] = 0;
		TankAbility[client] = 0;
		TankAlive[client] = 0;
		TankAbilityTimer[client] = 0;
	}
}
stock FrameUpdateClients()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			UpdateMovementSpeed(i);
		}
		else if (IsTank(i) && GetEntRenderColor(i) == 100255200)
		{
			if (GetEntGlowColor(i) == 02550)
			{
				HealTank(i, iHealHealth);
			}
		}
	}
}
stock UpdateTimers(client)
{
	if (IsSurvivor(client) || IsSpectator(client))
	{
		if (PlayerSpeed[client] > 0)
		{
			PlayerSpeed[client] -= 1;
		}
	}
}
stock TimerUpdateClients()
{
	for (new i=1; i<=MaxClients; i++)
	{
		UpdateTimers(i);
	}
}
stock SpawnInfectedInterval()
{
	iSpawnBotTick += 1;
	new spawninterval = GetRandomInt(iSpecialMin,iSpecialMax);
	if (iSpawnBotTick >= spawninterval)
	{
		if (CountSI() < iSpecialAmount)
		{
			SpawnInfectedBot();
		}
		iSpawnBotTick = 0;
	}
}
stock SpawnInfectedBot()
{
	if (CountTotal() < 29)
	{
		new bot = CreateFakeClient("Smoker");
		if (bot > 0)
		{
			new random = GetRandomInt(1,6);
			SpawnInfected(bot, random, true);
		}
	}
}
stock SpawnInfected(client, class, bool:bAuto)
{
	new bool:resetGhostState[MaxClients+1];
	new bool:resetIsAlive[MaxClients+1];
	new bool:resetLifeState[MaxClients+1];
	ChangeClientTeam(client, 3);
	new String:classname[16];
	new String:options[32];
	switch(class)
	{
		case 1: classname = "smoker";
		case 2: classname = "boomer";
		case 3: classname = "hunter";
		case 4: classname = "spitter";
		case 5: classname = "jockey";
		case 6: classname = "charger";
		case 8: classname = "tank";
	}
	if (class == 7 || (class < 1 || class > 8)) return false;
	if (GetClientTeam(client) != 3) return false;
	if (!IsClientInGame(client)) return false;
	if (IsPlayerAlive(client)) return false;
	
	for (new i=1; i<=MaxClients; i++)
	{ 
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip
		
		if (IsPlayerGhost(i))
		{
			resetGhostState[i] = true;
			SetPlayerGhostStatus(i, false);
			resetIsAlive[i] = true; 
			SetPlayerIsAlive(i, true);
		}
		else if (!IsPlayerAlive(i))
		{
			resetLifeState[i] = true;
			SetPlayerLifeState(i, false);
		}
	}
	if (bAuto)
	{
		Format(options, sizeof(options), "%s auto", classname);
		CheatCommand(client, "z_spawn_old", options);
	}
	else
	{
		decl Float:Origin[3], Float:Angles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
		ForceSpawnInfected(classname, Origin, Angles);
	}
	if (IsFakeClient(client)) KickClient(client);
	for (new i=1; i<=MaxClients; i++)
	{
		if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if (resetLifeState[i]) SetPlayerLifeState(i, true);
	}
	return true;
}
stock bool:IsMissionFinalMap()
{
	if (L4D2_IsMissionFinalMap())
	{
		return true;
	}
	return false;
}
stock SetGameDifficulty()
{
	decl String:GameDifficulty[16];
	GetConVarString(FindConVar("z_difficulty"), GameDifficulty, sizeof(GameDifficulty));
	if (StrEqual(GameDifficulty, "Easy", false))
	{
		iDifficulty = 1;
	}
	else if (StrEqual(GameDifficulty, "Normal", false))
	{
		iDifficulty = 2;
	}
	else if (StrEqual(GameDifficulty, "Hard", false))
	{
		iDifficulty = 3;
	}
	else if (StrEqual(GameDifficulty, "Impossible", false))
	{
		if (!bNightmare)
		{
			iDifficulty = 4;
		}
	}
}
stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost){	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
	}else{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
	}
}
stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}
stock SetPlayerLifeState(client, bool:ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}
stock RGB_TO_INT(red, green, blue) 
{
	return (blue * 65536) + (green * 256) + red;
}
stock GetEntRenderColor(client)
{
	if (client > 0)
	{
		new offset = GetEntSendPropOffs(client, "m_clrRender");
		new r = GetEntData(client, offset, 1);
		new g = GetEntData(client, offset+1, 1);
		new b = GetEntData(client, offset+2, 1);
		decl String:rgb[10];
		Format(rgb, sizeof(rgb), "%i%i%i", r, g, b);
		new color = StringToInt(rgb);
		return color;
	}
	return 0;	
}
stock GetEntGlowColor(client)
{
	if (client > 0)
	{
		new offset = GetEntSendPropOffs(client, "m_Glow");
		new r = GetEntData(client, offset+16, 1);
		new g = GetEntData(client, offset+17, 1);
		new b = GetEntData(client, offset+18, 1);
		decl String:rgb[10];
		Format(rgb, sizeof(rgb), "%i%i%i", r, g, b);
		new color = StringToInt(rgb);
		return color;
	}
	return 0;	
}
stock GetSuperTankByRenderColor(color)
{
	switch(color)
	{
		//Fire Tank
		case 12800:
		{
			return 6;
		}
		//Gravity Tank
		case 333435:
		{
			return 15;
		}
		//Ice Tank
		case 0100170:
		{
			return 7;
		}
		//Cobalt Tank
		case 0105255:
		{
			return 13;
		}
		//Meteor Tank
		case 1002525:
		{
			return 3;
		}
		//Jumper Tank
		case 2002550:
		{
			return 14;
		}
		//Jockey Tank
		case 2552000:
		{
			return 8;
		}
		//Smasher Tank
		case 7080100:
		{
			return 1;
		}		
		//Spitter Tank
		case 12115128:
		{
			return 4;
		}
		//Heal Tank
		case 100255200:
		{
			return 5;
		}				
		//Ghost Tank
		case 100100100:
		{
			return 9;
		}
		//Shock Tank
		case 100165255:
		{
			return 10;
		}
		//Warp Tank
		case 130130255:
		{
			return 2;
		}
		//Shield Tank
		case 135205255:
		{
			return 12;
		}
		//Demon Tank
		case 255150100:
		{
			return 16;
		}		
		//Witch Tank
		case 255200255:
		{
			return 11;
		}
		//Default Tank
		case 255255255:
		{
			return 0;
		}
	}
	return -1;
}
stock ResetInfectedAbility(client, Float:time)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			new ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
			if (ability > 0)
			{
				SetEntPropFloat(ability, Prop_Send, "m_duration", time);
				SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
			}
		}
	}
}
public Action:TimerTankWave2(Handle:timer)
{
	CountTanks();
	if (iNumTanks == 0)
	{
		iFinaleStage = 2;
	}
}
public Action:TimerTankWave3(Handle:timer)
{
	CountTanks();
	if (iNumTanks == 0)
	{
		iFinaleStage = 3;
	}
}
public Action:SpawnTankTimer(Handle:timer)
{
	CountTanks();
	if (iFinaleStage == 1)
	{
		if (iNumTanks < iWave1Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (iFinaleStage == 2)
	{
		if (iNumTanks < iWave2Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (iFinaleStage == 3)
	{
		if (iNumTanks < iWave3Cvar)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
}
stock EnableFogRealism()
{
	if (bNightmare)
	{
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			SetEntPropFloat(entity, Prop_Data, "m_fog.start", 242.0);
			SetEntPropFloat(entity, Prop_Data, "m_fog.end", 730.0);
			AcceptEntityInput(entity, "StartFogTransition");
		}
		SetConVarInt(FindConVar("sv_force_time_of_day"), 3);
	}
}
stock DisableFogRealism()
{
	new entity = -1;
	new index = 0;
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(entity, Prop_Data, "m_fog.start", aFogStart[index]);
		SetEntPropFloat(entity, Prop_Data, "m_fog.end", aFogEnd[index]);
		AcceptEntityInput(entity, "StartFogTransition");
		index++;
	}
	while ((entity = FindEntityByClassname(entity, "color_correction")) != INVALID_ENT_REFERENCE)
	{
		if (entity == iCCEnt)
		{
			AcceptEntityInput(entity, "Disable");
			SetVariantString("OnUser1 !self:Kill::4.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
	}
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != INVALID_ENT_REFERENCE)
	{
		if (entity == iFogVolEnt)
		{
			AcceptEntityInput(entity, "Disable");
			SetVariantString("OnUser1 !self:Kill::4.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
		else
		{
			new hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");
			if (hammerid != 3131004 && hammerid != 800572 && hammerid != 2292555 && hammerid != 1616857 && hammerid != 13058 && 
			hammerid != 2733982)
			{
				AcceptEntityInput(entity, "Enable");
			}
		}
	}
	iCCEnt = 0;
	iFogVolEnt = 0;
	SetConVarInt(FindConVar("sv_force_time_of_day"), timeofday);

	if (bNightmare)
	{
		iGameMode = 10;
	}
	else
	{
		iGameMode = 0;
	}
}
stock RenableFogRealism()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "color_correction")) != INVALID_ENT_REFERENCE)
	{
		if (entity == iCCEnt)
		{
			AcceptEntityInput(entity, "Disable");
			SetVariantString("OnUser1 !self:Kill::4.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
	}
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != INVALID_ENT_REFERENCE)
	{
		if (entity == iFogVolEnt)
		{
			AcceptEntityInput(entity, "Disable");
			SetVariantString("OnUser1 !self:Kill::4.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
		else
		{
			new hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");
			if (hammerid != 3131004 && hammerid != 800572 && hammerid != 2292555 && hammerid != 1616857 && hammerid != 13058 && 
			hammerid != 2733982)
			{
				AcceptEntityInput(entity, "Enable");
			}
		}
	}
	iCCEnt = 0;
	iFogVolEnt = 0;
	if (bNightmare)
	{
		iGameMode = 10;
		while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			SetEntPropFloat(entity, Prop_Data, "m_fog.start", 242.0);
			SetEntPropFloat(entity, Prop_Data, "m_fog.end", 730.0);
			AcceptEntityInput(entity, "StartFogTransition");
		}
		SetConVarInt(FindConVar("sv_force_time_of_day"), 3);
	}
	else
	{
		iGameMode = 0;
	}
}
stock CreateColorCorrection(String:FileName[])
{
	decl String:tName[8];
	if (iCCEnt <= 0)
	{
		new colorent = CreateEntityByName("color_correction");
		if (colorent > 32 && IsValidEntity(colorent))
		{
			DispatchKeyValue(colorent, "spawnflags", "2");
			DispatchKeyValue(colorent, "maxweight", "0.6");
			DispatchKeyValue(colorent, "fadeInDuration", "4");
			DispatchKeyValue(colorent, "fadeOutDuration", "4");
			DispatchKeyValue(colorent, "maxfalloff", "-1");
			DispatchKeyValue(colorent, "minfalloff", "-1");
			DispatchKeyValue(colorent, "filename", FileName);
			DispatchSpawn(colorent);
			ActivateEntity(colorent);
			AcceptEntityInput(colorent, "Enable");

			Format(tName, sizeof(tName), "CC%i", colorent);
			DispatchKeyValue(colorent, "targetname", tName);
			iCCEnt = colorent;

			new Float:Origin[3] = {0.0, 0.0, 0.0};
			TeleportEntity(colorent, Origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	if (iFogVolEnt == 0 || iFogVolEnt == -1)
	{
		new fogent = CreateEntityByName("fog_volume");
		if (fogent != -1)
		{
			DispatchKeyValue(fogent, "ColorCorrectionName", tName);
			DispatchKeyValue(fogent, "spawnflags", "0");

			DispatchSpawn(fogent);
			ActivateEntity(fogent);
			AcceptEntityInput(fogent, "Enable");

			new Float:vMins[3] = {-99999.0, -99999.0, -99999.0};
			new Float:vMaxs[3] = {99999.0, 99999.0, 99999.0};
			new Float:Origin[3] = {0.0, 0.0, 0.0};

			SetEntPropVector(fogent, Prop_Send, "m_vecMins", vMins);
			SetEntPropVector(fogent, Prop_Send, "m_vecMaxs", vMaxs);
			iFogVolEnt = fogent;

			TeleportEntity(fogent, Origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "fog_volume")) != INVALID_ENT_REFERENCE)
	{
		if (entity != iFogVolEnt)
		{
			AcceptEntityInput(entity, "Disable");
		}
	}
}

stock ExecGameModes()
{
	if (iFogControl == 0)
	{
		new index = 0;
		new entity = -1;
		while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != INVALID_ENT_REFERENCE)
		{
			aFogStart[index] = GetEntPropFloat(entity, Prop_Data, "m_fog.start");
			aFogEnd[index] = GetEntPropFloat(entity, Prop_Data, "m_fog.end");
			index++;
		}
		timeofday = GetConVarInt(FindConVar("sv_force_time_of_day"));
		iFogControl = 1;
	}
	if (bNightmare)
	{
		if (iGameMode != 10)
		{
			RenableFogRealism();
		}
		if (iFogControl == 1)
		{
			RenableFogRealism();
			iFogControl = 2;
		}
	}
	else
	{
		if (iGameMode != 0)
		{
			DisableFogRealism();
		}
		if (iFogControl == 1)
		{
			DisableFogRealism();
			iFogControl = 2;
		}
	}
	ExecNightmare();
}
stock ExecNightmare()
{
	if (bNightmare)
	{
		new random = GetRandomInt(1,15);
		if (random == 1)
		{
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
		}
		if (iNumTanks < 3)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
		new witchcount = CountWitches();
		if (witchcount < 66)
		{
			CreateWitchEvent();
			if (witchcount < 50)
			{
				CreateWitchEvent();
				if (witchcount < 40)
				{
					CreateWitchEvent();
					if (witchcount < 30)
					{
						CreateWitchEvent();
						if (witchcount < 20)
						{
							CreateWitchEvent();
						}
					}
				}
			}
		}
		RecycleWitches();
		EnrageAllWitches();
		InfernoMeteorFall();
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				DirectorCommand(i, "director_force_panic_event");
				break;
			}
		}
		if (iCCEnt <= 0)
		{
			CreateColorCorrection("materials/correction/urban_night_red.pwl.raw");
		}
	}
	else if (iNightmareBegin == 1)
	{
		if (iFinaleStage < 4)
		{
			StartCountdown();
		}
	}
	else
	{
		if (bIsFinale)
		{
			iCountDownTimer = 60;
			
		}
		else
		{
			iCountDownTimer = 30;
		}
	}
}
stock CreateWitchEvent()
{
	new bot = CreateFakeClient("Witch");
	if (bot > 0)
	{
		SpawnCommand(bot, "z_spawn_old", "witch auto");
	}
}
stock StartCountdown()
{
	if (iFinaleStage < 4)
	{
		new amount;
		if (bIsFinale)
		{
			amount = 60;
		}
		else
		{
			amount = 30;
		}
		if (iNightmareTick >= 0 && iNightmareTick < amount)
		{
			if (bIsFinale)
			{
				if (iFinaleStage <= 0)
				{
					PrintHintTextToAll("Entering Nightmare mode in %i seconds. You must start the finale!", iCountDownTimer);
				}
				else
				{
					PrintHintTextToAll("Entering Nightmare mode in %i seconds. Get to the escape vehicle!", iCountDownTimer);
				}
			}
			else
			{
				PrintHintTextToAll("Entering Nightmare mode in %i seconds. Get to the saferoom!", iCountDownTimer);
			}
			switch(iCountDownTimer)
			{
				case 5: EmitSoundToAll("ui/beep22.wav");
				case 10: EmitSoundToAll("ui/beep22.wav");	
				case 15: EmitSoundToAll("ui/beep22.wav");
				case 20: EmitSoundToAll("ui/beep22.wav");
				case 25: EmitSoundToAll("ui/beep22.wav");
				case 30: EmitSoundToAll("ui/beep22.wav");
				case 35: EmitSoundToAll("ui/beep22.wav");
				case 40: EmitSoundToAll("ui/beep22.wav");
				case 45: EmitSoundToAll("ui/beep22.wav");
				case 50: EmitSoundToAll("ui/beep22.wav");
				case 55: EmitSoundToAll("ui/beep22.wav");
				case 60: EmitSoundToAll("ui/beep22.wav");
			}
			iCountDownTimer -= 1;
		}
		else if (iNightmareTick == amount)
		{
			PrintHintTextToAll("Time limit reached. Entering Nightmare mode...");
			SetConVarBool(hNightmare, true);
		}
		else if (iNightmareTick == (amount + 5))
		{
			PrintHintTextToAll("Nightmare mode enabled, Zombies grow stronger!");
			EmitSoundToAll("npc/mega_mob/mega_mob_incoming.wav");
		}
		iNightmareTick += 1;
	}
}
stock RecycleWitches()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll <= 0)
		{
			new time = GetEntProp(entity, Prop_Send, "m_hEffectEntity");
			SetEntProp(entity, Prop_Send, "m_hEffectEntity", time+1);
			new distance = GetNearestSurvivorDistEnt(entity);
			if (distance > 1000 && time > 20)
			{	
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
}
stock bool:IsWitchAngry(entity)
{
	if (IsWitch(entity))
	{
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll <= 0)
		{
			new Float:rage = GetEntPropFloat(entity, Prop_Send, "m_rage");
			new Float:wanderrage = GetEntPropFloat(entity, Prop_Send, "m_wanderrage");
			if (rage > 0.0 || wanderrage > 0.0)
			{
				return true;
			}
		}
	}
	return false;
}
stock AngryWitchAmount()
{
	new count = 0;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (IsWitchAngry(entity))
		{
			count++;
		}
	}
	return count;
}
stock GetNearestSurvivorDistEnt(entity)
{
    	new Float:EntityPos[3], Float:TargetPos[3], Float:nearest = 0.0, Float:distance = 0.0, visible = 0;
	if (IsWitch(entity) || IsInfected(entity))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", EntityPos);
		if (EntityPos[0] == 0.0 && EntityPos[1] == 0.0 && EntityPos[2] == 0.0)
		{
			return 0;
		}
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll != 0)
		{
			return 0;
		}
   		for (new i=1; i<=MaxClients; i++)
    		{
        		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				if (IsClientViewing(i, entity))
				{
					visible = 1;
				}
				GetClientAbsOrigin(i, TargetPos);
                        	distance = GetVectorDistance(EntityPos, TargetPos);
                        	if (nearest == 0.0 || nearest > distance)
				{
					nearest = distance;
				}
			}
		} 
    	}
	if (visible == 1)
	{
		return 0;
	}
	else
	{
    		return RoundFloat(nearest);
	}
}
stock bool:IsClientViewing(client, target)
{
    	// Retrieve view and target eyes position
	new Float:fThreshold = 0.73;
    	decl Float:fViewPos[3];   
	GetClientEyePosition(client, fViewPos);
    	decl Float:fViewAng[3];
	GetClientEyeAngles(client, fViewAng);
    	decl Float:fViewDir[3];
    	decl Float:fTargetPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", fTargetPos);
	fTargetPos[2] += 30;
    	decl Float:fTargetDir[3];
    	decl Float:fDistance[3];
    
    	// Calculate view direction
    	fViewAng[0] = fViewAng[2] = 0.0;
    	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    	// Calculate distance to viewer to see if it can be seen.
    	fDistance[0] = fTargetPos[0]-fViewPos[0];
    	fDistance[1] = fTargetPos[1]-fViewPos[1];
    	fDistance[2] = 0.0;
    
    	// Check dot product. If it's negative, that means the viewer is facing
    	// backwards to the target.
    	NormalizeVector(fDistance, fTargetDir);
    	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    	// Now check if there are no obstacles in between through raycasting
    	new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    	if (TR_DidHit(hTrace)) 
	{
		CloseHandle(hTrace); 
		return false; 
	}
    	CloseHandle(hTrace);
    	return true;
}
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    	if (Entity > 0 && IsValidEntity(Entity)) return false;
    	return true;
}
stock CountWitches()
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		count++;
	}
	return count;
}
stock EnrageWitches()
{
	new count = 0;
	new random = GetRandomInt(2,6);
	new entity = -1;
	new maxangrywitch = 66;
	if (maxangrywitch > AngryWitchAmount())
	{
		while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
		{
			new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
			if (ragdoll == 0)
			{
				new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
				if (owner <= 0 || !IsWitchAngry(entity))
				{
					new target = Pick();
					if (IsSurvivor(target) && IsPlayerAlive(target))
					{
						L4D2_InfectedHitByVomitJar(entity, target);
						SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
						SetEntProp(entity, Prop_Send, "m_hOwnerEntity", target);
						count++;
						if (count == random)
						{
							break;
						}
					}
				}
			}
		}
	}
}
stock EnrageAllWitches()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		new ragdoll = GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll");
		if (ragdoll == 0)
		{
			new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner <= 0 || !IsWitchAngry(entity))
			{
				new target = Pick();
				if (IsSurvivor(target) && IsPlayerAlive(target))
				{
					L4D2_InfectedHitByVomitJar(entity, target);
					SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
					SetEntProp(entity, Prop_Send, "m_hOwnerEntity", target);
				}
			}
		}
	}
}
stock InfernoMeteorFall()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		if (OnGroundUnits(entity) < 200.0)
		{
			ExplodeInfernoMeteor(entity);
		}
	}
	if (GetRandomInt(1,2) == 1)
	{
		new target = Pick();
		if (IsSurvivor(target) && IsPlayerAlive(target))
		{
			decl Float:pos[3];
			GetClientEyePosition(target, pos);
			decl Float:angle[3], Float:velocity[3], Float:hitpos[3];
			angle[0] = 0.0 + GetRandomFloat(-20.0, 20.0);
			angle[1] = 0.0 + GetRandomFloat(-20.0, 20.0);
			angle[2] = 60.0;
		
			GetVectorAngles(angle, angle);
			GetRayHitPos(pos, angle, hitpos, target, true);
			new Float:dis = GetVectorDistance(pos, hitpos);
			if (GetVectorDistance(pos, hitpos) > 2000.0)
			{
				dis = 1600.0;
			}
			decl Float:t[3];
			MakeVectorFromPoints(pos, hitpos, t);
			NormalizeVector(t, t);
			ScaleVector(t, dis - 40.0);
			AddVectors(pos, t, hitpos);
		
			if (dis > 500.0)
			{
				new ent = CreateEntityByName("tank_rock");
				if (ent > 0)
				{
					DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl"); 
					DispatchSpawn(ent);  
					decl Float:angle2[3];
					angle2[0] = GetRandomFloat(-180.0, 180.0);
					angle2[1] = GetRandomFloat(-180.0, 180.0);
					angle2[2] = GetRandomFloat(-180.0, 180.0);

					velocity[0] = GetRandomFloat(0.0, 350.0);
					velocity[1] = GetRandomFloat(0.0, 350.0);
					velocity[2] = GetRandomFloat(0.0, 30.0);

					TeleportEntity(ent, hitpos, angle2, velocity);
					ActivateEntity(ent);
	 
					AcceptEntityInput(ent, "Ignite");
					SetVariantString("OnUser1 !self:Kill::7.0:-1");
					AcceptEntityInput(ent, "AddOutput");
					AcceptEntityInput(ent, "FireUser1");
				}
			}
		} 
	}
}
stock ExplodeInfernoMeteor(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		new attacker, target;
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i))
			{
				target = i;
				break;
			}
		}
		for (new j=1; j<=MaxClients; j++)
		{
			if (IsTank(j) || IsSpecialInfected(j))
			{
				attacker = j;
				break;
			}
		}
		decl String:classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (!StrEqual(classname, "tank_rock", true))
		{
			return;
		}

		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
		pos[2]+=50.0;
		AcceptEntityInput(entity, "Kill");

		PropaneExplode(target, pos);

		new pointHurt = CreateEntityByName("point_hurt");   
		DispatchKeyValue(pointHurt, "Damage", "20");        
		DispatchKeyValue(pointHurt, "DamageType", "128");  
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);  
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);
		if (attacker > 0)
		{
			AcceptEntityInput(pointHurt, "Hurt", attacker);
		}
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(pointHurt, "AddOutput");
		AcceptEntityInput(pointHurt, "FireUser1");
	}
} 
stock ForceWeaponDrop(client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		decl String:classname[32];
		GetClientWeapon(client, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_melee", false))
		{
			new weaponid = GetPlayerWeaponSlot(client, 1);
			new String:Model[48];
			GetEntPropString(weaponid, Prop_Data, "m_ModelName", Model, sizeof(Model));
			if (StrEqual(Model, MODEL_V_FIREAXE, false)) classname = "weapon_fireaxe";
			else if (StrEqual(Model, MODEL_V_FRYING_PAN, false)) classname = "weapon_frying_pan";
			else if (StrEqual(Model, MODEL_V_MACHETE, false)) classname = "weapon_machete";
			else if (StrEqual(Model, MODEL_V_BAT, false)) classname = "weapon_baseball_bat";
			else if (StrEqual(Model, MODEL_V_CROWBAR, false)) classname = "weapon_crowbar";
			else if (StrEqual(Model, MODEL_V_CRICKET_BAT, false)) classname = "weapon_cricket_bat";
			else if (StrEqual(Model, MODEL_V_TONFA, false)) classname = "weapon_tonfa";
			else if (StrEqual(Model, MODEL_V_KATANA, false)) classname = "weapon_katana";
			else if (StrEqual(Model, MODEL_V_ELECTRIC_GUITAR, false)) classname = "weapon_electric_guitar";
			else if (StrEqual(Model, MODEL_V_KNIFE, false)) classname = "weapon_knife";
			else if (StrEqual(Model, MODEL_V_GOLFCLUB, false)) classname = "weapon_golfclub";		
		}

		new slot = 2;
		for (new index=1; index<=40; index++)
		{
			switch(index)
			{
				case 4: slot = 3;
				case 8: slot = 4;
				case 10: slot = 1;
				case 24: slot = 0;
			}
			if (StrEqual(classname, WeaponClassname[index], false))
			{
				if (index != 10 && index != 11)
				{
					DropSlot(client, index, slot);
					return true;
				}
			}
		}
	}
	return false;
}
public DropSlot(client, index, slot)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (GetPlayerWeaponSlot(client, slot) > 0)
		{
			new weapon = GetPlayerWeaponSlot(client, slot);
			if (index >= 12 && index <= 23)
			{
				CheatCommand(client, "give", "pistol");
			}
			else
			{
				SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
			}
			if (index == 5)
			{
				SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", MODEL_DEFIB);
			}
		}
	}
}
public PerformFade(client, duration, unknown, type1, type2, const Color[4]) 
{
	switch(type1)
	{
		case 1: type1 = FFADE_IN;
		case 2: type1 = FFADE_OUT;
		case 4: type1 = FFADE_MODULATE;
		case 8: type1 = FFADE_STAYOUT;
		case 10: type1 = FFADE_PURGE;
	}
	switch(type2)
	{
		case 1: type2 = FFADE_IN;
		case 2: type2 = FFADE_OUT;
		case 4: type2 = FFADE_MODULATE;
		case 8: type2 = FFADE_STAYOUT;
		case 10: type2 = FFADE_PURGE;
	}
    	new Handle:hFadeClient=StartMessageOne("Fade", client);
    	BfWriteShort(hFadeClient, duration);
    	BfWriteShort(hFadeClient, unknown);
   	BfWriteShort(hFadeClient, (type1|type2));
    	BfWriteByte(hFadeClient, Color[0]);
    	BfWriteByte(hFadeClient, Color[1]);
    	BfWriteByte(hFadeClient, Color[2]);
    	BfWriteByte(hFadeClient, Color[3]);
    	EndMessage();
}
public ScreenShake(target, Float:intensity)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}
stock DealDamagePlayer(target, attacker, dmgtype, dmg, String:inflictor[])
{
	if (target > 0 && target <= 32)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
   	 		decl String:damage[16], String:type[16];
    			IntToString(dmg, damage, sizeof(damage));
    			IntToString(dmgtype, type, sizeof(type));
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchKeyValue(pointHurt, "classname", inflictor);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", (attacker > 0 && IsClientInGame(attacker))?attacker:-1);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}
stock DealDamageEntity(target, attacker, dmgtype, dmg, String:inflictor[])
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
   	 		decl String:damage[16], String:type[16];
    			IntToString(dmg, damage, sizeof(damage));
    			IntToString(dmgtype, type, sizeof(type));
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				if (IsInfected(target) || IsWitch(target))
				{
					new ragdoll = GetEntProp(target, Prop_Data, "m_bClientSideRagdoll");
					if (ragdoll == 0)
					{
						DispatchKeyValue(target, "targetname", "hurtme");
						DispatchKeyValue(pointHurt, "Damage", damage);
						DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
						DispatchKeyValue(pointHurt, "DamageType", type);
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
stock ReturnChapterData()
{
	if (IsMissionFinalMap())
		bIsFinale = true;
	bIsFinale = false;
}
stock CloseSRDoor()
{
	new entity = iSRDoor;
	if (entity > 0 && IsValidEntity(entity))
	{
		if (GetEntProp(entity, Prop_Data, "m_hasUnlockSequence") == 0)
		{
			if (GetEntProp(entity, Prop_Data, "m_eDoorState") == 2)
			{
				AcceptEntityInput(entity, "Close");
			}	
		}
	}
}
stock IdentifySRDoor()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Data, "m_hasUnlockSequence") == 0)
		{
			iSRDoor = entity;	
		}
	}
}
//=============================
// Movement Speed
//=============================
stock UpdateMovementSpeed(client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		decl Float:value;
		if (PlayerSpeed[client] > 0)
		{
			value = flShockStunMovement;
		}
		else
		{
			value = 1.0;
		}
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", value);
	}
}
stock ForceSpawnInfected(String:classname[], Float:Origin[3], Float:Angles[3])
{
	new entity = CreateEntityByName("info_zombie_spawn");
	if (entity > 0 && IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "population", classname);
		DispatchKeyValueVector(entity, "origin", Origin);
		DispatchKeyValueVector(entity, "angles", Angles)
;
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "SpawnZombie");
		AcceptEntityInput(entity, "Kill");
	}
}
stock GasCanExplode(client, Float:Origin[3])
{
	new gascan = CreateEntityByName("prop_physics");
	if (gascan > 32 && IsValidEntity(gascan))
	{
		DispatchKeyValue(gascan, "model", MODEL_GASCAN); 
		DispatchSpawn(gascan);
		if (IsValidClient(client))
		{
			SetEntPropEnt(gascan, Prop_Data, "m_hLastAttacker", client);
		}
		TeleportEntity(gascan, Origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(gascan);
		AcceptEntityInput(gascan, "Break");
	}
}
public Action:Timer_PropaneExplode(Handle:timer, any:data)
{
	new round = ReadPackCell(data);
	new client = ReadPackCell(data);
	decl Float:Location[3];
	Location[0] = ReadPackFloat(data);
	Location[1] = ReadPackFloat(data);
	Location[2] = ReadPackFloat(data);
	CloseHandle(data);

	if (iRound != round || !IsServerProcessing())
	{
		return;
	}
	if (!bNightmare)
	{
		PropaneExplode(client, Location);
	}
}
stock PropaneExplode(client, Float:Origin[3])
{
	new propane = CreateEntityByName("prop_physics");
	if (propane > 32 && IsValidEntity(propane))
	{
		DispatchKeyValue(propane, "model", MODEL_PROPANE); 
		DispatchSpawn(propane);
		if (IsValidClient(client))
		{
			SetEntPropEnt(propane, Prop_Data, "m_hLastAttacker", client);
		}
		TeleportEntity(propane, Origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(propane);
		AcceptEntityInput(propane, "Break");
	}
}
//=============================
// Hooks
//=============================
public OnEntityCreated(entity, const String:classname[])
{
	if (bSuperTanksEnabled)
	{
		if (StrEqual(classname, "tank_rock", false))
		{
			CreateTimer(0.1, RockThrowTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (StrEqual(classname, "witch", false))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage);
		}
	}
}
public OnEntityDestroyed(entity)
{
	if (!IsServerProcessing()) return;

	if (bSuperTanksEnabled)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			new String:classname[10];
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "tank_rock", false))
			{
				new color = GetEntRenderColor(entity);
				switch(color)
				{
					//Fire
					case 12800:
					{
						for (new i=1; i<=MaxClients; i++)
						{
							if (IsTank(i) && GetEntRenderColor(i) == 12800)
							{
								new Float:Origin[3];
								GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
								Origin[2] += 10.0;

								GasCanExplode(i, Origin);
								return;
							}
						}
					}
					//Spitter
					case 12115128:
					{
						for (new i=1; i<=MaxClients; i++)
						{
							if (IsTank(i) && GetEntRenderColor(i) == 12115128)
							{
								new Float:Origin[3];
								GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
								Origin[2] += 10.0;

								new ent = CreateEntityByName("spitter_projectile");
								if (IsValidEntity(ent))
								{
									DispatchSpawn(ent);
									SetEntPropFloat(ent, Prop_Send, "m_DmgRadius", 1024.0);
									SetEntProp(ent, Prop_Send, "m_bIsLive", 1 );
									SetEntPropEnt(ent, Prop_Send, "m_hThrower", i);
									TeleportEntity(ent, Origin, NULL_VECTOR, NULL_VECTOR);
									L4D2_SpitBurst(ent);
								}
								return;
							}
						}
					}
				}
			}
		}
	}
}
public Action:OnEntityTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (damage > 0.0 && victim > 32 && IsValidEntity(victim))
	{
		if (IsWitch(victim) && IsWitch(attacker))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (bSuperTanksEnabled && damage > 0.0)
	{
		decl String:inflictorname[28];
		decl String:weaponname[28];
		if (weapon > 0)
		{
			GetEdictClassname(weapon, weaponname, sizeof(weaponname));
		}
		if (inflictor > 0)
		{
			GetEdictClassname(inflictor, inflictorname, sizeof(inflictorname));
		}
		if (IsSurvivor(victim))
		{
			if (IsInfected(attacker))
			{
				if (bNightmare)
				{
					damage = 30.0;
				}
			}
			else if (IsWitch(attacker))
			{
				if (bNightmare)
				{
					damage = 500.0;
				}
				else if (GetEntProp(attacker, Prop_Send, "m_hOwnerEntity") == 255200255)
				{
					damage = 10.0;
				}
			}
			else if (IsValidClient(attacker))
			{
				if (GetClientTeam(attacker) == 3)
				{
					if (IsTank(attacker))
					{
						new color = GetEntRenderColor(attacker);
						switch(color)
						{
							//Fire Tank
							case 12800:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false) || StrEqual(inflictorname, "tank_rock", false))
								{
									SkillFlameClaw(victim);
								}
							}
							//Gravity Tank
							case 333435:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									SkillGravityClaw(victim);
								}
							}
							//Ice Tank
							case 0100170:
							{
								new flags = GetEntityFlags(victim);
								if (flags & FL_ONGROUND)
								{
									new random = GetRandomInt(1,3);
									if (random == 1)
									{
										SkillIceClaw(victim, attacker);
									}
								}
							}
							//Cobalt Tank
							case 0105255:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									TankAbility[attacker] = 0;
								}
							}
							//Smasher Tank
							case 7080100:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									new random = GetRandomInt(1,2);
									if (random == 1)
									{
										SkillSmashClawKill(victim, attacker);
									}
									else
									{
										SkillSmashClaw(victim);
									}
								}
							}
							//Shock Tank
							case 100165255:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									SkillElecClaw(victim, attacker);
								}
							}
							//Warp Tank
							case 130130255:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									new dmg = RoundFloat(damage / 2);
									DealDamagePlayer(victim, attacker, 128, dmg, "point_hurt");
								}
							}
							//Demon Tank
							case 255150100:
							{
								if (StrEqual(inflictorname, "weapon_tank_claw", false))
								{
									SkillSmashClawKill(victim, attacker);
									//TankAbility[attacker] += 1;
									//DemonTankLevelUp(attacker);
								}
							}
						}
						if (!StrEqual(inflictorname, "inferno", false) && !StrEqual(inflictorname, "pipe_bomb_project", false) && !StrEqual(inflictorname, "insect_swarm", false) && !StrEqual(inflictorname, "point_hurt", false))
						{
							if (bNightmare)
							{
								damage = 200.0;
							}
						}
					}
					else if (IsSpecialInfected(attacker) && bNightmare)
					{
						if (damagetype != 263168 && damagetype != 265216) //not acid
						{
							if (!StrEqual(inflictorname, "pipe_bomb_project", false) && !StrEqual(inflictorname, "point_hurt", false))
							{
								damage = 50.0;
							}
						}
					}
				}
			}
		}
		else if (IsValidClient(victim) && GetClientTeam(victim) == 3)
		{
			if (IsTank(victim))
			{
				if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)
				{
					new index = GetSuperTankByRenderColor(GetEntRenderColor(victim));
					if (index >= 0 && index <= 15)
					{
						if (bTankFireImmunity[index])
						{
							if (index != 0 || (index == 0 && bDefaultOverride))
							{
								return Plugin_Handled;
							}
						}
					}
				}
				if (IsSurvivor(attacker))
				{
					new color = GetEntRenderColor(victim);
					switch(color)
					{
						//Meteor Tank
						case 1002525:
						{
							if (weapon > 32 && IsValidEntity(weapon))
							{
								if (StrEqual(weaponname, "weapon_melee", false))
								{
									new random = GetRandomInt(1,2);
									if (random == 1)
									{
										if (TankAbility[victim] == 0)
										{
											StartMeteorFall(victim);
										}
									}
								}
							}
						}
						//Ghost Tank
						case 100100100:
						{
							if (bGhostDisarm)
							{
								if (StrEqual(weaponname, "weapon_melee"))
								{
									new random = GetRandomInt(1,4);
									if (random == 1)
									{
										ForceWeaponDrop(attacker);
										EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", victim);
									}
								}
							}
						}
						//Shield Tank
						case 135205255:
						{
							if (damagetype == 134217792 || damagetype == 33554432 || damagetype == 16777280 ||
							damagetype == -1602224062 || damagetype == -2139094974 || damagetype == -2122317758)
							{
								ShieldState[victim] = 8;
								if (ShieldsUp[victim] == 1)
								{
									DeactivateShield(victim, 8.0);
								}
							}
							else
							{
								if (ShieldsUp[victim] == 1)
								{
									return Plugin_Handled;
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}
//=============================
//	PARTICLE SYSTEM
//=============================
stock CreateParticle(target, const String:ParticleName[], Float:time, Float:origin)
{
	if (target > 0 && IsValidEntity(target))
	{
   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
			new String:text[28];
        		new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", ParticleName);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
			SetVariantString(text);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
    	}
}
stock AttachParticle(target, const String:ParticleName[], Float:time, Float:x, Float:y, Float:z)
{
	if (target > 0 && IsValidEntity(target))
	{
   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
			new String:text[28];
        		new Float:Origin[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);
			Origin[0] += x;
			Origin[1] += y;
			Origin[2] += z;
			TeleportEntity(particle, Origin, NULL_VECTOR, NULL_VECTOR);

			DispatchKeyValue(particle, "effect_name", ParticleName);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", target);
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
			SetVariantString(text);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
    	}
}
stock AttachParticleLoc(Float:Origin[3], const String:ParticleName[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
    	if (IsValidEntity(particle))
    	{
		TeleportEntity(particle, Origin, NULL_VECTOR, NULL_VECTOR);
		new String:text[28];
		DispatchKeyValue(particle, "effect_name", ParticleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Enable");
		AcceptEntityInput(particle, "start");
		Format(text, sizeof(text), "OnUser1 !self:Kill::%f:-1", time);
		SetVariantString(text);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
    	}
}
stock DisplayParticle(const String:ParticleName[], const Float:vPos[3], const Float:vAng[3])
{
	new entity = CreateEntityByName("info_particle_system");
	if (entity > 32 && IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "effect_name", ParticleName);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		return entity;
	}
	return 0;
}
stock PrecacheParticle(const String:ParticleName[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", ParticleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}  
}
//=============================
//	COMMANDS
//=============================
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
stock SpawnCommand(client, String:command[], String:arguments[] = "")
{
	ChangeClientTeam(client,3);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	if (IsFakeClient(client))
	{
		KickClient(client);
	}
}
stock DirectorCommand(client, String:command[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", command);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
public Action:Command_Nightmare(client, args)
{
	if (bSuperTanksEnabled)
	{
		SetConVarInt(hNightmareBegin, 1);
	}
	return Plugin_Handled;
}
//=============================
// GAMEFRAME
//=============================
public OnGameFrame()
{
	if (!IsServerProcessing()) return;

	if (bSuperTanksEnabled)
	{
		FrameUpdateClients();
	}
}
//=============================
// TIMER 0.1
//=============================
public Action:TimerUpdate01(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;

	if (bSuperTanksEnabled && bDisplayHealthCvar)
	{
		if (iNumTanks > 0)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					if (!IsFakeClient(i))
					{
						new entity = GetClientAimTarget(i, true);
						if (IsTank(entity))
						{
							new health = GetClientHealth(entity);
							if (health > 0)
							{
								PrintHintText(i, "%N (%i HP)", entity, health);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
//=============================
// TIMER 1.0
//=============================
public Action:TimerUpdate1(Handle:timer)
{
	if (bSuperTanksEnabled)
	{
		TankController();
		SpawnInfectedInterval();
		TimerUpdateClients();
		ExecGameModes();
	}

	return Plugin_Continue;
}