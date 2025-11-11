#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/*
===============================================================================
NATAN SUPERTANKS NIGHTMARE - MODULAR VERSION
===============================================================================

This is a modular reorganization of the SuperTanks Nightmare plugin.
The original monolithic file has been kept intact in: Natan_SuperTanks_Nightmare.sp

Future modularization structure:
- supertanks/st_constants.inc (CREATED)
- supertanks/st_variables.inc
- supertanks/st_config.inc
- supertanks/utilities/*.inc
- supertanks/tanks/*.inc
- supertanks/nightmare/*.inc
- supertanks/systems/*.inc

For now, this file includes the constants module and contains the rest of the
original code to maintain functionality while allowing gradual modularization.

Super Tanks Types:
0)  Normal/Default
1)  Smasher
2)  Warp
3)  Meteor
4)  Spitter
5)  Heal
6)  Fire
7)  Ice
8)  Jockey
9)  Ghost
10) Shock
11) Witch
12) Shield
13) Cobalt
14) Jumper
15) Gravity
16) Demon
===============================================================================
*/

// Include modular components
#include "supertanks/st_constants.inc"

#define PLUGIN_VERSION "2.0-modular"

public Plugin:myinfo =
{
	name = "[L4D2] Natan SuperTanks Nightmare (Modular)",
	author = "Natan (Modularized)",
	description = "Adds 16 types of super tanks with special abilities + Nightmare Mode",
	version = PLUGIN_VERSION,
	url = ""
};

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

static bool:bIsFinale = false;

// ConVar Handles - Core
static Handle:hSuperTanksEnabled = INVALID_HANDLE;
static Handle:hDisplayHealthCvar = INVALID_HANDLE;
static Handle:hWave1Cvar = INVALID_HANDLE;
static Handle:hWave2Cvar = INVALID_HANDLE;
static Handle:hWave3Cvar = INVALID_HANDLE;
static Handle:hFinaleOnly = INVALID_HANDLE;
static Handle:hDefaultTanks = INVALID_HANDLE;
static Handle:hGamemodeCvar = INVALID_HANDLE;

// ConVar Handles - Default Tank
static Handle:hDefaultOverride = INVALID_HANDLE;
static Handle:hDefaultExtraHealth = INVALID_HANDLE;
static Handle:hDefaultSpeed = INVALID_HANDLE;
static Handle:hDefaultThrow = INVALID_HANDLE;
static Handle:hDefaultFireImmunity = INVALID_HANDLE;

// ConVar Handles - Tank Types (Smasher through Gravity)
// [Lines 143-246 from original - all ConVar handles for each tank type]
// Note: Full list maintained in original file for reference

// ConVar Handles - Nightmare Mode
static Handle:hNightmare = INVALID_HANDLE;
static Handle:hNightmareBegin = INVALID_HANDLE;

// SDK Call Handles
static Handle:SDKSpitBurst = INVALID_HANDLE;
static Handle:SDKInfectedHitByVomitJar = INVALID_HANDLE;
static Handle:SDKIsMissionFinalMap = INVALID_HANDLE;

// Plugin State Variables
static bool:bSuperTanksEnabled = true;
static bool:bNightmare = false;
static iWave1Cvar;
static iWave2Cvar;
static iWave3Cvar;
static bool:bFinaleOnly;
static bool:bDisplayHealthCvar;
static bool:bDefaultTanks;

// Tank Configuration Arrays
static bool:bTankEnabled[15+1];
static iTankExtraHealth[16+1];
static Float:flTankSpeed[16+1];
static Float:flTankThrow[16+1];
static bool:bTankFireImmunity[16+1];

// Tank-Specific Configuration
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

// Nightmare Mode Variables
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

// Environment Variables
static Float:aFogStart[33];
static Float:aFogEnd[33];
static timeofday;
static iCCEnt;
static iFogVolEnt;
static iGameMode;
static iFogControl;
static iSRDoor;

// Tank-Related Player Arrays
static PlayerSpeed[33];
static TankAbility[33];
static TankAlive[33];
static ShieldsUp[33];
static ShieldState[33];
static GravityClaw[33];
static Rock[33];
static TankAbilityTimer[33];

// Misc
static MODEL_DEFIB;

// ============================================================================
// PLUGIN INITIALIZATION
// ============================================================================

public OnPluginStart()
{
	// NOTE: This is a placeholder for the modular version.
	// The full implementation is maintained in Natan_SuperTanks_Nightmare.sp
	// until complete modularization is achieved.

	PrintToServer("[SuperTanks] Modular structure initialized");
	PrintToServer("[SuperTanks] Using constants from: supertanks/st_constants.inc");
	PrintToServer("[SuperTanks] Full functionality requires compilation of complete modular structure");

	// Future: Load all module includes here
	// #include "supertanks/st_config.inc" initialization
	// #include "supertanks/utilities/st_sdk.inc" initialization
	// etc.
}

// ============================================================================
// NOTE TO DEVELOPERS
// ============================================================================
/*
This modular version provides the foundation for separating the monolithic
5,737-line plugin into maintainable modules.

Current Status:
✓ Folder structure created (tanks/, nightmare/, systems/, utilities/)
✓ Constants extracted (st_constants.inc)
✓ Documentation created (SUPERTANKS_README.md)

Remaining Work:
- Extract all ConVar initialization to st_config.inc
- Extract SDK calls to utilities/st_sdk.inc
- Extract utility functions to utilities/st_utils.inc
- Extract each tank type to tanks/st_tank_*.inc
- Extract nightmare mode to nightmare/*.inc
- Extract systems to systems/*.inc

To use the FULL WORKING VERSION, compile:
    Natan_SuperTanks_Nightmare.sp

To continue modularization, extract functions from the original file
into the appropriate module files following the structure in
SUPERTANKS_README.md
*/
